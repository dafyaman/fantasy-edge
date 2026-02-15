# Regression check: slm.ps1 run -PrintOnly should not execute Blender.
# Verifies:
#  - Output includes: "PrintOnly enabled: not executing Blender."
#  - Output does NOT include a Blender *version banner* line (e.g. "Blender 4.2.14").
#
# Usage:
#   pwsh -NoProfile -File slm-tool/scripts/check_ps_printonly_regression.ps1

[CmdletBinding()]
param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'

$slm = Join-Path $RepoRoot 'slm-tool\scripts\slm.ps1'
if (!(Test-Path $slm)) { throw "Missing slm shim: $slm" }

# Capture output so we can assert on it.
$out = & pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $slm run -PrintOnly 2>&1 | Out-String

if ($out -notmatch [regex]::Escape('PrintOnly enabled: not executing Blender.')) {
  Write-Host $out
  throw 'Expected PrintOnly confirmation line was not found.'
}

# A version banner typically starts a line with "Blender <version>".
if ($out -match "(?m)^Blender\s+\d") {
  Write-Host $out
  throw 'Unexpected Blender version banner detected; PrintOnly may have executed Blender.'
}

Write-Host '[check_ps_printonly_regression] OK'
