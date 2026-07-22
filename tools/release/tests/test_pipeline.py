from __future__ import annotations

import unittest
import sys
from pathlib import Path
from unittest.mock import Mock, patch

from tools.release.pipeline import ReleaseOptions, ReleasePipeline
from tools.release.runner import CommandError
from tools.release.settings import (
    LOCAL_TEST_JWT_SECRET,
    TRIVY_SCAN_TIMEOUT,
    ReleaseContext,
)


class ReleasePipelineTest(unittest.TestCase):
    def setUp(self) -> None:
        self.context = ReleaseContext(
            root=Path("."),
            sha="a" * 40,
            owner="owner",
            repository="repository",
            dirty=True,
        )
        self.runner = Mock()

    def test_verify_rejects_dirty_tree_by_default(self) -> None:
        pipeline = ReleasePipeline(
            self.context,
            ReleaseOptions(publish=False),
            self.runner,
        )
        with self.assertRaisesRegex(CommandError, "Working tree is dirty"):
            pipeline._preflight()

    def test_publish_always_rejects_dirty_tree(self) -> None:
        pipeline = ReleasePipeline(
            self.context,
            ReleaseOptions(publish=True, allow_dirty=True),
            self.runner,
        )
        with self.assertRaisesRegex(CommandError, "Publishing a dirty"):
            pipeline._preflight()

    def test_backend_uses_deterministic_high_entropy_test_secret(self) -> None:
        pipeline = ReleasePipeline(
            self.context,
            ReleaseOptions(publish=False, allow_dirty=True),
            self.runner,
        )

        pipeline._backend()

        self.runner.run.assert_called_once_with(
            ["mvn", "clean", "verify", "-q"],
            cwd=Path("backend"),
            env={
                "SPRING_PROFILES_ACTIVE": "test",
                "JWT_SECRET": LOCAL_TEST_JWT_SECRET,
                "DEEPSEEK_API_KEY": "",
            },
        )

    @patch("tools.release.pipeline.run_repository_quality")
    def test_quality_delegates_to_repository_gate(self, quality: Mock) -> None:
        pipeline = ReleasePipeline(
            self.context,
            ReleaseOptions(publish=False, allow_dirty=True),
            self.runner,
        )

        pipeline._quality()

        quality.assert_called_once_with(self.context.root, self.runner)

    def test_image_scans_use_an_explicit_timeout(self) -> None:
        pipeline = ReleasePipeline(
            self.context,
            ReleaseOptions(publish=False, allow_dirty=True),
            self.runner,
        )

        pipeline._scan_images()

        self.assertEqual(self.runner.run.call_count, 2)
        for call in self.runner.run.call_args_list:
            command = call.args[0]
            timeout_index = command.index("--timeout")
            self.assertEqual(command[timeout_index + 1], TRIVY_SCAN_TIMEOUT)

    @patch("tools.release.pipeline.SmokeStack")
    def test_smoke_runs_playwright_against_production_stack(
        self, smoke_stack: Mock
    ) -> None:
        stack = smoke_stack.return_value.__enter__.return_value
        stack.base_url = "http://127.0.0.1:49152"
        pipeline = ReleasePipeline(
            self.context,
            ReleaseOptions(publish=False, allow_dirty=True),
            self.runner,
        )

        pipeline._smoke()

        self.runner.run.assert_called_once_with(
            [
                sys.executable,
                "-m",
                "tools.release.browser_smoke",
                "--base-url",
                stack.base_url,
                "--artifacts",
                str(Path(".release/browser-smoke")),
            ],
            cwd=Path("."),
        )


if __name__ == "__main__":
    unittest.main()
