from __future__ import annotations

import json
from pathlib import Path

from source_line_policy import (
    ALLOWED_GENERATED_FILES,
    GENERATED_CONTENT_SIGNATURES,
    GENERATED_HEADER_MARKER,
    SourceLinePolicy,
    load_policy,
)

FUTURE_EXPIRY = "2099-12-31"


class RepositoryFixture:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.legacy_files: list[dict[str, object]] = []
        for source_root in (
            "mobile/lib",
            "mobile/test",
            "backend/src/main/java",
            "backend/src/test/java",
        ):
            (root / source_root).mkdir(parents=True, exist_ok=True)
        for generated_path in ALLOWED_GENERATED_FILES:
            self.write_generated(generated_path, 301)

    def write_lines(
        self, relative_path: str, count: int, *, generated: bool = False
    ) -> Path:
        lines = [GENERATED_HEADER_MARKER] if generated else []
        lines.extend("source line" for _ in range(count - len(lines)))
        return self.write_text(relative_path, "\n".join(lines))

    def write_text(self, relative_path: str, content: str) -> Path:
        path = self.root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def write_generated(self, relative_path: str, count: int) -> Path:
        lines = [
            GENERATED_HEADER_MARKER,
            *GENERATED_CONTENT_SIGNATURES[relative_path],
        ]
        lines.extend("generated line" for _ in range(count - len(lines)))
        return self.write_text(relative_path, "\n".join(lines))

    def add_legacy(
        self,
        relative_path: str,
        baseline_lines: int,
        *,
        expires_on: str = FUTURE_EXPIRY,
    ) -> None:
        self.legacy_files.append(
            {
                "path": relative_path,
                "baseline_lines": baseline_lines,
                "issue": "#999",
                "expires_on": expires_on,
            }
        )

    def write_policy(self) -> Path:
        policy_path = self.root / "policy.json"
        policy_path.write_text(
            json.dumps(
                {
                    "version": 1,
                    "legacy_files": self.legacy_files,
                    "generated_files": sorted(ALLOWED_GENERATED_FILES),
                }
            ),
            encoding="utf-8",
        )
        return policy_path

    def load_policy(self) -> SourceLinePolicy:
        return load_policy(self.write_policy())
