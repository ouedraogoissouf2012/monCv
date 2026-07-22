"""Bounded binary pipelines for streaming encrypted recovery data."""

from __future__ import annotations

import os
import subprocess
import time
from collections.abc import Mapping
from dataclasses import dataclass

from .commands import SAFE_ACTION, CommandSpec
from .processes import kill_process_tree, process_group_options
from .runner import RecoveryCommandError, sanitized_environment

PROCESS_EXIT_SECONDS = 5


@dataclass(frozen=True)
class PipelineSpec:
    action: str
    source: CommandSpec
    sink: CommandSpec
    timeout_seconds: int

    def __post_init__(self) -> None:
        if (
            SAFE_ACTION.fullmatch(self.action) is None
            or self.timeout_seconds <= 0
            or self.timeout_seconds
            > min(self.source.timeout_seconds, self.sink.timeout_seconds)
        ):
            raise ValueError("pipeline specification is invalid")


class SafePipelineRunner:
    def __init__(self, environment: Mapping[str, str] | None = None) -> None:
        self._environment = dict(os.environ if environment is None else environment)

    def run(self, specification: PipelineSpec) -> None:
        print(f"[recovery] {specification.action}", flush=True)
        source: subprocess.Popen[bytes] | None = None
        sink: subprocess.Popen[bytes] | None = None
        try:
            source = self._start_source(specification.source)
            sink = self._start_sink(specification.sink, source)
            source_code, sink_code = self._wait(source, sink, specification)
        except RecoveryCommandError:
            self._stop(source, sink)
            raise
        except BaseException:
            self._stop(source, sink)
            raise
        if source_code != 0 or sink_code != 0:
            raise RecoveryCommandError(
                specification.action,
                f"source exit code {source_code}, sink exit code {sink_code}",
            )

    def _start_source(self, specification: CommandSpec) -> subprocess.Popen[bytes]:
        try:
            return subprocess.Popen(
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
                specification.action, "source executable unavailable"
            ) from error

    def _start_sink(
        self, specification: CommandSpec, source: subprocess.Popen[bytes]
    ) -> subprocess.Popen[bytes]:
        stream = source.stdout
        try:
            sink = subprocess.Popen(
                specification.arguments,
                cwd=specification.cwd,
                env=sanitized_environment(specification.arguments, self._environment),
                stdin=stream,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                shell=False,
                **process_group_options(),
            )
        except OSError as error:
            raise RecoveryCommandError(
                specification.action, "sink executable unavailable"
            ) from error
        finally:
            if stream is not None:
                stream.close()
        return sink

    def _wait(
        self,
        source: subprocess.Popen[bytes],
        sink: subprocess.Popen[bytes],
        specification: PipelineSpec,
    ) -> tuple[int, int]:
        deadline = time.monotonic() + specification.timeout_seconds
        try:
            sink_code = sink.wait(timeout=specification.timeout_seconds)
            remaining = max(0.001, deadline - time.monotonic())
            source_code = source.wait(timeout=remaining)
        except subprocess.TimeoutExpired as error:
            raise RecoveryCommandError(specification.action, "timeout") from error
        except OSError as error:
            raise RecoveryCommandError(
                specification.action, "process unavailable"
            ) from error
        return source_code, sink_code

    def _stop(
        self,
        source: subprocess.Popen[bytes] | None,
        sink: subprocess.Popen[bytes] | None,
    ) -> None:
        processes = tuple(process for process in (source, sink) if process is not None)
        for process in processes:
            kill_process_tree(process)
        for process in processes:
            try:
                process.wait(timeout=PROCESS_EXIT_SECONDS)
            except (OSError, subprocess.TimeoutExpired):
                pass
