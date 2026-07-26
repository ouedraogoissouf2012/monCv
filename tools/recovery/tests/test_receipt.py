from __future__ import annotations

import json
import unittest
from dataclasses import replace
from datetime import UTC, datetime, timedelta, timezone

from tools.recovery.backup import BackupReceipt
from tools.recovery.receipt import (
    BACKUP_FORMAT,
    MAX_RECEIPT_BYTES,
    RESTORE_FORMAT,
    ReceiptError,
    decode_backup_receipt,
    decode_restore_receipt,
    encode_backup_receipt,
    encode_restore_receipt,
)
from tools.recovery.restore_contract import RestoreReceipt

SHA = "a" * 40
DATABASE = "b" * 64
UPLOADS = "c" * 64
OPERATION = "12345678-1234-4234-9234-123456789abc"
DRILL = "87654321-4321-4321-8321-cba987654321"
COMPLETED = datetime(
    2026, 7, 26, 12, 30, 45, 123456, tzinfo=timezone(timedelta(hours=2))
)


class ReceiptCodecTest(unittest.TestCase):
    def setUp(self) -> None:
        self.backup = BackupReceipt(
            OPERATION,
            SHA,
            DATABASE,
            UPLOADS,
            COMPLETED,
        )
        self.restore = RestoreReceipt(
            drill_id=DRILL,
            operation_id=OPERATION,
            deployed_sha=SHA,
            database_snapshot=DATABASE,
            uploads_snapshot=UPLOADS,
            latest_migration="14",
            migration_count=14,
            upload_files=3,
            upload_directories=2,
            upload_bytes=4096,
            uploads_sha256="d" * 64,
            completed_at=COMPLETED,
        )

    def test_backup_round_trip_is_canonical_utc_and_non_sensitive(self) -> None:
        document = encode_backup_receipt(self.backup)
        decoded = decode_backup_receipt(document)

        self.assertTrue(document.endswith("\n"))
        self.assertLess(len(document.encode()), MAX_RECEIPT_BYTES)
        self.assertEqual(decoded.operation_id, OPERATION)
        self.assertEqual(
            decoded.completed_at,
            datetime(2026, 7, 26, 10, 30, 45, 123456, tzinfo=UTC),
        )
        payload = json.loads(document)
        self.assertEqual(payload["format"], BACKUP_FORMAT)
        self.assertEqual(payload["completed_at"], "2026-07-26T10:30:45.123456Z")
        self.assertNotIn("password", document.casefold())
        self.assertNotIn("repository", document.casefold())

    def test_restore_round_trip_preserves_only_proof_metrics(self) -> None:
        document = encode_restore_receipt(self.restore)
        decoded = decode_restore_receipt(document)

        self.assertEqual(
            decoded, replace(self.restore, completed_at=decoded.completed_at)
        )
        self.assertEqual(decoded.completed_at.tzinfo, UTC)
        self.assertEqual(json.loads(document)["format"], RESTORE_FORMAT)
        self.assertEqual(
            (
                decoded.migration_count,
                decoded.upload_files,
                decoded.upload_directories,
                decoded.upload_bytes,
            ),
            (14, 3, 2, 4096),
        )

    def test_backup_encoder_rejects_invalid_identity_snapshots_and_clock(self) -> None:
        invalid = (
            replace(self.backup, operation_id="not-a-uuid"),
            replace(self.backup, deployed_sha="A" * 40),
            replace(self.backup, database_snapshot="short"),
            replace(self.backup, uploads_snapshot=DATABASE),
            replace(
                self.backup,
                completed_at=datetime(2026, 7, 26, 10, 30),  # noqa: DTZ001
            ),
            object(),
        )
        for receipt in invalid:
            with self.subTest(receipt=type(receipt).__name__):
                self._assert_invalid(
                    encode_backup_receipt,
                    receipt,  # type: ignore[arg-type]
                )

    def test_restore_encoder_rejects_invalid_proof_contracts(self) -> None:
        invalid = (
            replace(self.restore, drill_id="not-a-uuid"),
            replace(self.restore, latest_migration="V14"),
            replace(self.restore, migration_count=0),
            replace(self.restore, upload_files=-1),
            replace(self.restore, upload_directories=True),
            replace(self.restore, upload_bytes=-1),
            replace(self.restore, uploads_sha256="short"),
            replace(self.restore, completed_at="not-a-date"),  # type: ignore[arg-type]
        )
        for receipt in invalid:
            with self.subTest(receipt=receipt):
                self._assert_invalid(encode_restore_receipt, receipt)

    def test_decoder_rejects_structural_json_attacks(self) -> None:
        document = encode_backup_receipt(self.backup)
        payload = json.loads(document)
        unknown = {**payload, "secret": "sensitive-marker"}
        missing = dict(payload)
        missing.pop("deployed_sha")
        wrong_format = {**payload, "format": RESTORE_FORMAT}
        duplicate = document.replace(
            '"format":',
            '"format":"sensitive-marker","format":',
            1,
        )
        invalid = (
            "",
            "[]",
            json.dumps(unknown),
            json.dumps(missing),
            json.dumps(wrong_format),
            duplicate,
            " " * (MAX_RECEIPT_BYTES + 1),
            "\ud800",
        )
        for candidate in invalid:
            with self.subTest(candidate=candidate[:30]):
                self._assert_invalid(decode_backup_receipt, candidate)

    def test_decoder_rejects_noncanonical_or_invalid_field_values(self) -> None:
        backup = json.loads(encode_backup_receipt(self.backup))
        restore = json.loads(encode_restore_receipt(self.restore))
        cases = (
            (
                decode_backup_receipt,
                {**backup, "completed_at": "2026-07-26T10:30:45Z"},
            ),
            (
                decode_backup_receipt,
                {**backup, "database_snapshot": "B" * 64},
            ),
            (
                decode_restore_receipt,
                {**restore, "migration_count": True},
            ),
            (
                decode_restore_receipt,
                {**restore, "uploads_sha256": "E" * 64},
            ),
        )
        for decoder, payload in cases:
            with self.subTest(field=tuple(payload.items())[-1][0]):
                self._assert_invalid(decoder, json.dumps(payload))

    def _assert_invalid(self, function, value) -> None:
        with self.assertRaises(ReceiptError) as raised:
            function(value)
        self.assertEqual(raised.exception.error_code, "RECEIPT_INVALID")
        self.assertNotIn("sensitive-marker", str(raised.exception))


if __name__ == "__main__":
    unittest.main()
