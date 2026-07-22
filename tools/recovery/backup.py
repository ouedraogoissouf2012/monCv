"""Transactional coordination of coherent production backups."""

from __future__ import annotations

import json
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Protocol

from .commands import SNAPSHOT_ID, CommandSpec, RecoveryCommands
from .identity import SnapshotIdentity
from .runner import RecoveryCommandError


class CommandExecutor(Protocol):
    def run(self, specification: CommandSpec) -> str: ...


class BackupProtocolError(RuntimeError):
    """Raised when an external tool returns an unexpected safe contract."""


class BackupError(RuntimeError):
    def __init__(self, error_codes: tuple[str, ...]) -> None:
        self.error_codes = tuple(dict.fromkeys(error_codes))
        super().__init__("Backup failed: " + ", ".join(self.error_codes))


@dataclass(frozen=True)
class BackupReceipt:
    operation_id: str
    deployed_sha: str
    database_snapshot: str
    uploads_snapshot: str
    completed_at: datetime


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


class BackupCoordinator:
    def __init__(
        self,
        commands: RecoveryCommands,
        executor: CommandExecutor,
        clock: Callable[[], datetime] = _utc_now,
    ) -> None:
        self._commands = commands
        self._executor = executor
        self._clock = clock

    def create_backup(self, identity: SnapshotIdentity) -> BackupReceipt:
        try:
            self._require_healthy_backend()
        except (BackupProtocolError, RecoveryCommandError) as error:
            raise BackupError(("BACKEND_PREFLIGHT_FAILED",)) from error
        restart_required = False
        snapshots: list[str] = []
        failure: BackupError | None = None
        cause: Exception | None = None
        receipt: BackupReceipt | None = None
        try:
            restart_required = True
            self._executor.run(self._commands.stop_backend())
            database = self._capture(
                self._commands.database_backup(identity), snapshots
            )
            uploads = self._capture(self._commands.uploads_backup(identity), snapshots)
            if database == uploads:
                raise BackupProtocolError("snapshot identifiers must be distinct")
            self._executor.run(self._commands.check_repository(identity))
            completed_at = self._clock()
            if completed_at.utcoffset() is None:
                raise BackupProtocolError("completion clock must be timezone-aware")
            receipt = BackupReceipt(
                operation_id=identity.operation_id,
                deployed_sha=identity.deployed_sha,
                database_snapshot=database,
                uploads_snapshot=uploads,
                completed_at=completed_at.astimezone(timezone.utc),
            )
        except (BackupProtocolError, RecoveryCommandError) as error:
            codes = ["BACKUP_INCOMPLETE"]
            if self._rollback(snapshots):
                codes.append("SNAPSHOT_CLEANUP_FAILED")
            failure = BackupError(tuple(codes))
            cause = error
        finally:
            if restart_required:
                try:
                    self._executor.run(self._commands.start_backend())
                except RecoveryCommandError as error:
                    codes = ["BACKEND_RESTART_FAILED"]
                    if failure is not None:
                        codes.extend(failure.error_codes)
                    raise BackupError(tuple(codes)) from error

        if failure is not None:
            raise failure from cause
        if receipt is None:
            raise BackupError(("BACKUP_RECEIPT_MISSING",))
        return receipt

    def _require_healthy_backend(self) -> None:
        output = self._executor.run(self._commands.backend_state())
        services = _json_objects(output)
        if len(services) != 1:
            raise BackupProtocolError("backend state is ambiguous")
        service = services[0]
        state = str(service.get("State", "")).casefold()
        health = str(service.get("Health", "")).casefold()
        if state != "running" or health != "healthy":
            raise BackupProtocolError("backend must be running and healthy")

    def _capture(self, specification: CommandSpec, snapshots: list[str]) -> str:
        output = self._executor.run(specification)
        identifiers = [
            str(item.get("snapshot_id", ""))
            for item in _json_objects(output)
            if item.get("message_type") == "summary"
        ]
        if len(identifiers) != 1 or SNAPSHOT_ID.fullmatch(identifiers[0]) is None:
            raise BackupProtocolError("snapshot result is invalid")
        snapshots.append(identifiers[0])
        return identifiers[0]

    def _rollback(self, snapshots: list[str]) -> bool:
        failed = False
        for snapshot_id in dict.fromkeys(reversed(snapshots)):
            try:
                self._executor.run(self._commands.forget_snapshot(snapshot_id))
            except RecoveryCommandError:
                failed = True
        return failed


def _json_objects(output: str) -> list[dict]:
    try:
        decoded = json.loads(output)
        values = decoded if isinstance(decoded, list) else [decoded]
    except json.JSONDecodeError:
        try:
            values = [json.loads(line) for line in output.splitlines() if line.strip()]
        except json.JSONDecodeError as error:
            raise BackupProtocolError("external JSON is invalid") from error
    if not values or any(not isinstance(value, dict) for value in values):
        raise BackupProtocolError("external JSON contract is invalid")
    return values
