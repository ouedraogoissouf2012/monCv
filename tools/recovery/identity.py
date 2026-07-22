"""Validated identifiers shared by database and upload snapshots."""

from __future__ import annotations

import re
import uuid
from dataclasses import dataclass
from enum import StrEnum

GIT_SHA = re.compile(r"[0-9a-f]{40}")


class SnapshotKind(StrEnum):
    DATABASE = "database"
    UPLOADS = "uploads"


@dataclass(frozen=True)
class SnapshotIdentity:
    deployed_sha: str
    operation_id: str

    @classmethod
    def create(
        cls, deployed_sha: str, operation_id: str | None = None
    ) -> SnapshotIdentity:
        candidate = str(uuid.uuid4()) if operation_id is None else operation_id
        if not isinstance(candidate, str):
            raise ValueError("operation_id must be a canonical UUID")
        try:
            parsed_id = uuid.UUID(candidate)
        except ValueError as error:
            raise ValueError("operation_id must be a canonical UUID") from error
        if str(parsed_id) != candidate:
            raise ValueError("operation_id must be a canonical UUID")
        if not isinstance(deployed_sha, str) or GIT_SHA.fullmatch(deployed_sha) is None:
            raise ValueError("deployed_sha must be a lowercase 40-character Git SHA")
        return cls(deployed_sha=deployed_sha, operation_id=str(parsed_id))

    def tags(self, kind: SnapshotKind) -> tuple[str, ...]:
        return (
            "moncv",
            f"operation:{self.operation_id}",
            f"git:{self.deployed_sha}",
            f"kind:{kind.value}",
        )
