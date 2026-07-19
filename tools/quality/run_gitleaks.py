"""Scan the exact Git index with native Gitleaks or its pinned Docker image."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path, PurePosixPath

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
GITLEAKS_IMAGE = (
    "zricethezav/gitleaks@"
    "sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f"
)


class GitleaksConfigurationError(RuntimeError):
    """Raised when the scanner cannot run safely."""


def _git(root: Path, *arguments: str) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        ["git", *arguments],
        cwd=root,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def normalize_tracked_path(raw_path: str) -> PurePosixPath:
    path = PurePosixPath(raw_path)
    if path.is_absolute() or not path.parts or ".." in path.parts:
        raise GitleaksConfigurationError(f"Unsafe tracked path: {raw_path!r}")
    return path


def tracked_paths(root: Path) -> list[PurePosixPath]:
    output = _git(root, "ls-files", "-z").stdout
    decoded = output.decode("utf-8", errors="surrogateescape")
    return [normalize_tracked_path(item) for item in decoded.split("\0") if item]


def materialize_index(root: Path, destination: Path) -> int:
    count = 0
    for path in tracked_paths(root):
        git_path = path.as_posix()
        content = _git(root, "show", f":{git_path}").stdout
        target = destination.joinpath(*path.parts)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)
        count += 1
    return count


def select_engine(requested: str) -> str:
    if requested == "native":
        if not shutil.which("gitleaks"):
            raise GitleaksConfigurationError("gitleaks executable not found")
        return requested
    if requested == "docker":
        if not shutil.which("docker"):
            raise GitleaksConfigurationError("docker executable not found")
        return requested
    if shutil.which("gitleaks"):
        return "native"
    if shutil.which("docker"):
        return "docker"
    raise GitleaksConfigurationError("Install Gitleaks or Docker")


def scanner_command(engine: str, snapshot: Path) -> list[str]:
    config = snapshot / ".gitleaks.toml"
    if not config.is_file():
        raise GitleaksConfigurationError("Tracked .gitleaks.toml is missing")
    if engine == "native":
        return [
            "gitleaks",
            "dir",
            f"--config={config}",
            "--redact",
            "--no-banner",
            str(snapshot),
        ]
    return [
        "docker",
        "run",
        "--rm",
        "-v",
        f"{snapshot.resolve()}:/scan:ro",
        GITLEAKS_IMAGE,
        "dir",
        "--config=/scan/.gitleaks.toml",
        "--redact",
        "--no-banner",
        "/scan",
    ]


def run_scan(root: Path, engine: str) -> int:
    selected_engine = select_engine(engine)
    with tempfile.TemporaryDirectory(prefix="moncv-gitleaks-") as temp:
        snapshot = Path(temp)
        file_count = materialize_index(root, snapshot)
        print(f"Scanning {file_count} tracked files with {selected_engine} Gitleaks")
        return subprocess.run(scanner_command(selected_engine, snapshot)).returncode


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--engine", choices=("auto", "native", "docker"), default="auto"
    )
    parser.add_argument("--root", type=Path, default=REPOSITORY_ROOT)
    args = parser.parse_args(argv)
    try:
        return run_scan(args.root.resolve(), args.engine)
    except (
        GitleaksConfigurationError,
        OSError,
        subprocess.CalledProcessError,
    ) as error:
        print(f"Gitleaks setup error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
