"""Safe subprocess execution with consistent diagnostics."""

from __future__ import annotations

import os
import shlex
import shutil
import subprocess
from collections.abc import Mapping, Sequence
from pathlib import Path


class CommandError(RuntimeError):
    """Raised when an external command cannot complete successfully."""


def executable_command(arguments: Sequence[str]) -> list[str]:
    command = [str(argument) for argument in arguments]
    executable = shutil.which(command[0])
    if executable is None:
        return command
    resolved = [executable, *command[1:]]
    if os.name != "nt" or Path(executable).suffix.lower() not in {".bat", ".cmd"}:
        return resolved
    return [
        os.environ.get("COMSPEC", "cmd.exe"),
        "/d",
        "/s",
        "/c",
        "call",
        *resolved,
    ]


class CommandRunner:
    def require(self, *executables: str) -> None:
        missing = [name for name in executables if shutil.which(name) is None]
        if missing:
            raise CommandError(f"Missing required tools: {', '.join(missing)}")

    def run(
        self,
        arguments: Sequence[str],
        *,
        cwd: Path,
        env: Mapping[str, str] | None = None,
        check: bool = True,
        capture: bool = False,
    ) -> subprocess.CompletedProcess[str]:
        command = [str(argument) for argument in arguments]
        execution_command = executable_command(command)
        print(f"\n[{cwd}]$ {shlex.join(command)}", flush=True)
        process_env = os.environ.copy()
        if env:
            process_env.update(env)
        result = subprocess.run(
            execution_command,
            cwd=cwd,
            env=process_env,
            check=False,
            text=True,
            encoding="utf-8",
            errors="replace",
            stdout=subprocess.PIPE if capture else None,
            stderr=subprocess.PIPE if capture else None,
        )
        if check and result.returncode != 0:
            details = (result.stderr or result.stdout or "").strip()
            suffix = f"\n{details}" if details else ""
            raise CommandError(
                f"Command failed with exit code {result.returncode}: "
                f"{shlex.join(command)}{suffix}"
            )
        return result

    def capture(
        self,
        arguments: Sequence[str],
        *,
        cwd: Path,
        env: Mapping[str, str] | None = None,
    ) -> str:
        return self.run(arguments, cwd=cwd, env=env, capture=True).stdout.strip()
