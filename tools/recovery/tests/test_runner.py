from __future__ import annotations

import os
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

from tools.recovery.commands import CommandSpec
from tools.recovery.runner import (
    RecoveryCommandError,
    SafeCommandRunner,
    sanitized_environment,
)


class SafeCommandRunnerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name).resolve()
        self.environment = {
            key: value
            for key, value in os.environ.items()
            if key.casefold() in {"path", "pathext", "systemroot", "windir"}
        }

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def command(self, script: str, *, timeout: int = 5) -> CommandSpec:
        return CommandSpec(
            action="run isolated fixture",
            arguments=(sys.executable, "-c", script),
            cwd=self.root,
            timeout_seconds=timeout,
        )

    def test_captures_successful_utf8_output(self) -> None:
        runner = SafeCommandRunner(self.environment)
        self.assertEqual(runner.run(self.command("print('ready')")), "ready")

    def test_external_output_and_arguments_never_reach_errors(self) -> None:
        marker = "fixture-sensitive-value"
        runner = SafeCommandRunner(self.environment)
        command = self.command(f"print('{marker}'); raise SystemExit(7)")

        with self.assertRaises(RecoveryCommandError) as raised:
            runner.run(command)
        self.assertNotIn(marker, str(raised.exception))
        self.assertIn("exit code 7", str(raised.exception))

    def test_missing_executable_has_a_safe_diagnostic(self) -> None:
        runner = SafeCommandRunner(self.environment)
        command = CommandSpec(
            "run missing fixture",
            ("moncv-command-that-does-not-exist",),
            self.root,
        )
        with self.assertRaisesRegex(RecoveryCommandError, "executable unavailable"):
            runner.run(command)

    def test_bounds_output_and_terminates_the_process(self) -> None:
        runner = SafeCommandRunner(self.environment, max_capture_bytes=32)
        with self.assertRaisesRegex(RecoveryCommandError, "output limit"):
            runner.run(self.command("print('x' * 1000)"))

    def test_enforces_timeout_without_exposing_the_script(self) -> None:
        marker = "timeout-sensitive-value"
        runner = SafeCommandRunner(self.environment)
        with self.assertRaises(RecoveryCommandError) as raised:
            runner.run(
                self.command(
                    f"import time; time.sleep(5); print('{marker}')", timeout=1
                )
            )
        self.assertNotIn(marker, str(raised.exception))
        self.assertIn("timeout", str(raised.exception))

    def test_timeout_terminates_descendant_processes(self) -> None:
        sentinel = self.root / "orphan.txt"
        child = (
            f"import time; time.sleep(3); open({str(sentinel)!r}, 'w').write('orphan')"
        )
        parent = (
            "import subprocess, sys, time; "
            f"subprocess.Popen([sys.executable, '-c', {child!r}]); time.sleep(10)"
        )
        with self.assertRaisesRegex(RecoveryCommandError, "timeout"):
            SafeCommandRunner(self.environment).run(self.command(parent, timeout=1))

        time.sleep(3)
        self.assertFalse(sentinel.exists())

    def test_reader_join_is_bounded(self) -> None:
        process = Mock(stdout=Mock())
        reader = Mock()
        reader.is_alive.side_effect = (True, True)
        runner = SafeCommandRunner(self.environment)
        with patch.object(runner, "_kill_process_tree") as kill_tree:
            self.assertFalse(runner._join_reader(process, reader))
        self.assertEqual(reader.join.call_count, 2)
        process.stdout.close.assert_called_once()
        kill_tree.assert_called_once_with(process)

    @patch("tools.recovery.runner.signal.SIGKILL", 9, create=True)
    @patch("tools.recovery.runner.os.killpg", create=True)
    def test_posix_cleanup_targets_the_entire_process_group(self, killpg) -> None:
        process = Mock(pid=42)
        process.poll.side_effect = (None, 0)
        with patch("tools.recovery.runner.os.name", "posix"):
            SafeCommandRunner(self.environment)._kill_process_tree(process)
        killpg.assert_called_once_with(42, 9)

    def test_sanitizes_environment_by_target_tool(self) -> None:
        source = {
            "PATH": "system-path",
            "DOCKER_HOST": "named-context",
            "AWS_SECRET_ACCESS_KEY": "cloud-credential",
            "RESTIC_PASSWORD": "override",
            "COMPOSE_FILE": "attacker.yml",
            "JWT_SECRET": "application-secret",
        }

        compose = sanitized_environment(("docker", "compose"), source)
        restic = sanitized_environment(("restic", "version"), source)

        self.assertEqual(
            compose, {"PATH": "system-path", "DOCKER_HOST": "named-context"}
        )
        self.assertIn("AWS_SECRET_ACCESS_KEY", restic)
        self.assertNotIn("RESTIC_PASSWORD", restic)
        self.assertNotIn("COMPOSE_FILE", restic)
        self.assertNotIn("JWT_SECRET", restic)

    def test_rejects_invalid_capture_limit(self) -> None:
        with self.assertRaises(ValueError):
            SafeCommandRunner(self.environment, max_capture_bytes=0)


if __name__ == "__main__":
    unittest.main()
