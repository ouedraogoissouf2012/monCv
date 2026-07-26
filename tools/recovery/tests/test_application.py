from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.recovery.application import RecoveryApplication
from tools.recovery.commands import CommandSpec
from tools.recovery.pipeline import PipelineSpec
from tools.recovery.receipt import ReceiptError
from tools.recovery.receipt_store import (
    read_backup_receipt,
    read_restore_receipt,
)
from tools.recovery.runner import RecoveryCommandError
from tools.recovery.settings import RecoverySettings
from tools.recovery.toolchain import ToolchainError
from tools.recovery.validation import RestoreValidationError

SHA = "a" * 40
DATABASE_SNAPSHOT = "b" * 64
UPLOADS_SNAPSHOT = "c" * 64
CONTAINER = "d" * 64
OPERATION = "12345678-1234-4234-9234-123456789abc"
PASSWORD = "Recovery-" + "x" * 20 + "-2026-" + "Y" * 8


class ScriptedExecutor:
    def __init__(self, settings: RecoverySettings) -> None:
        self.settings = settings
        self.calls: list[str] = []
        self.failures: set[str] = set()
        self.restic_version = "restic 0.19.1"
        self.drill_id = ""
        self.receipt = None

    def run(self, specification: CommandSpec) -> str:
        action = specification.action
        self.calls.append(action)
        if action in self.failures:
            raise RecoveryCommandError(action, "fixture failure")
        if action == "check Restic version":
            return self.restic_version
        if action == "check Docker Compose version":
            return "5.1.3"
        if action == "inspect backend state":
            return '[{"State":"running","Health":"healthy"}]'
        if action == "snapshot PostgreSQL":
            return _summary(DATABASE_SNAPSHOT)
        if action == "snapshot uploads":
            return _summary(UPLOADS_SNAPSHOT)
        if action == "inspect restore snapshots":
            return _metadata(self.settings, self.receipt)
        if action == "create isolated restore database":
            self.drill_id = _label(specification, "com.moncv.recovery.drill=")
            return CONTAINER
        if action == "inspect isolated restore ownership":
            return CONTAINER + "|" + self.drill_id
        if action == "inspect restored Flyway schema":
            return '[{"version":"1","success":true},{"version":"2","success":true}]'
        if action == "restore uploads snapshot":
            target = Path(
                specification.arguments[specification.arguments.index("--target") + 1]
            )
            target.mkdir(parents=True)
            (target / "avatar.jpg").write_bytes(b"image")
        return ""


class ScriptedPipeline:
    def __init__(self) -> None:
        self.calls: list[PipelineSpec] = []

    def run(self, specification: PipelineSpec) -> None:
        self.calls.append(specification)


class RecoveryApplicationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name).resolve()
        for name in ("docker-compose.yml", "docker-compose.prod.yml"):
            (self.root / name).write_text("services: {}", encoding="utf-8")
        uploads = self.root / "backend" / "uploads"
        uploads.mkdir(parents=True)
        migrations = (
            self.root / "backend" / "src" / "main" / "resources" / "db" / "migration"
        )
        migrations.mkdir(parents=True)
        (migrations / "V1__base.sql").write_text("SELECT 1;", encoding="utf-8")
        (migrations / "V2__next.sql").write_text("SELECT 2;", encoding="utf-8")
        environment = _file(self.root / "production.env", "TAG=" + SHA)
        repository = _file(
            self.root / "repository",
            "s3:https://backup.test/moncv",
        )
        password = _file(self.root / "password", PASSWORD)
        self.settings = RecoverySettings(
            self.root,
            environment,
            repository,
            password,
            uploads,
        )
        self.executor = ScriptedExecutor(self.settings)
        self.pipeline = ScriptedPipeline()
        self.application = RecoveryApplication(
            self.settings,
            self.executor,
            self.pipeline,
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_creates_and_persists_a_verified_backup_receipt(self) -> None:
        path = self.root / "backup.json"
        receipt = self.application.create_backup(SHA, path)

        self.assertEqual(receipt, read_backup_receipt(path))
        self.assertEqual(
            self.executor.calls,
            [
                "check Restic version",
                "check Docker Compose version",
                "inspect backend state",
                "stop backend writes",
                "snapshot PostgreSQL",
                "snapshot uploads",
                "verify backup data",
                "start healthy backend",
            ],
        )
        self.assertEqual(receipt.database_snapshot, DATABASE_SNAPSHOT)
        self.assertEqual(receipt.uploads_snapshot, UPLOADS_SNAPSHOT)

    def test_builds_secure_runners_from_environment(self) -> None:
        environment = {
            "RECOVERY_COMPOSE_ENV_FILE": str(self.settings.compose_environment),
            "RESTIC_REPOSITORY_FILE": str(self.settings.repository_file),
            "RESTIC_PASSWORD_FILE": str(self.settings.password_file),
            "RECOVERY_UPLOADS_PATH": str(self.settings.uploads_path),
        }
        application = RecoveryApplication.from_environment(self.root, environment)
        self.assertIsInstance(application, RecoveryApplication)

    def test_rejects_invalid_sha_or_toolchain_before_backup_effects(self) -> None:
        with self.assertRaises(ValueError):
            self.application.create_backup("invalid", self.root / "invalid.json")
        self.assertEqual(self.executor.calls, [])

        self.executor.restic_version = "restic 0.19.0"
        with self.assertRaises(ToolchainError):
            self.application.create_backup(SHA, self.root / "old.json")
        self.assertEqual(self.executor.calls, ["check Restic version"])

    def test_rejects_occupied_output_before_toolchain_or_data_effects(self) -> None:
        output = self.root / "occupied.json"
        output.write_text("existing", encoding="utf-8")
        with self.assertRaises(ReceiptError):
            self.application.create_backup(SHA, output)
        self.assertEqual(self.executor.calls, [])

    def test_proves_restore_and_persists_the_complete_receipt(self) -> None:
        backup_path = self.root / "backup.json"
        output_path = self.root / "restore.json"
        backup = self.application.create_backup(SHA, backup_path)
        self.executor.calls.clear()
        self.executor.receipt = backup

        receipt = self.application.prove_restore(backup_path, output_path)

        self.assertEqual(receipt, read_restore_receipt(output_path))
        self.assertEqual(receipt.latest_migration, "2")
        self.assertEqual(receipt.migration_count, 2)
        self.assertEqual(receipt.upload_files, 1)
        self.assertEqual(receipt.upload_bytes, 5)
        self.assertEqual(len(self.pipeline.calls), 1)
        self.assertEqual(
            self.executor.calls,
            [
                "check Restic version",
                "check Docker Compose version",
                "inspect restore snapshots",
                "create isolated restore database",
                "inspect isolated restore ownership",
                "probe isolated restore database",
                "inspect restored Flyway schema",
                "remove isolated restore database",
                "restore uploads snapshot",
            ],
        )

    def test_validates_receipt_and_migrations_before_toolchain(self) -> None:
        missing = self.root / "missing.json"
        with self.assertRaises(ReceiptError):
            self.application.prove_restore(missing, self.root / "output.json")
        self.assertEqual(self.executor.calls, [])

        backup_path = self.root / "backup.json"
        backup = self.application.create_backup(SHA, backup_path)
        self.executor.calls.clear()
        self.executor.receipt = backup
        migration = (
            self.root
            / "backend"
            / "src"
            / "main"
            / "resources"
            / "db"
            / "migration"
            / "V2__next.sql"
        )
        migration.unlink()
        migration.parent.joinpath("unexpected.txt").write_text("x", encoding="utf-8")
        with self.assertRaises(RestoreValidationError):
            self.application.prove_restore(backup_path, self.root / "output.json")
        self.assertEqual(self.executor.calls, [])


def _summary(snapshot_id: str) -> str:
    return '{"message_type":"summary","snapshot_id":"' + snapshot_id + '"}'


def _label(specification: CommandSpec, prefix: str) -> str:
    return next(
        argument.removeprefix(prefix)
        for argument in specification.arguments
        if argument.startswith(prefix)
    )


def _metadata(settings: RecoverySettings, receipt) -> str:
    common = [
        "moncv",
        "operation:" + receipt.operation_id,
        "git:" + receipt.deployed_sha,
    ]
    return json.dumps(
        [
            {
                "id": receipt.database_snapshot,
                "hostname": "moncv-production",
                "tags": [*common, "kind:database"],
                "paths": ["/moncv/postgres.dump"],
            },
            {
                "id": receipt.uploads_snapshot,
                "hostname": "moncv-production",
                "tags": [*common, "kind:uploads"],
                "paths": [str(settings.uploads_path.resolve())],
            },
        ]
    )


def _file(path: Path, content: str) -> Path:
    path.write_text(content, encoding="utf-8")
    path.chmod(0o600)
    return path


if __name__ == "__main__":
    unittest.main()
