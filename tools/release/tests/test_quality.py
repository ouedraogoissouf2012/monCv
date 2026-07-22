from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest.mock import Mock, call

from tools.release.quality import UNIT_TEST_SUITES, run_repository_quality


class RepositoryQualityTest(unittest.TestCase):
    def test_runs_unit_guards_and_real_deployment_contract(self) -> None:
        root = Path("repository")
        runner = Mock()

        run_repository_quality(root, runner)

        unit_calls = [
            call(
                [
                    sys.executable,
                    "-m",
                    "unittest",
                    "discover",
                    "-s",
                    suite,
                    "-p",
                    "test_*.py",
                ],
                cwd=root,
            )
            for suite in UNIT_TEST_SUITES
        ]
        self.assertEqual(
            runner.run.call_args_list,
            [
                *unit_calls,
                call(
                    [sys.executable, "tools/quality/check_source_lines.py"],
                    cwd=root,
                ),
                call(
                    [sys.executable, "tools/quality/run_gitleaks.py"],
                    cwd=root,
                ),
                call(
                    [sys.executable, "-m", "tools.deployment.compose_contract"],
                    cwd=root,
                ),
            ],
        )


if __name__ == "__main__":
    unittest.main()
