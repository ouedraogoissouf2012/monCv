"""Secure filesystem storage for canonical recovery receipts."""

from __future__ import annotations

import os
import stat
import tempfile
from pathlib import Path

from .backup import BackupReceipt
from .receipt import (
    MAX_RECEIPT_BYTES,
    ReceiptError,
    decode_backup_receipt,
    decode_restore_receipt,
    encode_backup_receipt,
    encode_restore_receipt,
)
from .restore_contract import RestoreReceipt


def read_backup_receipt(path: Path) -> BackupReceipt:
    return decode_backup_receipt(_read_document(path))


def read_restore_receipt(path: Path) -> RestoreReceipt:
    return decode_restore_receipt(_read_document(path))


def write_backup_receipt(path: Path, receipt: BackupReceipt) -> None:
    _write_document(path, encode_backup_receipt(receipt))


def write_restore_receipt(path: Path, receipt: RestoreReceipt) -> None:
    _write_document(path, encode_restore_receipt(receipt))


def validate_receipt_destination(path: Path) -> Path:
    candidate = _absolute_path(path)
    try:
        if (
            _path_has_link(candidate.parent)
            or not candidate.parent.is_dir()
            or candidate.exists()
            or _is_link(candidate)
        ):
            raise OSError
        return candidate
    except OSError as error:
        raise ReceiptError("RECEIPT_WRITE_FAILED") from error


def _read_document(path: Path) -> str:
    candidate = _absolute_path(path)
    flags = os.O_RDONLY | getattr(os, "O_BINARY", 0) | getattr(os, "O_NOFOLLOW", 0)
    try:
        if _path_has_link(candidate):
            raise OSError
        with os.fdopen(os.open(candidate, flags), "rb") as stream:
            before = os.fstat(stream.fileno())
            content = stream.read(MAX_RECEIPT_BYTES + 1)
            after = os.fstat(stream.fileno())
        if (
            not stat.S_ISREG(before.st_mode)
            or before.st_nlink != 1
            or before.st_size > MAX_RECEIPT_BYTES
            or len(content) > MAX_RECEIPT_BYTES
            or _signature(before) != _signature(after)
            or (os.name == "posix" and stat.S_IMODE(before.st_mode) & 0o077)
        ):
            raise OSError
        return content.decode("utf-8")
    except (OSError, UnicodeError, ValueError) as error:
        raise ReceiptError("RECEIPT_READ_FAILED") from error


def _write_document(path: Path, document: str) -> None:
    candidate = validate_receipt_destination(path)
    parent = candidate.parent
    temporary: Path | None = None
    descriptor: int | None = None
    try:
        encoded = document.encode("utf-8")
        if (
            len(encoded) > MAX_RECEIPT_BYTES
            or _path_has_link(parent)
            or not parent.is_dir()
            or candidate.exists()
            or _is_link(candidate)
        ):
            raise OSError
        descriptor, temporary_name = tempfile.mkstemp(
            prefix="." + candidate.name + ".",
            suffix=".tmp",
            dir=parent,
        )
        temporary = Path(temporary_name)
        os.chmod(temporary, 0o600)
        with os.fdopen(descriptor, "wb") as stream:
            descriptor = None
            stream.write(encoded)
            stream.flush()
            os.fsync(stream.fileno())
        os.link(temporary, candidate, follow_symlinks=False)
    except (OSError, TypeError, UnicodeError, ValueError) as error:
        raise ReceiptError("RECEIPT_WRITE_FAILED") from error
    finally:
        if descriptor is not None:
            try:
                os.close(descriptor)
            except OSError:
                pass
        if temporary is not None:
            try:
                temporary.unlink(missing_ok=True)
            except OSError:
                pass


def _absolute_path(path: Path) -> Path:
    try:
        candidate = Path(path)
    except TypeError as error:
        raise ReceiptError("RECEIPT_PATH_INVALID") from error
    if not candidate.is_absolute():
        raise ReceiptError("RECEIPT_PATH_INVALID")
    return candidate


def _path_has_link(path: Path) -> bool:
    return any(_is_link(candidate) for candidate in (path, *path.parents))


def _is_link(path: Path) -> bool:
    is_junction = getattr(path, "is_junction", None)
    return path.is_symlink() or bool(is_junction and is_junction())


def _signature(value: os.stat_result) -> tuple[int, int, int, int]:
    return value.st_dev, value.st_ino, value.st_size, value.st_mtime_ns
