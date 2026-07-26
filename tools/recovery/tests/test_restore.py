from __future__ import annotations

import json
import tempfile
import unittest
from dataclasses import FrozenInstanceError, replace
from datetime import UTC, datetime, timedelta, timezone
from pathlib import Path

from tools.recovery.backup import BackupReceipt
from tools.recovery.commands import CommandSpec
from tools.recovery.restore import RestoreCoordinator
from tools.recovery.restore_contract import RestoreError, RestoreFailure
from tools.recovery.runner import RecoveryCommandError
from tools.recovery.settings import RecoverySettings
from tools.recovery.target import RestoreTarget
from tools.recovery.validation import SchemaProof

SHA = "a" * 40
DATABASE_SNAPSHOT = "b" * 64
UPLOADS_SNAPSHOT = "c" * 64
OPERATION = "12345678-1234-4234-9234-123456789abc"
PASSWORD = "Recovery-" + "x" * 20 + "-2026-" + "Y" * 8
METADATA = "inspect restore snapshots"
UPLOADS = "restore uploads snapshot"
F = RestoreFailure
COMPLETED = datetime(2026, 7, 26, 12, 30, tzinfo=timezone(timedelta(hours=2)))


class ScriptedExecutor:
    def __init__(self, metadata: str, events: list[str]) -> None:
        self.metadata = metadata
        self.events = events
        self.calls: list[str] = []
        self.failures: set[str] = set()
        self.materialize_uploads = True

    def run(self, specification: CommandSpec) -> str:
        action = specification.action
        self.calls.append(action)
        self.events.append(action)
        if action in self.failures:
            raise RecoveryCommandError(action, "sensitive provider detail")
        if action == METADATA:
            return self.metadata
        if action == UPLOADS and self.materialize_uploads:
            target = Path(
                specification.arguments[specification.arguments.index("--target") + 1]
            )
            target.mkdir(parents=True)
            (target / "resume.pdf").write_bytes(b"resume")
            images = target / "images"
            images.mkdir()
            (images / "avatar.jpg").write_bytes(b"image")
        return ""


class ScriptedDatabase:
    def __init__(self, events: list[str]) -> None:
        self.events = events
        self.calls: list[tuple[RestoreTarget, str]] = []
        self.failure: RestoreError | None = None

    def restore(self, target: RestoreTarget, snapshot_id: str) -> SchemaProof:
        self.events.append("restore database")
        self.calls.append((target, snapshot_id))
        if self.failure:
            raise self.failure
        return SchemaProof(("1", "2"))


class TrackingWorkspace:
    def __init__(self, events: list[str], fail_cleanup: bool) -> None:
        self._temporary = tempfile.TemporaryDirectory()
        self.name = self._temporary.name
        self.events = events
        self.fail_cleanup = fail_cleanup
        self.cleaned = False

    def cleanup(self) -> None:
        self._temporary.cleanup()
        self.cleaned = True
        self.events.append("cleanup workspace")
        if self.fail_cleanup:
            self.fail_cleanup = False
            raise OSError("fixture cleanup failure")


class NamedWorkspace:
    def __init__(self, name: str, events: list[str]) -> None:
        self.name = name
        self.events = events

    def cleanup(self) -> None:
        self.events.append("cleanup workspace")


class WorkspaceFactory:
    def __init__(self, events: list[str]) -> None:
        self.events = events
        self.calls = 0
        self.fail_create = False
        self.fail_cleanup = False
        self.override: NamedWorkspace | None = None
        self.workspaces: list[TrackingWorkspace] = []

    def __call__(self) -> TrackingWorkspace | NamedWorkspace:
        self.calls += 1
        if self.fail_create:
            raise OSError("fixture create failure")
        if self.override:
            return self.override
        workspace = TrackingWorkspace(self.events, self.fail_cleanup)
        self.workspaces.append(workspace)
        return workspace


