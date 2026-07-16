"""Command-line entry point for the maintained-source line policy."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from source_line_guard import inspect_repository, render_report
from source_line_policy import PolicyConfigurationError, load_policy
from source_line_transition import validate_policy_transition

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_POLICY_PATH = Path("tools/quality/source_line_policy.json")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Enforce the maintained Dart/Java 300-line ratchet."
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=REPOSITORY_ROOT,
        help="Repository root (defaults to the script repository).",
    )
    parser.add_argument(
        "--policy",
        type=Path,
        help="Candidate policy JSON (defaults inside the repository root).",
    )
    parser.add_argument(
        "--reference-policy",
        type=Path,
        help="Base-branch policy used to reject relaxed legacy allowances.",
    )
    args = parser.parse_args(argv)

    repository_root = args.root.resolve()
    policy_path = (
        args.policy.resolve() if args.policy else repository_root / DEFAULT_POLICY_PATH
    )
    try:
        policy = load_policy(policy_path)
        if args.reference_policy:
            reference_policy = load_policy(args.reference_policy.resolve())
            validate_policy_transition(reference_policy, policy)
        report = inspect_repository(repository_root, policy)
    except (OSError, PolicyConfigurationError) as error:
        print(f"Source line policy configuration error: {error}", file=sys.stderr)
        return 2

    print(render_report(report))
    return 0 if report.passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
