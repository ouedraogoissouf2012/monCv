from __future__ import annotations

import json
import tempfile
import unittest
from datetime import UTC, datetime
from io import StringIO
from pathlib import Path

from tools.recovery.backup import BackupError, BackupReceipt
from tools.recovery.cli import (
    EXIT_BACKUP,
    EXIT_CONFIGURATION,
    EXIT_INTERNAL,
    EXIT_RECEIPT,
    EXIT_RESTORE,
    EXIT_VALIDATION,
    build_parser,
    main,
)
from tools.recovery.receipt import ReceiptError
from tools.recovery.restore_contract import RestoreError, RestoreReceipt
from tools.recovery.settings import RecoveryConfigurationError
from tools.recovery.toolchain import ToolchainError, ToolchainProof
from tools.recovery.validation import RestoreValidationError

SHA = "a" * 40
DATABASE = "b" * 64
UPLOADS = "c" * 64
OPERATION = "12345678-1234-4234-9234-123456789abc"
DRILL = "87654321-4321-4321-8321-cba987654321"
COMPLETED = datetime(2026, 7, 26, 10, 30, tzinfo=UTC)


class ScriptedApplication:
    def __init__(self) -> None:
        self.calls: list[tuple] = []
        self.failure: Exception | None = None

    def verify_toolchain(self) -> ToolchainProof:
        self.calls.append(("check",))
        self._raise()
        return ToolchainProof("0.19.1", "5.1.3")

    def create_backup(self, deployed_sha: str, path: Path) -> BackupReceipt:
        self.calls.append(("backup", deployed_sha, path))
        self._raise()
        return BackupReceipt(
            OPERATION,
            SHA,
            DATABASE,
            UPLOADS,
            COMPLETED,
        )

    def prove_restore(self, source: Path, target: Path) -> RestoreReceipt:
        self.calls.append(("restore", source, target))
        self._raise()
        return RestoreReceipt(
            drill_id=DRILL,
            operation_id=OPERATION,
            deployed_sha=SHA,
            database_snapshot=DATABASE,
            uploads_snapshot=UPLOADS,
            latest_migration="14",
            migration_count=14,
            upload_files=1,
            upload_directories=0,
            upload_bytes=42,
            uploads_sha256="d" * 64,
            completed_at=COMPLETED,
        )

    def _raise(self) -> None:
        if self.failure:
            raise self.failure


class ApplicationFactory:
    def __init__(self, application: ScriptedApplication) -> None:
        self.application = application
        self.calls: list[tuple[Path, bool]] = []

    def __call__(self, root: Path, allow_local: bool) -> ScriptedApplication:
        self.calls.append((root, allow_local))
        if self.application.failure and not self.application.calls:
            raise self.application.failure
        return self.application


class RecoveryCliTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name).resolve()
        self.application = ScriptedApplication()
        self.factory = ApplicationFactory(self.application)
        self.stdout = StringIO()
        self.stderr = StringIO()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def invoke(self, *arguments: str) -> int:
        return main(
            arguments,
            application_factory=self.factory,
            output=self.stdout,
            error=self.stderr,
        )

    def test_check_emits_canonical_non_sensitive_json(self) -> None:
        code = self.invoke(
            "check",
            "--root",
            str(self.root),
            "--allow-local-repository",
        )
        self.assertEqual(code, 0)
        self.assertEqual(
            json.loads(self.stdout.getvalue()),
            {
                "action": "check",
                "compose_version": "5.1.3",
                "restic_version": "0.19.1",
                "status": "ok",
            },
        )
        self.assertEqual(self.factory.calls, [(self.root, True)])
        self.assertEqual(self.stderr.getvalue(), "")

    def test_backup_routes_absolute_path_and_returns_operation_only(self) -> None:
        receipt = self.root / "backup.json"
        code = self.invoke(
            "backup",
            "--root",
            str(self.root),
            "--deployed-sha",
            SHA,
            "--receipt",
            str(receipt),
        )
        self.assertEqual(code, 0)
        self.assertEqual(
            self.application.calls,
            [("backup", SHA, receipt)],
        )
        self.assertEqual(
            json.loads(self.stdout.getvalue()),
            {"action": "backup", "operation_id": OPERATION, "status": "ok"},
        )

    def test_restore_routes_receipts_and_returns_drill_identity(self) -> None:
        source = self.root / "backup.json"
        target = self.root / "restore.json"
        code = self.invoke(
            "restore",
            "--backup-receipt",
            str(source),
            "--receipt",
            str(target),
        )
        self.assertEqual(code, 0)
        self.assertEqual(
            self.application.calls,
            [("restore", source, target)],
        )
        self.assertEqual(
            json.loads(self.stdout.getvalue()),
            {
                "action": "restore",
                "drill_id": DRILL,
                "operation_id": OPERATION,
                "status": "ok",
            },
        )

    def test_maps_known_failures_to_stable_exit_codes(self) -> None:
        cases = (
            (
                RecoveryConfigurationError(("secret-setting",)),
                EXIT_CONFIGURATION,
                ["CONFIGURATION_INVALID"],
            ),
            (
                ToolchainError("RESTIC_UNAVAILABLE"),
                EXIT_CONFIGURATION,
                ["RESTIC_UNAVAILABLE"],
            ),
            (BackupError(("BACKUP_INCOMPLETE",)), EXIT_BACKUP, ["BACKUP_INCOMPLETE"]),
            (
                RestoreError(("RESTORE_UPLOADS_INVALID",)),
                EXIT_RESTORE,
                ["RESTORE_UPLOADS_INVALID"],
            ),
            (
                ReceiptError("RECEIPT_READ_FAILED"),
                EXIT_RECEIPT,
                ["RECEIPT_READ_FAILED"],
            ),
            (
                RestoreValidationError("MIGRATION_CATALOG_INVALID"),
                EXIT_VALIDATION,
                ["MIGRATION_CATALOG_INVALID"],
            ),
            (ValueError("sensitive-marker"), EXIT_VALIDATION, ["INPUT_INVALID"]),
            (RuntimeError("sensitive-marker"), EXIT_INTERNAL, ["INTERNAL_ERROR"]),
        )
        for failure, expected_code, expected_codes in cases:
            with self.subTest(failure=type(failure).__name__):
                self.application = ScriptedApplication()
                self.application.failure = failure
                self.factory = ApplicationFactory(self.application)
                self.stderr = StringIO()
                code = self.invoke("check")
                self.assertEqual(code, expected_code)
                self.assertEqual(
                    json.loads(self.stderr.getvalue()),
                    {"codes": expected_codes, "status": "error"},
                )
                self.assertNotIn("sensitive", self.stderr.getvalue())

    def test_default_factory_maps_invalid_environment_without_traceback(self) -> None:
        code = main(
            ("check", "--root", str(self.root)),
            output=self.stdout,
            error=self.stderr,
        )
        self.assertEqual(code, EXIT_CONFIGURATION)
        self.assertEqual(
            json.loads(self.stderr.getvalue()),
            {"codes": ["CONFIGURATION_INVALID"], "status": "error"},
        )

    def test_parser_requires_a_command_and_command_specific_arguments(self) -> None:
        parser = build_parser()
        invalid = (
            (),
            ("backup",),
            ("backup", "--deployed-sha", SHA),
            ("restore", "--receipt", "restore.json"),
        )
        for arguments in invalid:
            with (
                self.subTest(arguments=arguments),
                self.assertRaises(SystemExit) as raised,
            ):
                parser.parse_args(arguments)
            self.assertEqual(raised.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
