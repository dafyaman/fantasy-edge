<#
.SYNOPSIS
  Downloads and unpacks a portable Blender release into tools/blender/<version>/.

.DESCRIPTION
  This is meant to make SLM-001 smoke runs reproducible on Windows by pinning a
  known-good Blender 4.2 LTS portable zip.

  Default version is 4.2.14 (referenced by historical SLM run report).

  NOTE: This script downloads a large zip (~400MB). It is not run automatically.

.EXAMPLE
  pwsh -NoProfile -ExecutionPolicy Bypass -File tools/blender/get_blender_portable.ps1

.EXAMPLE
  pwsh -NoProfile -ExecutionPolicy Bypass -File tools/blender/get_blender_portable.ps1 -Version 4.2.17
#>

[CmdletBinding()]
param(
  [Parameter()][string]$Version = '4.2.14',
  [Parameter()][ValidateSet('windows-x64')][string]$Platform = 'windows-x64',
  [Parameter()][string]$DestRoot = (Join-Path $PSScriptRoot $Version),
  [Parameter()][switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ReleaseUrl([string]$version, [string]$platform) {
  # NOTE: GitHub Actions runners sometimes end up with an empty/invalid zip when
  # downloading via blender.org redirect URLs.
  # Use the canonical CDN URL directly to avoid redirects.
  return "https://download.blender.org/release/Blender4.2/blender-$version-$platform.zip"
}

$zipName = "blender-$Version-$Platform.zip"
$downloadDir = Join-Path $PSScriptRoot '_downloads'
$zipPath = Join-Path $downloadDir $zipName

if (-not (Test-Path -LiteralPath $downloadDir)) {
  New-Item -ItemType Directory -Path $downloadDir | Out-Null
}

if ((Test-Path -LiteralPath $DestRoot) -and -not $Force) {
  Write-Host "Destination already exists: $DestRoot" -ForegroundColor Yellow
  Write-Host "Pass -Force to overwrite." -ForegroundColor Yellow
  exit 2
}

if ($Force -and (Test-Path -LiteralPath $DestRoot)) {
  Remove-Item -Recurse -Force -LiteralPath $DestRoot
}

$url = Get-ReleaseUrl -version $Version -platform $Platform
Write-Host "Downloading: $url"
Write-Host "To: $zipPath"

Invoke-WebRequest -Uri $url -OutFile $zipPath -UserAgent 'Mozilla/5.0 (OpenClaw SLM-001)'

$zipBytes = (Get-Item $zipPath).Length
Write-Host "Downloaded OK ($([Math]::Round(($zipBytes / 1MB), 1)) MB)"

# Quick sanity check: Blender zips are hundreds of MB. If we got something tiny,
# it's almost certainly an HTML error page or a failed download.
if ($zipBytes -lt 50MB) {
  Write-Host "ERROR: Downloaded zip is unexpectedly small ($zipBytes bytes): $zipPath" -ForegroundColor Red
  Write-Host "URL was: $url" -ForegroundColor Red
  exit 4
}

Write-Host "Extracting to: $DestRoot"
Expand-Archive -Path $zipPath -DestinationPath $DestRoot

# Blender zips usually contain a top-level folder like blender-4.2.14-windows-x64\blender.exe.
$exe = Get-ChildItem -LiteralPath $DestRoot -Recurse -Filter blender.exe -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $exe) {
  Write-Host "ERROR: blender.exe not found after extraction under: $DestRoot" -ForegroundColor Red
  exit 3
}

Write-Host "FOUND_BLENDER_EXE=$($exe.FullName)"
Write-Host "Tip: set `$env:BLENDER_EXE to that path, or copy/move so tools/blender/$Version/blender.exe exists."