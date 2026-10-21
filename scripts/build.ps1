# JO-Launcher Windows packaging script
#
# Usage (pwsh, PowerShell 7):
#   pwsh -ExecutionPolicy Bypass -File scripts\build.ps1
#
# Output goes to dist/.
#
# Note: Linux builds cannot be cross-compiled from Windows. Build on Linux or
# GitHub Actions ubuntu-latest: flutter build linux --release

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$dist = Join-Path $root "dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null

Write-Host "== 1/2  Windows release ==" -ForegroundColor Cyan
# Flutter's Windows version info is injected at CMake configure time; incremental
# builds do not refresh it. Remove build\windows to force a clean rebuild with the
# correct version / identity.
Remove-Item -Recurse -Force "build\windows" -ErrorAction SilentlyContinue

# The Microsoft application client_id does not go into the repository; inject it
# from an environment variable. The app still builds without it; only sign-in is
# unavailable.
$defines = @()
if ($env:JO_MS_CLIENT_ID) {
  $defines += "--dart-define=JO_MS_CLIENT_ID=$env:JO_MS_CLIENT_ID"
} else {
  Write-Warning "JO_MS_CLIENT_ID is not set; the built app will not be able to sign in to Microsoft accounts."
}
flutter build windows --release @defines

Write-Host "== 2/2  Inno Setup installer ==" -ForegroundColor Cyan

# Single source of truth for the version: pubspec.yaml's version
$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -notmatch '(?m)^version:\s*(\S+)') { throw "version not found in pubspec.yaml" }
$full = $Matches[1]                 # e.g. 0.1.0+1
$ver = ($full -split '\+')[0]        # e.g. 0.1.0
Write-Host "  Version: $full (version $ver)"

$iscc = @(
  "C:\Program Files\Inno Setup 7\ISCC.exe",
  "C:\Program Files (x86)\Inno Setup 7\ISCC.exe",
  "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw "ISCC.exe not found; install Inno Setup first." }
& $iscc "/DMyAppVersion=$ver" "/DMyAppFullVersion=$full" "installer\JO-Launcher.iss"
if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed with exit code $LASTEXITCODE" }

Write-Host "`n== dist output ==" -ForegroundColor Green
Get-ChildItem $dist | Select-Object Name, @{n='MB';e={[math]::Round($_.Length/1MB,1)}} | Format-Table
