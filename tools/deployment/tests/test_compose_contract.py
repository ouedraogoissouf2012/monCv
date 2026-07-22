from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.deployment.compose_contract import (
    ContractError,
    REQUIRED_BACKEND_ENV,
    main,
    render_contract,
    repository_environment,
    validate_contract,
)

SHA = "a" * 40


def valid_document() -> dict:
    environment = {key: f"contract-{key.lower()}" for key in REQUIRED_BACKEND_ENV}
    environment.update(
        {
            "SPRING_PROFILES_ACTIVE": "prod",
            "AI_FALLBACK_ENABLED": "false",
            "RATE_LIMIT_ENABLED": "true",
            "RATE_LIMIT_ADMIN_BYPASS": "false",
            "SHOW_SQL": "false",
            "DB_USERNAME": "moncv_contract",
            "DB_PASSWORD": "database-contract-value",
        }
    )
    return {
        "services": {
            "postgres": {
                "environment": {
                    "POSTGRES_USER": environment["DB_USERNAME"],
                    "POSTGRES_PASSWORD": environment["DB_PASSWORD"],
                },
                "networks": {"data-net": None},
            },
            "redis": {"networks": {"data-net": None}},
            "backend": {
                "image": f"ghcr.io/ouedraogoissouf2012/cv-mobile-backend:{SHA}",
                "environment": environment,
                "networks": {"edge-net": None, "data-net": None},
            },
            "web": {
                "image": f"ghcr.io/ouedraogoissouf2012/cv-mobile-web:{SHA}",
                "ports": [{"host_ip": "127.0.0.1", "target": 8080}],
                "networks": {"edge-net": None},
            },
            "adminer": {
                "profiles": ["dev-tools"],
                "networks": {"data-net": None},
            },
        },
        "networks": {"edge-net": {}, "data-net": {"internal": True}},
    }


class ContractValidationTest(unittest.TestCase):
    def test_accepts_hardened_contract(self) -> None:
        validate_contract(valid_document())

    def test_rejects_each_missing_backend_setting_without_exposing_values(self) -> None:
        for key in REQUIRED_BACKEND_ENV:
            with self.subTest(key=key):
                document = valid_document()
                document["services"]["backend"]["environment"][key] = ""
                with self.assertRaisesRegex(ContractError, key) as raised:
                    validate_contract(document)
                self.assertNotIn("database-contract-value", str(raised.exception))

    def test_rejects_unsafe_flags(self) -> None:
        unsafe = {
            "SPRING_PROFILES_ACTIVE": "dev",
            "AI_FALLBACK_ENABLED": "true",
            "RATE_LIMIT_ENABLED": "false",
            "RATE_LIMIT_ADMIN_BYPASS": "true",
            "SHOW_SQL": "true",
        }
        for key, value in unsafe.items():
            with self.subTest(key=key):
                document = valid_document()
                document["services"]["backend"]["environment"][key] = value
                with self.assertRaisesRegex(ContractError, key):
                    validate_contract(document)

    def test_rejects_mutable_images_and_host_exposure(self) -> None:
        cases = (
            ("backend image", ("backend", "image"), "backend:latest"),
            ("web image", ("web", "image"), "web:v1"),
            ("database port", ("postgres", "ports"), [{"target": 5432}]),
            ("public web", ("web", "ports"), [{"host_ip": "0.0.0.0", "target": 8080}]),
        )
        for name, (service, field), value in cases:
            with self.subTest(name=name):
                document = valid_document()
                document["services"][service][field] = value
                with self.assertRaises(ContractError):
                    validate_contract(document)

    def test_rejects_network_drift_and_database_credential_mismatch(self) -> None:
        documents = []
        wrong_network = valid_document()
        wrong_network["services"]["redis"]["networks"] = {"edge-net": None}
        documents.append(wrong_network)
        public_data = valid_document()
        public_data["networks"]["data-net"]["internal"] = False
        documents.append(public_data)
        mismatch = valid_document()
        mismatch["services"]["postgres"]["environment"]["POSTGRES_PASSWORD"] = "other"
        documents.append(mismatch)
        for document in documents:
            with self.subTest(document=document):
                with self.assertRaises(ContractError):
                    validate_contract(document)


class ComposeRenderingTest(unittest.TestCase):
    @patch("tools.deployment.compose_contract.subprocess.run")
    def test_renders_json_without_inheriting_application_environment(self, run) -> None:
        run.return_value = subprocess.CompletedProcess(
            [], 0, json.dumps(valid_document()), ""
        )
        with patch.dict(
            "os.environ",
            {"COMPOSE_FILE": "attacker.yml", "JWT_SECRET": "host-secret"},
            clear=True,
        ):
            document = render_contract(
                Path("."), environment=repository_environment(SHA)
            )

        self.assertIn("services", document)
        process_environment = run.call_args.kwargs["env"]
        self.assertNotEqual(process_environment["JWT_SECRET"], "host-secret")
        self.assertNotIn("COMPOSE_FILE", process_environment)
        self.assertEqual(run.call_args.kwargs["timeout"], 60)

    @patch("tools.deployment.compose_contract.subprocess.run")
    def test_render_failure_never_includes_subprocess_output(self, run) -> None:
        run.return_value = subprocess.CompletedProcess([], 1, "", "leaked-secret-value")
        with self.assertRaises(ContractError) as raised:
            render_contract(Path("."), environment=repository_environment(SHA))
        self.assertNotIn("leaked-secret-value", str(raised.exception))

    def test_rejects_missing_environment_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(ContractError, "environment file is missing"):
                render_contract(Path("."), env_file=Path(directory) / "missing.env")

    @patch("tools.deployment.compose_contract.validate_contract")
    @patch("tools.deployment.compose_contract.render_contract")
    def test_cli_validates_an_environment_file(self, render, validate) -> None:
        render.return_value = valid_document()
        self.assertEqual(main(["--env-file", "production.env"]), 0)
        render.assert_called_once()
        validate.assert_called_once_with(render.return_value)

    @patch("tools.deployment.compose_contract.render_contract")
    def test_cli_returns_failure_for_safe_contract_error(self, render) -> None:
        render.side_effect = ContractError(("invalid setting",))
        self.assertEqual(main(["--env-file", "production.env"]), 1)


if __name__ == "__main__":
    unittest.main()
