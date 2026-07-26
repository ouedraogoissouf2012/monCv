"""Immutable release metadata derived from Git."""

from __future__ import annotations

import base64
import hashlib
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Protocol

LOCAL_TEST_JWT_SECRET = base64.urlsafe_b64encode(
    hashlib.sha512(b"moncv-local-release-test-jwt-v1").digest()
).decode("ascii")
TRIVY_SCAN_TIMEOUT = "20m"
TRIVY_IMAGE = (
    "aquasec/trivy@"
    "sha256:cffe3f5161a47a6823fbd23d985795b3ed72a4c806da4c4df16266c02accdd6f"
)
_SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
_FLUTTER_VERSION_PATTERN = re.compile(r"^\d+\.\d+\.\d+$")
_GITHUB_REMOTE = re.compile(
    r"github\.com[/:](?P<owner>[^/]+)/(?P<repository>[^/]+?)(?:\.git)?$"
)


class MetadataRunner(Protocol):
    def capture(self, arguments: list[str], *, cwd: Path) -> str: ...


def parse_github_remote(remote: str) -> tuple[str, str]:
    match = _GITHUB_REMOTE.search(remote.strip())
    if not match:
        raise ValueError(f"Unsupported GitHub remote: {remote!r}")
    return match.group("owner"), match.group("repository")


@dataclass(frozen=True)
class ReleaseContext:
    root: Path
    sha: str
    owner: str
    repository: str
    dirty: bool

    @classmethod
    def discover(cls, root: Path, runner: MetadataRunner) -> "ReleaseContext":
        sha = runner.capture(["git", "rev-parse", "HEAD"], cwd=root)
        if not _SHA_PATTERN.fullmatch(sha):
            raise ValueError(f"Invalid Git SHA: {sha!r}")
        remote = runner.capture(
            ["git", "config", "--get", "remote.origin.url"], cwd=root
        )
        owner, repository = parse_github_remote(remote)
        dirty = bool(
            runner.capture(
                ["git", "status", "--porcelain", "--untracked-files=all"],
                cwd=root,
            )
        )
        return cls(root.resolve(), sha, owner, repository, dirty)

    @property
    def short_sha(self) -> str:
        return self.sha[:12]

    @property
    def flutter_version(self) -> str:
        path = self.root / "mobile" / ".fvmrc"
        try:
            version = json.loads(path.read_text(encoding="utf-8"))["flutter"]
        except (OSError, KeyError, TypeError, json.JSONDecodeError) as error:
            raise ValueError(f"Invalid Flutter version file: {path}") from error
        if not isinstance(version, str) or not _FLUTTER_VERSION_PATTERN.fullmatch(version):
            raise ValueError(f"Invalid exact Flutter version in {path}: {version!r}")
        return version

    @property
    def tag_suffix(self) -> str:
        return f"{self.sha}-dirty" if self.dirty else self.sha

    @property
    def backend_image(self) -> str:
        return f"moncv-backend:{self.tag_suffix}"

    @property
    def web_image(self) -> str:
        return f"moncv-web:{self.tag_suffix}"

    @property
    def backend_remote_image(self) -> str:
        return f"ghcr.io/{self.owner.lower()}/cv-mobile-backend:{self.sha}"

    @property
    def web_remote_image(self) -> str:
        return f"ghcr.io/{self.owner.lower()}/cv-mobile-web:{self.sha}"
