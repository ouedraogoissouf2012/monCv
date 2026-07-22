"""Hardened command specifications for disposable restore drills."""

from __future__ import annotations

from pathlib import Path

from .commands import (
    DATABASE_DUMP_NAME,
    DEFAULT_TIMEOUT_SECONDS,
    SNAPSHOT_ID,
    CommandSpec,
    restic_command,
)
from .pipeline import PipelineSpec
from .settings import RecoverySettings
from .target import RestoreTarget

RESTORE_TIMEOUT_SECONDS = 3600
RESTORE_DATABASE_IMAGE = (
    "postgres@sha256:979c4379dd698aba0b890599a6104e082035f98ef31d9b9291ec22f2b13059ca"
)
RESTORE_DATABASE_NAME = "moncv_restore"
RESTORE_SCHEMA_QUERY = (
    "SELECT COALESCE(json_agg(json_build_object('version', version, "
    "'success', success) ORDER BY installed_rank), '[]'::json) "
    "FROM flyway_schema_history WHERE version IS NOT NULL;"
)


class RestoreCommands:
    def __init__(self, settings: RecoverySettings) -> None:
        settings.validate()
        self._settings = settings

    def database_dump(self, snapshot_id: str) -> CommandSpec:
        self._require_snapshot_id(snapshot_id)
        return self._restic(
            "stream database snapshot", "dump", snapshot_id, DATABASE_DUMP_NAME
        )

    def snapshot_metadata(
        self, database_snapshot: str, uploads_snapshot: str
    ) -> CommandSpec:
        self._require_snapshot_id(database_snapshot)
        self._require_snapshot_id(uploads_snapshot)
        if database_snapshot == uploads_snapshot:
            raise ValueError("restore snapshots must be distinct")
        return restic_command(
            self._settings,
            "inspect restore snapshots",
            "snapshots",
            "--json",
            "--",
            database_snapshot,
            uploads_snapshot,
        )

    def create_database(self, target: RestoreTarget) -> CommandSpec:
        self._require_disposable_target(target)
        return CommandSpec(
            action="create isolated restore database",
            arguments=(
                "docker",
                "run",
                "--detach",
                "--name",
                target.container_name,
                "--label",
                "com.moncv.recovery=restore-drill",
                "--label",
                f"com.moncv.recovery.operation={target.operation_id}",
                "--network",
                "none",
                "--read-only",
                "--security-opt",
                "no-new-privileges:true",
                "--cap-drop",
                "ALL",
                "--cap-add",
                "CHOWN",
                "--cap-add",
                "DAC_OVERRIDE",
                "--cap-add",
                "FOWNER",
                "--cap-add",
                "SETGID",
                "--cap-add",
                "SETUID",
                "--pids-limit",
                "256",
                "--memory",
                "2g",
                "--memory-swap",
                "2g",
                "--cpus",
                "2",
                "--tmpfs",
                "/var/lib/postgresql/data:rw,nosuid,nodev,size=2g",
                "--tmpfs",
                "/var/run/postgresql:rw,nosuid,nodev,size=16m",
                "--tmpfs",
                "/tmp:rw,noexec,nosuid,nodev,size=64m",
                "--env",
                f"POSTGRES_DB={RESTORE_DATABASE_NAME}",
                "--env",
                "POSTGRES_HOST_AUTH_METHOD=trust",
                RESTORE_DATABASE_IMAGE,
            ),
            cwd=self._settings.root,
        )

    def database_ready(self, target: RestoreTarget) -> CommandSpec:
        return self._database_exec(
            "probe isolated restore database",
            target,
            "pg_isready",
            "--quiet",
            "--username",
            "postgres",
            "--dbname",
            RESTORE_DATABASE_NAME,
        )

    def import_database(self, target: RestoreTarget) -> CommandSpec:
        return self._database_exec(
            "import database snapshot",
            target,
            "pg_restore",
            "--exit-on-error",
            "--single-transaction",
            "--no-owner",
            "--no-privileges",
            "--dbname",
            RESTORE_DATABASE_NAME,
            interactive=True,
            timeout_seconds=RESTORE_TIMEOUT_SECONDS,
        )

    def database_restore(self, snapshot_id: str, target: RestoreTarget) -> PipelineSpec:
        return PipelineSpec(
            action="restore database snapshot",
            source=self.database_dump(snapshot_id),
            sink=self.import_database(target),
            timeout_seconds=RESTORE_TIMEOUT_SECONDS,
        )

    def restored_schema(self, target: RestoreTarget) -> CommandSpec:
        return self._database_exec(
            "inspect restored Flyway schema",
            target,
            "psql",
            "--no-psqlrc",
            "--tuples-only",
            "--no-align",
            "--set",
            "ON_ERROR_STOP=1",
            "--dbname",
            RESTORE_DATABASE_NAME,
            "--command",
            RESTORE_SCHEMA_QUERY,
        )

    def restore_uploads(self, snapshot_id: str, target: RestoreTarget) -> CommandSpec:
        self._require_snapshot_id(snapshot_id)
        self._require_disposable_target(target)
        return self._restic(
            "restore uploads snapshot",
            "restore",
            "--verify",
            "--overwrite",
            "never",
            "--target",
            str(target.uploads_directory),
            snapshot_id,
        )

    def remove_database(self, target: RestoreTarget) -> CommandSpec:
        self._require_disposable_target(target)
        return CommandSpec(
            action="remove isolated restore database",
            arguments=("docker", "rm", "--force", "--volumes", target.container_name),
            cwd=self._settings.root,
        )

    def _database_exec(
        self,
        action: str,
        target: RestoreTarget,
        *arguments: str,
        interactive: bool = False,
        timeout_seconds: int = DEFAULT_TIMEOUT_SECONDS,
    ) -> CommandSpec:
        self._require_disposable_target(target)
        command = ["docker", "exec"]
        if interactive:
            command.append("--interactive")
        command.extend(("--user", "postgres", target.container_name, *arguments))
        return CommandSpec(action, tuple(command), self._settings.root, timeout_seconds)

    def _restic(self, action: str, *arguments: str) -> CommandSpec:
        return restic_command(
            self._settings,
            action,
            *arguments,
            timeout_seconds=RESTORE_TIMEOUT_SECONDS,
        )

    def _require_disposable_target(self, target: RestoreTarget) -> None:
        if not isinstance(target, RestoreTarget) or any(
            _paths_overlap(target.workspace, protected)
            for protected in (self._settings.root, self._settings.uploads_path)
        ):
            raise ValueError("restore target overlaps protected application data")

    @staticmethod
    def _require_snapshot_id(snapshot_id: str) -> None:
        if (
            not isinstance(snapshot_id, str)
            or SNAPSHOT_ID.fullmatch(snapshot_id) is None
        ):
            raise ValueError("snapshot_id must be a full lowercase Restic identifier")


def _paths_overlap(first: Path, second: Path) -> bool:
    resolved_first = first.resolve()
    resolved_second = second.resolve()
    return (
        resolved_first == resolved_second
        or resolved_first.is_relative_to(resolved_second)
        or resolved_second.is_relative_to(resolved_first)
    )
