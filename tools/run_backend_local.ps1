[CmdletBinding()]
param(
    [string]$EnvFile,
    [string]$DatabaseUrl
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($EnvFile)) {
    $candidates = @(
        (Join-Path $repoRoot "backend/.env"),
        (Join-Path $repoRoot ".env")
    )
    $EnvFile = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

    if ([string]::IsNullOrWhiteSpace($EnvFile)) {
        $worktreeRoots = & git -C $repoRoot worktree list --porcelain 2>$null |
            Where-Object { $_ -like "worktree *" } |
            ForEach-Object { $_.Substring("worktree ".Length) }
        $EnvFile = $worktreeRoots |
            ForEach-Object { Join-Path $_ ".env" } |
            Where-Object { Test-Path -LiteralPath $_ } |
            Select-Object -First 1
    }
}

if ([string]::IsNullOrWhiteSpace($EnvFile) -or -not (Test-Path -LiteralPath $EnvFile)) {
    throw "Fichier .env introuvable. Copiez .env.example vers .env, puis relancez cette tache."
}

foreach ($line in Get-Content -LiteralPath $EnvFile -Encoding utf8) {
    $trimmed = $line.Trim()
    if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#") -or -not $trimmed.Contains("=")) {
        continue
    }

    $parts = $trimmed -split "=", 2
    $name = $parts[0].Trim()
    $value = $parts[1].Trim()
    if ($value.Length -ge 2 -and
        (($value.StartsWith('"') -and $value.EndsWith('"')) -or
         ($value.StartsWith("'") -and $value.EndsWith("'")))) {
        $value = $value.Substring(1, $value.Length - 2)
    }
    [Environment]::SetEnvironmentVariable($name, $value, "Process")
}

if ([string]::IsNullOrWhiteSpace($env:DB_PASSWORD)) {
    throw "DB_PASSWORD est absent du fichier .env."
}

# Les noms postgres/redis ne sont resolvables que depuis le reseau Docker.
# Le port hote 5436 evite un conflit avec un PostgreSQL natif sur 5432.
if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) {
    $DatabaseUrl = "jdbc:postgresql://localhost:5436/cvmobile"
}

$env:DB_URL = $DatabaseUrl
$env:RATE_LIMIT_REDIS_URL = "redis://localhost:6379"
$env:UPLOAD_DIR = Join-Path $repoRoot "backend/uploads"

Write-Host "Base locale : $DatabaseUrl"

$backendDir = Join-Path $repoRoot "backend"
Push-Location $backendDir
try {
    & mvn.cmd spring-boot:run
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
