from __future__ import annotations

import os
import stat
import tempfile
import unittest
from datetime import UTC, datetime
from pathlib import Path
from unittest.mock import patch

from tools.recovery.backup import BackupReceipt
from tools.recovery.receipt import MAX_RECEIPT_BYTES, ReceiptError
from tools.recovery.receipt_store import (
    read_backup_receipt,
    read_restore_receipt,
    write_backup_receipt,
    write_restore_receipt,
)
from tools.recovery.restore_contract import RestoreReceipt

SHA = "a" * 40
DATABASE = "b" * 64
UPLOADS = "c" * 64
OPERATION = "12345678-1234-4234-9234-123456789abc"
DRILL = "87654321-4321-4321-8321-cba987654321"
COMPLETED = datetime(2026, 7, 26, 10, 30, tzinfo=UTC)


class ReceiptStoreTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name).resolve()
        self.backup = BackupReceipt(
            OPERATION,
            SHA,
            DATABASE,
            UPLOADS,
            COMPLETED,
        )
        self.restore = RestoreReceipt(
            drill_id=DRILL,
            operation_id=OPERATION,
            deployed_sha=SHA,
            database_snapshot=DATABASE,
            uploads_snapshot=UPLOADS,
            latest_migration="14",
            migration_count=14,
            upload_files=2,
            upload_directories=1,
            upload_bytes=42,
            uploads_sha256="d" * 64,
            completed_at=COMPLETED,
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_round_trips_private_receipts_without_temporary_residue(self) -> None:
        backup_path = self.root / "backup.json"
        restore_path = self.root / "restore.json"

        write_backup_receipt(backup_path, self.backup)
        write_restore_receipt(restore_path, self.restore)

        self.assertEqual(read_backup_receipt(backup_path), self.backup)
        self.assertEqual(read_restore_receipt(restore_path), self.restore)
        self.assertEqual(list(self.root.glob(".*.tmp")), [])
        if os.name == "posix":
            self.assertEqual(stat.S_IMODE(backup_path.stat().st_mode), 0o600)
            self.assertEqual(stat.S_IMODE(restore_path.stat().st_mode), 0o600)

    def test_never_overwrites_an_existing_receipt(self) -> None:
        path = self.root / "receipt.json"
        write_backup_receipt(path, self.backup)
        before = path.read_bytes()

        self._assert_code(
            "RECEIPT_WRITE_FAILED",
            write_restore_receipt,
            path,
            self.restore,
        )
        self.assertEqual(path.read_bytes(), before)
        self.assertEqual(list(self.root.glob(".*.tmp")), [])

    def test_rejects_relative_invalid_and_unavailable_paths(self) -> None:
        self._assert_code(
            "RECEIPT_PATH_INVALID",
            write_backup_receipt,
            Path("relative.json"),
            self.backup,
        )
        self._assert_code(
            "RECEIPT_PATH_INVALID",
            read_backup_receipt,
            object(),  # type: ignore[arg-type]
        )
        self._assert_code(
            "RECEIPT_WRITE_FAILED",
            write_backup_receipt,
            self.root / "missing" / "receipt.json",
            self.backup,
        )
        directory = self.root / "directory"
        directory.mkdir()
        self._assert_code("RECEIPT_READ_FAILED", read_backup_receipt, directory)

    def test_rejects_oversized_non_utf8_and_invalid_documents(self) -> None:
        cases = (
            ("oversized.json", b"x" * (MAX_RECEIPT_BYTES + 1), "RECEIPT_READ_FAILED"),
            ("binary.json", b"\xff", "RECEIPT_READ_FAILED"),
            ("invalid.json", b"{}", "RECEIPT_INVALID"),
        )
        for name, content, code in cases:
            with self.subTest(name=name):
                path = _raw_file(self.root / name, content)
                self._assert_code(code, read_backup_receipt, path)

    @unittest.skipUnless(os.name == "posix", "POSIX mode enforcement")
    def test_rejects_group_or_world_access(self) -> None:
        path = self.root / "public.json"
        write_backup_receipt(path, self.backup)
        path.chmod(0o644)
        self._assert_code("RECEIPT_READ_FAILED", read_backup_receipt, path)

    def test_rejects_hard_links_and_mutated_reads(self) -> None:
        path = self.root / "receipt.json"
        alias = self.root / "alias.json"
        write_backup_receipt(path, self.backup)
        os.link(path, alias)
        self._assert_code("RECEIPT_READ_FAILED", read_backup_receipt, path)
        alias.unlink()

        with patch(
            "tools.recovery.receipt_store._signature",
            side_effect=[(1, 1, 1, 1), (1, 1, 1, 2)],
        ):
            self._assert_code("RECEIPT_READ_FAILED", read_backup_receipt, path)

    def test_rejects_symbolic_links_in_file_or_parent_path(self) -> None:
        target = self.root / "target.json"
        write_backup_receipt(target, self.backup)
        link = self.root / "link.json"
        linked_parent = self.root / "linked-parent"
        try:
            link.symlink_to(target)
            linked_parent.symlink_to(self.root, target_is_directory=True)
        except (OSError, NotImplementedError):
            self.skipTest("symbolic links are unavailable")

        self._assert_code("RECEIPT_READ_FAILED", read_backup_receipt, link)
        self._assert_code(
            "RECEIPT_WRITE_FAILED",
            write_backup_receipt,
            linked_parent / "new.json",
            self.backup,
        )

    def test_removes_temporary_file_when_atomic_install_fails(self) -> None:
        path = self.root / "receipt.json"
        with patch("tools.recovery.receipt_store.os.link", side_effect=OSError):
            self._assert_code(
                "RECEIPT_WRITE_FAILED",
                write_backup_receipt,
                path,
                self.backup,
            )
        self.assertFalse(path.exists())
        self.assertEqual(list(self.root.glob(".*.tmp")), [])

    def _assert_code(self, code: str, function, *arguments) -> None:
        with self.assertRaises(ReceiptError) as raised:
            function(*arguments)
        self.assertEqual(raised.exception.error_code, code)


def _raw_file(path: Path, content: bytes) -> Path:
    path.write_bytes(content)
    path.chmod(0o600)
    return path


if __name__ == "__main__":
    unittest.main()
