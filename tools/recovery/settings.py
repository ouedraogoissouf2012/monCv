"""Fail-fast recovery configuration without secret disclosure."""

from __future__ import annotations

import os
import stat
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlsplit

REMOTE_REPOSITORY_PREFIXES = (
    "azure:",
    "b2:",
    "gs:",
    "rclone:",
    "rest:",
    "s3:",
    "sftp:",
    "swift:",
)
WEAK_PASSWORDS = frozenset(
    {"change-me", "changeme", "password", "placeholder", "restic-password"}
)
MAX_CONFIGURATION_BYTES = 4096
MINIMUM_PASSWORD_LENGTH = 32
MINIMUM_PASSWORD_VARIETY = 12


class RecoveryConfigurationError(RuntimeError):
    def __init__(self, invalid_settings: tuple[str, ...]) -> None:
        self.invalid_settings = invalid_settings
        super().__init__(
            "Invalid recovery configuration: " + ", ".join(invalid_settings)
        )


@dataclass(frozen=True)
class RecoverySettings:
    root: Path
    compose_environment: Path
    repository_file: Path
    password_file: Path
    uploads_path: Path
    allow_local_repository: bool = False

    @classmethod
    def from_environment(
        cls,
        root: Path,
        environment: Mapping[str, str] | None = None,
        *,
        allow_local_repository: bool = False,
    ) -> RecoverySettings:
        values = os.environ if environment is None else environment
        resolved_root = root.resolve()
        settings = cls(
            root=resolved_root,
            compose_environment=_path(
                resolved_root,
                values.get("RECOVERY_COMPOSE_ENV_FILE", ".env.production"),
            ),
            repository_file=_required_path(
                resolved_root, values, "RESTIC_REPOSITORY_FILE"
            ),
            password_file=_required_path(resolved_root, values, "RESTIC_PASSWORD_FILE"),
            uploads_path=_path(
                resolved_root,
                values.get("RECOVERY_UPLOADS_PATH", "backend/uploads"),
            ),
            allow_local_repository=allow_local_repository,
        )
        settings.validate()
        return settings

    @property
    def compose_files(self) -> tuple[Path, Path]:
        return (self.root / "docker-compose.yml", self.root / "docker-compose.prod.yml")

    def validate(self) -> None:
        invalid: list[str] = []
        valid_sensitive_files: dict[str, bool] = {}
        sensitive_files = (
            ("RECOVERY_COMPOSE_ENV_FILE", self.compose_environment),
            ("RESTIC_REPOSITORY_FILE", self.repository_file),
            ("RESTIC_PASSWORD_FILE", self.password_file),
        )
        for name, path in sensitive_files:
            valid_sensitive_files[name] = _private_file(path)
            if not valid_sensitive_files[name]:
                invalid.append(name)
        for name, path in zip(
            ("docker-compose.yml", "docker-compose.prod.yml"), self.compose_files
        ):
            if not path.is_file() or path.is_symlink():
                invalid.append(name)
        if (
            not self.uploads_path.is_dir()
            or self.uploads_path.is_symlink()
            or self.uploads_path.resolve() == Path(self.uploads_path.anchor)
        ):
            invalid.append("RECOVERY_UPLOADS_PATH")

        repository = (
            _single_line(self.repository_file)
            if valid_sensitive_files["RESTIC_REPOSITORY_FILE"]
            else None
        )
        password = (
            _single_line(self.password_file)
            if valid_sensitive_files["RESTIC_PASSWORD_FILE"]
            else None
        )
        repository_is_remote = bool(
            repository and repository.startswith(REMOTE_REPOSITORY_PREFIXES)
        )
        if repository is None:
            invalid.append("RESTIC_REPOSITORY_FILE_CONTENT")
        elif not self.allow_local_repository and not repository_is_remote:
            invalid.append("RESTIC_REPOSITORY_REMOTE")
        elif _unsafe_repository_uri(repository):
            invalid.append("RESTIC_REPOSITORY_URI")
        elif (
            self.allow_local_repository
            and not repository_is_remote
            and _paths_overlap(_path(self.root, repository), self.uploads_path)
        ):
            invalid.append("RESTIC_REPOSITORY_OVERLAP")
        if (
            password is None
            or len(password) < MINIMUM_PASSWORD_LENGTH
            or len(set(password)) < MINIMUM_PASSWORD_VARIETY
            or password.casefold() in WEAK_PASSWORDS
        ):
            invalid.append("RESTIC_PASSWORD_FILE_CONTENT")
        if self.repository_file.resolve() == self.password_file.resolve():
            invalid.append("RESTIC_CONFIGURATION_FILES_DISTINCT")
        if invalid:
            raise RecoveryConfigurationError(tuple(dict.fromkeys(invalid)))


def _path(root: Path, value: str) -> Path:
    candidate = Path(value).expanduser()
    return (
        candidate.absolute()
        if candidate.is_absolute()
        else (root / candidate).absolute()
    )


def _required_path(root: Path, values: Mapping[str, str], name: str) -> Path:
    value = values.get(name, "").strip()
    return _path(root, value) if value else root / f".{name.lower()}.missing"


def _private_file(path: Path) -> bool:
    if not path.is_file() or path.is_symlink():
        return False
    return os.name != "posix" or stat.S_IMODE(path.stat().st_mode) & 0o077 == 0


def _single_line(path: Path) -> str | None:
    try:
        if not path.is_file() or path.stat().st_size > MAX_CONFIGURATION_BYTES:
            return None
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError):
        return None
    if len(lines) != 1 or not lines[0] or lines[0] != lines[0].strip():
        return None
    return lines[0]


def _unsafe_repository_uri(repository: str) -> bool:
    location = repository.split(":", maxsplit=1)[-1]
    if repository.startswith("sftp:") and "@" in location:
        if ":" in location.partition("@")[0]:
            return True
    if "://" not in location:
        return False
    try:
        parsed = urlsplit(location)
        return (
            parsed.scheme != "https"
            or parsed.username is not None
            or parsed.password is not None
            or bool(parsed.query)
            or bool(parsed.fragment)
        )
    except ValueError:
        return True


def _paths_overlap(first: Path, second: Path) -> bool:
    resolved_first = first.resolve()
    resolved_second = second.resolve()
    return (
        resolved_first == resolved_second
        or resolved_first.is_relative_to(resolved_second)
        or resolved_second.is_relative_to(resolved_first)
    )
