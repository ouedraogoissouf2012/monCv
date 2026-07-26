#!/usr/bin/env python3
"""Enforce the trust boundaries of the repository's GitHub workflows."""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from tools.ci.workflow_model import (
    JOB_ENTRY_RE,
    JOB_RE,
    LOCAL_WORKFLOW_USE_RE,
    Job,
    canonical_syntax_issues,
    iter_uses,
    job_at,
    normalized_digest,
    parse_jobs,
)
from tools.ci.workflow_security_policy import (
    LOCAL_REUSABLE_WORKFLOWS,
    PRIVILEGED_ACTIONS,
    PRIVILEGED_PERMISSIONS,
    READ_ONLY,
    REQUIRED_JOBS,
    TRUSTED_WORKFLOW_DIGESTS,
    VERIFIED_ACTIONS,
    WORKFLOW_DIR,
)

PERMISSION_RE = re.compile(r"^      (?P<name>[a-z-]+):\s*(?P<value>[a-z-]+)\s*$")
SECRET_RE = re.compile(r"\$\{\{\s*secrets\s*(?:\.|\[)", re.IGNORECASE)
PULL_REQUEST_TARGET_BANS = (
    re.compile(r"working-directory:\s*(?:\./)?candidate(?:/|\s|$)"),
    re.compile(r"(?:^|\s)\./candidate/", re.MULTILINE),
    re.compile(r"\bcandidate/[^\s|]+\.(?:sh|py|js|ts|jar)\b"),
    re.compile(r"\b(?:bash|sh|python3?|node|dart)\s+(?:\./)?candidate/"),
    re.compile(r"\b(?:mvn|gradle|npm|npx|dart run|pip install|pre-commit)\b"),
    re.compile(r"\bflutter\s+(?:pub|get|test|build|run)\b"),
    re.compile(r"(?:\||xargs\s+)(?:bash|sh|python|node)\b"),
    re.compile(r"(?:core\.hooksPath|\.git/hooks)"),
)
TRUSTED_PULL_REQUEST_TARGET_COMMANDS = (
    re.compile(
        r"      - name: Initialize isolated formatter metadata\n"
        r"        working-directory: \$\{\{ runner\.temp \}\}/l10n-project\n"
        r"        run: flutter pub get --offline"
    ),
)


@dataclass(frozen=True)
class Violation:
    path: Path
    line: int
    message: str

    def render(self, root: Path) -> str:
        try:
            path = self.path.relative_to(root)
        except ValueError:
            path = self.path
        return f"{path.as_posix()}:{self.line}: {self.message}"


def _check_top_level(path: Path, lines: list[str]) -> list[Violation]:
    violations: list[Violation] = []
    try:
        jobs_line = lines.index("jobs:")
    except ValueError:
        jobs_line = len(lines)
    permission_lines = [
        index
        for index, line in enumerate(lines[:jobs_line])
        if line.startswith("permissions:")
    ]
    if len(permission_lines) != 1 or lines[permission_lines[0]] != "permissions: {}":
        violations.append(Violation(path, 1, "workflow permissions must be exactly {}"))
    for index, line in enumerate(lines):
        if SECRET_RE.search(line):
            violations.append(Violation(path, index + 1, "secret context is forbidden"))
    return violations


def _check_job_syntax(path: Path, lines: list[str], jobs: list[Job]) -> list[Violation]:
    try:
        jobs_line = lines.index("jobs:")
    except ValueError:
        return [Violation(path, 1, "workflow must declare jobs")]
    invalid = [
        index
        for index, line in enumerate(lines[jobs_line + 1 :], jobs_line + 1)
        if JOB_ENTRY_RE.match(line) and not JOB_RE.match(line)
    ]
    violations = [
        Violation(path, index + 1, "job keys must use an unquoted canonical name")
        for index in invalid
    ]
    names = [job.name for job in jobs]
    if len(names) != len(set(names)):
        violations.append(Violation(path, jobs_line + 1, "duplicate job key"))
    return violations


def _permissions(
    path: Path,
    lines: list[str],
    job: Job,
) -> tuple[dict[str, str], int, list[Violation]]:
    blocks = [
        index
        for index in range(job.start + 1, job.end)
        if lines[index].startswith("    permissions:")
    ]
    if len(blocks) != 1 or lines[blocks[0]] != "    permissions:":
        return {}, job.start + 1, [
            Violation(path, job.start + 1, f"job {job.name!r} must declare one permissions block")
        ]
    index = blocks[0]
    values: dict[str, str] = {}
    for child in lines[index + 1 : job.end]:
        match = PERMISSION_RE.match(child)
        if match:
            name = match.group("name")
            if name in values:
                return values, index + 1, [
                    Violation(path, index + 1, f"job {job.name!r} has duplicate permissions")
                ]
            values[name] = match.group("value")
        elif child.strip() and len(child) - len(child.lstrip()) <= 4:
            break
    return values, index + 1, []


def _check_layout(path: Path, jobs: list[Job], strict: bool) -> list[Violation]:
    if not strict or path.name not in REQUIRED_JOBS:
        return []
    actual = {job.name for job in jobs}
    return [
        Violation(path, 1, f"required job is missing: {name}")
        for name in sorted(REQUIRED_JOBS[path.name] - actual)
    ]


