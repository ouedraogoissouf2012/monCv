"""Operator CLI for encrypted backup and disposable restore proofs."""

from __future__ import annotations

import argparse
import json
import sys
from collections.abc import Callable, Sequence
from pathlib import Path
from typing import TextIO

from .application import RecoveryApplication
from .backup import BackupError
from .receipt import ReceiptError
from .restore_contract import RestoreError
from .settings import RecoveryConfigurationError
from .toolchain import ToolchainError
from .validation import RestoreValidationError

EXIT_CONFIGURATION = 10
EXIT_BACKUP = 20
EXIT_RESTORE = 30
EXIT_RECEIPT = 40
EXIT_VALIDATION = 50
EXIT_INTERNAL = 70
ApplicationFactory = Callable[[Path, bool], RecoveryApplication]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python -m tools.recovery",
        description=__doc__,
    )
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--root", type=_absolute_path, default=Path.cwd().absolute())
    common.add_argument("--allow-local-repository", action="store_true")
    commands = parser.add_subparsers(dest="action", required=True)
    commands.add_parser("check", parents=[common])

    backup = commands.add_parser("backup", parents=[common])
    backup.add_argument("--deployed-sha", required=True)
    backup.add_argument("--receipt", required=True, type=_absolute_path)

    restore = commands.add_parser("restore", parents=[common])
    restore.add_argument("--backup-receipt", required=True, type=_absolute_path)
    restore.add_argument("--receipt", required=True, type=_absolute_path)
    return parser


def main(
    argv: Sequence[str] | None = None,
    *,
    application_factory: ApplicationFactory | None = None,
    output: TextIO | None = None,
    error: TextIO | None = None,
) -> int:
    arguments = build_parser().parse_args(argv)
    factory = application_factory or _application
    stdout = output or sys.stdout
    stderr = error or sys.stderr
    try:
        application = factory(
            arguments.root,
            arguments.allow_local_repository,
        )
        if arguments.action == "check":
            proof = application.verify_toolchain()
            payload = {
                "action": "check",
                "compose_version": proof.compose_version,
                "restic_version": proof.restic_version,
                "status": "ok",
            }
        elif arguments.action == "backup":
            receipt = application.create_backup(
                arguments.deployed_sha,
                arguments.receipt,
            )
            payload = {
                "action": "backup",
                "operation_id": receipt.operation_id,
                "status": "ok",
            }
        else:
            receipt = application.prove_restore(
                arguments.backup_receipt,
                arguments.receipt,
            )
            payload = {
                "action": "restore",
                "drill_id": receipt.drill_id,
                "operation_id": receipt.operation_id,
                "status": "ok",
            }
        _emit(stdout, payload)
        return 0
    except RecoveryConfigurationError:
        return _fail(stderr, EXIT_CONFIGURATION, ("CONFIGURATION_INVALID",))
    except ToolchainError as exception:
        return _fail(stderr, EXIT_CONFIGURATION, (exception.error_code,))
    except BackupError as exception:
        return _fail(stderr, EXIT_BACKUP, exception.error_codes)
    except RestoreError as exception:
        return _fail(stderr, EXIT_RESTORE, exception.error_codes)
    except ReceiptError as exception:
        return _fail(stderr, EXIT_RECEIPT, (exception.error_code,))
    except RestoreValidationError as exception:
        return _fail(stderr, EXIT_VALIDATION, (exception.error_code,))
    except (TypeError, ValueError):
        return _fail(stderr, EXIT_VALIDATION, ("INPUT_INVALID",))
    except Exception:  # noqa: BLE001 - the CLI is a secret-safe trust boundary
        return _fail(stderr, EXIT_INTERNAL, ("INTERNAL_ERROR",))


def _application(root: Path, allow_local_repository: bool) -> RecoveryApplication:
    return RecoveryApplication.from_environment(
        root,
        allow_local_repository=allow_local_repository,
    )


def _absolute_path(value: str) -> Path:
    return Path(value).absolute()


def _fail(stream: TextIO, exit_code: int, codes: tuple[str, ...]) -> int:
    _emit(stream, {"codes": list(dict.fromkeys(codes)), "status": "error"})
    return exit_code


def _emit(stream: TextIO, payload: dict) -> None:
    print(
        json.dumps(payload, ensure_ascii=True, sort_keys=True, separators=(",", ":")),
        file=stream,
        flush=True,
    )
