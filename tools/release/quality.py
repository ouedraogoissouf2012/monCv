"""Repository quality gates shared by release commands."""

from __future__ import annotations

import sys
from pathlib import Path

from .runner import CommandRunner

UNIT_TEST_SUITES = (
    "tools/quality/tests",
    "tools/deployment/tests",
    "tools/release/tests",
)


def run_repository_quality(root: Path, runner: CommandRunner) -> None:
    python = sys.executable
    for suite in UNIT_TEST_SUITES:
        runner.run(
            [
                python,
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
    runner.run([python, "tools/quality/check_source_lines.py"], cwd=root)
    runner.run([python, "tools/quality/run_gitleaks.py"], cwd=root)
    runner.run([python, "-m", "tools.deployment.compose_contract"], cwd=root)
