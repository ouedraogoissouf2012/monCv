"""Small, dependency-free model for the repository's canonical workflow YAML."""

from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass

JOB_RE = re.compile(r"^  (?P<name>[A-Za-z0-9_-]+):\s*(?:#.*)?$")
JOB_ENTRY_RE = re.compile(r"^  (?!#)\S")
TOP_LEVEL_KEY_RE = re.compile(r"^(?P<name>[A-Za-z][A-Za-z0-9_-]*):")
NON_CANONICAL_KEY_RE = re.compile(
    r"""^\s*(?:-\s*)?(?:["'](?:jobs|permissions|steps|uses)["']"""
    r"|(?:jobs|permissions|steps|uses)\s+):"
)
USES_RE = re.compile(
    r"^\s*(?:-\s*)?uses:\s*(?P<action>[^@\s#]+)@(?P<ref>[^\s#]+)"
    r"(?:\s+#\s*(?P<tag>\S+))?\s*$"
)
LOCAL_WORKFLOW_USE_RE = re.compile(
    r"^    uses:\s*(?P<path>\./\.github/workflows/[A-Za-z0-9._-]+\.ya?ml)\s*$"
)


@dataclass(frozen=True)
class Job:
    name: str
    start: int
    end: int


def normalized_digest(lines: list[str]) -> str:
    content = ("\n".join(lines) + "\n").encode("utf-8")
    return hashlib.sha256(content).hexdigest()


def parse_jobs(lines: list[str]) -> list[Job]:
    try:
        jobs_line = lines.index("jobs:")
    except ValueError:
        return []
    starts = [
        (index, match.group("name"))
        for index, line in enumerate(lines[jobs_line + 1 :], jobs_line + 1)
        if (match := JOB_RE.match(line))
    ]
    return [
        Job(name, start, starts[offset + 1][0] if offset + 1 < len(starts) else len(lines))
        for offset, (start, name) in enumerate(starts)
    ]


def job_at(jobs: list[Job], line: int) -> Job | None:
    return next((job for job in jobs if job.start <= line < job.end), None)


def iter_uses(lines: list[str], start: int = 0, end: int | None = None):
    for index in range(start, len(lines) if end is None else end):
        if "uses:" in lines[index]:
            yield index, USES_RE.match(lines[index])


def canonical_syntax_issues(lines: list[str]) -> list[tuple[int, str]]:
    issues: list[tuple[int, str]] = []
    top_level: dict[str, int] = {}
    for index, line in enumerate(lines):
        if "\t" in line:
            issues.append((index + 1, "workflow YAML must not contain tabs"))
        if NON_CANONICAL_KEY_RE.match(line):
            issues.append(
                (index + 1, "security-sensitive YAML keys must use canonical syntax")
            )
        match = TOP_LEVEL_KEY_RE.match(line)
        if not match:
            continue
        name = match.group("name")
        if name in top_level:
            issues.append((index + 1, f"duplicate top-level key: {name}"))
        else:
            top_level[name] = index
    return issues
