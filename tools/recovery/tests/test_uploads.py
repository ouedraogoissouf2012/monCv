from __future__ import annotations

import hashlib
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.recovery.uploads import UploadsProof, validate_restored_uploads
from tools.recovery.validation import RestoreValidationError


class UploadsProofTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name).resolve() / "restored"
        self.root.mkdir()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_hashes_nested_files_and_empty_directories_deterministically(self) -> None:
        photos = self.root / "source" / "uploads" / "photos"
        photos.mkdir(parents=True)
        (photos / "empty").mkdir()
        (photos / "b.bin").write_bytes(bytes(range(256)))
        (photos / "a.txt").write_text("profile-photo", encoding="utf-8")

        first = validate_restored_uploads(self.root)
        second = validate_restored_uploads(self.root)

        self.assertIsInstance(first, UploadsProof)
        self.assertEqual(first, second)
        self.assertEqual(first.file_count, 2)
        self.assertEqual(first.directory_count, 4)
        self.assertEqual(first.total_bytes, 269)
        self.assertRegex(first.tree_sha256, r"[0-9a-f]{64}")

    def test_accepts_an_empty_restored_snapshot(self) -> None:
        proof = validate_restored_uploads(self.root)
        self.assertEqual(proof.file_count, 0)
        self.assertEqual(proof.directory_count, 0)
        self.assertEqual(proof.total_bytes, 0)
        self.assertEqual(proof.tree_sha256, hashlib.sha256().hexdigest())

    def test_content_and_names_change_the_proof(self) -> None:
        file = self.root / "photo.jpg"
        file.write_bytes(b"first")
        first = validate_restored_uploads(self.root)

        file.write_bytes(b"second")
        second = validate_restored_uploads(self.root)
        file.rename(self.root / "renamed.jpg")
        renamed = validate_restored_uploads(self.root)

        self.assertNotEqual(first.tree_sha256, second.tree_sha256)
        self.assertNotEqual(second.tree_sha256, renamed.tree_sha256)

    def test_rejects_missing_files_symlinks_and_special_entries_without_leak(
        self,
    ) -> None:
        marker = "sensitive-upload-name"
        missing = self.root / marker
        with self.assertRaises(RestoreValidationError) as raised:
            validate_restored_uploads(missing)
        self.assertNotIn(marker, str(raised.exception))
        with self.assertRaises(RestoreValidationError):
            validate_restored_uploads(None)  # type: ignore[arg-type]

        target = self.root / "target"
        target.write_bytes(b"data")
        link = self.root / "link"
        try:
            link.symlink_to(target)
        except OSError:
            self.skipTest("file symlinks are unavailable")
        with self.assertRaises(RestoreValidationError):
            validate_restored_uploads(self.root)

    @unittest.skipUnless(hasattr(os, "mkfifo"), "FIFO files require POSIX")
    def test_rejects_special_files(self) -> None:
        os.mkfifo(self.root / "upload.pipe")
        with self.assertRaises(RestoreValidationError):
            validate_restored_uploads(self.root)

    def test_enforces_entry_and_depth_limits(self) -> None:
        for name in ("one", "two"):
            (self.root / name).write_bytes(name.encode())
        with patch("tools.recovery.uploads.MAX_UPLOAD_ENTRIES", 1):
            with self.assertRaises(RestoreValidationError):
                validate_restored_uploads(self.root)

        for child in tuple(self.root.iterdir()):
            child.unlink()
        current = self.root
        for _ in range(4):
            current = current / "d"
            current.mkdir()
        with patch("tools.recovery.uploads.MAX_UPLOAD_DEPTH", 2):
            with self.assertRaises(RestoreValidationError):
                validate_restored_uploads(self.root)


if __name__ == "__main__":
    unittest.main()
