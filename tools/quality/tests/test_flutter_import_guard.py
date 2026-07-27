"""Tests du garde-fou de frontiere Flutter (presentation -> transport, #235)."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from flutter_import_guard import (  # noqa: E402
    PolicyError,
    evaluate,
    find_violations,
    main,
)


def _write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _write_policy(root: Path, paths: list[str]) -> Path:
    policy = root / "tools/quality/flutter_import_policy.json"
    entries = [{"path": p, "issue": "#237", "expires_on": "2027-01-31"} for p in paths]
    _write(policy, json.dumps({"version": 1, "allowlisted_files": entries}))
    return Path("tools/quality/flutter_import_policy.json")


class FindViolationsTest(unittest.TestCase):
    def test_detects_banned_api_service_import(self) -> None:
        root = Path(self.enterContext(_tmp()))
        _write(
            root / "mobile/lib/widgets/foo.dart",
            "import 'package:cv_mobile/services/api_service.dart';\n"
            "class Foo {}\n",
        )
        violations = find_violations(root)
        self.assertEqual(len(violations), 1)
        self.assertEqual(violations[0].path, "mobile/lib/widgets/foo.dart")
        self.assertEqual(violations[0].line, 1)

    def test_detects_relative_i_api_client_import(self) -> None:
        root = Path(self.enterContext(_tmp()))
        _write(
            root / "mobile/lib/screens/bar.dart",
            "import '../services/i_api_client.dart';\n",
        )
        self.assertEqual(len(find_violations(root)), 1)

    def test_detects_package_http_import(self) -> None:
        root = Path(self.enterContext(_tmp()))
        _write(
            root / "mobile/lib/providers/baz.dart",
            "import 'package:http/http.dart' as http;\n",
        )
        self.assertEqual(len(find_violations(root)), 1)

    def test_ignores_legitimate_domain_import(self) -> None:
        root = Path(self.enterContext(_tmp()))
        _write(
            root / "mobile/lib/widgets/ok.dart",
            "import 'package:cv_mobile/usecases/cv/get_all_cvs_usecase.dart';\n",
        )
        self.assertEqual(find_violations(root), [])

    def test_ignores_files_outside_presentation(self) -> None:
        root = Path(self.enterContext(_tmp()))
        # Un data source a le DROIT d'importer le transport.
        _write(
            root / "mobile/lib/repositories/cv_repository.dart",
            "import 'package:cv_mobile/services/api_service.dart';\n",
        )
        self.assertEqual(find_violations(root), [])


class EvaluateTest(unittest.TestCase):
    def test_allowlisted_violation_is_not_reported_as_new(self) -> None:
        root = Path(self.enterContext(_tmp()))
        _write(
            root / "mobile/lib/widgets/legacy.dart",
            "import 'package:cv_mobile/services/api_service.dart';\n",
        )
        policy = _write_policy(root, ["mobile/lib/widgets/legacy.dart"])
        new_violations, stale = evaluate(root, policy)
        self.assertEqual(new_violations, [])
        self.assertEqual(stale, set())

    def test_new_violation_outside_allowlist_is_reported(self) -> None:
        root = Path(self.enterContext(_tmp()))
        _write(
            root / "mobile/lib/widgets/fresh.dart",
            "import 'package:cv_mobile/services/api_service.dart';\n",
        )
        policy = _write_policy(root, [])  # allowlist vide
        new_violations, _ = evaluate(root, policy)
        self.assertEqual(len(new_violations), 1)
        self.assertEqual(new_violations[0].path, "mobile/lib/widgets/fresh.dart")

    def test_stale_allowlist_entry_is_flagged(self) -> None:
        root = Path(self.enterContext(_tmp()))
        # Fichier propre (aucun import interdit) mais encore dans l'allowlist.
        _write(root / "mobile/lib/widgets/clean.dart", "class Clean {}\n")
        policy = _write_policy(root, ["mobile/lib/widgets/clean.dart"])
        _, stale = evaluate(root, policy)
        self.assertIn("mobile/lib/widgets/clean.dart", stale)

    def test_missing_policy_raises(self) -> None:
        root = Path(self.enterContext(_tmp()))
        with self.assertRaises(PolicyError):
            evaluate(root, Path("tools/quality/does_not_exist.json"))


class MainExitCodeTest(unittest.TestCase):
    def test_main_returns_1_on_new_violation(self) -> None:
        root = Path(self.enterContext(_tmp()))
        _write(
            root / "mobile/lib/screens/leak.dart",
            "import 'package:cv_mobile/services/i_api_client.dart';\n",
        )
        policy = _write_policy(root, [])
        self.assertEqual(main(["--root", str(root), "--policy", str(policy)]), 1)

    def test_main_returns_0_when_clean(self) -> None:
        root = Path(self.enterContext(_tmp()))
        _write(root / "mobile/lib/widgets/ok.dart", "class Ok {}\n")
        policy = _write_policy(root, [])
        self.assertEqual(main(["--root", str(root), "--policy", str(policy)]), 0)


def _tmp():
    import tempfile

    return tempfile.TemporaryDirectory()


if __name__ == "__main__":
    unittest.main()
