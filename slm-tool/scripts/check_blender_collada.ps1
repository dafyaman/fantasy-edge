# SLM-001 helper: check whether the current Blender build has the Collada (DAE) addon/module available.
# This is useful because some Blender 5.x distributions no longer ship io_scene_dae.
#
# Usage:
#   $env:BLENDER_EXE='C:\\Program Files\\Blender Foundation\\Blender 5.0\\blender.exe'
#   pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\slm-tool\scripts\check_blender_collada.ps1
#
# Exit codes:
#   0 = module present
#   2 = module missing
#   3 = Blender exe not found

[CmdletBinding()]
param(
  [string]$BlenderExe = $env:BLENDER_EXE
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-BlenderExe([string]$p) {
  if ($p -and (Test-Path -LiteralPath $p)) { return (Resolve-Path -LiteralPath $p).Path }
  return $null
}

$blender = Resolve-BlenderExe $BlenderExe
if (-not $blender) {
  Write-Host "[check_blender_collada] BLENDER_EXE missing or not found: '$BlenderExe'" -ForegroundColor Yellow
  Write-Host "[check_blender_collada] Tip: set env var BLENDER_EXE or pass -BlenderExe" -ForegroundColor Yellow
  exit 3
}

# Ask Blender's embedded Python if the module spec exists.
# NOTE: keep this a single line; Windows argument quoting + Blender parsing can be fragile with newlines.
$py = "import sys; import io_scene_dae; sys.stdout.write('HAS_IO_SCENE_DAE=1\\n'); sys.stdout.flush()"

$cmd = @(
  $blender,
  '-b',
  '-noaudio',
  '--factory-startup',
  '--python-expr',
  $py
)

Write-Host ('[check_blender_collada] Running: ' + ($cmd -join ' '))

# Run once in capture mode so we can both validate exit code and parse output.
# (In strict mode, $LASTEXITCODE may be unset until after a native process runs.)
$out = & $cmd[0] $cmd[1..($cmd.Count-1)] 2>&1
$exit = if (Test-Path variable:global:LASTEXITCODE) { $global:LASTEXITCODE } else { 0 }

if ($exit -ne 0) {
  Write-Host "[check_blender_collada] Blender exited non-zero ($exit). Treating as MISSING (likely ModuleNotFoundError)." -ForegroundColor Yellow
  Write-Host "[check_blender_collada] Last output lines:" -ForegroundColor Yellow
  ($out | Select-Object -Last 30) | ForEach-Object { Write-Host "  $_" }
  exit 2
}

$line = ($out | Where-Object { $_ -match '^HAS_IO_SCENE_DAE=' } | Select-Object -Last 1)

if (-not $line) {
  Write-Host "[check_blender_collada] Could not find HAS_IO_SCENE_DAE line in output." -ForegroundColor Yellow
  Write-Host "[check_blender_collada] Last output lines:" -ForegroundColor Yellow
  ($out | Select-Object -Last 30) | ForEach-Object { Write-Host "  $_" }
  Write-Host "[check_blender_collada] Assuming missing." -ForegroundColor Yellow
  exit 2
}

if ($line -match 'HAS_IO_SCENE_DAE=1') {
  Write-Host "[check_blender_collada] OK: Collada module present (io_scene_dae)." -ForegroundColor Green
  exit 0
}

Write-Host "[check_blender_collada] MISSING: Collada module not present (io_scene_dae)." -ForegroundColor Yellow
exit 2
