from __future__ import annotations

import unittest
from unittest.mock import Mock, call, patch

from tools.release.browser_flow import BrowserSmokeFlow
from tools.release.browser_smoke import BrowserDiagnostics


class BrowserDiagnosticsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.diagnostics = BrowserDiagnostics("http://127.0.0.1:49152")

    def test_only_console_errors_are_recorded(self) -> None:
        warning = Mock(type="warning", text="warning")
        error = Mock(type="error", text="broken")

        self.diagnostics._on_console(warning)
        self.diagnostics._on_console(error)

        self.assertEqual(self.diagnostics.console_errors, ["broken"])

    def test_cross_origin_request_failures_are_ignored(self) -> None:
        request = Mock(
            url="https://fonts.example/font.woff2",
            method="GET",
            failure="net::ERR_FAILED",
        )

        self.diagnostics._on_request_failed(request)

        self.assertEqual(self.diagnostics.failed_requests, [])

    def test_same_origin_request_failures_are_reported(self) -> None:
        request = Mock(
            url="http://127.0.0.1:49152/main.dart.js",
            method="GET",
            failure="net::ERR_FAILED",
        )

        self.diagnostics._on_request_failed(request)

        with self.assertRaisesRegex(RuntimeError, "main.dart.js"):
            self.diagnostics.assert_clean()

    def test_intentional_browser_aborts_are_ignored(self) -> None:
        request = Mock(
            url="http://127.0.0.1:49152/old",
            method="GET",
            failure="net::ERR_ABORTED",
        )

        self.diagnostics._on_request_failed(request)

        self.diagnostics.assert_clean()


class BrowserSmokeFlowTest(unittest.TestCase):
    def setUp(self) -> None:
        self.page = Mock()
        self.flow = BrowserSmokeFlow(self.page, Mock())
        self.field = Mock()
        self.flow._field = Mock(return_value=self.field)

    @patch("tools.release.browser_flow.expect")
    def test_suggestion_can_be_clicked(self, expect_value: Mock) -> None:
        options = self.page.get_by_text.return_value
        options.count.return_value = 1
        options.first.is_visible.return_value = True

        self.flow._select_suggestion("Pays", "Côte d'Ivoire")

        self.field.fill.assert_called_once_with("Côte d'Ivoire")
        options.first.click.assert_called_once_with()
        self.page.keyboard.press.assert_not_called()
        self.assertEqual(expect_value.call_count, 2)

    @patch("tools.release.browser_flow.expect")
    def test_keyboard_selects_when_focus_is_preserved(
        self, expect_value: Mock
    ) -> None:
        self.page.get_by_text.return_value.count.return_value = 0
        self.page.locator.return_value.count.return_value = 1
        self.page.locator.return_value.first.get_attribute.return_value = "Ville"

        self.flow._select_suggestion("Ville", "Abidjan")

        self.page.keyboard.press.assert_has_calls([call("ArrowDown"), call("Enter")])
        self.assertEqual(expect_value.call_count, 2)

    @patch("tools.release.browser_flow.expect")
    def test_rebuilt_flutter_input_keeps_entered_value(
        self, expect_value: Mock
    ) -> None:
        self.page.get_by_text.return_value.count.return_value = 0
        self.page.locator.return_value.count.return_value = 0

        self.flow._select_suggestion("Pays", "Côte d'Ivoire")

        self.field.fill.assert_called_once_with("Côte d'Ivoire")
        self.page.keyboard.press.assert_not_called()
        self.assertEqual(expect_value.call_count, 2)

    def test_created_cv_location_is_required(self) -> None:
        BrowserSmokeFlow._assert_location(
            {
                "personalInfo": {
                    "pays": "Côte d'Ivoire",
                    "ville": "Abidjan",
                }
            }
        )

        with self.assertRaisesRegex(RuntimeError, "location is invalid"):
            BrowserSmokeFlow._assert_location(
                {"personalInfo": {"pays": "France", "ville": "Paris"}}
            )
        with self.assertRaisesRegex(RuntimeError, "no personal information"):
            BrowserSmokeFlow._assert_location({})


if __name__ == "__main__":
    unittest.main()