def _check_permissions(path: Path, lines: list[str], jobs: list[Job]) -> list[Violation]:
    violations: list[Violation] = []
    for job in jobs:
        actual, line, parsing = _permissions(path, lines, job)
        violations.extend(parsing)
        expected = PRIVILEGED_PERMISSIONS.get((path.name, job.name), READ_ONLY)
        if actual != expected:
            violations.append(
                Violation(
                    path,
                    line,
                    f"job {job.name!r} permissions must be {expected}, got {actual}",
                )
            )
    return violations


def _check_actions(path: Path, lines: list[str], jobs: list[Job]) -> list[Violation]:
    violations: list[Violation] = []
    for index, match in iter_uses(lines):
        local = LOCAL_WORKFLOW_USE_RE.match(lines[index])
        if local:
            job = job_at(jobs, index)
            key = (path.name, job.name) if job else None
            expected = LOCAL_REUSABLE_WORKFLOWS.get(key)
            if local.group("path") != expected:
                violations.append(
                    Violation(path, index + 1, "unexpected local reusable workflow")
                )
            continue
        if not match:
            violations.append(Violation(path, index + 1, "action must use a verified full SHA"))
            continue
        action, ref, tag = match.group("action", "ref", "tag")
        if not re.fullmatch(r"[0-9a-f]{40}", ref):
            violations.append(Violation(path, index + 1, "action must use a verified full SHA"))
        expected = VERIFIED_ACTIONS.get(action)
        if expected != (ref, tag):
            violations.append(
                Violation(path, index + 1, f"{action} must use verified pin {expected}, got {(ref, tag)}")
            )
        if action == "actions/checkout":
            next_step = next(
                (
                    cursor
                    for cursor in range(index + 1, len(lines))
                    if re.match(r"^      - ", lines[cursor])
                ),
                len(lines),
            )
            credentials = [
                line.strip()
                for line in lines[index:next_step]
                if "persist-credentials:" in line
            ]
            if credentials != ["persist-credentials: false"]:
                violations.append(
                    Violation(path, index + 1, "checkout must set persist-credentials exactly once to false")
                )
    for job in jobs:
        allowed = PRIVILEGED_ACTIONS.get((path.name, job.name))
        if allowed is None:
            continue
        for index, match in iter_uses(lines, job.start, job.end):
            if not match or match.group("action") not in allowed:
                violations.append(
                    Violation(path, index + 1, f"unexpected action in privileged job {job.name!r}")
                )
    return violations


def _check_trusted_digest(path: Path, lines: list[str]) -> list[Violation]:
    allowed = TRUSTED_WORKFLOW_DIGESTS.get(path.name)
    if allowed is None or normalized_digest(lines) in allowed:
        return []
    return [
        Violation(
            path,
            1,
            "trusted workflow digest changed; use the documented two-PR transition",
        )
    ]


def _check_pull_request_target(path: Path, lines: list[str]) -> list[Violation]:
    text = "\n".join(lines)
    if not re.search(r"^  pull_request_target:\s*$", text, re.MULTILINE):
        return []
    audited_text = text
    for trusted in TRUSTED_PULL_REQUEST_TARGET_COMMANDS:
        audited_text = trusted.sub(
            lambda match: "\n" * match.group().count("\n"),
            audited_text,
        )
    violations: list[Violation] = []
    if path.name != "source-policy.yml":
        violations.append(Violation(path, 1, "pull_request_target is restricted to source-policy.yml"))
    violations.extend(
        Violation(path, audited_text[: match.start()].count("\n") + 1, "pull_request_target executes candidate code")
        for pattern in PULL_REQUEST_TARGET_BANS
        if (match := pattern.search(audited_text))
    )
    return violations


def audit_workflows(root: Path, *, enforce_layout: bool = True) -> list[Violation]:
    workflow_dir = root / WORKFLOW_DIR
    violations: list[Violation] = []
    paths = sorted((*workflow_dir.glob("*.yml"), *workflow_dir.glob("*.yaml")))
    for path in paths:
        lines = path.read_text(encoding="utf-8").splitlines()
        jobs = parse_jobs(lines)
        violations.extend(
            Violation(path, line, message)
            for line, message in canonical_syntax_issues(lines)
        )
        violations.extend(_check_top_level(path, lines))
        violations.extend(_check_job_syntax(path, lines, jobs))
        violations.extend(_check_layout(path, jobs, enforce_layout))
        violations.extend(_check_permissions(path, lines, jobs))
        violations.extend(_check_actions(path, lines, jobs))
        violations.extend(_check_trusted_digest(path, lines))
        violations.extend(_check_pull_request_target(path, lines))
    if enforce_layout:
        existing = {path.name for path in paths}
        for name in sorted(REQUIRED_JOBS.keys() - existing):
            violations.append(Violation(workflow_dir / name, 1, "required workflow is missing"))
    return violations


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args(argv)
    root = args.root.resolve()
    violations = audit_workflows(root)
    if violations:
        for violation in violations:
            print(violation.render(root), file=sys.stderr)
        return 1
    count = len(list((root / WORKFLOW_DIR).glob("*.yml")))
    print(f"Workflow security policy passed: {count} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
