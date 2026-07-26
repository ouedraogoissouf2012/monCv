from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.ci.check_workflow_security import audit_workflows


class WorkflowTestCase(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        (self.root / ".github/workflows").mkdir(parents=True)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write(self, name: str, content: str) -> None:
        (self.root / ".github/workflows" / name).write_text(
            content,
            encoding="utf-8",
        )

    def messages(self) -> str:
        return "\n".join(
            violation.message
            for violation in audit_workflows(self.root, enforce_layout=False)
        )

    @staticmethod
    def read_only(body: str = "      - run: echo safe") -> str:
        return f"""name: test
on:
  pull_request:
permissions: {{}}
jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
{body}
"""
