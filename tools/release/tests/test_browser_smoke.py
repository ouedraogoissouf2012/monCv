from __future__ import annotations

import unittest
from unittest.mock import Mock

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


if __name__ == "__main__":
    unittest.main()
