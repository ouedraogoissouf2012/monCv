from __future__ import annotations

import sys
import tempfile
import unittest
from datetime import date
from pathlib import Path

QUALITY_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(QUALITY_DIR))

from source_line_guard import (  # noqa: E402
    GuardReport,
    inspect_repository,
    render_report,
)
from source_line_test_fixture import RepositoryFixture  # noqa: E402

TODAY = date(2026, 7, 15)


class SourceLineGuardTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.fixture = RepositoryFixture(Path(self.temporary_directory.name))

    def inspect(self) -> GuardReport:
        return inspect_repository(
            self.fixture.root,
            self.fixture.load_policy(),
            today=TODAY,
        )

    def test_file_at_300_lines_is_accepted(self) -> None:
        self.fixture.write_lines("mobile/lib/accepted.dart", 300)

        report = self.inspect()

        self.assertTrue(report.passed, report.violations)

    def test_file_at_301_lines_is_rejected(self) -> None:
        self.fixture.write_lines("mobile/lib/rejected.dart", 301)

        report = self.inspect()

        self.assertEqual("new-oversized-source", report.violations[0].code)
        self.assertEqual("#232", report.violations[0].issue)

    def test_legacy_file_at_its_baseline_is_accepted(self) -> None:
        path = "backend/src/main/java/example/Legacy.java"
        self.fixture.write_lines(path, 350)
        self.fixture.add_legacy(path, 350)

        report = self.inspect()

        self.assertTrue(report.passed, report.violations)
        self.assertEqual(1, report.active_legacy_files)

    def test_legacy_growth_is_rejected_with_actionable_message(self) -> None:
        path = "backend/src/main/java/example/Legacy.java"
        self.fixture.write_lines(path, 351)
        self.fixture.add_legacy(path, 350)

        report = self.inspect()

        self.assertEqual("legacy-growth", report.violations[0].code)
        rendered = render_report(report)
        self.assertIn(f'path="{path}"', rendered)
        self.assertIn("lines=351 limit=300 issue=#999", rendered)

    def test_legacy_reduction_requires_a_tighter_baseline(self) -> None:
        path = "backend/src/main/java/example/Legacy.java"
        self.fixture.write_lines(path, 349)
        self.fixture.add_legacy(path, 350)

        report = self.inspect()

        self.assertEqual("legacy-baseline-must-be-lowered", report.violations[0].code)
        self.assertIn("from 350 to 349", report.violations[0].detail)

    def test_compliant_legacy_file_requires_baseline_cleanup(self) -> None:
        path = "mobile/test/legacy_test.dart"
        self.fixture.write_lines(path, 300)
        self.fixture.add_legacy(path, 350)

        report = self.inspect()

        self.assertEqual("legacy-entry-must-be-removed", report.violations[0].code)

    def test_legacy_entry_expires_at_start_of_expiry_date(self) -> None:
        path = "mobile/lib/legacy.dart"
        self.fixture.write_lines(path, 350)
        self.fixture.add_legacy(path, 350, expires_on=TODAY.isoformat())

        report = self.inspect()

        self.assertEqual("legacy-entry-expired", report.violations[0].code)

    def test_missing_legacy_source_requires_baseline_cleanup(self) -> None:
        self.fixture.add_legacy("mobile/lib/deleted.dart", 350)

        report = self.inspect()

        self.assertEqual("stale-legacy-entry", report.violations[0].code)


if __name__ == "__main__":
    unittest.main()
