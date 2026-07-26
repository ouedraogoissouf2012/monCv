from __future__ import annotations

import re
import unittest

from tools.ci.workflow_model import (
    canonical_syntax_issues,
    iter_uses,
    job_at,
    normalized_digest,
    parse_jobs,
)
from tools.ci.workflow_security_policy import (
    PRIVILEGED_PERMISSIONS,
    READ_ONLY,
    VERIFIED_ACTIONS,
)


class WorkflowModelTest(unittest.TestCase):
    def test_digest_normalizes_the_final_newline(self) -> None:
        self.assertEqual(
            normalized_digest(["name: CI", "jobs:"]),
            normalized_digest("name: CI\njobs:\n".splitlines()),
        )

    def test_jobs_have_stable_boundaries(self) -> None:
        lines = [
            "name: CI",
            "jobs:",
            "  first:",
            "    runs-on: ubuntu-latest",
            "  second:",
            "    runs-on: ubuntu-latest",
        ]

        jobs = parse_jobs(lines)

        self.assertEqual(["first", "second"], [job.name for job in jobs])
        self.assertEqual("first", job_at(jobs, 3).name)
        self.assertEqual("second", job_at(jobs, 5).name)
        self.assertIsNone(job_at(jobs, 1))

    def test_action_references_are_reported_with_invalid_syntax(self) -> None:
        lines = [
            "      - uses: actions/checkout@abc # v4",
            "      - uses: actions/setup-python",
        ]

        references = list(iter_uses(lines))

        self.assertEqual("actions/checkout", references[0][1].group("action"))
        self.assertIsNone(references[1][1])

    def test_sensitive_yaml_syntax_is_canonical(self) -> None:
        issues = canonical_syntax_issues(
            [
                "name: one",
                "name: two",
                '"permissions": {}',
                "jobs :",
                "\tsteps:",
            ]
        )
        messages = [message for _, message in issues]

        self.assertIn("duplicate top-level key: name", messages)
        self.assertIn(
            "security-sensitive YAML keys must use canonical syntax",
            messages,
        )
        self.assertIn("workflow YAML must not contain tabs", messages)


class WorkflowPolicyTest(unittest.TestCase):
    def test_action_pins_are_exact_commits_with_version_labels(self) -> None:
        semantic_version = re.compile(r"^v\d+\.\d+\.\d+$")

        for action, (commit, tag) in VERIFIED_ACTIONS.items():
            with self.subTest(action=action):
                self.assertRegex(commit, r"^[0-9a-f]{40}$")
                self.assertRegex(tag, semantic_version)

    def test_privileged_jobs_never_receive_unrelated_capabilities(self) -> None:
        allowed = {
            "actions",
            "contents",
            "id-token",
            "packages",
            "pull-requests",
        }

        for job, permissions in PRIVILEGED_PERMISSIONS.items():
            with self.subTest(job=job):
                self.assertEqual("read", permissions.get("contents"))
                self.assertLessEqual(set(permissions), allowed)
                self.assertNotEqual(permissions, READ_ONLY)


if __name__ == "__main__":
    unittest.main()
