from __future__ import annotations

import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path

from tools.recovery.backup import BackupCoordinator, BackupError
from tools.recovery.commands import CommandSpec, RecoveryCommands
from tools.recovery.identity import SnapshotIdentity
from tools.recovery.runner import RecoveryCommandError
from tools.recovery.settings import RecoverySettings

SHA = "a" * 40
OPERATION = "12345678-1234-4234-9234-123456789abc"
DATABASE_SNAPSHOT = "b" * 64
UPLOADS_SNAPSHOT = "c" * 64
TEST_PASSWORD = "Recovery-" + "x" * 20 + "-2026-" + "Y" * 8
COMPLETED_AT = datetime(2026, 7, 22, 3, 0, tzinfo=timezone.utc)


class ScriptedExecutor:
    def __init__(self, failures: set[str] | None = None) -> None:
        self.failures = failures or set()
        self.calls: list[str] = []
        self.specifications: list[CommandSpec] = []
        self.outputs = {
            "inspect backend state": '[{"State":"running","Health":"healthy"}]',
            "snapshot PostgreSQL": _summary(DATABASE_SNAPSHOT),
            "snapshot uploads": _summary(UPLOADS_SNAPSHOT),
        }

    def run(self, specification: CommandSpec) -> str:
        self.specifications.append(specification)
        self.calls.append(specification.action)
        if specification.action in self.failures:
            raise RecoveryCommandError(specification.action, "fixture failure")
        return self.outputs.get(specification.action, "")


class BackupCoordinatorTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        root = Path(self.temporary.name).resolve()
        for name in ("docker-compose.yml", "docker-compose.prod.yml"):
            (root / name).write_text("services: {}", encoding="utf-8")
        uploads = root / "backend" / "uploads"
        uploads.mkdir(parents=True)
        environment = _file(root / "production.env", "TAG=" + SHA)
        repository = _file(root / "repository", "s3:https://backup.test/moncv")
        password = _file(root / "password", TEST_PASSWORD)
        settings = RecoverySettings(root, environment, repository, password, uploads)
        self.commands = RecoveryCommands(settings)
        self.identity = SnapshotIdentity.create(SHA, OPERATION)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def coordinator(self, executor: ScriptedExecutor) -> BackupCoordinator:
        return BackupCoordinator(self.commands, executor, lambda: COMPLETED_AT)

    def test_creates_a_verified_pair_and_restarts_backend(self) -> None:
        executor = ScriptedExecutor()
        receipt = self.coordinator(executor).create_backup(self.identity)

        self.assertEqual(receipt.database_snapshot, DATABASE_SNAPSHOT)
        self.assertEqual(receipt.uploads_snapshot, UPLOADS_SNAPSHOT)
        self.assertEqual(receipt.completed_at, COMPLETED_AT)
        self.assertEqual(
            executor.calls,
            [
                "inspect backend state",
                "stop backend writes",
                "snapshot PostgreSQL",
                "snapshot uploads",
                "verify backup data",
                "start healthy backend",
            ],
        )

    def test_refuses_unhealthy_or_ambiguous_backend_without_stopping_it(self) -> None:
        for output in (
            "[]",
            '[{"State":"running","Health":"unhealthy"}]',
            '{"State":"exited","Health":"healthy"}',
            "not-json",
        ):
            executor = ScriptedExecutor()
            executor.outputs["inspect backend state"] = output
            with self.subTest(output=output), self.assertRaises(BackupError) as raised:
                self.coordinator(executor).create_backup(self.identity)
            self.assertEqual(
                raised.exception.error_codes, ("BACKEND_PREFLIGHT_FAILED",)
            )
            self.assertEqual(executor.calls, ["inspect backend state"])

        executor = ScriptedExecutor({"inspect backend state"})
        with self.assertRaisesRegex(BackupError, "BACKEND_PREFLIGHT_FAILED"):
            self.coordinator(executor).create_backup(self.identity)

    def test_rolls_back_known_snapshots_in_reverse_order(self) -> None:
        expected_cleanup = {
            "snapshot uploads": ["remove partial snapshot"],
            "verify backup data": [
                "remove partial snapshot",
                "remove partial snapshot",
            ],
        }
        for failing_action, cleanup in expected_cleanup.items():
            executor = ScriptedExecutor({failing_action})
            with self.subTest(action=failing_action), self.assertRaises(BackupError):
                self.coordinator(executor).create_backup(self.identity)
            cleanup_calls = [
                call for call in executor.calls if call == "remove partial snapshot"
            ]
            self.assertEqual(cleanup_calls, cleanup)
            forgotten = [
                spec.arguments[-1]
                for spec in executor.specifications
                if spec.action == "remove partial snapshot"
            ]
            expected_ids = (
                [DATABASE_SNAPSHOT]
                if failing_action == "snapshot uploads"
                else [UPLOADS_SNAPSHOT, DATABASE_SNAPSHOT]
            )
            self.assertEqual(forgotten, expected_ids)
            self.assertEqual(executor.calls[-1], "start healthy backend")

    def test_restart_is_attempted_even_when_stop_acknowledgement_fails(self) -> None:
        executor = ScriptedExecutor({"stop backend writes"})
        with self.assertRaisesRegex(BackupError, "BACKUP_INCOMPLETE"):
            self.coordinator(executor).create_backup(self.identity)
        self.assertEqual(executor.calls[-1], "start healthy backend")

    def test_restart_failure_prevents_success_and_preserves_both_codes(self) -> None:
        executor = ScriptedExecutor({"snapshot PostgreSQL", "start healthy backend"})
        with self.assertRaises(BackupError) as raised:
            self.coordinator(executor).create_backup(self.identity)
        self.assertEqual(
            raised.exception.error_codes,
            ("BACKEND_RESTART_FAILED", "BACKUP_INCOMPLETE"),
        )

    def test_reports_cleanup_failure_without_skipping_remaining_cleanup(self) -> None:
        executor = ScriptedExecutor({"verify backup data", "remove partial snapshot"})
        with self.assertRaises(BackupError) as raised:
            self.coordinator(executor).create_backup(self.identity)
        self.assertIn("SNAPSHOT_CLEANUP_FAILED", raised.exception.error_codes)
        self.assertEqual(executor.calls.count("remove partial snapshot"), 2)

    def test_rejects_invalid_snapshot_contract_without_leaking_output(self) -> None:
        marker = "sensitive-provider-output"
        invalid_outputs = (
            marker,
            _summary("short"),
            _summary(DATABASE_SNAPSHOT) + "\n" + _summary(UPLOADS_SNAPSHOT),
        )
        for output in invalid_outputs:
            executor = ScriptedExecutor()
            executor.outputs["snapshot PostgreSQL"] = output
            with self.subTest(output=output), self.assertRaises(BackupError) as raised:
                self.coordinator(executor).create_backup(self.identity)
            self.assertNotIn(marker, str(raised.exception))

    def test_rejects_duplicate_snapshots_and_naive_completion_clock(self) -> None:
        duplicate = ScriptedExecutor()
        duplicate.outputs["snapshot uploads"] = _summary(DATABASE_SNAPSHOT)
        with self.assertRaises(BackupError):
            self.coordinator(duplicate).create_backup(self.identity)
        self.assertEqual(duplicate.calls.count("remove partial snapshot"), 1)

        naive_clock = ScriptedExecutor()
        coordinator = BackupCoordinator(
            self.commands, naive_clock, lambda: datetime(2026, 7, 22)
        )
        with self.assertRaises(BackupError):
            coordinator.create_backup(self.identity)
        self.assertEqual(naive_clock.calls.count("remove partial snapshot"), 2)


def _summary(snapshot_id: str) -> str:
    return '{"message_type":"summary","snapshot_id":"' + snapshot_id + '"}'


def _file(path: Path, content: str) -> Path:
    path.write_text(content, encoding="utf-8")
    path.chmod(0o600)
    return path


if __name__ == "__main__":
    unittest.main()
