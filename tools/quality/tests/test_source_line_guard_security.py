from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from datetime import date
from pathlib import Path

QUALITY_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(QUALITY_DIR))

from source_line_guard import inspect_repository  # noqa: E402
from source_line_policy import (  # noqa: E402
    GENERATED_CONTENT_SIGNATURES,
    GENERATED_HEADER_MARKER,
    PolicyConfigurationError,
)
from source_line_test_fixture import RepositoryFixture  # noqa: E402


class SourceLineGuardSecurityTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.fixture = RepositoryFixture(Path(self.temporary_directory.name))

    def inspect(self):
        return inspect_repository(
            self.fixture.root,
            self.fixture.load_policy(),
            today=date(2026, 7, 15),
        )

    def test_fake_generated_file_is_rejected(self) -> None:
        path = "mobile/lib/l10n/app_localizations_en.dart"
        self.fixture.write_lines(path, 301)

        report = self.inspect()

        self.assertEqual("invalid-generated-source", report.violations[0].code)

    def test_generated_declarations_copied_into_comments_are_rejected(self) -> None:
        path = "mobile/lib/l10n/app_localizations_fr.dart"
        lines = [GENERATED_HEADER_MARKER]
        lines.extend(
            f"// {signature}" for signature in GENERATED_CONTENT_SIGNATURES[path]
        )
        lines.extend("manual line" for _ in range(301 - len(lines)))
        self.fixture.write_text(path, "\n".join(lines))

        report = self.inspect()

        self.assertEqual("invalid-generated-source", report.violations[0].code)

    def test_generated_marker_after_header_window_is_rejected(self) -> None:
        path = "mobile/lib/l10n/app_localizations_en.dart"
        lines = ["manual line"] * 20
        lines.append(GENERATED_HEADER_MARKER)
        lines.extend(GENERATED_CONTENT_SIGNATURES[path])
        lines.extend("manual line" for _ in range(301 - len(lines)))
        self.fixture.write_text(path, "\n".join(lines))

        report = self.inspect()

        self.assertEqual("invalid-generated-source", report.violations[0].code)

    def test_missing_generated_file_is_rejected(self) -> None:
        path = self.fixture.root / "mobile/lib/l10n/app_localizations_fr.dart"
        path.unlink()

        report = self.inspect()

        self.assertEqual("generated-source-missing", report.violations[0].code)

    def test_standard_generated_directories_outside_roots_are_not_scanned(self) -> None:
        self.fixture.write_lines("mobile/build/oversized.dart", 301)
        self.fixture.write_lines("mobile/.dart_tool/oversized.dart", 301)
        self.fixture.write_lines("backend/target/Oversized.java", 301)

        report = self.inspect()

        self.assertTrue(report.passed, report.violations)

    def test_generated_directory_name_inside_source_root_cannot_bypass(self) -> None:
        self.fixture.write_lines("mobile/lib/build/oversized.dart", 301)

        report = self.inspect()

        self.assertEqual("new-oversized-source", report.violations[0].code)

    def test_crlf_uses_the_same_301_line_boundary(self) -> None:
        path = self.fixture.root / "mobile/lib/windows.dart"
        path.write_bytes(b"source line\r\n" * 301)

        report = self.inspect()

        self.assertEqual("new-oversized-source", report.violations[0].code)
        self.assertEqual(301, report.violations[0].line_count)

    def test_missing_source_root_is_a_configuration_error(self) -> None:
        shutil.rmtree(self.fixture.root / "backend/src/test/java")

        with self.assertRaisesRegex(PolicyConfigurationError, "Source root"):
            self.inspect()

    def test_symbolic_link_in_source_root_is_rejected(self) -> None:
        target = self.fixture.write_lines("outside.dart", 1)
        link = self.fixture.root / "mobile/lib/link.dart"
        try:
            link.symlink_to(target)
        except OSError as error:
            self.skipTest(f"Symbolic links unavailable: {error}")

        with self.assertRaisesRegex(PolicyConfigurationError, "Links are forbidden"):
            self.inspect()


if __name__ == "__main__":
    unittest.main()
