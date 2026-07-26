"""Owned lifecycle and validation of an isolated restore database."""

from __future__ import annotations

import re
import time
from collections.abc import Callable
from dataclasses import dataclass
from typing import Protocol

from .commands import SNAPSHOT_ID, CommandSpec
from .pipeline import PipelineSpec
from .restore_commands import DOCKER_CONTAINER_ID, RestoreCommands
from .restore_contract import RestoreError, RestoreFailure
from .runner import RecoveryCommandError
from .target import RestoreTarget
from .validation import (
    MigrationCatalog,
    RestoreValidationError,
    SchemaProof,
    validate_restored_schema,
)

RESTORE_READY_TIMEOUT_SECONDS = 120
RESTORE_READY_POLL_SECONDS = 2
CONTAINER_OWNER = re.compile(
    r"(?P<container>[0-9a-f]{64})\|"
    r"(?P<drill>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-"
    r"[0-9a-f]{4}-[0-9a-f]{12})"
)


class CommandExecutor(Protocol):
    def run(self, specification: CommandSpec) -> str: ...


class PipelineExecutor(Protocol):
    def run(self, specification: PipelineSpec) -> None: ...


@dataclass(frozen=True)
class _DatabasePlan:
    create: CommandSpec
    owner: CommandSpec
    ready: CommandSpec
    restore: PipelineSpec
    schema: CommandSpec


@dataclass(frozen=True)
class _DatabaseClaim:
    container_id: str | None
    failure: RestoreFailure | None


class DatabaseRestoreCoordinator:
    def __init__(
        self,
        commands: RestoreCommands,
        executor: CommandExecutor,
        pipeline: PipelineExecutor,
        catalog: MigrationCatalog,
        *,
        monotonic: Callable[[], float] = time.monotonic,
        sleeper: Callable[[float], None] = time.sleep,
    ) -> None:
        if not isinstance(catalog, MigrationCatalog) or not catalog.versions:
            raise ValueError("migration catalog must not be empty")
        self._commands = commands
        self._executor = executor
        self._pipeline = pipeline
        self._catalog = catalog
        self._monotonic = monotonic
        self._sleep = sleeper

    def restore(self, target: RestoreTarget, snapshot_id: str) -> SchemaProof:
        plan = self._plan(target, snapshot_id)
        failure: RestoreError | None = None
        proof: SchemaProof | None = None
        cleanup: CommandSpec | None = None
        try:
            claim = self._claim_database(target, plan)
            if claim.container_id:
                cleanup = self._commands.remove_database(target, claim.container_id)
            if claim.failure:
                raise RestoreError((claim.failure,))
            self._wait_until_ready(plan.ready)
            self._import_database(plan.restore)
            proof = self._validate_schema(plan.schema)
        except RestoreError as error:
            failure = error
        finally:
            if cleanup is not None:
                try:
                    self._executor.run(cleanup)
                except RecoveryCommandError as error:
                    codes = failure.error_codes if failure else ()
                    failure = RestoreError((*codes, RestoreFailure.DATABASE_CLEANUP))
                    failure.__cause__ = error
        if failure is not None:
            raise failure
        if proof is None:
            raise RestoreError((RestoreFailure.RECEIPT_INVALID,))
        return proof

    def _plan(self, target: RestoreTarget, snapshot_id: str) -> _DatabasePlan:
        if (
            not isinstance(snapshot_id, str)
            or SNAPSHOT_ID.fullmatch(snapshot_id) is None
        ):
            raise RestoreError((RestoreFailure.SNAPSHOTS_INVALID,))
        try:
            return _DatabasePlan(
                create=self._commands.create_database(target),
                owner=self._commands.database_owner(target),
                ready=self._commands.database_ready(target),
                restore=self._commands.database_restore(snapshot_id, target),
                schema=self._commands.restored_schema(target),
            )
        except (TypeError, ValueError) as error:
            raise RestoreError((RestoreFailure.TARGET_INVALID,)) from error

    def _claim_database(
        self, target: RestoreTarget, plan: _DatabasePlan
    ) -> _DatabaseClaim:
        creation_failed = False
        try:
            created = self._executor.run(plan.create)
        except RecoveryCommandError:
            created = ""
            creation_failed = True
        container_id = created if DOCKER_CONTAINER_ID.fullmatch(created) else None
        creation_failed = creation_failed or container_id is None
        try:
            inspected = self._executor.run(plan.owner)
        except RecoveryCommandError:
            return _DatabaseClaim(
                container_id,
                (
                    RestoreFailure.DATABASE_CREATE
                    if creation_failed
                    else RestoreFailure.DATABASE_OWNERSHIP
                ),
            )
        owner = CONTAINER_OWNER.fullmatch(inspected)
        if owner is None or owner.group("drill") != target.drill_id:
            failure = (
                RestoreFailure.DATABASE_CREATE
                if creation_failed
                else RestoreFailure.DATABASE_OWNERSHIP
            )
            return _DatabaseClaim(container_id, failure)
        if container_id is not None and owner.group("container") != container_id:
            return _DatabaseClaim(container_id, RestoreFailure.DATABASE_OWNERSHIP)
        return _DatabaseClaim(
            owner.group("container"),
            RestoreFailure.DATABASE_CREATE if creation_failed else None,
        )

    def _wait_until_ready(self, specification: CommandSpec) -> None:
        deadline = self._monotonic() + RESTORE_READY_TIMEOUT_SECONDS
        last_error: RecoveryCommandError | None = None
        while self._monotonic() < deadline:
            try:
                self._executor.run(specification)
                return
            except RecoveryCommandError as error:
                last_error = error
                remaining = deadline - self._monotonic()
                if remaining > 0:
                    self._sleep(min(RESTORE_READY_POLL_SECONDS, remaining))
        raise RestoreError((RestoreFailure.DATABASE_READY,)) from last_error

    def _import_database(self, specification: PipelineSpec) -> None:
        try:
            self._pipeline.run(specification)
        except RecoveryCommandError as error:
            raise RestoreError((RestoreFailure.DATABASE_IMPORT,)) from error

    def _validate_schema(self, specification: CommandSpec) -> SchemaProof:
        try:
            output = self._executor.run(specification)
        except RecoveryCommandError as error:
            raise RestoreError((RestoreFailure.SCHEMA_QUERY,)) from error
        try:
            return validate_restored_schema(output, self._catalog)
        except RestoreValidationError as error:
            raise RestoreError((error.error_code,)) from error
