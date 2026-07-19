from __future__ import annotations

import unittest
from pathlib import Path
from unittest.mock import Mock

from tools.release.settings import LOCAL_TEST_JWT_SECRET, ReleaseContext
from tools.release.smoke import SmokeStack


class SmokeStackTest(unittest.TestCase):
    def test_compose_reuses_the_validated_test_jwt_secret(self) -> None:
        context = ReleaseContext(
            root=Path("."),
            sha="a" * 40,
            owner="owner",
            repository="repository",
            dirty=True,
        )

        stack = SmokeStack(context, Mock(), requested_port=18080)

        self.assertEqual(
            stack.environment["SMOKE_JWT_SECRET"],
            LOCAL_TEST_JWT_SECRET,
        )
        self.assertEqual(stack.environment["SMOKE_WEB_PORT"], "18080")


if __name__ == "__main__":
    unittest.main()
