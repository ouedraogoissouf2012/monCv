from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.recovery.settings import (
    RecoveryConfigurationError,
    RecoverySettings,
    _private_file,
)

TEST_PASSWORD = "Recovery-" + "x" * 20 + "-2026-" + "Y" * 8


class RecoverySettingsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        (self.root / "docker-compose.yml").write_text("services: {}", encoding="utf-8")
        (self.root / "docker-compose.prod.yml").write_text(
            "services: {}", encoding="utf-8"
        )
        (self.root / "backend" / "uploads").mkdir(parents=True)
        self.environment_file = self._private_file("production.env", "TAG=" + "a" * 40)
        self.repository_file = self._private_file(
            "repository", "s3:https://backup.test/moncv"
        )
        self.password_file = self._private_file("password", TEST_PASSWORD)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _private_file(self, name: str, content: str) -> Path:
        path = self.root / name
        path.write_text(content, encoding="utf-8")
        path.chmod(0o600)
        return path

    def _environment(self, **overrides: str) -> dict[str, str]:
        values = {
            "RECOVERY_COMPOSE_ENV_FILE": str(self.environment_file),
            "RESTIC_REPOSITORY_FILE": str(self.repository_file),
            "RESTIC_PASSWORD_FILE": str(self.password_file),
        }
        values.update(overrides)
        return values

    def test_accepts_a_remote_repository_and_resolves_paths(self) -> None:
        settings = RecoverySettings.from_environment(self.root, self._environment())

        self.assertTrue(settings.repository_file.samefile(self.repository_file))
        self.assertTrue(
            settings.uploads_path.samefile(self.root / "backend" / "uploads")
        )
        self.assertFalse(settings.allow_local_repository)

    def test_local_repository_requires_explicit_test_mode(self) -> None:
        self.repository_file.write_text(str(self.root / "restic"), encoding="utf-8")
        with self.assertRaisesRegex(RecoveryConfigurationError, "REMOTE"):
            RecoverySettings.from_environment(
                self.root,
                self._environment(RECOVERY_ALLOW_LOCAL_REPOSITORY="true"),
            )

        accepted = RecoverySettings.from_environment(
            self.root,
            self._environment(RECOVERY_ALLOW_LOCAL_REPOSITORY="true"),
            allow_local_repository=True,
        )
        self.assertTrue(accepted.allow_local_repository)

    def test_rejects_secret_files_without_leaking_their_values(self) -> None:
        secret = "visible-nowhere-in-diagnostics"
        valid_password = TEST_PASSWORD
        valid_repository = "s3:https://backup.test/moncv"
        cases = (
            (self.password_file, secret, valid_password),
            (self.password_file, "line-one\nline-two", valid_password),
            (self.password_file, " " + "z" * 40, valid_password),
            (self.password_file, "z" * 40, valid_password),
            (
                self.repository_file,
                f"rest:https://user:{secret}@backup.test/repo",
                valid_repository,
            ),
        )
        for path, value, valid_value in cases:
            with self.subTest(value=value):
                path.write_text(value, encoding="utf-8")
                try:
                    with self.assertRaises(RecoveryConfigurationError) as raised:
                        RecoverySettings.from_environment(
                            self.root, self._environment()
                        )
                    self.assertNotIn(secret, str(raised.exception))
                finally:
                    path.write_text(valid_value, encoding="utf-8")

    def test_rejects_oversized_configuration_files(self) -> None:
        self.password_file.write_text("z" * 4097, encoding="utf-8")
        with self.assertRaisesRegex(
            RecoveryConfigurationError, "PASSWORD_FILE_CONTENT"
        ):
            RecoverySettings.from_environment(self.root, self._environment())

    def test_rejects_missing_compose_or_upload_paths(self) -> None:
        production_compose = self.root / "docker-compose.prod.yml"
        production_compose.unlink()
        with self.assertRaisesRegex(RecoveryConfigurationError, "docker-compose.prod"):
            RecoverySettings.from_environment(self.root, self._environment())

        production_compose.write_text("services: {}", encoding="utf-8")
        (self.root / "backend" / "uploads").rmdir()
        with self.assertRaisesRegex(RecoveryConfigurationError, "UPLOADS_PATH"):
            RecoverySettings.from_environment(self.root, self._environment())

    def test_rejects_invalid_or_shared_repository_files(self) -> None:
        self.repository_file.write_text("", encoding="utf-8")
        with self.assertRaisesRegex(RecoveryConfigurationError, "FILE_CONTENT"):
            RecoverySettings.from_environment(self.root, self._environment())

        self.repository_file.write_text("rest:https://[invalid", encoding="utf-8")
        with self.assertRaisesRegex(RecoveryConfigurationError, "URI"):
            RecoverySettings.from_environment(self.root, self._environment())

        shared_value = "s3:https://backup.test/moncv-long-password-file"
        self.repository_file.write_text(shared_value, encoding="utf-8")
        with self.assertRaisesRegex(RecoveryConfigurationError, "FILES_DISTINCT"):
            RecoverySettings.from_environment(
                self.root,
                self._environment(RESTIC_PASSWORD_FILE=str(self.repository_file)),
            )

    def test_rejects_non_utf8_configuration(self) -> None:
        self.password_file.write_bytes(b"\xff\xfe")
        with self.assertRaisesRegex(
            RecoveryConfigurationError, "PASSWORD_FILE_CONTENT"
        ):
            RecoverySettings.from_environment(self.root, self._environment())

    def test_rejects_insecure_repository_locations(self) -> None:
        cases = (
            "rest:http://backup.test/repo",
            "sftp:operator:" + "inline" + "@backup.test:/repo",
            "s3:https://backup.test/repo?" + "token=value",
        )
        for location in cases:
            with self.subTest(location=location):
                self.repository_file.write_text(location, encoding="utf-8")
                with self.assertRaisesRegex(RecoveryConfigurationError, "URI"):
                    RecoverySettings.from_environment(self.root, self._environment())

    def test_local_repository_must_not_overlap_uploads(self) -> None:
        repository = self.root / "backend" / "uploads" / "restic"
        self.repository_file.write_text(str(repository), encoding="utf-8")
        with self.assertRaisesRegex(RecoveryConfigurationError, "OVERLAP"):
            RecoverySettings.from_environment(
                self.root,
                self._environment(),
                allow_local_repository=True,
            )

    def test_posix_permissions_are_private(self) -> None:
        self.password_file.chmod(0o644)
        with patch("tools.recovery.settings.os.name", "posix"):
            self.assertFalse(_private_file(self.password_file))

    def test_rejects_missing_symlinked_or_public_inputs(self) -> None:
        self.password_file.unlink()
        with self.assertRaisesRegex(RecoveryConfigurationError, "PASSWORD_FILE"):
            RecoverySettings.from_environment(self.root, self._environment())

        self.password_file = self._private_file("password", TEST_PASSWORD)
        if os.name == "posix":
            self.password_file.chmod(0o644)
            with self.assertRaisesRegex(RecoveryConfigurationError, "PASSWORD_FILE"):
                RecoverySettings.from_environment(self.root, self._environment())


if __name__ == "__main__":
    unittest.main()
