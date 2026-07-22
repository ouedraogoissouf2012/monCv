from __future__ import annotations

import json
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path

from tools.recovery.backup import BackupReceipt
from tools.recovery.validation import (
    MigrationCatalog,
    RestoreValidationError,
    validate_restored_schema,
    validate_snapshot_metadata,
)

SHA = "a" * 40
OPERATION = "12345678-1234-4234-9234-123456789abc"
DATABASE_SNAPSHOT = "b" * 64
UPLOADS_SNAPSHOT = "c" * 64


class MigrationValidationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary.name).resolve() / "migration"
        self.directory.mkdir()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def migration(self, name: str) -> None:
        (self.directory / name).write_text("SELECT 1;", encoding="utf-8")

    def test_catalog_normalizes_and_orders_flyway_versions(self) -> None:
        for name in (
            "V10__latest.sql",
            "V1__initial.sql",
            "V2_1__middle.sql",
        ):
            self.migration(name)

        catalog = MigrationCatalog.from_directory(self.directory)

        self.assertEqual(catalog.versions, ("1", "2.1", "10"))

    def test_repository_catalog_matches_the_current_schema(self) -> None:
        directory = (
            Path(__file__).resolve().parents[3]
            / "backend"
            / "src"
            / "main"
            / "resources"
            / "db"
            / "migration"
        )
        catalog = MigrationCatalog.from_directory(directory)
        self.assertEqual(len(catalog.versions), 14)
        self.assertEqual(catalog.versions[-1], "14")

    def test_catalog_rejects_empty_unknown_and_duplicate_versions(self) -> None:
        with self.assertRaises(RestoreValidationError):
            MigrationCatalog.from_directory(self.directory)

        self.migration("README.sql")
        with self.assertRaises(RestoreValidationError):
            MigrationCatalog.from_directory(self.directory)

        (self.directory / "README.sql").unlink()
        self.migration("V1__first.sql")
        self.migration("V1_0__duplicate.sql")
        with self.assertRaises(RestoreValidationError):
            MigrationCatalog.from_directory(self.directory)

    def test_schema_requires_every_successful_migration_in_order(self) -> None:
        catalog = MigrationCatalog(("1", "2", "3"))
        valid = json.dumps(
            [
                {"version": "1", "success": True},
                {"version": "2.0", "success": True},
                {"version": "3", "success": True},
            ]
        )
        proof = validate_restored_schema(valid, catalog)
        self.assertEqual(proof.latest_version, "3")

        invalid = (
            "not-json",
            "[]",
            json.dumps([{"version": "1", "success": False}]),
            json.dumps(
                [
                    {"version": "2", "success": True},
                    {"version": "1", "success": True},
                    {"version": "3", "success": True},
                ]
            ),
            json.dumps(
                [
                    {"version": "1", "success": True},
                    {"version": "1.0", "success": True},
                    {"version": "3", "success": True},
                ]
            ),
        )
        for output in invalid:
            with self.subTest(output=output), self.assertRaises(RestoreValidationError):
                validate_restored_schema(output, catalog)


class SnapshotValidationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.receipt = BackupReceipt(
            OPERATION,
            SHA,
            DATABASE_SNAPSHOT,
            UPLOADS_SNAPSHOT,
            datetime(2026, 7, 22, tzinfo=timezone.utc),
        )

    def metadata(self, snapshot_id: str, kind: str) -> dict:
        return {
            "id": snapshot_id,
            "hostname": "moncv-production",
            "tags": [
                "moncv",
                "operation:" + OPERATION,
                "git:" + SHA,
                "kind:" + kind,
                "provider-retention:daily",
            ],
        }

    def test_accepts_exact_correlated_snapshot_metadata(self) -> None:
        output = json.dumps(
            [
                self.metadata(DATABASE_SNAPSHOT, "database"),
                self.metadata(UPLOADS_SNAPSHOT, "uploads"),
            ]
        )
        proof = validate_snapshot_metadata(output, self.receipt)
        self.assertEqual(proof.operation_id, OPERATION)
        self.assertEqual(proof.deployed_sha, SHA)

    def test_rejects_missing_duplicate_or_conflicting_metadata_without_leak(
        self,
    ) -> None:
        marker = "sensitive-provider-output"
        database = self.metadata(DATABASE_SNAPSHOT, "database")
        conflicting = self.metadata(UPLOADS_SNAPSHOT, "uploads")
        conflicting["tags"].append("operation:" + "0" * 36)
        wrong_host = self.metadata(UPLOADS_SNAPSHOT, "uploads")
        wrong_host["hostname"] = marker
        invalid = (
            marker,
            "[]",
            json.dumps([database]),
            json.dumps([database, database]),
            json.dumps([database, conflicting]),
            json.dumps([database, wrong_host]),
        )
        for output in invalid:
            with (
                self.subTest(output=output),
                self.assertRaises(RestoreValidationError) as raised,
            ):
                validate_snapshot_metadata(output, self.receipt)
            self.assertNotIn(marker, str(raised.exception))


if __name__ == "__main__":
    unittest.main()
