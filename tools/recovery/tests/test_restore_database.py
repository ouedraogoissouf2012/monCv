from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.recovery.commands import CommandSpec
from tools.recovery.identity import SnapshotIdentity
from tools.recovery.pipeline import PipelineSpec
from tools.recovery.restore_commands import RestoreCommands
from tools.recovery.restore_contract import RestoreError, RestoreFailure
from tools.recovery.restore_database import DatabaseRestoreCoordinator
from tools.recovery.runner import RecoveryCommandError
from tools.recovery.settings import RecoverySettings
from tools.recovery.target import RestoreTarget
from tools.recovery.validation import MigrationCatalog

SHA = "a" * 40
SNAPSHOT = "b" * 64
CONTAINER = "c" * 64
OPERATION = "12345678-1234-4234-9234-123456789abc"
DRILL = "87654321-4321-4321-8321-cba987654321"
PASSWORD = "Recovery-" + "x" * 20 + "-2026-" + "Y" * 8
F = RestoreFailure
CREATE = "create isolated restore database"
OWNER = "inspect isolated restore ownership"
READY = "probe isolated restore database"
SCHEMA = "inspect restored Flyway schema"
CLEANUP = "remove isolated restore database"


class ScriptedExecutor:
    def __init__(self) -> None:
        self.calls: list[str] = []
        self.specifications: list[CommandSpec] = []
        self.failures: set[str] = set()
        self.create_output = CONTAINER
        self.owner_container = CONTAINER
        self.owner_drill = DRILL
        self.ready_failures = 0
        self.schema_output = (
            '[{"version":"1","success":true},{"version":"2","success":true}]'
        )

    def run(self, specification: CommandSpec) -> str:
        action = specification.action
        self.specifications.append(specification)
        self.calls.append(action)
        if action in self.failures:
            raise RecoveryCommandError(action, "sensitive fixture detail")
        if action == CREATE:
            return self.create_output
        if action == OWNER:
            return self.owner_container + "|" + self.owner_drill
        if action == READY and self.ready_failures:
            self.ready_failures -= 1
            raise RecoveryCommandError(action, "not ready")
        if action == SCHEMA:
            return self.schema_output
        return ""


class ScriptedPipeline:
    def __init__(self) -> None:
        self.calls: list[PipelineSpec] = []
        self.fails = False

    def run(self, specification: PipelineSpec) -> None:
        self.calls.append(specification)
        if self.fails:
            raise RecoveryCommandError(specification.action, "sensitive fixture detail")


class ManualTime:
    def __init__(self) -> None:
        self.value = 0.0
        self.sleeps: list[float] = []

    def monotonic(self) -> float:
        return self.value

    def sleep(self, seconds: float) -> None:
        self.sleeps.append(seconds)
        self.value += seconds


