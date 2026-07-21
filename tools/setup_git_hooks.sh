#!/usr/bin/env sh
set -eu

repo_root=$(git rev-parse --show-toplevel)

if ! command -v uvx >/dev/null 2>&1 && ! command -v pre-commit >/dev/null 2>&1; then
  echo "Install uv before configuring hooks: https://docs.astral.sh/uv/" >&2
  exit 1
fi

git -C "$repo_root" config core.hooksPath .githooks
echo "Git hooks configured from .githooks."
