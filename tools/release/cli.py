"""Command-line entry point for local MonCV releases."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from .pipeline import ReleaseOptions, ReleasePipeline
from .runner import CommandError, CommandRunner
from .settings import ReleaseContext

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("command", choices=("verify", "publish"))
    result.add_argument(
        "--allow-dirty",
        action="store_true",
        help="Allow uncommitted files for verify only; images receive a dirty suffix.",
    )
    result.add_argument("--smoke-port", type=int)
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    if args.command == "publish" and args.allow_dirty:
        parser().error("--allow-dirty cannot be used with publish")
    runner = CommandRunner()
    try:
        context = ReleaseContext.discover(REPOSITORY_ROOT, runner)
        options = ReleaseOptions(
            publish=args.command == "publish",
            allow_dirty=args.allow_dirty,
            smoke_port=args.smoke_port,
        )
        ReleasePipeline(context, options, runner).execute()
        return 0
    except (CommandError, OSError, RuntimeError, ValueError) as error:
        print(f"Release failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
