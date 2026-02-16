Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Integration check: export-enabled Blender pipeline smoke run.
#
# Notes:
# - Blender 5.x on Windows may not ship the Collada add-on (io_scene_dae).
# - We pin portable Blender 4.2.14 LTS by default because Collada export is available there.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

$blenderExe = $env:BLENDER_EXE

if ([string]::IsNullOrWhiteSpace($blenderExe)) {
  # Prefer a portable Blender exe that lives beside its DLLs.
  # (Some local layouts extracted directly under tools\blender\4.2.14\blender-...)
  # The copied tools\blender\4.2.14\blender.exe may fail on CI with
  # "side-by-side configuration is incorrect" if the DLLs aren't alongside it.
  $candidates = @(
    (Join-Path $repoRoot 'tools\blender\4.2.14\extracted\blender-4.2.14-windows-x64\blender.exe'),
    (Join-Path $repoRoot 'tools\blender\4.2.14\blender-4.2.14-windows-x64\blender.exe'),
    (Join-Path $repoRoot 'tools\blender\4.2.14\blender.exe')
  )

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      $blenderExe = $candidate
      break
    }
  }

  if ([string]::IsNullOrWhiteSpace($blenderExe)) {
    # Fallback globs for future naming/layout changes.
    $found = Get-ChildItem -LiteralPath (Join-Path $repoRoot 'tools\blender\4.2.14') -Filter 'blender.exe' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
      $blenderExe = $found.FullName
    }
  }
}

if ([string]::IsNullOrWhiteSpace($blenderExe) -or -not (Test-Path $blenderExe)) {
  throw @"
Blender executable not found.

- Set env var BLENDER_EXE to the full path to blender.exe
  OR
- Place portable Blender extracted at: tools\\blender\\4.2.14\\extracted\\blender-4.2.14-windows-x64\\blender.exe
  (or copied exe at tools\\blender\\4.2.14\\blender.exe)

This export-enabled smoke run expects Blender 4.2.14 LTS (Collada exporter present).
"@
}

$runner = Join-Path $repoRoot 'slm-tool\scripts\run_blender_pipeline_smoke.ps1'

if (-not (Test-Path $runner)) {
  throw "Smoke runner missing: $runner"
}

$outDir = Join-Path $repoRoot ("slm-tool\\_runs\\export-smoke-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

& $runner -BlenderExe $blenderExe -NoExport 0 -SaveBlend 0 -OutDir $outDir

# Validate expected export artifacts exist (useful for CI signal).
$dae = Join-Path $outDir 'model.dae'
$report = Join-Path $outDir 'report.json'

if (-not (Test-Path $dae)) {
  throw "Expected export missing: $dae"
}

if (-not (Test-Path $report)) {
  throw "Expected report missing: $report"
}

$reportJson = Get-Content $report -Raw | ConvertFrom-Json
$daeBytes = $reportJson.export.collada_dae_bytes
if (-not $daeBytes -or $daeBytes -lt 1) {
  throw "Report indicates Collada export failed (export.collada_dae_bytes=$daeBytes). See: $report"
}

Write-Host "[check_ps_exec_export_smoke] OK: model.dae bytes=$daeBytes at $dae"
