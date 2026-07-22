"""Pure validation of restored snapshot metadata and Flyway history."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path

from .backup import BackupReceipt
from .commands import SNAPSHOT_ID
from .identity import SnapshotIdentity, SnapshotKind

MIGRATION_FILE = re.compile(
    r"V(?P<version>[0-9]+(?:[._][0-9]+)*)__[A-Za-z0-9][A-Za-z0-9_]*\.sql"
)
MIGRATION_VERSION = re.compile(r"[0-9]+(?:[._][0-9]+)*")
MANAGED_TAG_PREFIXES = ("operation:", "git:", "kind:")


class RestoreValidationError(RuntimeError):
    def __init__(self, error_code: str) -> None:
        self.error_code = error_code
        super().__init__("Restore validation failed: " + error_code)


@dataclass(frozen=True)
class MigrationCatalog:
    versions: tuple[str, ...]

    @classmethod
    def from_directory(cls, directory: Path) -> MigrationCatalog:
        candidate = Path(directory)
        try:
            resolved = candidate.resolve(strict=True)
            entries = tuple(resolved.iterdir())
        except OSError as error:
            raise RestoreValidationError("MIGRATION_CATALOG_INVALID") from error
        if candidate.is_symlink() or not resolved.is_dir() or not entries:
            raise RestoreValidationError("MIGRATION_CATALOG_INVALID")
        versions: dict[tuple[int, ...], str] = {}
        for entry in entries:
            match = MIGRATION_FILE.fullmatch(entry.name)
            if entry.is_symlink() or not entry.is_file() or match is None:
                raise RestoreValidationError("MIGRATION_CATALOG_INVALID")
            key = _version_key(match.group("version"))
            if key in versions:
                raise RestoreValidationError("MIGRATION_CATALOG_INVALID")
            versions[key] = ".".join(str(part) for part in key)
        return cls(tuple(versions[key] for key in sorted(versions)))


@dataclass(frozen=True)
class SchemaProof:
    versions: tuple[str, ...]

    @property
    def latest_version(self) -> str:
        return self.versions[-1]


@dataclass(frozen=True)
class SnapshotProof:
    operation_id: str
    deployed_sha: str
    database_snapshot: str
    uploads_snapshot: str


def validate_restored_schema(output: str, catalog: MigrationCatalog) -> SchemaProof:
    values = _json_list(output, "RESTORE_SCHEMA_INVALID")
    actual: list[tuple[int, ...]] = []
    try:
        for value in values:
            if not isinstance(value, dict) or value.get("success") is not True:
                raise ValueError
            version = value.get("version")
            if (
                not isinstance(version, str)
                or MIGRATION_VERSION.fullmatch(version) is None
            ):
                raise ValueError
            actual.append(_version_key(version))
    except (TypeError, ValueError) as error:
        raise RestoreValidationError("RESTORE_SCHEMA_INVALID") from error
    expected = tuple(_version_key(version) for version in catalog.versions)
    if tuple(actual) != expected or len(set(actual)) != len(actual):
        raise RestoreValidationError("RESTORE_SCHEMA_INVALID")
    return SchemaProof(catalog.versions)


def validate_snapshot_metadata(output: str, receipt: BackupReceipt) -> SnapshotProof:
    try:
        identity = SnapshotIdentity.create(receipt.deployed_sha, receipt.operation_id)
        database_snapshot = receipt.database_snapshot
        uploads_snapshot = receipt.uploads_snapshot
    except (AttributeError, ValueError) as error:
        raise RestoreValidationError("RESTORE_SNAPSHOTS_INVALID") from error
    if (
        not isinstance(database_snapshot, str)
        or not isinstance(uploads_snapshot, str)
        or database_snapshot == uploads_snapshot
        or SNAPSHOT_ID.fullmatch(database_snapshot) is None
        or SNAPSHOT_ID.fullmatch(uploads_snapshot) is None
    ):
        raise RestoreValidationError("RESTORE_SNAPSHOTS_INVALID")
    expected = {
        database_snapshot: SnapshotKind.DATABASE,
        uploads_snapshot: SnapshotKind.UPLOADS,
    }
    values = _json_list(output, "RESTORE_SNAPSHOTS_INVALID")
    observed: set[str] = set()
    for value in values:
        if not isinstance(value, dict):
            raise RestoreValidationError("RESTORE_SNAPSHOTS_INVALID")
        snapshot_id = value.get("id")
        kind = expected.get(snapshot_id)
        tags = value.get("tags")
        if (
            kind is None
            or snapshot_id in observed
            or value.get("hostname") != "moncv-production"
            or not isinstance(tags, list)
            or any(not isinstance(tag, str) for tag in tags)
        ):
            raise RestoreValidationError("RESTORE_SNAPSHOTS_INVALID")
        required = set(identity.tags(kind))
        managed = [
            tag
            for tag in tags
            if tag == "moncv" or tag.startswith(MANAGED_TAG_PREFIXES)
        ]
        if set(managed) != required or len(managed) != len(required):
            raise RestoreValidationError("RESTORE_SNAPSHOTS_INVALID")
        observed.add(snapshot_id)
    if observed != set(expected):
        raise RestoreValidationError("RESTORE_SNAPSHOTS_INVALID")
    return SnapshotProof(
        identity.operation_id,
        identity.deployed_sha,
        database_snapshot,
        uploads_snapshot,
    )


def _json_list(output: str, error_code: str) -> list:
    try:
        values = json.loads(output)
    except (json.JSONDecodeError, TypeError) as error:
        raise RestoreValidationError(error_code) from error
    if not isinstance(values, list) or not values:
        raise RestoreValidationError(error_code)
    return values


def _version_key(version: str) -> tuple[int, ...]:
    values = [int(value) for value in re.split(r"[._]", version)]
    while len(values) > 1 and values[-1] == 0:
        values.pop()
    return tuple(values)
