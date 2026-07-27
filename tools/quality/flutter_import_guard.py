"""Frontiere d'architecture Flutter : la presentation n'importe pas le transport.

Regle (ADR 002, issue #235) : aucun fichier de presentation
(`lib/screens`, `lib/widgets`, `lib/providers`) ne doit importer le transport
reseau (`services/api_service.dart`, `services/i_api_client.dart`,
`package:http`, `package:dio`). Il doit passer par un use case / repository.

Les violations existantes sont gelees dans une allowlist decroissante : une
NOUVELLE violation fait echouer le controle ; l'allowlist ne peut que retrecir.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_POLICY_PATH = Path("tools/quality/flutter_import_policy.json")

# Dossiers de presentation soumis a la regle.
PRESENTATION_DIRS = (
    "mobile/lib/screens",
    "mobile/lib/widgets",
    "mobile/lib/providers",
)

# Imports interdits dans la presentation (transport reseau).
BANNED_IMPORT = re.compile(
    r"""^\s*import\s+['"]"""
    r"""(?:"""
    r"""package:http/|"""
    r"""package:dio/|"""
    r"""(?:package:cv_mobile/|[./]*)services/(?:api_service|i_api_client)\.dart"""
    r""")""",
    re.MULTILINE,
)


class PolicyError(RuntimeError):
    """La policy est absente ou malformee."""


@dataclass(frozen=True)
class Violation:
    path: str
    line: int
    statement: str


def _load_allowlist(policy_path: Path) -> set[str]:
    if not policy_path.exists():
        raise PolicyError(f"Policy introuvable : {policy_path}")
    try:
        data = json.loads(policy_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise PolicyError(f"Policy JSON invalide : {exc}") from exc
    return {entry["path"] for entry in data.get("allowlisted_files", [])}


def find_violations(root: Path) -> list[Violation]:
    """Retourne toutes les violations reelles (sans filtrer par allowlist)."""
    violations: list[Violation] = []
    for directory in PRESENTATION_DIRS:
        base = root / directory
        if not base.exists():
            continue
        for dart_file in sorted(base.rglob("*.dart")):
            text = dart_file.read_text(encoding="utf-8")
            for match in BANNED_IMPORT.finditer(text):
                line = text.count("\n", 0, match.start()) + 1
                rel = dart_file.relative_to(root).as_posix()
                violations.append(Violation(rel, line, match.group(0).strip()))
    return violations


def evaluate(root: Path, policy_path: Path) -> tuple[list[Violation], set[str]]:
    """Retourne (nouvelles violations, entrees d'allowlist devenues inutiles)."""
    allowlist = _load_allowlist(root / policy_path)
    violations = find_violations(root)
    offending_paths = {v.path for v in violations}
    new_violations = [v for v in violations if v.path not in allowlist]
    stale_allowlist = allowlist - offending_paths
    return new_violations, stale_allowlist


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Empeche la presentation Flutter d'importer le transport reseau."
    )
    parser.add_argument("--root", type=Path, default=REPOSITORY_ROOT)
    parser.add_argument("--policy", type=Path, default=DEFAULT_POLICY_PATH)
    args = parser.parse_args(argv)

    try:
        new_violations, stale = evaluate(args.root, args.policy)
    except PolicyError as exc:
        print(f"ERREUR policy : {exc}", file=sys.stderr)
        return 2

    exit_code = 0
    if new_violations:
        exit_code = 1
        print("NOUVELLES violations de frontiere (presentation -> transport) :")
        for v in new_violations:
            print(f"  {v.path}:{v.line}  {v.statement}")
        print(
            "\nLa presentation doit passer par un use case / repository (ADR 002).\n"
            "Si c'est un cas legitime a geler temporairement, ajoutez-le a "
            f"{args.policy} avec issue + expires_on."
        )
    if stale:
        exit_code = 1
        print("\nEntrees d'allowlist DEVENUES INUTILES (a supprimer, l'allowlist "
              "ne fait que retrecir) :")
        for path in sorted(stale):
            print(f"  {path}")

    if exit_code == 0:
        print("Frontiere presentation -> transport respectee.")
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
