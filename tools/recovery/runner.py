"""Bounded subprocess execution with secret-safe diagnostics."""

from __future__ import annotations

import os
import subprocess
import threading
from collections.abc import Mapping, Sequence
from pathlib import Path
from typing import BinaryIO, cast

from .commands import CommandSpec
from .processes import kill_process_tree, process_group_options

MAX_CAPTURE_BYTES = 1024 * 1024
READ_CHUNK_BYTES = 8192
READER_JOIN_SECONDS = 5
CORE_ENVIRONMENT = frozenset(
    {
        "appdata",
        "comspec",
        "home",
        "http_proxy",
        "https_proxy",
        "lang",
        "lc_all",
        "localappdata",
        "no_proxy",
        "path",
        "pathext",
        "programfiles",
        "ssh_auth_sock",
        "ssl_cert_dir",
        "ssl_cert_file",
        "systemroot",
        "temp",
        "tmp",
        "tz",
        "userprofile",
        "windir",
    }
)
TOOL_ENVIRONMENT_PREFIXES = ("docker_",)
RESTIC_CREDENTIAL_PREFIXES = (
    "aws_",
    "azure_",
    "b2_",
    "google_",
    "os_",
    "rclone_",
)
BLOCKED_ENVIRONMENT_PREFIXES = ("compose_", "restic_")


class RecoveryCommandError(RuntimeError):
    def __init__(self, action: str, reason: str) -> None:
        self.action = action
        self.reason = reason
        super().__init__(f"Recovery action failed: {action} ({reason})")


def sanitized_environment(
    arguments: Sequence[str], source: Mapping[str, str]
) -> dict[str, str]:
    executable = Path(arguments[0]).name.casefold()
    is_restic = executable in {"restic", "restic.exe"}
    result: dict[str, str] = {}
    for name, value in source.items():
        normalized = name.casefold()
        if normalized.startswith(BLOCKED_ENVIRONMENT_PREFIXES):
            continue
        allowed = normalized in CORE_ENVIRONMENT or normalized.startswith(
            TOOL_ENVIRONMENT_PREFIXES
        )
        if is_restic:
            allowed = allowed or normalized.startswith(RESTIC_CREDENTIAL_PREFIXES)
        if allowed:
            result[name] = value
    return result


class SafeCommandRunner:
    def __init__(
        self,
        environment: Mapping[str, str] | None = None,
        max_capture_bytes: int = MAX_CAPTURE_BYTES,
    ) -> None:
        if max_capture_bytes <= 0:
            raise ValueError("max_capture_bytes must be positive")
        self._environment = dict(os.environ if environment is None else environment)
        self._max_capture_bytes = max_capture_bytes

    def run(self, specification: CommandSpec) -> str:
        print(f"[recovery] {specification.action}", flush=True)
        try:
            process = subprocess.Popen(
                specification.arguments,
                cwd=specification.cwd,
                env=sanitized_environment(specification.arguments, self._environment),
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                shell=False,
                **process_group_options(),
            )
        except OSError as error:
            raise RecoveryCommandError(
                specification.action, "executable unavailable"
            ) from error

        output = bytearray()
        overflow = threading.Event()
        read_failure = threading.Event()
        reader = threading.Thread(
            target=self._read_output,
            args=(process, output, overflow, read_failure),
            daemon=True,
        )
        reader.start()
        try:
            return_code = process.wait(timeout=specification.timeout_seconds)
        except subprocess.TimeoutExpired as error:
            self._kill_process_tree(process)
            process.wait()
            self._join_reader(process, reader)
            raise RecoveryCommandError(specification.action, "timeout") from error
        reader_completed = self._join_reader(process, reader)
        if overflow.is_set():
            raise RecoveryCommandError(specification.action, "output limit exceeded")
        if not reader_completed or read_failure.is_set():
            raise RecoveryCommandError(
                specification.action, "output stream unavailable"
            )
        if return_code != 0:
            raise RecoveryCommandError(specification.action, f"exit code {return_code}")
        return output.decode("utf-8", errors="replace").strip()

    def _read_output(
        self,
        process: subprocess.Popen[bytes],
        output: bytearray,
        overflow: threading.Event,
        read_failure: threading.Event,
    ) -> None:
        stream = cast(BinaryIO, process.stdout)
        try:
            with stream:
                while chunk := stream.read(READ_CHUNK_BYTES):
                    if len(output) + len(chunk) > self._max_capture_bytes:
                        overflow.set()
                        self._kill_process_tree(process)
                        return
                    output.extend(chunk)
        except (OSError, ValueError):
            read_failure.set()

    def _join_reader(
        self,
        process: subprocess.Popen[bytes],
        reader: threading.Thread,
    ) -> bool:
        reader.join(READER_JOIN_SECONDS)
        if not reader.is_alive():
            return True
        self._kill_process_tree(process)
        if process.stdout is not None:
            try:
                process.stdout.close()
            except (OSError, ValueError):
                pass
        reader.join(READER_JOIN_SECONDS)
        return not reader.is_alive()

    def _kill_process_tree(self, process: subprocess.Popen[bytes]) -> None:
        kill_process_tree(process)
