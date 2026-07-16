from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

QUALITY_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(QUALITY_DIR))

from source_line_policy import (  # noqa: E402
    ALLOWED_GENERATED_FILES,
    PolicyConfigurationError,
    load_policy,
)


class SourceLinePolicyTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.policy_path = Path(self.temporary_directory.name) / "policy.json"

    def valid_policy(self) -> dict[str, object]:
        return {
            "version": 1,
            "legacy_files": [
                {
                    "path": "mobile/lib/legacy.dart",
                    "baseline_lines": 301,
                    "issue": "#999",
                    "expires_on": "2099-12-31",
                }
            ],
            "generated_files": sorted(ALLOWED_GENERATED_FILES),
        }

    def load(self, policy: dict[str, object]):
        self.policy_path.write_text(json.dumps(policy), encoding="utf-8")
        return load_policy(self.policy_path)

    def test_valid_policy_is_loaded(self) -> None:
        policy = self.load(self.valid_policy())

        self.assertEqual(301, policy.legacy_files[0].baseline_lines)
        self.assertEqual(ALLOWED_GENERATED_FILES, policy.generated_files)

    def test_boolean_version_is_rejected(self) -> None:
        policy = self.valid_policy()
        policy["version"] = True

        with self.assertRaisesRegex(
            PolicyConfigurationError, "Unsupported policy version"
        ):
            self.load(policy)

    def test_duplicate_legacy_path_is_rejected(self) -> None:
        policy = self.valid_policy()
        policy["legacy_files"] = [
            *policy["legacy_files"],
            dict(policy["legacy_files"][0]),
        ]

        with self.assertRaisesRegex(PolicyConfigurationError, "Duplicate"):
            self.load(policy)

    def test_invalid_source_paths_are_rejected(self) -> None:
        cases = (
            ("mobile/lib/../escape.dart", "normalized"),
            ("/mobile/lib/absolute.dart", "normalized"),
            (r"mobile\lib\windows.dart", "outside source roots"),
            ("mobile/library/neighbor.dart", "outside source roots"),
            ("mobile/lib/not-source.txt", "Dart or Java"),
            ("mobile/lib/control\n.dart", "control characters"),
        )
        for path, message in cases:
            with self.subTest(path=path):
                policy = self.valid_policy()
                policy["legacy_files"][0]["path"] = path
                with self.assertRaisesRegex(PolicyConfigurationError, message):
                    self.load(policy)

    def test_baseline_at_limit_is_rejected(self) -> None:
        policy = self.valid_policy()
        policy["legacy_files"][0]["baseline_lines"] = 300

        with self.assertRaisesRegex(PolicyConfigurationError, "above 300"):
            self.load(policy)

    def test_unapproved_generated_exception_is_rejected(self) -> None:
        policy = self.valid_policy()
        policy["generated_files"] = sorted(
            ALLOWED_GENERATED_FILES | {"mobile/lib/generated_escape.dart"}
        )

        with self.assertRaisesRegex(
            PolicyConfigurationError, "Generated exceptions are immutable"
        ):
            self.load(policy)


if __name__ == "__main__":
    unittest.main()
