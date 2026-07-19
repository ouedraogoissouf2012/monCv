from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

QUALITY_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(QUALITY_DIR))

from run_gitleaks import (  # noqa: E402
    GITLEAKS_IMAGE,
    GitleaksConfigurationError,
    materialize_index,
    normalize_tracked_path,
    scanner_command,
    select_engine,
)


class RunGitleaksTest(unittest.TestCase):
    def test_normalize_tracked_path_rejects_traversal(self) -> None:
        with self.assertRaises(GitleaksConfigurationError):
            normalize_tracked_path("../secret.env")
        with self.assertRaises(GitleaksConfigurationError):
            normalize_tracked_path("/absolute/path")

    def test_docker_command_pins_image_and_config(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            snapshot = Path(temp)
            (snapshot / ".gitleaks.toml").write_text("title = 'test'\n")
            command = scanner_command("docker", snapshot)

        self.assertIn(GITLEAKS_IMAGE, command)
        self.assertIn("--config=/scan/.gitleaks.toml", command)
        self.assertNotIn("latest", " ".join(command))

    @patch("run_gitleaks.shutil.which")
    def test_auto_engine_falls_back_to_docker(self, which) -> None:
        which.side_effect = lambda executable: (
            "docker" if executable == "docker" else None
        )
        self.assertEqual(select_engine("auto"), "docker")

    def test_snapshot_uses_staged_content(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "repository"
            root.mkdir()
            self._git(root, "init")
            tracked = root / "tracked.txt"
            tracked.write_text("staged\n")
            self._git(root, "add", "tracked.txt")
            tracked.write_text("unstaged\n")

            snapshot = Path(temp) / "snapshot"
            snapshot.mkdir()
            self.assertEqual(materialize_index(root, snapshot), 1)
            self.assertEqual((snapshot / "tracked.txt").read_text(), "staged\n")

    @staticmethod
    def _git(root: Path, *arguments: str) -> None:
        subprocess.run(
            ["git", *arguments],
            cwd=root,
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


if __name__ == "__main__":
    unittest.main()
