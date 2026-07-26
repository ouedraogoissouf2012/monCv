"""Fail-fast version policy for recovery command-line dependencies."""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Protocol

from .commands import CommandSpec
from .runner import RecoveryCommandError

MINIMUM_RESTIC_VERSION = (0, 19, 1)
MINIMUM_COMPOSE_VERSION = (2, 20, 0)
VERSION_PART = r"(?:0|[1-9][0-9]{0,3})"
VERSION = rf"{VERSION_PART}\.{VERSION_PART}\.{VERSION_PART}"
RESTIC_OUTPUT = re.compile(
    rf"restic (?P<version>{VERSION})"
    r"(?: compiled with [A-Za-z0-9.+_-]{1,32} on [A-Za-z0-9_./-]{1,32})?"
)
COMPOSE_OUTPUT = re.compile(rf"v?(?P<version>{VERSION})")


class ToolchainCommands(Protocol):
    def restic_version(self) -> CommandSpec: ...

    def compose_version(self) -> CommandSpec: ...


class CommandExecutor(Protocol):
    def run(self, specification: CommandSpec) -> str: ...


class ToolchainError(RuntimeError):
    def __init__(self, error_code: str) -> None:
        self.error_code = error_code
        super().__init__("Recovery toolchain failed: " + error_code)


@dataclass(frozen=True)
class ToolchainProof:
    restic_version: str
    compose_version: str


class ToolchainVerifier:
    def __init__(
        self,
        commands: ToolchainCommands,
        executor: CommandExecutor,
    ) -> None:
        self._commands = commands
        self._executor = executor

    def verify(self) -> ToolchainProof:
        restic = self._read_version(
            self._commands.restic_version(),
            RESTIC_OUTPUT,
            MINIMUM_RESTIC_VERSION,
            "RESTIC",
        )
        compose = self._read_version(
            self._commands.compose_version(),
            COMPOSE_OUTPUT,
            MINIMUM_COMPOSE_VERSION,
            "COMPOSE",
        )
        return ToolchainProof(restic, compose)

    def _read_version(
        self,
        specification: CommandSpec,
        pattern: re.Pattern[str],
        minimum: tuple[int, int, int],
        tool: str,
    ) -> str:
        try:
            output = self._executor.run(specification)
        except RecoveryCommandError as error:
            raise ToolchainError(tool + "_UNAVAILABLE") from error
        match = pattern.fullmatch(output)
        if match is None:
            raise ToolchainError(tool + "_UNSUPPORTED")
        version = tuple(int(part) for part in match.group("version").split("."))
        if version < minimum:
            raise ToolchainError(tool + "_UNSUPPORTED")
        return ".".join(str(part) for part in version)
