"""Bounded, atomic JSON receipts for backup and restore operations."""

from __future__ import annotations

import json
import re
import uuid
from datetime import UTC, datetime

from .backup import BackupReceipt
from .commands import SNAPSHOT_ID
from .identity import SnapshotIdentity
from .restore_contract import RestoreReceipt
from .validation import MIGRATION_VERSION

BACKUP_FORMAT = "moncv-backup-receipt/v1"
RESTORE_FORMAT = "moncv-restore-receipt/v1"
MAX_RECEIPT_BYTES = 64 * 1024
SHA256 = re.compile(r"[0-9a-f]{64}")
BACKUP_KEYS = frozenset(
    {
        "format",
        "operation_id",
        "deployed_sha",
        "database_snapshot",
        "uploads_snapshot",
        "completed_at",
    }
)
RESTORE_KEYS = frozenset(
    {
        *BACKUP_KEYS,
        "drill_id",
        "latest_migration",
        "migration_count",
        "upload_files",
        "upload_directories",
        "upload_bytes",
        "uploads_sha256",
    }
)


class ReceiptError(RuntimeError):
    def __init__(self, error_code: str) -> None:
        self.error_code = error_code
        super().__init__("Recovery receipt failed: " + error_code)


def encode_backup_receipt(receipt: BackupReceipt) -> str:
    try:
        payload = {
            "format": BACKUP_FORMAT,
            "operation_id": receipt.operation_id,
            "deployed_sha": receipt.deployed_sha,
            "database_snapshot": receipt.database_snapshot,
            "uploads_snapshot": receipt.uploads_snapshot,
            "completed_at": _format_time(receipt.completed_at),
        }
        _parse_backup(payload)
        return _encode(payload)
    except (AttributeError, TypeError, UnicodeError, ValueError) as error:
        raise ReceiptError("RECEIPT_INVALID") from error


def decode_backup_receipt(document: str) -> BackupReceipt:
    try:
        return _parse_backup(_decode(document))
    except (AttributeError, TypeError, UnicodeError, ValueError) as error:
        raise ReceiptError("RECEIPT_INVALID") from error


def encode_restore_receipt(receipt: RestoreReceipt) -> str:
    try:
        payload = {
            "format": RESTORE_FORMAT,
            "drill_id": receipt.drill_id,
            "operation_id": receipt.operation_id,
            "deployed_sha": receipt.deployed_sha,
            "database_snapshot": receipt.database_snapshot,
            "uploads_snapshot": receipt.uploads_snapshot,
            "latest_migration": receipt.latest_migration,
            "migration_count": receipt.migration_count,
            "upload_files": receipt.upload_files,
            "upload_directories": receipt.upload_directories,
            "upload_bytes": receipt.upload_bytes,
            "uploads_sha256": receipt.uploads_sha256,
            "completed_at": _format_time(receipt.completed_at),
        }
        _parse_restore(payload)
        return _encode(payload)
    except (AttributeError, TypeError, UnicodeError, ValueError) as error:
        raise ReceiptError("RECEIPT_INVALID") from error


def decode_restore_receipt(document: str) -> RestoreReceipt:
    try:
        return _parse_restore(_decode(document))
    except (AttributeError, TypeError, UnicodeError, ValueError) as error:
        raise ReceiptError("RECEIPT_INVALID") from error


def _parse_backup(payload: dict) -> BackupReceipt:
    _require_keys(payload, BACKUP_KEYS, BACKUP_FORMAT)
    identity = SnapshotIdentity.create(payload["deployed_sha"], payload["operation_id"])
    database = payload["database_snapshot"]
    uploads = payload["uploads_snapshot"]
    if (
        not isinstance(database, str)
        or not isinstance(uploads, str)
        or database == uploads
        or SNAPSHOT_ID.fullmatch(database) is None
        or SNAPSHOT_ID.fullmatch(uploads) is None
    ):
        raise ValueError
    return BackupReceipt(
        operation_id=identity.operation_id,
        deployed_sha=identity.deployed_sha,
        database_snapshot=database,
        uploads_snapshot=uploads,
        completed_at=_parse_time(payload["completed_at"]),
    )


def _parse_restore(payload: dict) -> RestoreReceipt:
    _require_keys(payload, RESTORE_KEYS, RESTORE_FORMAT)
    backup_payload = {key: payload[key] for key in BACKUP_KEYS}
    backup_payload["format"] = BACKUP_FORMAT
    backup = _parse_backup(backup_payload)
    drill_id = _canonical_uuid(payload["drill_id"])
    latest = payload["latest_migration"]
    counts = (
        payload["migration_count"],
        payload["upload_files"],
        payload["upload_directories"],
        payload["upload_bytes"],
    )
    digest = payload["uploads_sha256"]
    if (
        not isinstance(latest, str)
        or MIGRATION_VERSION.fullmatch(latest) is None
        or not all(type(value) is int and value >= 0 for value in counts)
        or counts[0] == 0
        or not isinstance(digest, str)
        or SHA256.fullmatch(digest) is None
    ):
        raise ValueError
    return RestoreReceipt(
        drill_id=drill_id,
        operation_id=backup.operation_id,
        deployed_sha=backup.deployed_sha,
        database_snapshot=backup.database_snapshot,
        uploads_snapshot=backup.uploads_snapshot,
        latest_migration=latest,
        migration_count=counts[0],
        upload_files=counts[1],
        upload_directories=counts[2],
        upload_bytes=counts[3],
        uploads_sha256=digest,
        completed_at=backup.completed_at,
    )


def _require_keys(payload: dict, expected: frozenset[str], format_name: str) -> None:
    if (
        not isinstance(payload, dict)
        or frozenset(payload) != expected
        or payload.get("format") != format_name
    ):
        raise ValueError


def _canonical_uuid(value: object) -> str:
    if not isinstance(value, str):
        raise TypeError
    parsed = uuid.UUID(value)
    if str(parsed) != value:
        raise ValueError
    return value


def _format_time(value: datetime) -> str:
    if not isinstance(value, datetime) or value.utcoffset() is None:
        raise ValueError
    return (
        value.astimezone(UTC).isoformat(timespec="microseconds").replace("+00:00", "Z")
    )


def _parse_time(value: object) -> datetime:
    if not isinstance(value, str) or not value.endswith("Z"):
        raise ValueError
    parsed = datetime.fromisoformat(value)
    if _format_time(parsed) != value:
        raise ValueError
    return parsed


def _encode(payload: dict) -> str:
    document = json.dumps(
        payload, ensure_ascii=True, sort_keys=True, separators=(",", ":")
    )
    encoded = (document + "\n").encode("utf-8")
    if len(encoded) > MAX_RECEIPT_BYTES:
        raise ValueError
    return encoded.decode("utf-8")


def _decode(document: str) -> dict:
    if (
        not isinstance(document, str)
        or len(document.encode("utf-8")) > MAX_RECEIPT_BYTES
    ):
        raise ValueError
    try:
        payload = json.loads(document, object_pairs_hook=_unique_object)
    except (json.JSONDecodeError, UnicodeError) as error:
        raise ValueError from error
    if not isinstance(payload, dict):
        raise TypeError
    return payload


def _unique_object(pairs: list[tuple[str, object]]) -> dict:
    result: dict = {}
    for key, value in pairs:
        if key in result:
            raise ValueError
        result[key] = value
    return result
