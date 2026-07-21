"""Isolated production-image smoke stack and HTTP assertions."""

from __future__ import annotations

import base64
import hashlib
import os
import socket
import time
import urllib.error
import urllib.request
from pathlib import Path

from .runner import CommandRunner
from .settings import LOCAL_TEST_JWT_SECRET, ReleaseContext


def available_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as candidate:
        candidate.bind(("127.0.0.1", 0))
        return int(candidate.getsockname()[1])


class SmokeStack:
    def __init__(
        self,
        context: ReleaseContext,
        runner: CommandRunner,
        requested_port: int | None = None,
    ) -> None:
        self.context = context
        self.runner = runner
        self.port = requested_port or available_port()
        self.compose_file = Path(__file__).with_name("smoke-compose.yml")
        self.project = f"moncv-release-{context.short_sha}-{os.getpid()}".lower()
        self.environment = self._environment()
        self.started = False

    @property
    def base_url(self) -> str:
        return f"http://127.0.0.1:{self.port}"

    def __enter__(self) -> "SmokeStack":
        try:
            self.runner.run(
                [
                    *self._compose(),
                    "up",
                    "-d",
                    "--wait",
                    "--wait-timeout",
                    "240",
                ],
                cwd=self.context.root,
                env=self.environment,
            )
            self.started = True
            self.verify_web()
            return self
        except BaseException:
            self._cleanup(failed=True)
            raise

    def __exit__(self, exception_type, exception, traceback) -> None:
        self._cleanup(failed=exception is not None)

    def _cleanup(self, *, failed: bool) -> None:
        if failed:
            self.runner.run(
                [*self._compose(), "logs", "--no-color", "--tail", "200"],
                cwd=self.context.root,
                env=self.environment,
                check=False,
            )
        self.runner.run(
            [
                *self._compose(),
                "down",
                "--volumes",
                "--remove-orphans",
                "--timeout",
                "15",
            ],
            cwd=self.context.root,
            env=self.environment,
            check=False,
        )

    def verify_web(self) -> None:
        health_body, _ = self._request("/healthz")
        if health_body.strip() != b"ok":
            raise RuntimeError("Unexpected web health response")
        index, headers = self._request("/")
        if b"flutter_bootstrap.js" not in index:
            raise RuntimeError("Flutter bootstrap is absent from index.html")
        csp = headers.get("Content-Security-Policy", "")
        if "default-src 'self'" not in csp:
            raise RuntimeError("Content-Security-Policy header is missing")
        google_sources = (
            "https://accounts.google.com/gsi/client",
            "https://accounts.google.com/gsi/",
        )
        if not all(source in csp for source in google_sources):
            raise RuntimeError("Google Identity CSP sources are missing")
        bootstrap, _ = self._request("/flutter_bootstrap.js")
        if not bootstrap:
            raise RuntimeError("Flutter bootstrap is empty")
        canvaskit, _ = self._request("/canvaskit/chromium/canvaskit.js")
        if not canvaskit:
            raise RuntimeError("Local CanvasKit is unavailable")

    def _request(self, path: str) -> tuple[bytes, object]:
        last_error: Exception | None = None
        for _ in range(20):
            try:
                with urllib.request.urlopen(
                    f"{self.base_url}{path}", timeout=5
                ) as response:
                    if response.status != 200:
                        raise RuntimeError(f"HTTP {response.status} for {path}")
                    return response.read(), response.headers
            except (OSError, urllib.error.URLError) as error:
                last_error = error
                time.sleep(1)
        raise RuntimeError(f"Unable to load {path}: {last_error}")

    def _compose(self) -> list[str]:
        return [
            "docker",
            "compose",
            "--project-name",
            self.project,
            "--file",
            str(self.compose_file),
        ]

    def _environment(self) -> dict[str, str]:
        link_key = base64.b64encode(
            hashlib.sha256(b"moncv-local-release-smoke").digest()
        ).decode("ascii")
        return {
            "BACKEND_IMAGE": self.context.backend_image,
            "WEB_IMAGE": self.context.web_image,
            "SMOKE_WEB_PORT": str(self.port),
            "SMOKE_DB_PASSWORD": "local-smoke-" + ("db" * 16),
            "SMOKE_JWT_SECRET": LOCAL_TEST_JWT_SECRET,
            "SMOKE_PUBLIC_LINK_KEY": link_key,
        }
