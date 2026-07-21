[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ReleaseArguments
)

$ErrorActionPreference = 'Stop'
$repoRoot = (& git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
    throw 'Run this command from a Git checkout.'
}
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    throw 'uv is required: https://docs.astral.sh/uv/'
}

Push-Location $repoRoot
try {
    & uv run --locked --python 3.12.13 python -m tools.release.cli @ReleaseArguments
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
