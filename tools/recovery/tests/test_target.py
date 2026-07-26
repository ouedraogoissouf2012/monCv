from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.recovery.identity import SnapshotIdentity
from tools.recovery.target import RestoreTarget

SHA = "a" * 40
OPERATION = "12345678-1234-4234-9234-123456789abc"
DRILL = "87654321-4321-4321-8321-cba987654321"


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

        target = RestoreTarget(workspace, self.identity, DRILL)

        self.assertEqual(target.workspace, workspace)
        self.assertEqual(
            target.container_name,
            "moncv-restore-87654321432143218321cba987654321",
        )
        self.assertEqual(target.drill_id, DRILL)
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
        with self.assertRaises(ValueError):
            RestoreTarget(workspace, self.identity, "not-a-uuid")
        with self.assertRaises(TypeError):
            RestoreTarget(workspace, self.identity, 123)  # type: ignore[arg-type]

        link = self.parent / "workspace-link"
        try:
            link.symlink_to(workspace, target_is_directory=True)
        except OSError:
            self.skipTest("directory symlinks are unavailable")
        with self.assertRaises(ValueError):
            RestoreTarget(link, self.identity)

    def test_default_drill_ids_are_unique(self) -> None:
        first = self.parent / "first"
        second = self.parent / "second"
        first.mkdir()
        second.mkdir()
        first_target = RestoreTarget(first, self.identity)
        second_target = RestoreTarget(second, self.identity)
        self.assertNotEqual(first_target.drill_id, second_target.drill_id)
        self.assertNotEqual(first_target.container_name, second_target.container_name)


if __name__ == "__main__":
    unittest.main()
