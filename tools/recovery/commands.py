"""Side-effect-free command specifications for recovery operations."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from .identity import SnapshotIdentity, SnapshotKind
from .settings import RecoverySettings

DEFAULT_TIMEOUT_SECONDS = 60
BACKUP_TIMEOUT_SECONDS = 3600
CHECK_TIMEOUT_SECONDS = 7200
SNAPSHOT_ID = re.compile(r"[0-9a-f]{64}")
DATABASE_DUMP_NAME = "moncv/postgres.dump"
DATABASE_DUMP_COMMAND = (
    "exec pg_dump --format=custom --no-owner --no-privileges "
    '--username="$POSTGRES_USER" --dbname="$POSTGRES_DB"'
)


@dataclass(frozen=True)
class CommandSpec:
    action: str
    arguments: tuple[str, ...]
    cwd: Path
    timeout_seconds: int = DEFAULT_TIMEOUT_SECONDS

    def __post_init__(self) -> None:
        if not self.action or not self.arguments or self.timeout_seconds <= 0:
            raise ValueError("command specification is invalid")


class RecoveryCommands:
    def __init__(self, settings: RecoverySettings) -> None:
        settings.validate()
        self._settings = settings

    def restic_version(self) -> CommandSpec:
        return self._restic("check Restic version", "version")

    def compose_version(self) -> CommandSpec:
        return CommandSpec(
            action="check Docker Compose version",
            arguments=("docker", "compose", "version", "--short"),
            cwd=self._settings.root,
        )

    def backend_state(self) -> CommandSpec:
        return self._compose(
            "inspect backend state", "ps", "--format", "json", "backend"
        )

    def pause_backend(self) -> CommandSpec:
        return self._compose("pause backend writes", "pause", "backend")

    def unpause_backend(self) -> CommandSpec:
        return self._compose("resume backend writes", "unpause", "backend")

    def database_backup(self, identity: SnapshotIdentity) -> CommandSpec:
        child = self._compose_arguments(
            "exec",
            "-T",
            "postgres",
            "sh",
            "-ceu",
            DATABASE_DUMP_COMMAND,
        )
        return self._restic(
            "snapshot PostgreSQL",
            "backup",
            "--json",
            "--host",
            "moncv-production",
            *self._tag_arguments(identity, SnapshotKind.DATABASE),
            "--stdin-filename",
            DATABASE_DUMP_NAME,
            "--stdin-from-command",
            "--",
            *child,
            timeout_seconds=BACKUP_TIMEOUT_SECONDS,
        )

    def uploads_backup(self, identity: SnapshotIdentity) -> CommandSpec:
        return self._restic(
            "snapshot uploads",
            "backup",
            "--json",
            "--host",
            "moncv-production",
            *self._tag_arguments(identity, SnapshotKind.UPLOADS),
            "--one-file-system",
            "--",
            str(self._settings.uploads_path),
            timeout_seconds=BACKUP_TIMEOUT_SECONDS,
        )

    def forget_snapshot(self, snapshot_id: str) -> CommandSpec:
        if SNAPSHOT_ID.fullmatch(snapshot_id) is None:
            raise ValueError("snapshot_id must be a full lowercase Restic identifier")
        return self._restic(
            "remove partial snapshot", "forget", "--json", "--", snapshot_id
        )

    def check_repository(self, identity: SnapshotIdentity) -> CommandSpec:
        return self._restic(
            "verify backup data",
            "check",
            "--read-data",
            "--tag",
            f"operation:{identity.operation_id}",
            timeout_seconds=CHECK_TIMEOUT_SECONDS,
        )

    def _compose(self, action: str, *arguments: str) -> CommandSpec:
        return CommandSpec(
            action=action,
            arguments=self._compose_arguments(*arguments),
            cwd=self._settings.root,
        )

    def _compose_arguments(self, *arguments: str) -> tuple[str, ...]:
        command = [
            "docker",
            "compose",
            "--env-file",
            str(self._settings.compose_environment),
        ]
        for compose_file in self._settings.compose_files:
            command.extend(("-f", str(compose_file)))
        command.extend(arguments)
        return tuple(command)

    def _restic(
        self,
        action: str,
        *arguments: str,
        timeout_seconds: int = DEFAULT_TIMEOUT_SECONDS,
    ) -> CommandSpec:
        return CommandSpec(
            action=action,
            arguments=(
                "restic",
                "--repository-file",
                str(self._settings.repository_file),
                "--password-file",
                str(self._settings.password_file),
                "--no-cache",
                "--retry-lock=2m",
                *arguments,
            ),
            cwd=self._settings.root,
            timeout_seconds=timeout_seconds,
        )

    @staticmethod
    def _tag_arguments(
        identity: SnapshotIdentity, kind: SnapshotKind
    ) -> tuple[str, ...]:
        return tuple(value for tag in identity.tags(kind) for value in ("--tag", tag))
