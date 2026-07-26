"""Fail-closed orchestration of complete disposable recovery drills."""

from __future__ import annotations

import tempfile
from collections.abc import Callable
from datetime import UTC, datetime
from pathlib import Path
from typing import Protocol

from .backup import BackupReceipt
from .commands import CommandSpec
from .identity import SnapshotIdentity
from .restore_commands import RestoreCommands
from .restore_contract import RestoreError, RestoreFailure, RestoreReceipt
from .runner import RecoveryCommandError
from .settings import RecoverySettings
from .target import RestoreTarget
from .uploads import UploadsProof, validate_restored_uploads
from .validation import (
    RestoreValidationError,
    SchemaProof,
    SnapshotProof,
    validate_snapshot_metadata,
)


class CommandExecutor(Protocol):
    def run(self, specification: CommandSpec) -> str: ...


class DatabaseRestorer(Protocol):
    def restore(self, target: RestoreTarget, snapshot_id: str) -> SchemaProof: ...


class DisposableWorkspace(Protocol):
    name: str

    def cleanup(self) -> None: ...


def _utc_now() -> datetime:
    return datetime.now(UTC)


def _temporary_workspace() -> DisposableWorkspace:
    return tempfile.TemporaryDirectory(prefix="moncv-restore-")


class RestoreCoordinator:
    def __init__(
        self,
        settings: RecoverySettings,
        executor: CommandExecutor,
        database: DatabaseRestorer,
        *,
        clock: Callable[[], datetime] = _utc_now,
        workspace_factory: Callable[[], DisposableWorkspace] = _temporary_workspace,
    ) -> None:
        settings.validate()
        self._settings = settings
        self._commands = RestoreCommands(settings)
        self._executor = executor
        self._database = database
        self._clock = clock
        self._workspace_factory = workspace_factory

    def run(self, receipt: BackupReceipt) -> RestoreReceipt:
        snapshots = self._validate_snapshots(receipt)
        try:
            workspace = self._workspace_factory()
        except (OSError, TypeError, ValueError) as error:
            raise RestoreError((RestoreFailure.WORKSPACE_CREATE,)) from error

        failure: RestoreError | None = None
        target: RestoreTarget | None = None
        schema: SchemaProof | None = None
        uploads: UploadsProof | None = None
        try:
            identity = SnapshotIdentity.create(
                snapshots.deployed_sha, snapshots.operation_id
            )
            target = RestoreTarget(Path(workspace.name), identity)
            upload_command = self._commands.restore_uploads(
                snapshots.uploads_snapshot, target
            )
            schema = self._database.restore(target, snapshots.database_snapshot)
            uploads = self._restore_uploads(upload_command, target)
        except RestoreError as error:
            failure = error
        except (AttributeError, OSError, TypeError, ValueError) as error:
            failure = RestoreError((RestoreFailure.TARGET_INVALID,))
            failure.__cause__ = error
        finally:
            try:
                workspace.cleanup()
            except (AttributeError, OSError) as error:
                codes = failure.error_codes if failure else ()
                failure = RestoreError((*codes, RestoreFailure.WORKSPACE_CLEANUP))
                failure.__cause__ = error

        if failure is not None:
            raise failure
        if target is None or schema is None or uploads is None:
            raise RestoreError((RestoreFailure.RECEIPT_INVALID,))
        return RestoreReceipt(
            drill_id=target.drill_id,
            operation_id=snapshots.operation_id,
            deployed_sha=snapshots.deployed_sha,
            database_snapshot=snapshots.database_snapshot,
            uploads_snapshot=snapshots.uploads_snapshot,
            latest_migration=schema.latest_version,
            migration_count=len(schema.versions),
            upload_files=uploads.file_count,
            upload_directories=uploads.directory_count,
            upload_bytes=uploads.total_bytes,
            uploads_sha256=uploads.tree_sha256,
            completed_at=self._completion_time(),
        )

    def _validate_snapshots(self, receipt: BackupReceipt) -> SnapshotProof:
        try:
            specification = self._commands.snapshot_metadata(
                receipt.database_snapshot, receipt.uploads_snapshot
            )
        except (AttributeError, TypeError, ValueError) as error:
            raise RestoreError((RestoreFailure.SNAPSHOTS_INVALID,)) from error
        try:
            output = self._executor.run(specification)
        except RecoveryCommandError as error:
            raise RestoreError((RestoreFailure.SNAPSHOT_PREFLIGHT,)) from error
        try:
            return validate_snapshot_metadata(
                output, receipt, self._settings.uploads_path
            )
        except RestoreValidationError as error:
            raise RestoreError((error.error_code,)) from error

    def _restore_uploads(
        self, specification: CommandSpec, target: RestoreTarget
    ) -> UploadsProof:
        try:
            self._executor.run(specification)
        except RecoveryCommandError as error:
            raise RestoreError((RestoreFailure.UPLOADS_RESTORE,)) from error
        try:
            return validate_restored_uploads(target.uploads_directory)
        except RestoreValidationError as error:
            raise RestoreError((error.error_code,)) from error

    def _completion_time(self) -> datetime:
        try:
            completed_at = self._clock()
            if (
                not isinstance(completed_at, datetime)
                or completed_at.utcoffset() is None
            ):
                raise ValueError
            return completed_at.astimezone(UTC)
        except (OSError, OverflowError, TypeError, ValueError) as error:
            raise RestoreError((RestoreFailure.RECEIPT_INVALID,)) from error
