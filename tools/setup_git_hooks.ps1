[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = (& git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
    throw 'Run this command from a Git checkout.'
}

if (-not (Get-Command uvx -ErrorAction SilentlyContinue) -and
    -not (Get-Command pre-commit -ErrorAction SilentlyContinue)) {
    throw 'Install uv before configuring hooks: https://docs.astral.sh/uv/'
}

& git -C $repoRoot config core.hooksPath .githooks
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to configure core.hooksPath.'
}

Write-Host 'Git hooks configured from .githooks.'
