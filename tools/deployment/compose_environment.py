"""Discover host variables that can affect Compose interpolation."""

from __future__ import annotations

import re
from collections.abc import Iterable
from pathlib import Path

INTERPOLATION = re.compile(r"(?<!\$)\$(?:\{)?([A-Za-z_][A-Za-z0-9_]*)")


def interpolation_keys(paths: Iterable[Path]) -> frozenset[str]:
    keys: set[str] = set()
    for path in paths:
        keys.update(INTERPOLATION.findall(path.read_text(encoding="utf-8")))
    return frozenset(keys)
