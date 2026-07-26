from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.recovery.commands import CommandSpec
from tools.recovery.runner import RecoveryCommandError
from tools.recovery.toolchain import ToolchainError, ToolchainVerifier

RESTIC = "check Restic version"
COMPOSE = "check Docker Compose version"


class ScriptedCommands:
    def __init__(self, root: Path) -> None:
        self.root = root

    def restic_version(self) -> CommandSpec:
        return CommandSpec(RESTIC, ("restic", "version"), self.root)

    def compose_version(self) -> CommandSpec:
        return CommandSpec(
            COMPOSE,
            ("docker", "compose", "version", "--short"),
            self.root,
        )


class ScriptedExecutor:
    def __init__(self, restic: str, compose: str) -> None:
        self.outputs = {RESTIC: restic, COMPOSE: compose}
        self.failures: set[str] = set()
        self.calls: list[str] = []

    def run(self, specification: CommandSpec) -> str:
        self.calls.append(specification.action)
        if specification.action in self.failures:
            raise RecoveryCommandError(
                specification.action, "sensitive executable detail"
            )
        return self.outputs[specification.action]


class ToolchainVerifierTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name).resolve()
        self.commands = ScriptedCommands(self.root)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def verifier(
        self, restic: str, compose: str
    ) -> tuple[ToolchainVerifier, ScriptedExecutor]:
        executor = ScriptedExecutor(restic, compose)
        return ToolchainVerifier(self.commands, executor), executor

    def test_accepts_tested_restic_and_compose_v2_or_v5(self) -> None:
        cases = (
            (
                "restic 0.19.1 compiled with go1.25.5 on windows/amd64",
                "2.20.0",
                ("0.19.1", "2.20.0"),
            ),
            (
                "restic 1.0.0 compiled with go1.26 on linux/arm64",
                "v5.1.3",
                ("1.0.0", "5.1.3"),
            ),
            ("restic 0.19.1", "5.1.3", ("0.19.1", "5.1.3")),
        )
        for restic, compose, expected in cases:
            with self.subTest(restic=restic, compose=compose):
                verifier, executor = self.verifier(restic, compose)
                proof = verifier.verify()
                self.assertEqual(
                    (proof.restic_version, proof.compose_version),
                    expected,
                )
                self.assertEqual(executor.calls, [RESTIC, COMPOSE])

    def test_rejects_old_or_ambiguous_restic_before_compose(self) -> None:
        invalid = (
            "restic 0.19.0",
            "restic 0.19.1-rc.1",
            "restic 10000.1.1",
            "restic 00.19.1",
            "restic 0.19.1\nunexpected",
            "Restic 0.19.1",
            "sensitive executable detail",
        )
        for output in invalid:
            with self.subTest(output=output):
                verifier, executor = self.verifier(output, "5.1.3")
                self._assert_error(verifier, "RESTIC_UNSUPPORTED")
                self.assertEqual(executor.calls, [RESTIC])

    def test_rejects_old_prerelease_or_decorated_compose(self) -> None:
        invalid = (
            "2.19.9",
            "2.20.0-rc.1",
            "Docker Compose version v5.1.3",
            "5.1",
            "05.1.3",
            "5.1.3\nunexpected",
        )
        for output in invalid:
            with self.subTest(output=output):
                verifier, executor = self.verifier("restic 0.19.1", output)
                self._assert_error(verifier, "COMPOSE_UNSUPPORTED")
                self.assertEqual(executor.calls, [RESTIC, COMPOSE])

    def test_maps_unavailable_tools_without_leaking_runner_details(self) -> None:
        for action, code in (
            (RESTIC, "RESTIC_UNAVAILABLE"),
            (COMPOSE, "COMPOSE_UNAVAILABLE"),
        ):
            with self.subTest(action=action):
                verifier, executor = self.verifier("restic 0.19.1", "5.1.3")
                executor.failures.add(action)
                with self.assertRaises(ToolchainError) as raised:
                    verifier.verify()
                self.assertEqual(raised.exception.error_code, code)
                self.assertNotIn("sensitive executable detail", str(raised.exception))

    def _assert_error(self, verifier: ToolchainVerifier, code: str) -> None:
        with self.assertRaises(ToolchainError) as raised:
            verifier.verify()
        self.assertEqual(raised.exception.error_code, code)


if __name__ == "__main__":
    unittest.main()
