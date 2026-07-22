"""Release verification pipeline shared by local verify and publish commands."""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path

from .quality import run_repository_quality
from .runner import CommandError, CommandRunner
from .settings import (
    EXPECTED_FLUTTER_VERSION,
    LOCAL_TEST_JWT_SECRET,
    TRIVY_IMAGE,
    TRIVY_SCAN_TIMEOUT,
    ReleaseContext,
)
from .smoke import SmokeStack


@dataclass(frozen=True)
class ReleaseOptions:
    publish: bool
    allow_dirty: bool = False
    smoke_port: int | None = None


class ReleasePipeline:
    def __init__(
        self,
        context: ReleaseContext,
        options: ReleaseOptions,
        runner: CommandRunner,
    ) -> None:
        self.context = context
        self.options = options
        self.runner = runner

    def execute(self) -> Path:
        self._preflight()
        self._quality()
        self._backend()
        self._frontend()
        self._build_images()
        self._scan_images()
        self._smoke()
        if self.options.publish:
            self._publish_images()
        manifest = self._write_manifest()
        print(f"\nRelease validation passed. Manifest: {manifest}")
        return manifest

    def _preflight(self) -> None:
        self.runner.require("git", "mvn", "flutter", "dart", "docker", "uv")
        if self.context.dirty and not self.options.allow_dirty:
            raise CommandError(
                "Working tree is dirty. Commit changes or use --allow-dirty for verify."
            )
        if self.options.publish and self.context.dirty:
            raise CommandError("Publishing a dirty working tree is forbidden")
        flutter_version = self.runner.capture(
            ["flutter", "--version"], cwd=self.context.root
        )
        if EXPECTED_FLUTTER_VERSION not in flutter_version.splitlines()[0]:
            raise CommandError(
                f"Flutter {EXPECTED_FLUTTER_VERSION} is required; got "
                f"{flutter_version.splitlines()[0]}"
            )
        self.runner.run(["docker", "version"], cwd=self.context.root)
        self.runner.run(["docker", "compose", "version"], cwd=self.context.root)
        if self.options.publish:
            self.runner.run(["git", "fetch", "origin", "main"], cwd=self.context.root)
            remote_main = self.runner.capture(
                ["git", "rev-parse", "origin/main"], cwd=self.context.root
            )
            if remote_main != self.context.sha:
                raise CommandError("Publish requires HEAD to equal origin/main")

    def _quality(self) -> None:
        run_repository_quality(self.context.root, self.runner)

    def _backend(self) -> None:
        test_environment = {
            "SPRING_PROFILES_ACTIVE": "test",
            "JWT_SECRET": LOCAL_TEST_JWT_SECRET,
            "DEEPSEEK_API_KEY": "",
        }
        self.runner.run(
            ["mvn", "clean", "verify", "-q"],
            cwd=self.context.root / "backend",
            env=test_environment,
        )

    def _frontend(self) -> None:
        mobile = self.context.root / "mobile"
        self.runner.run(["flutter", "pub", "get", "--enforce-lockfile"], cwd=mobile)
        self.runner.run(["flutter", "gen-l10n"], cwd=mobile)
        generated = [
            "mobile/lib/l10n/app_localizations.dart",
            "mobile/lib/l10n/app_localizations_en.dart",
            "mobile/lib/l10n/app_localizations_fr.dart",
        ]
        self.runner.run(
            ["git", "diff", "--exit-code", "--", *generated],
            cwd=self.context.root,
        )
        self.runner.run(["flutter", "analyze", "--no-fatal-infos"], cwd=mobile)
        self.runner.run(
            [
                "flutter",
                "test",
                "--coverage",
                "--no-pub",
                "--exclude-tags",
                "web-smoke",
                "--concurrency=1",
            ],
            cwd=mobile,
        )
        self.runner.run(
            [
                "dart",
                "run",
                "tool/check_coverage.dart",
                "--summary=coverage/summary.md",
            ],
            cwd=mobile,
        )

    def _build_images(self) -> None:
        for directory, image in (
            ("backend", self.context.backend_image),
            ("mobile", self.context.web_image),
        ):
            self.runner.run(
                [
                    "docker",
                    "build",
                    "--progress=plain",
                    "--pull",
                    "--tag",
                    image,
                    ".",
                ],
                cwd=self.context.root / directory,
            )

    def _scan_images(self) -> None:
        for image in (self.context.backend_image, self.context.web_image):
            self.runner.run(
                [
                    "docker",
                    "run",
                    "--rm",
                    "-v",
                    "/var/run/docker.sock:/var/run/docker.sock",
                    "-v",
                    "moncv-trivy-cache:/root/.cache/trivy",
                    TRIVY_IMAGE,
                    "image",
                    "--timeout",
                    TRIVY_SCAN_TIMEOUT,
                    "--scanners",
                    "vuln",
                    "--severity",
                    "HIGH,CRITICAL",
                    "--ignore-unfixed",
                    "--exit-code",
                    "1",
                    image,
                ],
                cwd=self.context.root,
            )

    def _smoke(self) -> None:
        with SmokeStack(
            self.context, self.runner, requested_port=self.options.smoke_port
        ) as stack:
            self.runner.run(
                [
                    sys.executable,
                    "-m",
                    "tools.release.browser_smoke",
                    "--base-url",
                    stack.base_url,
                    "--artifacts",
                    str(self.context.root / ".release" / "browser-smoke"),
                ],
                cwd=self.context.root,
            )

    def _publish_images(self) -> None:
        for local_image, remote_image in (
            (self.context.backend_image, self.context.backend_remote_image),
            (self.context.web_image, self.context.web_remote_image),
        ):
            self.runner.run(
                ["docker", "tag", local_image, remote_image], cwd=self.context.root
            )
            self.runner.run(["docker", "push", remote_image], cwd=self.context.root)

    def _write_manifest(self) -> Path:
        image_ids = {
            "backend": self.runner.capture(
                [
                    "docker",
                    "image",
                    "inspect",
                    self.context.backend_image,
                    "--format",
                    "{{.Id}}",
                ],
                cwd=self.context.root,
            ),
            "web": self.runner.capture(
                [
                    "docker",
                    "image",
                    "inspect",
                    self.context.web_image,
                    "--format",
                    "{{.Id}}",
                ],
                cwd=self.context.root,
            ),
        }
        output = self.context.root / ".release" / self.context.sha
        output.mkdir(parents=True, exist_ok=True)
        manifest = output / "manifest.json"
        manifest.write_text(
            json.dumps(
                {
                    "commit": self.context.sha,
                    "createdAt": datetime.now(UTC).isoformat(),
                    "dirty": self.context.dirty,
                    "published": self.options.publish,
                    "images": {
                        "backend": {
                            "local": self.context.backend_image,
                            "remote": self.context.backend_remote_image,
                            "id": image_ids["backend"],
                        },
                        "web": {
                            "local": self.context.web_image,
                            "remote": self.context.web_remote_image,
                            "id": image_ids["web"],
                        },
                    },
                },
                indent=2,
                sort_keys=True,
            )
            + "\n",
            encoding="utf-8",
        )
        return manifest
