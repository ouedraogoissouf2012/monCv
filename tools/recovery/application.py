"""Composition layer for backup and restore recovery use cases."""

from __future__ import annotations

from collections.abc import Mapping
from pathlib import Path
from typing import Protocol

from .backup import BackupCoordinator, BackupReceipt
from .commands import CommandSpec, RecoveryCommands
from .identity import SnapshotIdentity
from .pipeline import PipelineSpec, SafePipelineRunner
from .receipt_store import (
    read_backup_receipt,
    validate_receipt_destination,
    write_backup_receipt,
    write_restore_receipt,
)
from .restore import RestoreCoordinator
from .restore_commands import RestoreCommands
from .restore_contract import RestoreReceipt
from .restore_database import DatabaseRestoreCoordinator
from .runner import SafeCommandRunner
from .settings import RecoverySettings
from .toolchain import ToolchainProof, ToolchainVerifier
from .validation import MigrationCatalog

MIGRATIONS_DIRECTORY = Path("backend/src/main/resources/db/migration")


class CommandExecutor(Protocol):
    def run(self, specification: CommandSpec) -> str: ...


class PipelineExecutor(Protocol):
    def run(self, specification: PipelineSpec) -> None: ...


class RecoveryApplication:
    def __init__(
        self,
        settings: RecoverySettings,
        executor: CommandExecutor,
        pipeline: PipelineExecutor,
    ) -> None:
        settings.validate()
        self._settings = settings
        self._executor = executor
        self._pipeline = pipeline
        self._commands = RecoveryCommands(settings)

    @classmethod
    def from_environment(
        cls,
        root: Path,
        environment: Mapping[str, str] | None = None,
        *,
        allow_local_repository: bool = False,
    ) -> RecoveryApplication:
        settings = RecoverySettings.from_environment(
            root,
            environment,
            allow_local_repository=allow_local_repository,
        )
        return cls(
            settings,
            SafeCommandRunner(environment),
            SafePipelineRunner(environment),
        )

    def verify_toolchain(self) -> ToolchainProof:
        return ToolchainVerifier(self._commands, self._executor).verify()

    def create_backup(
        self,
        deployed_sha: str,
        receipt_path: Path,
    ) -> BackupReceipt:
        identity = SnapshotIdentity.create(deployed_sha)
        validate_receipt_destination(receipt_path)
        self.verify_toolchain()
        receipt = BackupCoordinator(
            self._commands,
            self._executor,
        ).create_backup(identity)
        write_backup_receipt(receipt_path, receipt)
        return receipt

    def prove_restore(
        self,
        backup_receipt_path: Path,
        restore_receipt_path: Path,
    ) -> RestoreReceipt:
        backup_receipt = read_backup_receipt(backup_receipt_path)
        catalog = MigrationCatalog.from_directory(
            self._settings.root / MIGRATIONS_DIRECTORY
        )
        validate_receipt_destination(restore_receipt_path)
        self.verify_toolchain()
        restore_commands = RestoreCommands(self._settings)
        database = DatabaseRestoreCoordinator(
            restore_commands,
            self._executor,
            self._pipeline,
            catalog,
        )
        receipt = RestoreCoordinator(
            self._settings,
            self._executor,
            database,
        ).run(backup_receipt)
        write_restore_receipt(restore_receipt_path, receipt)
        return receipt
