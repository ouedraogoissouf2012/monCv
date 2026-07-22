from __future__ import annotations

import unittest

from tools.recovery.identity import SnapshotIdentity, SnapshotKind

SHA = "a" * 40
OPERATION = "12345678-1234-4234-9234-123456789abc"


class SnapshotIdentityTest(unittest.TestCase):
    def test_builds_shared_safe_tags(self) -> None:
        identity = SnapshotIdentity.create(SHA, OPERATION)

        self.assertEqual(
            identity.tags(SnapshotKind.DATABASE),
            (
                "moncv",
                f"operation:{OPERATION}",
                f"git:{SHA}",
                "kind:database",
            ),
        )
        self.assertEqual(
            identity.tags(SnapshotKind.UPLOADS)[1:3],
            identity.tags(SnapshotKind.DATABASE)[1:3],
        )

    def test_generates_a_canonical_operation_identifier(self) -> None:
        identity = SnapshotIdentity.create(SHA)
        self.assertEqual(len(identity.operation_id), 36)
        self.assertEqual(identity.operation_id[14], "4")

    def test_rejects_untrusted_identifiers(self) -> None:
        invalid = (
            ("A" * 40, OPERATION),
            ("a" * 39, OPERATION),
            (SHA, "../../repository"),
            (SHA, OPERATION.upper()),
            (SHA, "{12345678-1234-4234-9234-123456789abc}"),
        )
        for deployed_sha, operation_id in invalid:
            with self.subTest(deployed_sha=deployed_sha, operation_id=operation_id):
                with self.assertRaises(ValueError):
                    SnapshotIdentity.create(deployed_sha, operation_id)

        with self.assertRaises(ValueError):
            SnapshotIdentity.create(None, OPERATION)  # type: ignore[arg-type]
        with self.assertRaises(ValueError):
            SnapshotIdentity.create(SHA, 1234)  # type: ignore[arg-type]


if __name__ == "__main__":
    unittest.main()
