"""Configuration model for the maintained-source line policy."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from datetime import date
from pathlib import Path, PurePosixPath

MAX_SOURCE_LINES = 300
POLICY_VERSION = 1
POLICY_ISSUE = "#232"

SOURCE_ROOTS = (
    "mobile/lib",
    "mobile/test",
    "backend/src/main/java",
    "backend/src/test/java",
)
SOURCE_SUFFIXES = frozenset({".dart", ".java"})
IGNORED_GENERATED_DIRECTORIES = (
    "mobile/build",
    "mobile/.dart_tool",
    "backend/target",
)

GENERATED_HEADER_MARKER = "// ignore_for_file: type=lint"
GENERATED_HEADER_SCAN_LINES = 20
GENERATED_CONTENT_SIGNATURES = {
    "mobile/lib/l10n/app_localizations.dart": (
        "abstract class AppLocalizations {",
        "static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =",
    ),
    "mobile/lib/l10n/app_localizations_en.dart": (
        "class AppLocalizationsEn extends AppLocalizations {",
    ),
    "mobile/lib/l10n/app_localizations_fr.dart": (
        "class AppLocalizationsFr extends AppLocalizations {",
    ),
}
ALLOWED_GENERATED_FILES = frozenset(GENERATED_CONTENT_SIGNATURES)

_POLICY_KEYS = frozenset({"version", "legacy_files", "generated_files"})
_LEGACY_KEYS = frozenset({"path", "baseline_lines", "issue", "expires_on"})
_ISSUE_PATTERN = re.compile(r"^#[1-9][0-9]*$")


class PolicyConfigurationError(ValueError):
    """Raised when the checked-in policy cannot be applied safely."""


@dataclass(frozen=True)
class LegacyAllowance:
    path: str
    baseline_lines: int
    issue: str
    expires_on: date


@dataclass(frozen=True)
class SourceLinePolicy:
    legacy_files: tuple[LegacyAllowance, ...]
    generated_files: frozenset[str]


def load_policy(policy_path: Path) -> SourceLinePolicy:
    """Load and strictly validate the versioned source-line policy."""
    try:
        raw = json.loads(policy_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise PolicyConfigurationError(
            f"Cannot read policy {policy_path}: {error}"
        ) from error

    if not isinstance(raw, dict):
        raise PolicyConfigurationError("Policy root must be a JSON object")
    _require_exact_keys(raw, _POLICY_KEYS, "policy")
    if type(raw["version"]) is not int or raw["version"] != POLICY_VERSION:
        raise PolicyConfigurationError(
            f"Unsupported policy version: {raw['version']!r}"
        )

    legacy_files = _parse_legacy_files(raw["legacy_files"])
    generated_files = _parse_generated_files(raw["generated_files"])
    overlap = generated_files.intersection(item.path for item in legacy_files)
    if overlap:
        raise PolicyConfigurationError(
            f"Generated files cannot be legacy entries: {sorted(overlap)}"
        )

    return SourceLinePolicy(
        legacy_files=tuple(legacy_files),
        generated_files=generated_files,
    )


def _parse_legacy_files(raw_entries: object) -> list[LegacyAllowance]:
    if not isinstance(raw_entries, list):
        raise PolicyConfigurationError("legacy_files must be a JSON array")

    entries: list[LegacyAllowance] = []
    seen_paths: set[str] = set()
    for index, raw_entry in enumerate(raw_entries):
        context = f"legacy_files[{index}]"
        if not isinstance(raw_entry, dict):
            raise PolicyConfigurationError(f"{context} must be an object")
        _require_exact_keys(raw_entry, _LEGACY_KEYS, context)

        path = _validate_source_path(raw_entry["path"], f"{context}.path")
        if path in seen_paths:
            raise PolicyConfigurationError(f"Duplicate legacy path: {path}")
        seen_paths.add(path)

        baseline_lines = raw_entry["baseline_lines"]
        if (
            isinstance(baseline_lines, bool)
            or not isinstance(baseline_lines, int)
            or baseline_lines <= MAX_SOURCE_LINES
        ):
            raise PolicyConfigurationError(
                f"{context}.baseline_lines must be an integer above "
                f"{MAX_SOURCE_LINES}"
            )

        issue = raw_entry["issue"]
        if not isinstance(issue, str) or not _ISSUE_PATTERN.fullmatch(issue):
            raise PolicyConfigurationError(f"{context}.issue must use the #123 format")

        expires_on = _parse_date(raw_entry["expires_on"], context)
        entries.append(LegacyAllowance(path, baseline_lines, issue, expires_on))
    return entries


def _parse_generated_files(raw_entries: object) -> frozenset[str]:
    if not isinstance(raw_entries, list) or not all(
        isinstance(item, str) for item in raw_entries
    ):
        raise PolicyConfigurationError("generated_files must be a string array")
    if len(raw_entries) != len(set(raw_entries)):
        raise PolicyConfigurationError("generated_files contains duplicates")

    generated_files = frozenset(raw_entries)
    if generated_files != ALLOWED_GENERATED_FILES:
        missing = sorted(ALLOWED_GENERATED_FILES - generated_files)
        unexpected = sorted(generated_files - ALLOWED_GENERATED_FILES)
        raise PolicyConfigurationError(
            "Generated exceptions are immutable; "
            f"missing={missing}, unexpected={unexpected}"
        )
    return generated_files


def _validate_source_path(raw_path: object, context: str) -> str:
    if not isinstance(raw_path, str) or not raw_path:
        raise PolicyConfigurationError(f"{context} must be a non-empty string")
    path = PurePosixPath(raw_path)
    if path.is_absolute() or str(path) != raw_path or ".." in path.parts:
        raise PolicyConfigurationError(
            f"{context} must be a normalized repository-relative POSIX path"
        )
    if any(ord(character) < 32 for character in raw_path):
        raise PolicyConfigurationError(f"{context} contains control characters")
    if path.suffix not in SOURCE_SUFFIXES:
        raise PolicyConfigurationError(f"{context} must target Dart or Java")
    if not any(raw_path.startswith(f"{root}/") for root in SOURCE_ROOTS):
        raise PolicyConfigurationError(f"{context} is outside source roots")
    return raw_path


def _parse_date(raw_date: object, context: str) -> date:
    if not isinstance(raw_date, str):
        raise PolicyConfigurationError(f"{context}.expires_on must use YYYY-MM-DD")
    try:
        return date.fromisoformat(raw_date)
    except ValueError as error:
        raise PolicyConfigurationError(
            f"{context}.expires_on must use YYYY-MM-DD"
        ) from error


def _require_exact_keys(
    value: dict[str, object], expected: frozenset[str], context: str
) -> None:
    actual = frozenset(value)
    if actual != expected:
        raise PolicyConfigurationError(
            f"Invalid keys for {context}: "
            f"missing={sorted(expected - actual)}, "
            f"unexpected={sorted(actual - expected)}"
        )
