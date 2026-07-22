from __future__ import annotations

import os
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

from tools.recovery.commands import CommandSpec
from tools.recovery.pipeline import PipelineSpec, SafePipelineRunner
from tools.recovery.runner import RecoveryCommandError


class SafePipelineRunnerTest(unittest.TestCase):
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

    def command(self, action: str, script: str, *, timeout: int = 5) -> CommandSpec:
        return CommandSpec(
            action=action,
            arguments=(sys.executable, "-c", script),
            cwd=self.root,
            timeout_seconds=timeout,
        )

    def pipeline(self, source: str, sink: str, *, timeout: int = 5) -> PipelineSpec:
        return PipelineSpec(
            "stream isolated fixture",
            self.command("produce isolated fixture", source, timeout=timeout),
            self.command("consume isolated fixture", sink, timeout=timeout),
            timeout,
        )

    def test_streams_binary_data_without_text_decoding(self) -> None:
        source = "import sys; sys.stdout.buffer.write(bytes(range(256)) * 1024)"
        sink = (
            "import sys; data=sys.stdin.buffer.read(); "
            "raise SystemExit(0 if data == bytes(range(256)) * 1024 else 8)"
        )

        self.assertIsNone(
            SafePipelineRunner(self.environment).run(self.pipeline(source, sink))
        )

    def test_reports_both_exit_codes_without_leaking_stream_content(self) -> None:
        marker = "sensitive-database-content"
        source = f"import sys; sys.stdout.write('{marker}'); raise SystemExit(7)"
        sink = "import sys; sys.stdin.buffer.read()"

        with self.assertRaises(RecoveryCommandError) as raised:
            SafePipelineRunner(self.environment).run(self.pipeline(source, sink))
        self.assertIn("source exit code 7, sink exit code 0", str(raised.exception))
        self.assertNotIn(marker, str(raised.exception))

    def test_detects_a_sink_failure(self) -> None:
        pipeline = self.pipeline(
            "import sys; sys.stdout.buffer.write(b'data')",
            "raise SystemExit(9)",
        )
        with self.assertRaisesRegex(RecoveryCommandError, "sink exit code 9"):
            SafePipelineRunner(self.environment).run(pipeline)

    def test_missing_source_has_a_safe_error(self) -> None:
        missing = CommandSpec("missing source", ("missing-moncv-source",), self.root)
        sink = self.command("consume fixture", "pass")
        specification = PipelineSpec("stream isolated fixture", missing, sink, 5)

        with self.assertRaisesRegex(RecoveryCommandError, "source executable"):
            SafePipelineRunner(self.environment).run(specification)

    def test_missing_sink_terminates_the_source_tree(self) -> None:
        sentinel = self.root / "source-orphan.txt"
        child = (
            f"import time; time.sleep(2); open({str(sentinel)!r}, 'w').write('orphan')"
        )
        source = self.command(
            "produce fixture",
            "import subprocess, sys, time; "
            f"subprocess.Popen([sys.executable, '-c', {child!r}]); time.sleep(10)",
        )
        missing = CommandSpec("missing sink", ("missing-moncv-sink",), self.root)
        specification = PipelineSpec("stream isolated fixture", source, missing, 5)

        with self.assertRaisesRegex(RecoveryCommandError, "sink executable"):
            SafePipelineRunner(self.environment).run(specification)
        time.sleep(2)
        self.assertFalse(sentinel.exists())

    def test_timeout_terminates_descendants(self) -> None:
        sentinel = self.root / "timeout-orphan.txt"
        child = (
            f"import time; time.sleep(2); open({str(sentinel)!r}, 'w').write('orphan')"
        )
        source = (
            "import subprocess, sys, time; "
            f"subprocess.Popen([sys.executable, '-c', {child!r}]); time.sleep(10)"
        )
        sink = "import sys; sys.stdin.buffer.read()"

        with self.assertRaisesRegex(RecoveryCommandError, "timeout"):
            SafePipelineRunner(self.environment).run(
                self.pipeline(source, sink, timeout=1)
            )
        time.sleep(2)
        self.assertFalse(sentinel.exists())

    def test_interruption_stops_both_processes(self) -> None:
        runner = SafePipelineRunner(self.environment)
        source = Mock()
        sink = Mock()
        with (
            patch.object(runner, "_start_source", return_value=source),
            patch.object(runner, "_start_sink", return_value=sink),
            patch.object(runner, "_wait", side_effect=KeyboardInterrupt),
            patch.object(runner, "_stop") as stop,
            self.assertRaises(KeyboardInterrupt),
        ):
            runner.run(self.pipeline("pass", "pass"))
        stop.assert_called_once_with(source, sink)

    def test_rejects_a_timeout_larger_than_either_command(self) -> None:
        source = self.command("produce fixture", "pass", timeout=1)
        sink = self.command("consume fixture", "pass", timeout=2)
        with self.assertRaises(ValueError):
            PipelineSpec("stream isolated fixture", source, sink, 2)


if __name__ == "__main__":
    unittest.main()