class DatabaseRestoreCoordinatorTest(unittest.TestCase):
    def setUp(self) -> None:
        self.application = tempfile.TemporaryDirectory()
        self.workspace = tempfile.TemporaryDirectory()
        root = Path(self.application.name).resolve()
        for name in ("docker-compose.yml", "docker-compose.prod.yml"):
            (root / name).write_text("services: {}", encoding="utf-8")
        uploads = root / "backend" / "uploads"
        uploads.mkdir(parents=True)
        environment = _file(root / "production.env", "TAG=" + SHA)
        repository = _file(root / "repository", "s3:https://backup.test/moncv")
        password = _file(root / "password", PASSWORD)
        settings = RecoverySettings(root, environment, repository, password, uploads)
        self.commands = RestoreCommands(settings)
        identity = SnapshotIdentity.create(SHA, OPERATION)
        self.target = RestoreTarget(Path(self.workspace.name), identity, DRILL)
        self.executor = ScriptedExecutor()
        self.pipeline = ScriptedPipeline()
        self.time = ManualTime()

    def tearDown(self) -> None:
        self.workspace.cleanup()
        self.application.cleanup()

    def coordinator(
        self, catalog: MigrationCatalog | None = None
    ) -> DatabaseRestoreCoordinator:
        return DatabaseRestoreCoordinator(
            self.commands,
            self.executor,
            self.pipeline,
            catalog or MigrationCatalog(("1", "2")),
            monotonic=self.time.monotonic,
            sleeper=self.time.sleep,
        )

    def test_restores_validates_and_removes_owned_database(self) -> None:
        proof = self.coordinator().restore(self.target, SNAPSHOT)
        self.assertEqual(proof.versions, ("1", "2"))
        self.assertEqual(
            self.executor.calls,
            [CREATE, OWNER, READY, SCHEMA, CLEANUP],
        )
        (pipeline,) = self.pipeline.calls
        self.assertEqual(pipeline.action, "restore database snapshot")
        self.assertEqual(
            pipeline.source.arguments[-2:], (SNAPSHOT, "moncv/postgres.dump")
        )
        self.assertIn(self.target.container_name, pipeline.sink.arguments)

    def test_retries_readiness_with_a_bounded_clock(self) -> None:
        self.executor.ready_failures = 2
        self.coordinator().restore(self.target, SNAPSHOT)
        self.assertEqual(self.executor.calls.count(READY), 3)
        self.assertEqual(self.time.sleeps, [2, 2])
        executor = ScriptedExecutor()
        executor.ready_failures = 10_000
        self.executor = executor
        self.time = ManualTime()
        with self.assertRaises(RestoreError) as raised:
            self.coordinator().restore(self.target, SNAPSHOT)
        self.assertEqual(raised.exception.error_codes, _codes(F.DATABASE_READY))
        self.assertEqual((self.time.value, executor.calls.count(READY)), (120, 60))
        self.assertEqual(executor.calls[-1], CLEANUP)

    def test_rejects_invalid_inputs_before_starting_docker(self) -> None:
        for snapshot in ("short", "B" * 64, 123):
            with (
                self.subTest(snapshot=snapshot),
                self.assertRaises(RestoreError) as raised,
            ):
                self.coordinator().restore(
                    self.target,
                    snapshot,  # type: ignore[arg-type]
                )
            self.assertEqual(raised.exception.error_codes, _codes(F.SNAPSHOTS_INVALID))
        self.assertEqual(self.executor.calls, [])
        with self.assertRaises(RestoreError) as raised:
            self.coordinator().restore(object(), SNAPSHOT)  # type: ignore[arg-type]
        self.assertEqual(raised.exception.error_codes, _codes(F.TARGET_INVALID))
        self.assertEqual(self.executor.calls, [])
        self.assertRaises(ValueError, self.coordinator, MigrationCatalog(()))

    def test_cleans_a_claimed_container_after_ambiguous_creation(self) -> None:
        for create_failure in (False, True):
            with self.subTest(command_failure=create_failure):
                self.executor = ScriptedExecutor()
                if create_failure:
                    self.executor.failures.add(CREATE)
                else:
                    self.executor.create_output = "ambiguous"
                with self.assertRaises(RestoreError) as raised:
                    self.coordinator().restore(self.target, SNAPSHOT)
                self.assertEqual(
                    raised.exception.error_codes, _codes(F.DATABASE_CREATE)
                )
                self.assertEqual(self.executor.calls[-1], CLEANUP)

    def test_never_removes_a_container_without_exact_ownership(self) -> None:
        cases = (
            (CONTAINER, "d" * 64, DRILL, False),
            (CONTAINER, CONTAINER, "11111111-2222-4222-8222-333333333333", False),
            (CONTAINER, CONTAINER, DRILL, True),
            ("ambiguous", CONTAINER, DRILL, True),
        )
        for created, owned, drill, owner_failure in cases:
            with self.subTest(
                created=created, owned=owned, drill=drill, failed=owner_failure
            ):
                self.executor = ScriptedExecutor()
                self.executor.create_output = created
                self.executor.owner_container = owned
                self.executor.owner_drill = drill
                if owner_failure:
                    self.executor.failures.add(OWNER)
                with self.assertRaises(RestoreError) as raised:
                    self.coordinator().restore(self.target, SNAPSHOT)
                expected = (
                    F.DATABASE_CREATE
                    if created == "ambiguous"
                    else F.DATABASE_OWNERSHIP
                )
                self.assertEqual(raised.exception.error_codes, (expected.value,))
                if created == "ambiguous":
                    self.assertNotIn(CLEANUP, self.executor.calls)
                else:
                    self.assertEqual(self.executor.calls[-1], CLEANUP)
                    self.assertEqual(
                        self.executor.specifications[-1].arguments[-1], created
                    )

    def test_maps_pipeline_and_schema_failures_without_leaking_details(self) -> None:
        cases = (
            ("pipeline", F.DATABASE_IMPORT.value),
            ("query", F.SCHEMA_QUERY.value),
            ("schema", "RESTORE_SCHEMA_INVALID"),
        )
        for failure, expected in cases:
            with self.subTest(failure=failure):
                self.executor = ScriptedExecutor()
                self.pipeline = ScriptedPipeline()
                if failure == "pipeline":
                    self.pipeline.fails = True
                elif failure == "query":
                    self.executor.failures.add(SCHEMA)
                else:
                    self.executor.schema_output = '[{"version":"9","success":true}]'
                with self.assertRaises(RestoreError) as raised:
                    self.coordinator().restore(self.target, SNAPSHOT)
                self.assertEqual(raised.exception.error_codes, (expected,))
                self.assertNotIn("sensitive fixture detail", str(raised.exception))
                self.assertEqual(self.executor.calls[-1], CLEANUP)

    def test_cleanup_failure_blocks_success_and_preserves_primary_code(self) -> None:
        self.executor.failures.add(CLEANUP)
        with self.assertRaises(RestoreError) as raised:
            self.coordinator().restore(self.target, SNAPSHOT)
        self.assertEqual(raised.exception.error_codes, _codes(F.DATABASE_CLEANUP))
        self.executor = ScriptedExecutor()
        self.executor.failures.add(CLEANUP)
        self.pipeline.fails = True
        with self.assertRaises(RestoreError) as raised:
            self.coordinator().restore(self.target, SNAPSHOT)
        self.assertEqual(
            raised.exception.error_codes,
            _codes(F.DATABASE_IMPORT, F.DATABASE_CLEANUP),
        )


def _file(path: Path, content: str) -> Path:
    path.write_text(content, encoding="utf-8")
    path.chmod(0o600)
    return path


def _codes(*values: RestoreFailure | str) -> tuple[str, ...]:
    return tuple(str(value) for value in values)


if __name__ == "__main__":
    unittest.main()