class RestoreCoordinatorTest(unittest.TestCase):
    def setUp(self) -> None:
        self.application = tempfile.TemporaryDirectory()
        root = Path(self.application.name).resolve()
        for name in ("docker-compose.yml", "docker-compose.prod.yml"):
            (root / name).write_text("services: {}", encoding="utf-8")
        uploads = root / "backend" / "uploads"
        uploads.mkdir(parents=True)
        environment = _file(root / "production.env", "TAG=" + SHA)
        repository = _file(root / "repository", "s3:https://backup.test/moncv")
        password = _file(root / "password", PASSWORD)
        self.settings = RecoverySettings(
            root, environment, repository, password, uploads
        )
        self.receipt = BackupReceipt(
            OPERATION,
            SHA,
            DATABASE_SNAPSHOT,
            UPLOADS_SNAPSHOT,
            COMPLETED,
        )
        self.events: list[str] = []
        self.executor = ScriptedExecutor(
            _metadata(self.settings.uploads_path), self.events
        )
        self.database = ScriptedDatabase(self.events)
        self.workspaces = WorkspaceFactory(self.events)
        self.clock_value = COMPLETED
        self.clock_calls = 0

    def tearDown(self) -> None:
        for workspace in self.workspaces.workspaces:
            workspace.cleanup()
        self.application.cleanup()

    def coordinator(self) -> RestoreCoordinator:
        return RestoreCoordinator(
            self.settings,
            self.executor,
            self.database,
            clock=self._clock,
            workspace_factory=self.workspaces,
        )

    def _clock(self) -> datetime:
        self.events.append("completion clock")
        self.clock_calls += 1
        return self.clock_value

    def test_emits_a_receipt_only_after_both_proofs_and_cleanup(self) -> None:
        receipt = self.coordinator().run(self.receipt)
        self.assertEqual(
            self.events,
            [
                METADATA,
                "restore database",
                UPLOADS,
                "cleanup workspace",
                "completion clock",
            ],
        )
        self.assertEqual((receipt.operation_id, receipt.deployed_sha), (OPERATION, SHA))
        self.assertEqual(receipt.latest_migration, "2")
        self.assertEqual(receipt.migration_count, 2)
        self.assertEqual(
            (receipt.upload_files, receipt.upload_directories, receipt.upload_bytes),
            (2, 1, 11),
        )
        self.assertRegex(receipt.uploads_sha256, r"[0-9a-f]{64}")
        self.assertEqual(
            receipt.completed_at,
            datetime(2026, 7, 26, 10, 30, tzinfo=UTC),
        )
        workspace = self.workspaces.workspaces[0]
        self.assertTrue(workspace.cleaned)
        self.assertFalse(Path(workspace.name).exists())
        with self.assertRaises(FrozenInstanceError):
            receipt.drill_id = "changed"  # type: ignore[misc]

    def test_rejects_invalid_receipt_before_external_commands(self) -> None:
        invalid = replace(self.receipt, database_snapshot="short")
        with self.assertRaises(RestoreError) as raised:
            self.coordinator().run(invalid)
        self.assertEqual(raised.exception.error_codes, _codes(F.SNAPSHOTS_INVALID))
        self.assertEqual((self.executor.calls, self.workspaces.calls), ([], 0))

    def test_rejects_unavailable_or_invalid_metadata_before_workspace(self) -> None:
        self.executor.failures.add(METADATA)
        with self.assertRaises(RestoreError) as raised:
            self.coordinator().run(self.receipt)
        self.assertEqual(raised.exception.error_codes, _codes(F.SNAPSHOT_PREFLIGHT))
        self.assertNotIn("sensitive provider detail", str(raised.exception))
        self.executor.failures.clear()
        self.executor.metadata = "[]"
        with self.assertRaises(RestoreError) as raised:
            self.coordinator().run(self.receipt)
        self.assertEqual(raised.exception.error_codes, _codes(F.SNAPSHOTS_INVALID))
        self.assertEqual((self.workspaces.calls, self.database.calls), (0, []))

    def test_maps_workspace_creation_and_target_failures(self) -> None:
        self.workspaces.fail_create = True
        with self.assertRaises(RestoreError) as raised:
            self.coordinator().run(self.receipt)
        self.assertEqual(raised.exception.error_codes, _codes(F.WORKSPACE_CREATE))
        self.workspaces.fail_create = False
        self.workspaces.override = NamedWorkspace(str(self.settings.root), self.events)
        with self.assertRaises(RestoreError) as raised:
            self.coordinator().run(self.receipt)
        self.assertEqual(raised.exception.error_codes, _codes(F.TARGET_INVALID))
        self.assertTrue(self.settings.root.exists())

    def test_preserves_database_failure_when_workspace_cleanup_fails(self) -> None:
        self.database.failure = RestoreError((F.DATABASE_IMPORT,))
        self.workspaces.fail_cleanup = True
        with self.assertRaises(RestoreError) as raised:
            self.coordinator().run(self.receipt)
        self.assertEqual(
            raised.exception.error_codes,
            _codes(F.DATABASE_IMPORT, F.WORKSPACE_CLEANUP),
        )
        self.assertNotIn(UPLOADS, self.executor.calls)

    def test_maps_upload_command_and_tree_validation_failures(self) -> None:
        self.executor.failures.add(UPLOADS)
        with self.assertRaises(RestoreError) as raised:
            self.coordinator().run(self.receipt)
        self.assertEqual(raised.exception.error_codes, _codes(F.UPLOADS_RESTORE))
        self.executor.failures.clear()
        self.executor.materialize_uploads = False
        self.workspaces.fail_cleanup = True
        with self.assertRaises(RestoreError) as raised:
            self.coordinator().run(self.receipt)
        self.assertEqual(
            raised.exception.error_codes,
            _codes("RESTORE_UPLOADS_INVALID", F.WORKSPACE_CLEANUP),
        )

    def test_cleanup_or_invalid_clock_prevents_a_success_receipt(self) -> None:
        self.workspaces.fail_cleanup = True
        with self.assertRaises(RestoreError) as raised:
            self.coordinator().run(self.receipt)
        self.assertEqual(raised.exception.error_codes, _codes(F.WORKSPACE_CLEANUP))
        self.assertEqual(self.clock_calls, 0)
        self.workspaces = WorkspaceFactory(self.events)
        self.clock_value = datetime(2026, 7, 26, 10, 30)  # noqa: DTZ001
        with self.assertRaises(RestoreError) as raised:
            self.coordinator().run(self.receipt)
        self.assertEqual(raised.exception.error_codes, _codes(F.RECEIPT_INVALID))
        self.assertEqual(self.events[-2:], ["cleanup workspace", "completion clock"])


def _metadata(uploads: Path) -> str:
    common = ["moncv", f"operation:{OPERATION}", f"git:{SHA}"]
    return json.dumps(
        [
            {
                "id": DATABASE_SNAPSHOT,
                "hostname": "moncv-production",
                "tags": [*common, "kind:database"],
                "paths": ["/moncv/postgres.dump"],
            },
            {
                "id": UPLOADS_SNAPSHOT,
                "hostname": "moncv-production",
                "tags": [*common, "kind:uploads"],
                "paths": [str(uploads.resolve())],
            },
        ]
    )


def _file(path: Path, content: str) -> Path:
    path.write_text(content, encoding="utf-8")
    path.chmod(0o600)
    return path


def _codes(*values: RestoreFailure | str) -> tuple[str, ...]:
    return tuple(str(value) for value in values)


if __name__ == "__main__":
    unittest.main()
