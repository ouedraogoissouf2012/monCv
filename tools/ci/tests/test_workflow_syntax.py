from __future__ import annotations

from pathlib import Path

from tools.ci.check_workflow_security import _check_pull_request_target
from tools.ci.tests.workflow_test_case import WorkflowTestCase


class WorkflowSyntaxTest(WorkflowTestCase):
    def test_indexed_secret_context_is_rejected(self) -> None:
        self.write(
            "ci.yml",
            self.read_only(
                """      - env:
          LEAK: ${{ secrets['JWT_SECRET'] }}
        run: echo "$LEAK"
"""
            ),
        )
        self.assertIn("secret context is forbidden", self.messages())

    def test_quoted_sensitive_key_is_rejected(self) -> None:
        self.write(
            "ci.yml",
            self.read_only().replace("permissions: {}", '"permissions": {}', 1),
        )
        self.assertIn("must use canonical syntax", self.messages())

    def test_spaced_sensitive_key_is_rejected(self) -> None:
        self.write(
            "ci.yml",
            self.read_only().replace("permissions: {}", "permissions : {}", 1),
        )
        self.assertIn("must use canonical syntax", self.messages())

    def test_duplicate_top_level_key_is_rejected(self) -> None:
        self.write(
            "ci.yml",
            self.read_only().replace("jobs:", "name: duplicate\njobs:"),
        )
        self.assertIn("duplicate top-level key: name", self.messages())

    def test_known_local_reusable_workflow_is_allowed(self) -> None:
        workflow = self.read_only().replace(
            "  test:",
            "  docker-verify:",
        ).replace(
            "    runs-on: ubuntu-latest\n",
            "",
        ).replace(
            "    steps:\n      - run: echo safe",
            "    uses: ./.github/workflows/container-verify.yml",
        )
        self.write("ci.yml", workflow)
        self.assertEqual("", self.messages())

    def test_unexpected_local_reusable_workflow_is_rejected(self) -> None:
        workflow = self.read_only().replace(
            "    steps:\n      - run: echo safe",
            "    uses: ./.github/workflows/untrusted.yml",
        )
        self.write("ci.yml", workflow)
        self.assertIn("unexpected local reusable workflow", self.messages())

    def test_isolated_offline_formatter_bootstrap_is_allowed(self) -> None:
        workflow = self.read_only(
            """      - name: Initialize isolated formatter metadata
        working-directory: ${{ runner.temp }}/l10n-project
        run: flutter pub get --offline"""
        ).replace("  pull_request:", "  pull_request_target:")
        violations = _check_pull_request_target(
            Path("source-policy.yml"),
            workflow.splitlines(),
        )
        self.assertEqual([], violations)

    def test_online_formatter_bootstrap_is_rejected(self) -> None:
        workflow = self.read_only(
            """      - name: Initialize isolated formatter metadata
        working-directory: ${{ runner.temp }}/l10n-project
        run: flutter pub get"""
        ).replace("  pull_request:", "  pull_request_target:")
        violations = _check_pull_request_target(
            Path("source-policy.yml"),
            workflow.splitlines(),
        )
        self.assertIn(
            "pull_request_target executes candidate code",
            [violation.message for violation in violations],
        )
