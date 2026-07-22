from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.recovery.identity import SnapshotIdentity
from tools.recovery.target import RestoreTarget

SHA = "a" * 40
OPERATION = "12345678-1234-4234-9234-123456789abc"


class RestoreTargetTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.parent = Path(self.temporary.name).resolve()
        self.identity = SnapshotIdentity.create(SHA, OPERATION)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_derives_non_production_resource_names(self) -> None:
        workspace = self.parent / "workspace"
        workspace.mkdir()

        target = RestoreTarget(workspace, self.identity)

        self.assertEqual(target.workspace, workspace)
        self.assertEqual(
            target.container_name,
            "moncv-restore-12345678123442349234123456789abc",
        )
        self.assertEqual(target.uploads_directory, workspace / "uploads")

    def test_requires_an_empty_existing_temporary_directory(self) -> None:
        non_empty = self.parent / "non-empty"
        non_empty.mkdir()
        (non_empty / "data").write_text("protected", encoding="utf-8")

        for workspace in (
            self.parent / "missing",
            non_empty,
            Path(tempfile.gettempdir()).resolve(),
            Path.cwd(),
        ):
            with self.subTest(workspace=workspace), self.assertRaises(ValueError):
                RestoreTarget(workspace, self.identity)

    def test_rejects_symlinks_and_untrusted_identity_types(self) -> None:
        workspace = self.parent / "workspace"
        workspace.mkdir()
        with self.assertRaises(ValueError):
            RestoreTarget(workspace, object())  # type: ignore[arg-type]

        link = self.parent / "workspace-link"
        try:
            link.symlink_to(workspace, target_is_directory=True)
        except OSError:
            self.skipTest("directory symlinks are unavailable")
        with self.assertRaises(ValueError):
            RestoreTarget(link, self.identity)


if __name__ == "__main__":
    unittest.main()
