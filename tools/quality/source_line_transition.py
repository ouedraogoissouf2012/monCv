"""Monotonic transition rules for the legacy source-line baseline."""

from __future__ import annotations

from source_line_policy import PolicyConfigurationError, SourceLinePolicy


def validate_policy_transition(
    reference: SourceLinePolicy, candidate: SourceLinePolicy
) -> None:
    """Allow only removal or tightening of an established legacy baseline."""
    reference_by_path = {item.path: item for item in reference.legacy_files}
    candidate_by_path = {item.path: item for item in candidate.legacy_files}
    errors: list[str] = []

    for path in sorted(candidate_by_path.keys() - reference_by_path.keys()):
        errors.append(f"new legacy entry is forbidden: {path}")

    for path in sorted(candidate_by_path.keys() & reference_by_path.keys()):
        previous = reference_by_path[path]
        current = candidate_by_path[path]
        if current.baseline_lines > previous.baseline_lines:
            errors.append(
                f"baseline increase for {path}: "
                f"{previous.baseline_lines} -> {current.baseline_lines}"
            )
        if current.issue != previous.issue:
            errors.append(
                f"migration issue change for {path}: "
                f"{previous.issue} -> {current.issue}"
            )
        if current.expires_on > previous.expires_on:
            errors.append(
                f"expiry extension for {path}: "
                f"{previous.expires_on} -> {current.expires_on}"
            )

    if errors:
        details = "\n".join(f"- {error}" for error in errors)
        raise PolicyConfigurationError(
            f"Policy transition is not monotonic:\n{details}"
        )
