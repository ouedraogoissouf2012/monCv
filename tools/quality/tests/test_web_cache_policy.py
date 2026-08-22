"""Garde-fou sur la politique de cache HTTP du bundle web.

Aucun fichier produit par `flutter build web` n'est versionne par son nom :
`main.dart.js`, `flutter_bootstrap.js`, `assets/` et `canvaskit/` conservent la
meme URL d'un build a l'autre. Les servir avec un `max-age` positif et sans
revalidation fait executer du code perime apres chaque deploiement, pendant toute
la duree du cache.

Ce garde-fou echoue si cette politique reapparait. Il est decouvert
automatiquement par l'etape CI `unittest discover -s tools/quality/tests`.
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
NGINX_CONFIGURATION = REPOSITORY_ROOT / "mobile" / "deploy" / "nginx" / "default.conf"

CACHE_CONTROL_PATTERN = re.compile(r'add_header\s+Cache-Control\s+"([^"]+)"')
POSITIVE_MAX_AGE_PATTERN = re.compile(r"max-age=([1-9]\d*)")

REVALIDATING_DIRECTIVES = ("no-cache", "no-store")

STRICTER_BLOCKS = {
    "location = /healthz {": "no-store",
    "location = /index.html {": "no-store",
    "location = /flutter_service_worker.js {": "no-store",
    "location /downloads/ {": "no-store",
    "location = /sw.js {": "no-store",
}


def extract_block(configuration: str, header: str) -> str:
    """Retourne le corps du bloc nginx introduit par `header`, accolades exclues."""
    header_index = configuration.find(header)
    if header_index == -1:
        raise AssertionError(f"Bloc absent de la configuration : {header!r}")
    opening_index = configuration.index("{", header_index)
    depth = 0
    for index in range(opening_index, len(configuration)):
        character = configuration[index]
        if character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
            if depth == 0:
                return configuration[opening_index + 1 : index]
    raise AssertionError(f"Bloc non ferme : {header!r}")


class WebCachePolicyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.configuration = NGINX_CONFIGURATION.read_text(encoding="utf-8")

    def cache_control_of(self, header: str) -> str:
        block = extract_block(self.configuration, header)
        match = CACHE_CONTROL_PATTERN.search(block)
        if match is None:
            raise AssertionError(f"Aucun en-tete Cache-Control dans le bloc {header!r}")
        return match.group(1)

    def test_root_location_forces_revalidation(self) -> None:
        directive = self.cache_control_of("location / {")
        self.assertTrue(
            any(token in directive for token in REVALIDATING_DIRECTIVES),
            "Le bundle web n'est versionne par aucun hash : le bloc `location /` doit "
            f"imposer une revalidation, or il sert {directive!r}.",
        )

    def test_no_positive_max_age_on_unversioned_content(self) -> None:
        offenders = [
            directive
            for directive in CACHE_CONTROL_PATTERN.findall(self.configuration)
            if POSITIVE_MAX_AGE_PATTERN.search(directive)
        ]
        self.assertEqual(
            offenders,
            [],
            "Un max-age positif est reapparu sur du contenu non versionne. Ne lever "
            "cette regle que le jour ou les assets porteront un hash dans leur nom.",
        )

    def test_stricter_blocks_keep_their_policy(self) -> None:
        for header, expected_token in STRICTER_BLOCKS.items():
            with self.subTest(block=header):
                self.assertIn(expected_token, self.cache_control_of(header))

    def test_extract_block_rejects_an_unknown_header(self) -> None:
        with self.assertRaises(AssertionError):
            extract_block(self.configuration, "location /absent-de-la-configuration {")


if __name__ == "__main__":
    unittest.main()
