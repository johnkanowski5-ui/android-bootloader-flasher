$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$distDir = Join-Path $repoRoot "dist"
$installerDir = Join-Path $repoRoot "installer"
$issPath = Join-Path $installerDir "AndroidBootloaderFlasher.iss"

if (-not (Test-Path $installerDir)) {
    New-Item -ItemType Directory -Path $installerDir -Force | Out-Null
}

if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}

$isscc = Get-Command iscc -ErrorAction SilentlyContinue
if (-not $isscc) {
    throw "Inno Setup is required. Install Inno Setup and ensure iscc.exe is on PATH."
}

$scriptSource = Join-Path $repoRoot "AndroidBootloaderFlasher.ps1"
if (-not (Test-Path $scriptSource)) {
    throw "AndroidBootloaderFlasher.ps1 was not found in the repository root."
}

Write-Host "Building Windows installer..."
& $isscc.Source $issPath

if ($LASTEXITCODE -ne 0) {
    throw "Installer build failed."
}

Write-Host "Installer created in: $distDir"
