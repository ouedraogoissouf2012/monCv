from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.recovery.commands import (
    BACKUP_TIMEOUT_SECONDS,
    CHECK_TIMEOUT_SECONDS,
    DATABASE_DUMP_COMMAND,
    DATABASE_DUMP_NAME,
    CommandSpec,
    RecoveryCommands,
)
from tools.recovery.identity import SnapshotIdentity
from tools.recovery.settings import RecoverySettings

SHA = "a" * 40
OPERATION = "12345678-1234-4234-9234-123456789abc"
SNAPSHOT = "b" * 64
TEST_PASSWORD = "Recovery-" + "x" * 20 + "-2026-" + "Y" * 8
TEST_ENV_SECRET = "Jwt-" + "q" * 24 + "-2026-" + "Z" * 8


class RecoveryCommandsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        for name in ("docker-compose.yml", "docker-compose.prod.yml"):
            (self.root / name).write_text("services: {}", encoding="utf-8")
        self.uploads = self.root / "backend" / "uploads"
        self.uploads.mkdir(parents=True)
        self.environment = self._file(
            "production.env", "TAG=" + SHA + "\nJWT_SECRET=" + TEST_ENV_SECRET
        )
        self.repository = self._file("repository", "s3:https://backup.test/moncv")
        self.password = self._file("password", TEST_PASSWORD)
        settings = RecoverySettings(
            root=self.root,
            compose_environment=self.environment,
            repository_file=self.repository,
            password_file=self.password,
            uploads_path=self.uploads,
        )
        self.commands = RecoveryCommands(settings)
        self.identity = SnapshotIdentity.create(SHA, OPERATION)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _file(self, name: str, value: str) -> Path:
        path = self.root / name
        path.write_text(value, encoding="utf-8")
        path.chmod(0o600)
        return path

    def test_compose_commands_share_the_hardened_project_context(self) -> None:
        for spec in (
            self.commands.backend_state(),
            self.commands.pause_backend(),
            self.commands.unpause_backend(),
        ):
            with self.subTest(action=spec.action):
                self.assertEqual(spec.arguments[:2], ("docker", "compose"))
                self.assertIn(str(self.environment), spec.arguments)
                self.assertIn(
                    str(self.root / "docker-compose.prod.yml"), spec.arguments
                )
                self.assertEqual(spec.cwd, self.root)

    def test_tool_versions_use_fixed_non_shell_commands(self) -> None:
        self.assertEqual(self.commands.restic_version().arguments[-1], "version")
        self.assertEqual(
            self.commands.compose_version().arguments,
            ("docker", "compose", "version", "--short"),
        )

    def test_database_backup_propagates_pg_dump_exit_status_to_restic(self) -> None:
        spec = self.commands.database_backup(self.identity)
        separator = spec.arguments.index("--")

        self.assertEqual(spec.timeout_seconds, BACKUP_TIMEOUT_SECONDS)
        self.assertIn("--stdin-from-command", spec.arguments)
        self.assertIn(DATABASE_DUMP_NAME, spec.arguments)
        self.assertEqual(
            spec.arguments[separator + 1 : separator + 3], ("docker", "compose")
        )
        self.assertEqual(spec.arguments[-1], DATABASE_DUMP_COMMAND)
        self.assert_snapshot_tags(spec, "database")

    def test_upload_backup_stays_on_the_configured_filesystem(self) -> None:
        spec = self.commands.uploads_backup(self.identity)

        self.assertEqual(spec.timeout_seconds, BACKUP_TIMEOUT_SECONDS)
        self.assertIn("--one-file-system", spec.arguments)
        self.assertEqual(spec.arguments[-2:], ("--", str(self.uploads)))
        self.assert_snapshot_tags(spec, "uploads")

    def test_no_command_contains_secret_file_contents_or_repository_url(self) -> None:
        specs = (
            self.commands.restic_version(),
            self.commands.database_backup(self.identity),
            self.commands.uploads_backup(self.identity),
            self.commands.forget_snapshot(SNAPSHOT),
            self.commands.check_repository(self.identity),
        )
        for spec in specs:
            rendered = " ".join(spec.arguments)
            self.assertNotIn(TEST_PASSWORD, rendered)
            self.assertNotIn(TEST_ENV_SECRET, rendered)
            self.assertNotIn("https://backup.test/moncv", rendered)
            self.assertIsInstance(spec.arguments, tuple)

    def test_cleanup_requires_a_full_non_option_snapshot_identifier(self) -> None:
        for invalid in ("b" * 63, "B" * 64, "--keep-tag", "../snapshot"):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                self.commands.forget_snapshot(invalid)
        self.assertEqual(
            self.commands.forget_snapshot(SNAPSHOT).arguments[-1], SNAPSHOT
        )

    def test_repository_check_has_an_explicit_long_timeout(self) -> None:
        spec = self.commands.check_repository(self.identity)
        self.assertEqual(spec.timeout_seconds, CHECK_TIMEOUT_SECONDS)
        self.assertIn("--read-data", spec.arguments)
        self.assertEqual(spec.arguments[-1], f"operation:{OPERATION}")

    def test_command_spec_rejects_incomplete_metadata(self) -> None:
        for action, arguments, timeout in (
            ("", ("ok",), 1),
            ("ok", (), 1),
            ("ok", ("x",), 0),
        ):
            with self.subTest(action=action), self.assertRaises(ValueError):
                CommandSpec(action, arguments, self.root, timeout)

    def assert_snapshot_tags(self, spec: CommandSpec, kind: str) -> None:
        for tag in ("moncv", f"operation:{OPERATION}", f"git:{SHA}", f"kind:{kind}"):
            self.assertIn(tag, spec.arguments)


if __name__ == "__main__":
    unittest.main()
