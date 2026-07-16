"""Evaluate the 300-line ratchet for maintained Dart and Java sources."""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from datetime import date
from pathlib import Path

from source_line_policy import (
    GENERATED_CONTENT_SIGNATURES,
    GENERATED_HEADER_MARKER,
    GENERATED_HEADER_SCAN_LINES,
    MAX_SOURCE_LINES,
    POLICY_ISSUE,
    SOURCE_ROOTS,
    SOURCE_SUFFIXES,
    LegacyAllowance,
    PolicyConfigurationError,
    SourceLinePolicy,
)


@dataclass(frozen=True)
class Violation:
    code: str
    path: str
    line_count: int | None
    issue: str
    detail: str


@dataclass(frozen=True)
class GuardReport:
    scanned_files: int
    active_legacy_files: int
    generated_files: int
    violations: tuple[Violation, ...]

    @property
    def passed(self) -> bool:
        return not self.violations


def inspect_repository(
    repository_root: Path,
    policy: SourceLinePolicy,
    *,
    today: date | None = None,
) -> GuardReport:
    """Inspect configured source roots and return deterministic findings."""
    current_date = today or date.today()
    source_files = _discover_source_files(repository_root)
    legacy_by_path = {item.path: item for item in policy.legacy_files}
    seen_paths: set[str] = set()
    violations: list[Violation] = []
    active_legacy_files = 0
    valid_generated_files = 0

    for relative_path, absolute_path in source_files:
        seen_paths.add(relative_path)
        line_count = _count_physical_lines(absolute_path)

        if relative_path in policy.generated_files:
            if _has_generated_signature(relative_path, absolute_path):
                valid_generated_files += 1
            else:
                violations.append(
                    Violation(
                        "invalid-generated-source",
                        relative_path,
                        line_count,
                        POLICY_ISSUE,
                        "The expected gen-l10n header or declaration is "
                        "missing; this file cannot bypass the source limit.",
                    )
                )
            continue

        allowance = legacy_by_path.get(relative_path)
        if allowance is not None:
            active_legacy_files += 1
            violations.extend(
                _check_legacy_file(relative_path, line_count, allowance, current_date)
            )
        elif line_count > MAX_SOURCE_LINES:
            violations.append(
                Violation(
                    "new-oversized-source",
                    relative_path,
                    line_count,
                    POLICY_ISSUE,
                    "Split the file before merge; adding a legacy entry is forbidden.",
                )
            )

    violations.extend(_missing_policy_entries(policy, seen_paths))
    return GuardReport(
        scanned_files=len(source_files),
        active_legacy_files=active_legacy_files,
        generated_files=valid_generated_files,
        violations=tuple(sorted(violations, key=lambda item: (item.path, item.code))),
    )


def _check_legacy_file(
    path: str,
    line_count: int,
    allowance: LegacyAllowance,
    current_date: date,
) -> list[Violation]:
    if line_count <= MAX_SOURCE_LINES:
        return [
            Violation(
                "legacy-entry-must-be-removed",
                path,
                line_count,
                allowance.issue,
                "The file now respects the limit; remove its legacy entry.",
            )
        ]
    if line_count > allowance.baseline_lines:
        return [
            Violation(
                "legacy-growth",
                path,
                line_count,
                allowance.issue,
                f"Legacy ceiling is {allowance.baseline_lines}; growth is forbidden.",
            )
        ]
    if line_count < allowance.baseline_lines:
        return [
            Violation(
                "legacy-baseline-must-be-lowered",
                path,
                line_count,
                allowance.issue,
                f"Lower baseline_lines from {allowance.baseline_lines} to "
                f"{line_count} so removed lines cannot be reintroduced.",
            )
        ]
    if current_date >= allowance.expires_on:
        return [
            Violation(
                "legacy-entry-expired",
                path,
                line_count,
                allowance.issue,
                f"Legacy allowance expired on {allowance.expires_on.isoformat()}.",
            )
        ]
    return []


