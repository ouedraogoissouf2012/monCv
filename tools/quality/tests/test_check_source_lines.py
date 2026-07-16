from __future__ import annotations

import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

QUALITY_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(QUALITY_DIR))

from check_source_lines import main  # noqa: E402
from source_line_policy import ALLOWED_GENERATED_FILES  # noqa: E402
from source_line_test_fixture import RepositoryFixture  # noqa: E402


class CheckSourceLinesTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.fixture = RepositoryFixture(Path(self.temporary_directory.name))

    def run_cli(self, *extra_arguments: str) -> tuple[int, str, str]:
        stdout = io.StringIO()
        stderr = io.StringIO()
        arguments = [
            "--root",
            str(self.fixture.root),
            "--policy",
            str(self.fixture.write_policy()),
            *extra_arguments,
        ]
        with redirect_stdout(stdout), redirect_stderr(stderr):
            exit_code = main(arguments)
        return exit_code, stdout.getvalue(), stderr.getvalue()

    def test_success_returns_zero(self) -> None:
        exit_code, stdout, stderr = self.run_cli()

        self.assertEqual(0, exit_code)
        self.assertIn("Source line policy passed", stdout)
        self.assertEqual("", stderr)

    def test_source_violation_returns_one(self) -> None:
        self.fixture.write_lines("mobile/lib/oversized.dart", 301)

        exit_code, stdout, _ = self.run_cli()

        self.assertEqual(1, exit_code)
        self.assertIn("new-oversized-source", stdout)

    def test_relaxed_policy_transition_returns_two(self) -> None:
        path = "mobile/lib/legacy.dart"
        self.fixture.write_lines(path, 350)
        self.fixture.add_legacy(path, 350)
        reference_path = self.fixture.root / "reference-policy.json"
        reference_path.write_text(
            json.dumps(
                {
                    "version": 1,
                    "legacy_files": [],
                    "generated_files": sorted(ALLOWED_GENERATED_FILES),
                }
            ),
            encoding="utf-8",
        )

        exit_code, _, stderr = self.run_cli("--reference-policy", str(reference_path))

        self.assertEqual(2, exit_code)
        self.assertIn("new legacy entry is forbidden", stderr)


if __name__ == "__main__":
    unittest.main()
