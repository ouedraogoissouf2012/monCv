from __future__ import annotations

import sys
import unittest
from datetime import date
from pathlib import Path

QUALITY_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(QUALITY_DIR))

from source_line_policy import (  # noqa: E402
    ALLOWED_GENERATED_FILES,
    LegacyAllowance,
    PolicyConfigurationError,
    SourceLinePolicy,
)
from source_line_transition import validate_policy_transition  # noqa: E402


def policy(*entries: LegacyAllowance) -> SourceLinePolicy:
    return SourceLinePolicy(tuple(entries), ALLOWED_GENERATED_FILES)


def legacy(
    *, lines: int = 350, issue: str = "#999", expiry: str = "2099-12-31"
) -> LegacyAllowance:
    return LegacyAllowance(
        "mobile/lib/legacy.dart", lines, issue, date.fromisoformat(expiry)
    )


class SourceLineTransitionTest(unittest.TestCase):
    def assert_rejected(self, reference, candidate, message: str) -> None:
        with self.assertRaisesRegex(PolicyConfigurationError, message):
            validate_policy_transition(reference, candidate)

    def test_new_legacy_entry_is_rejected(self) -> None:
        self.assert_rejected(policy(), policy(legacy()), "new legacy entry")

    def test_baseline_increase_is_rejected(self) -> None:
        self.assert_rejected(
            policy(legacy(lines=350)), policy(legacy(lines=351)), "baseline increase"
        )

    def test_expiry_extension_is_rejected(self) -> None:
        self.assert_rejected(
            policy(legacy(expiry="2099-12-30")),
            policy(legacy(expiry="2099-12-31")),
            "expiry extension",
        )

    def test_issue_change_is_rejected(self) -> None:
        self.assert_rejected(
            policy(legacy(issue="#999")),
            policy(legacy(issue="#998")),
            "migration issue change",
        )

    def test_reduction_and_earlier_expiry_are_accepted(self) -> None:
        validate_policy_transition(
            policy(legacy(lines=350, expiry="2099-12-31")),
            policy(legacy(lines=340, expiry="2099-12-30")),
        )

    def test_entry_removal_is_accepted(self) -> None:
        validate_policy_transition(policy(legacy()), policy())


if __name__ == "__main__":
    unittest.main()