def _missing_policy_entries(
    policy: SourceLinePolicy, seen_paths: set[str]
) -> list[Violation]:
    violations: list[Violation] = []
    for allowance in policy.legacy_files:
        if allowance.path not in seen_paths:
            violations.append(
                Violation(
                    "stale-legacy-entry",
                    allowance.path,
                    None,
                    allowance.issue,
                    "The source no longer exists; remove its legacy entry.",
                )
            )
    for path in policy.generated_files:
        if path not in seen_paths:
            violations.append(
                Violation(
                    "generated-source-missing",
                    path,
                    None,
                    POLICY_ISSUE,
                    "The expected committed gen-l10n output is missing.",
                )
            )
    return violations


def _discover_source_files(repository_root: Path) -> list[tuple[str, Path]]:
    try:
        resolved_root = repository_root.resolve(strict=True)
    except OSError as error:
        raise PolicyConfigurationError(
            f"Repository root cannot be resolved: {repository_root}"
        ) from error

    files: list[tuple[str, Path]] = []
    for relative_root in SOURCE_ROOTS:
        source_root = repository_root.joinpath(*relative_root.split("/"))
        if not source_root.is_dir():
            raise PolicyConfigurationError(f"Source root is missing: {relative_root}")
        _require_safe_path(source_root, resolved_root)
        files.extend(_walk_source_root(repository_root, source_root, resolved_root))
    return sorted(files)


def _walk_source_root(
    repository_root: Path, source_root: Path, resolved_root: Path
) -> list[tuple[str, Path]]:
    files: list[tuple[str, Path]] = []
    pending_directories = [source_root]
    while pending_directories:
        directory = pending_directories.pop()
        with os.scandir(directory) as iterator:
            entries = sorted(iterator, key=lambda item: item.name)
        for entry in entries:
            path = Path(entry.path)
            relative_path = path.relative_to(repository_root).as_posix()
            if any(ord(character) < 32 for character in relative_path):
                raise PolicyConfigurationError(
                    f"Source path contains control characters: {relative_path!r}"
                )
            _require_safe_path(path, resolved_root)
            if entry.is_dir(follow_symlinks=False):
                pending_directories.append(path)
            elif (
                entry.is_file(follow_symlinks=False) and path.suffix in SOURCE_SUFFIXES
            ):
                files.append((relative_path, path))
    return files


def _require_safe_path(path: Path, resolved_root: Path) -> None:
    is_junction = getattr(path, "is_junction", lambda: False)
    if path.is_symlink() or is_junction():
        raise PolicyConfigurationError(f"Links are forbidden in source roots: {path}")
    try:
        resolved_path = path.resolve(strict=True)
    except OSError as error:
        raise PolicyConfigurationError(
            f"Source path cannot be resolved: {path}"
        ) from error
    if not resolved_path.is_relative_to(resolved_root):
        raise PolicyConfigurationError(f"Source path escapes repository root: {path}")


def _count_physical_lines(path: Path) -> int:
    return len(path.read_bytes().splitlines())


def _has_generated_signature(relative_path: str, path: Path) -> bool:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except UnicodeDecodeError:
        return False
    header_lines = lines[:GENERATED_HEADER_SCAN_LINES]
    has_header = any(line.strip() == GENERATED_HEADER_MARKER for line in header_lines)
    declarations = GENERATED_CONTENT_SIGNATURES[relative_path]
    return has_header and all(
        any(line.strip().startswith(declaration) for line in lines)
        for declaration in declarations
    )


def render_report(report: GuardReport) -> str:
    if report.passed:
        return (
            "Source line policy passed: "
            f"scanned={report.scanned_files}, limit={MAX_SOURCE_LINES}, "
            f"legacy={report.active_legacy_files}, "
            f"generated={report.generated_files}."
        )

    lines = [f"Source line policy failed: {len(report.violations)} violation(s)."]
    for violation in report.violations:
        line_count = (
            str(violation.line_count) if violation.line_count is not None else "missing"
        )
        path = json.dumps(violation.path, ensure_ascii=True)
        lines.append(
            f"ERROR [{violation.code}] path={path} "
            f"lines={line_count} limit={MAX_SOURCE_LINES} "
            f"issue={violation.issue}: {violation.detail}"
        )
    return "\n".join(lines)
