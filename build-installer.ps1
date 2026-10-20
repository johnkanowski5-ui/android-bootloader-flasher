$ErrorActionPreference = "Stop"

$version = "1.1.0"
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$distDir = Join-Path $repoRoot "dist"
$installerDir = Join-Path $repoRoot "installer"
$issPath = Join-Path $installerDir "AndroidBootloaderFlasher.iss"
$scriptSource = Join-Path $repoRoot "AndroidBootloaderFlasher.ps1"
$packageFiles = @(
    $scriptSource,
    (Join-Path $repoRoot "README.md"),
    (Join-Path $repoRoot "DOWNLOAD_INSTALL.md"),
    (Join-Path $repoRoot "RELEASE_NOTES.md")
)

if (-not (Test-Path -LiteralPath $installerDir)) {
    throw "The installer directory was not found."
}
if (-not (Test-Path -LiteralPath $issPath)) {
    throw "The Inno Setup script was not found: $issPath"
}
if (-not (Test-Path -LiteralPath $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}

foreach ($file in $packageFiles) {
    if (-not (Test-Path -LiteralPath $file)) {
        throw "A required package file was not found: $file"
    }
}

$isscc = Get-Command iscc -ErrorAction SilentlyContinue
if ($isscc) {
    $issccPath = $isscc.Source
}
else {
    $candidateCompilers = @(
        (Join-Path $env:ProgramFiles(x86) "Inno Setup 6\ISCC.exe"),
        (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe")
    )
    $issccPath = $candidateCompilers | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $issccPath) {
    throw "Inno Setup is required. Install Inno Setup and ensure iscc.exe is on PATH."
}

Write-Host "Building Android Bootloader Flasher v$version installer..."
& $issccPath $issPath
if ($LASTEXITCODE -ne 0) {
    throw "Installer build failed."
}

$zipPath = Join-Path $distDir "AndroidBootloaderFlasher-v$version.zip"
$packageDir = Join-Path $env:TEMP ("AndroidBootloaderFlasher-" + [Guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Path $packageDir -Force | Out-Null
    foreach ($file in $packageFiles) {
        Copy-Item -LiteralPath $file -Destination $packageDir
    }
    Compress-Archive -Path (Join-Path $packageDir "*") -DestinationPath $zipPath -Force
}
finally {
    if (Test-Path -LiteralPath $packageDir) {
        Remove-Item -LiteralPath $packageDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Installer and portable ZIP created in: $distDir"
