# Local release pipeline

This pipeline mirrors the blocking CI checks without requiring GitHub Actions.
It uses repository-owned Python 3.12.13 code, Docker, Maven, Flutter, Dart and
Playwright. Python dependencies are reproducibly installed from `uv.lock`.

## One-time hook setup

Windows:

```powershell
.\tools\setup_git_hooks.ps1
```

Linux/macOS:

```bash
./tools/setup_git_hooks.sh
```

The tracked hook runs the 300-line policy and scans the exact Git index. If a
native Gitleaks executable is unavailable, the pinned Docker image is used.

## Verify a candidate

The default requires a clean working tree:

```powershell
.\tools\release_local.ps1 verify
```

While developing the release tooling itself, `verify --allow-dirty` is allowed.
Dirty images receive a `-dirty` suffix and can never be published.

The command runs repository and deployment-contract tests, the real production
Compose preflight, source policy, Gitleaks, backend verification, Flutter
analysis/tests/coverage, Docker builds, Trivy scans and an isolated browser E2E
flow against the production images. Install Google Chrome, or set
`CHROME_EXECUTABLE` to a Chromium-compatible executable. The smoke Compose
project is always removed, including its volumes.

Validate a production environment file without printing rendered secrets:

```powershell
uv run --locked python -m tools.deployment.compose_contract `
  --env-file .env.production
```

## Publish immutable images

Authenticate Docker to GHCR, check out the exact `origin/main` commit, then run:

```powershell
.\tools\release_local.ps1 publish
```

Only full Git SHA tags are pushed. `latest` is intentionally never created.
A manifest containing the commit and local image IDs is written below
`.release/<sha>/manifest.json`.
