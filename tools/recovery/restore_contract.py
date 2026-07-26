"""Non-sensitive contracts shared by recovery drill coordinators."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum


class RestoreFailure(StrEnum):
    SNAPSHOT_PREFLIGHT = "RESTORE_SNAPSHOT_PREFLIGHT_FAILED"
    SNAPSHOTS_INVALID = "RESTORE_SNAPSHOTS_INVALID"
    WORKSPACE_CREATE = "RESTORE_WORKSPACE_CREATE_FAILED"
    TARGET_INVALID = "RESTORE_TARGET_INVALID"
    DATABASE_CREATE = "RESTORE_DATABASE_CREATE_FAILED"
    DATABASE_OWNERSHIP = "RESTORE_DATABASE_OWNERSHIP_FAILED"
    DATABASE_READY = "RESTORE_DATABASE_READY_TIMEOUT"
    DATABASE_IMPORT = "RESTORE_DATABASE_IMPORT_FAILED"
    SCHEMA_QUERY = "RESTORE_SCHEMA_QUERY_FAILED"
    UPLOADS_RESTORE = "RESTORE_UPLOADS_FAILED"
    DATABASE_CLEANUP = "RESTORE_DATABASE_CLEANUP_FAILED"
    WORKSPACE_CLEANUP = "RESTORE_WORKSPACE_CLEANUP_FAILED"
    RECEIPT_INVALID = "RESTORE_RECEIPT_INVALID"


class RestoreError(RuntimeError):
    def __init__(self, error_codes: tuple[str | RestoreFailure, ...]) -> None:
        self.error_codes = tuple(dict.fromkeys(str(code) for code in error_codes))
        super().__init__("Restore failed: " + ", ".join(self.error_codes))


@dataclass(frozen=True)
class RestoreReceipt:
    drill_id: str
    operation_id: str
    deployed_sha: str
    database_snapshot: str
    uploads_snapshot: str
    latest_migration: str
    migration_count: int
    upload_files: int
    upload_directories: int
    upload_bytes: int
    uploads_sha256: str
    completed_at: datetime
