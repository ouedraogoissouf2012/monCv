from __future__ import annotations

import unittest
from unittest.mock import Mock, call

from tools.release.browser_flow import BrowserSmokeFlow


class BrowserSmokeFlowTest(unittest.TestCase):
    def setUp(self) -> None:
        self.api = Mock()
        self.flow = BrowserSmokeFlow(Mock(), self.api)
        self.flow.token = "token"
        self.flow.duplicate_id = 12
        self.flow.cv_id = 34

    def test_successful_flow_fails_if_cleanup_fails_but_attempts_every_id(self) -> None:
        self.api.delete_cv.side_effect = [RuntimeError("first"), None]

        with self.assertRaisesRegex(RuntimeError, "cleanup failed"):
            self.flow._cleanup(suppress_errors=False)

        self.assertEqual(
            self.api.delete_cv.call_args_list,
            [call(12, "token"), call(34, "token")],
        )

    def test_original_failure_is_not_hidden_by_cleanup_failure(self) -> None:
        self.api.delete_cv.side_effect = RuntimeError("cleanup")

        self.flow._cleanup(suppress_errors=True)

        self.assertEqual(self.api.delete_cv.call_count, 2)


if __name__ == "__main__":
    unittest.main()
