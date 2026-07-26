from __future__ import annotations

import unittest
from pathlib import Path

from tools.ci.check_workflow_security import VERIFIED_ACTIONS, audit_workflows
from tools.ci.tests.workflow_test_case import WorkflowTestCase


class WorkflowSecurityTest(WorkflowTestCase):
    def test_repository_workflows_pass(self) -> None:
        repository = Path(__file__).resolve().parents[3]
        violations = audit_workflows(repository)
        self.assertEqual([], [item.render(repository) for item in violations])

    def test_job_without_explicit_permissions_is_rejected(self) -> None:
        self.write(
            "ci.yml",
            """name: test
on: pull_request
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo unsafe
""",
        )
        self.assertIn("permissions must be", self.messages())

    def test_workflow_without_empty_top_level_permissions_is_rejected(self) -> None:
        self.write("ci.yml", self.read_only().replace("permissions: {}\n", ""))
        self.assertIn("workflow permissions must be exactly", self.messages())

    def test_duplicate_job_permissions_are_rejected(self) -> None:
        workflow = self.read_only().replace(
            "    permissions:\n      contents: read",
            """    permissions:
      contents: read
    permissions:
      contents: read""",
        )
        self.write("ci.yml", workflow)
        self.assertIn("must declare one permissions block", self.messages())

    def test_secret_context_is_rejected(self) -> None:
        self.write(
            "ci.yml",
            self.read_only(
                """      - env:
          LEAK: ${{ secrets.JWT_SECRET }}
        run: echo "$LEAK"
"""
            ),
        )
        self.assertIn("secret context is forbidden", self.messages())

    def test_oidc_and_write_permissions_are_rejected_in_candidate_job(self) -> None:
        for capability in ("id-token: write", "pull-requests: write", "packages: write"):
            with self.subTest(capability=capability):
                workflow = self.read_only().replace(
                    "      contents: read", f"      contents: read\n      {capability}"
                )
                self.write("ci.yml", workflow)
                self.assertIn("permissions must be", self.messages())

    def test_mutable_action_reference_is_rejected(self) -> None:
        self.write(
            "ci.yml",
            self.read_only(
                """      - uses: actions/checkout@v4
        with:
          persist-credentials: false"""
            ),
        )
        self.assertIn("verified full SHA", self.messages())

    def test_unverified_sha_is_rejected(self) -> None:
        self.write(
            "ci.yml",
            self.read_only(
                f"""      - uses: actions/checkout@{'0' * 40} # v4
        with:
          persist-credentials: false"""
            ),
        )
        self.assertIn("must use verified pin", self.messages())

    def test_checkout_without_disabled_credentials_is_rejected(self) -> None:
        sha, tag = VERIFIED_ACTIONS["actions/checkout"]
        self.write(
            "ci.yml",
            self.read_only(f"      - uses: actions/checkout@{sha} # {tag}"),
        )
        self.assertIn("persist-credentials exactly once to false", self.messages())

    def test_duplicate_checkout_credentials_are_rejected(self) -> None:
        sha, tag = VERIFIED_ACTIONS["actions/checkout"]
        self.write(
            "ci.yml",
            self.read_only(
                f"""      - uses: actions/checkout@{sha} # {tag}
        with:
          persist-credentials: false
          persist-credentials: true"""
            ),
        )
        self.assertIn("persist-credentials exactly once to false", self.messages())

    def test_verified_checkout_without_credentials_passes(self) -> None:
        sha, tag = VERIFIED_ACTIONS["actions/checkout"]
        self.write(
            "ci.yml",
            self.read_only(
                f"""      - uses: actions/checkout@{sha} # {tag}
        with:
          persist-credentials: false"""
            ),
        )
        self.assertEqual("", self.messages())

    def test_reporting_workflow_is_frozen(self) -> None:
        self.write(
            "ci-reports.yml",
            """name: report
on:
  workflow_run:
jobs:
  backend-codecov:
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      id-token: write
    steps:
      - run: ./candidate/steal.sh
""",
        )
        self.assertIn("trusted workflow digest changed", self.messages())

    def test_privileged_workflow_trigger_is_frozen(self) -> None:
        self.write(
            "ci-reports.yml",
            """name: report
on:
  workflow_run:
  pull_request:
jobs:
  backend-codecov:
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      id-token: write
    steps:
      - name: no-op
""",
        )
        self.assertIn("trusted workflow digest changed", self.messages())

    def test_publisher_commands_are_frozen(self) -> None:
        self.write(
            "publish.yml",
            """name: publish
on:
  workflow_run:
    branches: [main]
jobs:
  docker-publish:
    if: github.event.workflow_run.event == 'push' && github.event.workflow_run.conclusion == 'success'
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      packages: write
    steps:
      - run: docker run candidate-image
""",
        )
        self.assertIn("trusted workflow digest changed", self.messages())

    def test_privileged_action_inputs_are_frozen(self) -> None:
        repository = Path(__file__).resolve().parents[3]
        workflow = (repository / ".github/workflows/ci-reports.yml").read_text(
            encoding="utf-8"
        )
        mutated = workflow.replace(
            "repository: ${{ github.repository }}",
            "repository: attacker/repository",
            1,
        )
        self.write("ci-reports.yml", mutated)
        self.assertIn("trusted workflow digest changed", self.messages())

    def test_pull_request_target_cannot_execute_candidate_script(self) -> None:
        self.write(
            "source-policy.yml",
            self.read_only("      - run: python candidate/steal.py").replace(
                "  pull_request:", "  pull_request_target:"
            ),
        )
        self.assertIn("pull_request_target executes candidate code", self.messages())

    def test_pull_request_target_cannot_install_candidate_dependencies(self) -> None:
        self.write(
            "source-policy.yml",
            self.read_only(
                """      - working-directory: candidate
        run: flutter pub get"""
            ).replace("  pull_request:", "  pull_request_target:"),
        )
        self.assertIn("pull_request_target executes candidate code", self.messages())

    def test_pull_request_target_policy_is_frozen(self) -> None:
        self.write(
            "source-policy.yml",
            self.read_only(
                "      - run: python trusted/check.py --root candidate"
            ).replace("  pull_request:", "  pull_request_target:"),
        )
        self.assertIn("trusted workflow digest changed", self.messages())


if __name__ == "__main__":
    unittest.main()
