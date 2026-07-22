"""Bounded, non-sensitive proof of a restored uploads tree."""

from __future__ import annotations

import hashlib
import os
import stat
from dataclasses import dataclass
from pathlib import Path

from .validation import RestoreValidationError

HASH_CHUNK_BYTES = 1024 * 1024
MAX_UPLOAD_ENTRIES = 1_000_000
MAX_UPLOAD_DEPTH = 64


@dataclass(frozen=True)
class UploadsProof:
    file_count: int
    directory_count: int
    total_bytes: int
    tree_sha256: str


def validate_restored_uploads(directory: Path) -> UploadsProof:
    try:
        candidate = Path(directory)
        root = candidate.resolve(strict=True)
        if _is_link(candidate) or not root.is_dir():
            raise RestoreValidationError("RESTORE_UPLOADS_INVALID")
        hasher = _TreeHasher(root)
        hasher.visit(root, (), 0)
        return UploadsProof(
            hasher.file_count,
            hasher.directory_count,
            hasher.total_bytes,
            hasher.digest.hexdigest(),
        )
    except RestoreValidationError:
        raise
    except (OSError, OverflowError, TypeError, UnicodeError, ValueError) as error:
        raise RestoreValidationError("RESTORE_UPLOADS_INVALID") from error


class _TreeHasher:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.digest = hashlib.sha256()
        self.entry_count = 0
        self.file_count = 0
        self.directory_count = 0
        self.total_bytes = 0

    def visit(self, directory: Path, relative: tuple[str, ...], depth: int) -> None:
        if depth > MAX_UPLOAD_DEPTH or _is_link(directory):
            raise RestoreValidationError("RESTORE_UPLOADS_INVALID")
        before = directory.stat(follow_symlinks=False)
        if not stat.S_ISDIR(before.st_mode):
            raise RestoreValidationError("RESTORE_UPLOADS_INVALID")
        with os.scandir(directory) as entries:
            names = sorted((entry.name for entry in entries), key=os.fsencode)
        for name in names:
            self.entry_count += 1
            if self.entry_count > MAX_UPLOAD_ENTRIES:
                raise RestoreValidationError("RESTORE_UPLOADS_INVALID")
            path = directory / name
            relative_path = (*relative, name)
            metadata = path.lstat()
            if _is_link(path):
                raise RestoreValidationError("RESTORE_UPLOADS_INVALID")
            if stat.S_ISDIR(metadata.st_mode):
                self.directory_count += 1
                self._record(b"D", relative_path)
                self.visit(path, relative_path, depth + 1)
            elif stat.S_ISREG(metadata.st_mode):
                self._hash_file(path, relative_path, metadata)
            else:
                raise RestoreValidationError("RESTORE_UPLOADS_INVALID")
        after = directory.stat(follow_symlinks=False)
        if _directory_signature(before) != _directory_signature(after):
            raise RestoreValidationError("RESTORE_UPLOADS_INVALID")

    def _hash_file(
        self, path: Path, relative: tuple[str, ...], before: os.stat_result
    ) -> None:
        flags = os.O_RDONLY | getattr(os, "O_BINARY", 0) | getattr(os, "O_NOFOLLOW", 0)
        file_digest = hashlib.sha256()
        size = 0
        with os.fdopen(os.open(path, flags), "rb") as stream:
            opened = os.fstat(stream.fileno())
            if not stat.S_ISREG(opened.st_mode) or _file_signature(
                before
            ) != _file_signature(opened):
                raise RestoreValidationError("RESTORE_UPLOADS_INVALID")
            while chunk := stream.read(HASH_CHUNK_BYTES):
                size += len(chunk)
                file_digest.update(chunk)
            after = os.fstat(stream.fileno())
        if size != before.st_size or _file_signature(before) != _file_signature(after):
            raise RestoreValidationError("RESTORE_UPLOADS_INVALID")
        self.file_count += 1
        self.total_bytes += size
        self._record(b"F", relative, size, file_digest.digest())

    def _record(
        self,
        kind: bytes,
        relative: tuple[str, ...],
        size: int = 0,
        content_digest: bytes = b"",
    ) -> None:
        path = b"/".join(os.fsencode(part) for part in relative)
        self.digest.update(kind)
        self.digest.update(len(path).to_bytes(8, "big"))
        self.digest.update(path)
        self.digest.update(size.to_bytes(16, "big"))
        self.digest.update(content_digest)


def _is_link(path: Path) -> bool:
    is_junction = getattr(path, "is_junction", None)
    return path.is_symlink() or bool(is_junction and is_junction())


def _directory_signature(value: os.stat_result) -> tuple[int, int, int]:
    return value.st_dev, value.st_ino, value.st_mtime_ns


def _file_signature(value: os.stat_result) -> tuple[int, int, int, int]:
    return value.st_dev, value.st_ino, value.st_size, value.st_mtime_ns
