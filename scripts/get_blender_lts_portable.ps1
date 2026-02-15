<#
.SYNOPSIS
  CI/dev helper to ensure portable Blender 4.2 LTS exists under tools/blender/<version>/.

.DESCRIPTION
  Wrapper around tools/blender/get_blender_portable.ps1.
  - In CI, pass -ConfirmDownload to allow downloading (~400MB).
  - Ensures tools/blender/<version>/blender.exe exists (copies from extracted folder if needed).

.EXAMPLE
  pwsh -NoProfile -File scripts/get_blender_lts_portable.ps1 -Version 4.2.14 -ConfirmDownload
#>

[CmdletBinding()]
param(
  [Parameter()][string]$Version = '4.2.14',
  [Parameter()][switch]$ConfirmDownload,
  [Parameter()][switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$toolsScript = Join-Path $repoRoot 'tools/blender/get_blender_portable.ps1'

if (-not (Test-Path -LiteralPath $toolsScript)) {
  throw "Expected downloader script not found: $toolsScript"
}

$destDir = Join-Path $repoRoot (Join-Path 'tools/blender' $Version)
$expectedExe = Join-Path $destDir 'blender.exe'

if (Test-Path -LiteralPath $expectedExe) {
  Write-Host "OK: $expectedExe already exists"
  exit 0
}

if (-not $ConfirmDownload) {
  Write-Host "Portable Blender not present at: $expectedExe" -ForegroundColor Yellow
  Write-Host "Re-run with -ConfirmDownload to download + extract Blender $Version (~400MB)." -ForegroundColor Yellow
  exit 2
}

# Download/extract into tools/blender/<version>/...
$downloadArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File', $toolsScript, '-Version', $Version)
if ($Force) { $downloadArgs += '-Force' }

& pwsh @downloadArgs
if ($LASTEXITCODE -ne 0) {
  throw "Downloader failed with exit code $LASTEXITCODE"
}

# After extraction, copy the first discovered blender.exe to tools/blender/<version>/blender.exe
$found = Get-ChildItem -LiteralPath $destDir -Recurse -Filter blender.exe -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $found) {
  throw "blender.exe not found under: $destDir"
}

Copy-Item -LiteralPath $found.FullName -Destination $expectedExe -Force

if (-not (Test-Path -LiteralPath $expectedExe)) {
  throw "Failed to create expected blender.exe at: $expectedExe"
}

Write-Host "OK: ensured portable Blender at: $expectedExe"
