Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Integration check used by .github/workflows/slm_ps_exec_smoke.yml
#
# This script intentionally has *no* side effects besides running the smoke runner.
# It expects a portable Blender layout under tools/ (cached in CI) but also
# supports user-provided B L E N D E R _ E X E.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

$blenderExe = $env:BLENDER_EXE

if ([string]::IsNullOrWhiteSpace($blenderExe)) {
  # Prefer the portable *extracted* blender.exe (it must live beside its DLLs).
  $candidateExtracted = Join-Path $repoRoot 'tools\blender\4.2.14\extracted\blender-4.2.14-windows-x64\blender.exe'
  if (Test-Path $candidateExtracted) {
    $blenderExe = $candidateExtracted
  } else {
    # Fallback: any extracted\*\blender.exe (covers future platform naming changes)
    $glob = Join-Path $repoRoot 'tools\blender\4.2.14\extracted\*\blender.exe'
    $found = Get-ChildItem -LiteralPath (Split-Path $glob -Parent) -Filter 'blender.exe' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
      $blenderExe = $found.FullName
    } else {
      # Last resort: a copied blender.exe at tools\blender\4.2.14\blender.exe (may fail without adjacent DLLs)
      $candidate = Join-Path $repoRoot 'tools\blender\4.2.14\blender.exe'
      if (Test-Path $candidate) {
        $blenderExe = $candidate
      }
    }
  }
}

if ([string]::IsNullOrWhiteSpace($blenderExe) -or -not (Test-Path $blenderExe)) {
  throw @"
Blender executable not found.

- Set env var BLENDER_EXE to the full path to blender.exe
  OR
- Place portable Blender at: tools\\blender\\4.2.14\\blender.exe

In CI this is typically populated by scripts/get_blender_lts_portable.ps1.
"@
}

$runner = Join-Path $repoRoot 'slm-tool\scripts\run_blender_pipeline_smoke.ps1'

if (-not (Test-Path $runner)) {
  throw "Smoke runner missing: $runner"
}

& $runner -BlenderExe $blenderExe
