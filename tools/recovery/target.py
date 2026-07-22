"""Disposable target identity for isolated recovery drills."""

from __future__ import annotations

import tempfile
from dataclasses import dataclass
from pathlib import Path

from .identity import SnapshotIdentity


@dataclass(frozen=True, init=False)
class RestoreTarget:
    workspace: Path
    operation_id: str

    def __init__(self, workspace: Path, identity: SnapshotIdentity) -> None:
        candidate = Path(workspace)
        temporary_root = Path(tempfile.gettempdir()).resolve()
        try:
            resolved = candidate.resolve(strict=True)
            is_empty = not any(resolved.iterdir())
        except OSError as error:
            raise ValueError("restore workspace is unavailable") from error
        if (
            not isinstance(identity, SnapshotIdentity)
            or candidate.is_symlink()
            or not resolved.is_dir()
            or resolved == temporary_root
            or not resolved.is_relative_to(temporary_root)
            or not is_empty
        ):
            raise ValueError("restore workspace must be an empty temporary directory")
        object.__setattr__(self, "workspace", resolved)
        object.__setattr__(self, "operation_id", identity.operation_id)

    @property
    def container_name(self) -> str:
        return "moncv-restore-" + self.operation_id.replace("-", "")

    @property
    def uploads_directory(self) -> Path:
        return self.workspace / "uploads"
