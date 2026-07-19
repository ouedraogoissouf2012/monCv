from __future__ import annotations

import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.release.runner import CommandError, CommandRunner, executable_command


class CommandRunnerTest(unittest.TestCase):
    @patch("tools.release.runner.os.name", "nt")
    @patch("tools.release.runner.shutil.which")
    def test_windows_batch_uses_cmd_wrapper(self, which) -> None:
        which.return_value = r"C:\tools\flutter.bat"
        command = executable_command(["flutter", "--version"])

        self.assertEqual(command[1:4], ["/d", "/s", "/c"])
        self.assertEqual(command[4], "call")
        self.assertIn("flutter.bat", command[5])
        self.assertEqual(command[6], "--version")

    @unittest.skipUnless(os.name == "nt", "Windows batch integration test")
    def test_runner_executes_batch_file_with_spaces(self) -> None:
        with tempfile.TemporaryDirectory(prefix="moncv runner ") as temp:
            root = Path(temp)
            script = root / "echo value.cmd"
            script.write_text("@echo off\r\necho %1\r\n", encoding="ascii")
            output = CommandRunner().capture([str(script), "ready"], cwd=root)

        self.assertEqual(output, "ready")

    def test_capture_returns_trimmed_stdout(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            result = CommandRunner().capture(
                [sys.executable, "-c", "print('ready')"], cwd=Path(temp)
            )
        self.assertEqual(result, "ready")

    def test_failure_includes_exit_code(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaisesRegex(CommandError, "exit code 7"):
                CommandRunner().run(
                    [sys.executable, "-c", "raise SystemExit(7)"],
                    cwd=Path(temp),
                )


if __name__ == "__main__":
    unittest.main()
