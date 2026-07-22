from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.deployment.compose_environment import interpolation_keys


class ComposeEnvironmentTest(unittest.TestCase):
    def test_discovers_unique_interpolations_across_files(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            base = root / "base.yml"
            override = root / "override.yml"
            base.write_text(
                "first: ${FIRST}\ndefault: ${FIRST:-value}\n",
                encoding="utf-8",
            )
            override.write_text(
                "required: ${SECOND:?missing}\nplain: $THIRD\nescaped: $${IGNORED}\n",
                encoding="utf-8",
            )

            keys = interpolation_keys((base, override))

        self.assertEqual(keys, frozenset({"FIRST", "SECOND", "THIRD"}))


if __name__ == "__main__":
    unittest.main()
