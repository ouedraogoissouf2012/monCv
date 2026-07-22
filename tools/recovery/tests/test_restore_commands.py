from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.recovery.commands import DATABASE_DUMP_NAME, DEFAULT_TIMEOUT_SECONDS
from tools.recovery.identity import SnapshotIdentity
from tools.recovery.restore_commands import (
    RESTORE_DATABASE_IMAGE,
    RESTORE_DATABASE_NAME,
    RESTORE_SCHEMA_QUERY,
    RESTORE_TIMEOUT_SECONDS,
    RestoreCommands,
)
from tools.recovery.settings import RecoverySettings
from tools.recovery.target import RestoreTarget

SHA = "a" * 40
OPERATION = "12345678-1234-4234-9234-123456789abc"
SNAPSHOT = "b" * 64
PASSWORD = "Recovery-" + "x" * 20 + "-2026-" + "Y" * 8


class RestoreCommandsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        parent = Path(self.temporary.name).resolve()
        self.root = parent / "application"
        self.root.mkdir()
        for name in ("docker-compose.yml", "docker-compose.prod.yml"):
            (self.root / name).write_text("services: {}", encoding="utf-8")
        uploads = self.root / "backend" / "uploads"
        uploads.mkdir(parents=True)
        settings = RecoverySettings(
            self.root,
            _file(self.root / "production.env", "TAG=" + SHA),
            _file(self.root / "repository", "s3:https://backup.test/moncv"),
            _file(self.root / "password", PASSWORD),
            uploads,
        )
        workspace = parent / "restore-workspace"
        workspace.mkdir()
        identity = SnapshotIdentity.create(SHA, OPERATION)
        self.target = RestoreTarget(workspace, identity)
        self.commands = RestoreCommands(settings)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_database_dump_is_a_bounded_restic_stream(self) -> None:
        spec = self.commands.database_dump(SNAPSHOT)

        self.assertEqual(spec.arguments[0], "restic")
        self.assertEqual(spec.arguments[-3:], ("dump", SNAPSHOT, DATABASE_DUMP_NAME))
        self.assertEqual(spec.timeout_seconds, RESTORE_TIMEOUT_SECONDS)

        for invalid in (None, "", "B" * 64, "b" * 63, "../latest"):
            with self.subTest(snapshot=invalid), self.assertRaises(ValueError):
                self.commands.database_dump(invalid)  # type: ignore[arg-type]

    def test_database_container_is_isolated_and_resource_bounded(self) -> None:
        spec = self.commands.create_database(self.target)
        arguments = spec.arguments

        self.assertEqual(arguments[:2], ("docker", "run"))
        self.assertEqual(arguments[-1], RESTORE_DATABASE_IMAGE)
        self.assertEqual(arguments[arguments.index("--network") + 1], "none")
        self.assertIn("--read-only", arguments)
        self.assertIn("no-new-privileges:true", arguments)
        self.assertIn("ALL", arguments)
        self.assertNotIn("SYS_ADMIN", arguments)
        self.assertNotIn("NET_ADMIN", arguments)
        self.assertNotIn("--publish", arguments)
        self.assertNotIn("-p", arguments)
        self.assertIn("2g", arguments)
        self.assertIn("com.moncv.recovery=restore-drill", arguments)
        self.assertIn(
            "com.moncv.recovery.operation=" + OPERATION,
            arguments,
        )
        self.assertNotIn(PASSWORD, " ".join(arguments))

    def test_database_commands_use_atomic_restore_and_fixed_schema_query(self) -> None:
        ready = self.commands.database_ready(self.target)
        restore = self.commands.import_database(self.target)
        schema = self.commands.restored_schema(self.target)

        self.assertIn("pg_isready", ready.arguments)
        self.assertNotIn("--interactive", ready.arguments)
        self.assertIn("--interactive", restore.arguments)
        self.assertIn("--single-transaction", restore.arguments)
        self.assertIn("--exit-on-error", restore.arguments)
        self.assertIn(RESTORE_DATABASE_NAME, restore.arguments)
        self.assertIn("ON_ERROR_STOP=1", schema.arguments)
        self.assertEqual(schema.arguments[-1], RESTORE_SCHEMA_QUERY)
        for spec in (ready, restore, schema):
            self.assertIn(self.target.container_name, spec.arguments)
        self.assertEqual(ready.timeout_seconds, DEFAULT_TIMEOUT_SECONDS)
        self.assertEqual(schema.timeout_seconds, DEFAULT_TIMEOUT_SECONDS)
        self.assertEqual(restore.timeout_seconds, RESTORE_TIMEOUT_SECONDS)

    def test_upload_restore_and_cleanup_stay_inside_disposable_target(self) -> None:
        restore = self.commands.restore_uploads(SNAPSHOT, self.target)
        cleanup = self.commands.remove_database(self.target)

        self.assertEqual(restore.arguments[0], "restic")
        self.assertIn("--verify", restore.arguments)
        self.assertEqual(
            restore.arguments[restore.arguments.index("--overwrite") + 1], "never"
        )
        target_index = restore.arguments.index("--target")
        self.assertEqual(
            restore.arguments[target_index + 1], str(self.target.uploads_directory)
        )
        self.assertEqual(restore.arguments[-1], SNAPSHOT)
        self.assertEqual(
            cleanup.arguments,
            (
                "docker",
                "rm",
                "--force",
                "--volumes",
                self.target.container_name,
            ),
        )

    def test_rejects_a_target_overlapping_application_data(self) -> None:
        overlap = self.root / "empty-restore-target"
        overlap.mkdir()
        identity = SnapshotIdentity.create(SHA, OPERATION)
        dangerous = RestoreTarget(overlap, identity)

        with self.assertRaises(ValueError):
            self.commands.create_database(dangerous)
        with self.assertRaises(ValueError):
            self.commands.restore_uploads(SNAPSHOT, dangerous)


def _file(path: Path, content: str) -> Path:
    path.write_text(content, encoding="utf-8")
    path.chmod(0o600)
    return path


if __name__ == "__main__":
    unittest.main()
