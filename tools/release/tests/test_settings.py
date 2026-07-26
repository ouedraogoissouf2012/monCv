from __future__ import annotations

import tempfile
import unittest
from collections import Counter
from math import log2
from pathlib import Path

from tools.release.settings import (
    LOCAL_TEST_JWT_SECRET,
    ReleaseContext,
    parse_github_remote,
)


class FakeRunner:
    def __init__(self, responses: dict[tuple[str, ...], str]) -> None:
        self.responses = responses

    def capture(self, arguments: list[str], *, cwd: Path) -> str:
        return self.responses[tuple(arguments)]


class ReleaseSettingsTest(unittest.TestCase):
    def test_flutter_version_comes_from_fvm_config(self) -> None:
        root = Path(__file__).resolve().parents[3]
        context = ReleaseContext(root, "a" * 40, "owner", "repository", False)

        self.assertEqual("3.41.9", context.flutter_version)

    def test_flutter_version_must_be_exact(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            mobile = root / "mobile"
            mobile.mkdir()
            (mobile / ".fvmrc").write_text(
                '{"flutter": "3.41.x"}',
                encoding="utf-8",
            )
            context = ReleaseContext(root, "a" * 40, "owner", "repository", False)

            with self.assertRaisesRegex(ValueError, "Invalid exact Flutter version"):
                _ = context.flutter_version

    def test_local_test_jwt_secret_meets_backend_entropy_policy(self) -> None:
        frequencies = Counter(LOCAL_TEST_JWT_SECRET)
        length = len(LOCAL_TEST_JWT_SECRET)
        entropy = -sum(
            (count / length) * log2(count / length) for count in frequencies.values()
        )

        self.assertGreaterEqual(length, 64)
        self.assertGreater(entropy, 4.0)

    def test_parse_https_and_ssh_remotes(self) -> None:
        expected = ("Owner", "Repository")
        self.assertEqual(
            parse_github_remote("https://github.com/Owner/Repository.git"),
            expected,
        )
        self.assertEqual(
            parse_github_remote("git@github.com:Owner/Repository.git"),
            expected,
        )

    def test_dirty_context_uses_non_publishable_local_tags(self) -> None:
        sha = "a" * 40
        runner = FakeRunner(
            {
                ("git", "rev-parse", "HEAD"): sha,
                ("git", "config", "--get", "remote.origin.url"): (
                    "https://github.com/Owner/Repository.git"
                ),
                (
                    "git",
                    "status",
                    "--porcelain",
                    "--untracked-files=all",
                ): " M mobile/Dockerfile",
            }
        )
        context = ReleaseContext.discover(Path("."), runner)

        self.assertEqual(context.backend_image, f"moncv-backend:{sha}-dirty")
        self.assertEqual(
            context.backend_remote_image,
            f"ghcr.io/owner/cv-mobile-backend:{sha}",
        )
        self.assertNotIn("latest", context.web_remote_image)


if __name__ == "__main__":
    unittest.main()
