"""Render and validate the production Docker Compose contract."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import re
import stat
import subprocess
from collections.abc import Mapping, Sequence
from pathlib import Path
from typing import Any

BACKEND_IMAGE = re.compile(
    r"^ghcr\.io/ouedraogoissouf2012/cv-mobile-backend:([0-9a-f]{40})$"
)
WEB_IMAGE = re.compile(r"^ghcr\.io/ouedraogoissouf2012/cv-mobile-web:([0-9a-f]{40})$")
REQUIRED_BACKEND_ENV = (
    "DB_URL",
    "DB_USERNAME",
    "DB_PASSWORD",
    "GOOGLE_CLIENT_ID",
    "JWT_SECRET",
    "JWT_EXPIRATION",
    "JWT_REFRESH_EXPIRATION",
    "ALLOWED_ORIGINS",
    "DEEPSEEK_API_KEY",
    "DEEPSEEK_BASE_URL",
    "RATE_LIMIT_REDIS_URL",
    "PUBLIC_LINK_ENCRYPTION_KEY",
    "PUBLIC_MEDIA_ALLOWED_ORIGINS",
)
APP_ENV_KEYS = frozenset(REQUIRED_BACKEND_ENV) | {
    "TAG",
    "WEB_PORT",
    "AI_FALLBACK_ENABLED",
    "RATE_LIMIT_ENABLED",
    "RATE_LIMIT_ADMIN_BYPASS",
    "SHOW_SQL",
    "SENTRY_DSN",
    "SENTRY_ENVIRONMENT",
    "SPRING_PROFILES_ACTIVE",
}
SECURE_FLAGS = {
    "SPRING_PROFILES_ACTIVE": "prod",
    "AI_FALLBACK_ENABLED": "false",
    "RATE_LIMIT_ENABLED": "true",
    "RATE_LIMIT_ADMIN_BYPASS": "false",
    "SHOW_SQL": "false",
}


class ContractError(RuntimeError):
    """A safe deployment error that never contains configuration values."""

    def __init__(self, violations: Sequence[str]) -> None:
        self.violations = tuple(sorted(set(violations)))
        super().__init__("Invalid production contract: " + "; ".join(self.violations))


def validate_contract(document: Mapping[str, Any]) -> None:
    """Validate a rendered Compose document without echoing its values."""
    violations: list[str] = []
    services = _mapping(document.get("services"))
    required_services = ("postgres", "redis", "backend", "web", "adminer")
    for name in required_services:
        if name not in services:
            violations.append(f"services.{name} is required")
    if violations:
        raise ContractError(violations)

    backend = _mapping(services["backend"])
    web = _mapping(services["web"])
    backend_env = _mapping(backend.get("environment"))
    postgres_env = _mapping(_mapping(services["postgres"]).get("environment"))

    for key in REQUIRED_BACKEND_ENV:
        if not _is_set(backend_env.get(key)):
            violations.append(f"services.backend.environment.{key} is required")
    for key, expected in SECURE_FLAGS.items():
        if str(backend_env.get(key, "")).lower() != expected:
            violations.append(f"services.backend.environment.{key} is unsafe")

    for key in ("POSTGRES_USER", "POSTGRES_PASSWORD"):
        if not _is_set(postgres_env.get(key)):
            violations.append(f"services.postgres.environment.{key} is required")
    if postgres_env.get("POSTGRES_USER") != backend_env.get("DB_USERNAME"):
        violations.append("database usernames must match")
    if postgres_env.get("POSTGRES_PASSWORD") != backend_env.get("DB_PASSWORD"):
        violations.append("database passwords must match")

    backend_tag = _image_tag(backend.get("image"), BACKEND_IMAGE)
    web_tag = _image_tag(web.get("image"), WEB_IMAGE)
    if backend_tag is None:
        violations.append("services.backend.image must use a full Git SHA")
    if web_tag is None:
        violations.append("services.web.image must use a full Git SHA")
    if backend_tag is not None and web_tag is not None and backend_tag != web_tag:
        violations.append("backend and web image SHAs must match")

    for name in ("postgres", "redis", "backend", "adminer"):
        if _ports(_mapping(services[name])):
            violations.append(f"services.{name}.ports must be empty")
    web_ports = _ports(web)
    if len(web_ports) != 1 or not _loopback_web_port(web_ports[0]):
        violations.append("services.web.ports must bind 127.0.0.1 to target 8080")

    expected_networks = {
        "postgres": {"data-net"},
        "redis": {"data-net"},
        "backend": {"edge-net", "data-net"},
        "web": {"edge-net"},
        "adminer": {"data-net"},
    }
    for name, expected in expected_networks.items():
        actual = _network_names(_mapping(services[name]))
        if actual != expected:
            violations.append(f"services.{name}.networks is invalid")
    networks = _mapping(document.get("networks"))
    if _mapping(networks.get("data-net")).get("internal") is not True:
        violations.append("networks.data-net must be internal")

    adminer_profiles = _mapping(services["adminer"]).get("profiles", [])
    if adminer_profiles != ["dev-tools"]:
        violations.append("services.adminer must require the dev-tools profile")
    if violations:
        raise ContractError(violations)


def render_contract(
    root: Path,
    *,
    env_file: Path | None = None,
    environment: Mapping[str, str] | None = None,
) -> Mapping[str, Any]:
    """Render the production Compose merge in memory."""
    root = root.resolve()
    command = ["docker", "compose", "--profile", "*"]
    process_env = {
        key: value
        for key, value in os.environ.items()
        if key not in APP_ENV_KEYS and not key.startswith("COMPOSE_")
    }
    if env_file is not None:
        env_file = env_file.resolve()
        _validate_env_file(env_file)
        command.extend(("--env-file", str(env_file)))
    process_env.update(environment or {})
    command.extend(
        (
            "-f",
            str(root / "docker-compose.yml"),
            "-f",
            str(root / "docker-compose.prod.yml"),
            "config",
            "--format",
            "json",
        )
    )
    try:
        result = subprocess.run(
            command,
            cwd=root,
            env=process_env,
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired) as error:
        raise ContractError(("docker compose is unavailable",)) from error
    if result.returncode != 0:
        raise ContractError(("docker compose could not render the configuration",))
    try:
        document = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ContractError(("docker compose returned invalid JSON",)) from error
    if not isinstance(document, Mapping):
        raise ContractError(("docker compose returned an invalid document",))
    return document


def repository_environment(sha: str) -> dict[str, str]:
    """Build non-production fixture values for repository contract checks."""
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise ContractError(
            ("repository SHA must contain 40 lowercase hex characters",)
        )
    return {
        "TAG": sha,
        "DB_USERNAME": "moncv_contract",
        "DB_PASSWORD": _derived_secret("database", 48),
        "GOOGLE_CLIENT_ID": "contract.apps.googleusercontent.com",
        "JWT_SECRET": _derived_secret("jwt", 88),
        "JWT_EXPIRATION": "3600000",
        "JWT_REFRESH_EXPIRATION": "604800000",
        "ALLOWED_ORIGINS": "https://cv.example.test",
        "DEEPSEEK_API_KEY": _derived_secret("ai", 48),
        "PUBLIC_LINK_ENCRYPTION_KEY": base64.b64encode(
            hashlib.sha256(b"public-link-contract").digest()
        ).decode("ascii"),
        "PUBLIC_MEDIA_ALLOWED_ORIGINS": "https://cv.example.test",
    }


def _validate_env_file(path: Path) -> None:
    if not path.is_file():
        raise ContractError(("production environment file is missing",))
    if os.name != "nt" and stat.S_IMODE(path.stat().st_mode) & 0o077:
        raise ContractError(("production environment file permissions must be 0600",))


def _mapping(value: Any) -> Mapping[str, Any]:
    return value if isinstance(value, Mapping) else {}


def _is_set(value: Any) -> bool:
    return value is not None and bool(str(value).strip())


def _image_tag(value: Any, pattern: re.Pattern[str]) -> str | None:
    match = pattern.fullmatch(str(value or ""))
    return match.group(1) if match else None


def _ports(service: Mapping[str, Any]) -> list[Any]:
    value = service.get("ports")
    return list(value) if isinstance(value, list) else []


def _loopback_web_port(port: Any) -> bool:
    value = _mapping(port)
    return value.get("host_ip") == "127.0.0.1" and str(value.get("target")) == "8080"


def _network_names(service: Mapping[str, Any]) -> set[str]:
    networks = service.get("networks")
    if isinstance(networks, Mapping):
        return set(networks)
    if isinstance(networks, list):
        return {str(value) for value in networks}
    return set()


def _derived_secret(label: str, length: int) -> str:
    digest = hashlib.sha512(f"moncv-compose-contract:{label}".encode()).hexdigest()
    return (digest * 2)[:length]


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).parents[2])
    parser.add_argument("--env-file", type=Path)
    args = parser.parse_args(argv)
    try:
        if args.env_file is None:
            sha = subprocess.run(
                ["git", "rev-parse", "HEAD"],
                cwd=args.root,
                capture_output=True,
                text=True,
                timeout=10,
                check=True,
            ).stdout.strip()
            document = render_contract(
                args.root, environment=repository_environment(sha)
            )
        else:
            document = render_contract(args.root, env_file=args.env_file)
        validate_contract(document)
    except (ContractError, subprocess.SubprocessError) as error:
        print(f"Deployment preflight failed: {error}")
        return 1
    print("Production Compose contract is valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
