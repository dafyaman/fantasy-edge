param(
  [Parameter(Mandatory=$false)]
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..") ).Path
)

$ErrorActionPreference = 'Stop'

Write-Host "[check_preflight] RepoRoot=$RepoRoot"

$checkPrintOnly = Join-Path $RepoRoot 'slm-tool\scripts\check_ps_printonly.ps1'
$checkPrintOnlyRegression = Join-Path $RepoRoot 'slm-tool\scripts\check_ps_printonly_regression.ps1'
$checkPyCompile = Join-Path $RepoRoot 'slm-tool\scripts\check_py_compile.ps1'
$checkFixtures = Join-Path $RepoRoot 'slm-tool\scripts\check_fixtures.ps1'

if (-not (Test-Path $checkPrintOnly)) { throw "Missing: $checkPrintOnly" }
if (-not (Test-Path $checkPrintOnlyRegression)) { throw "Missing: $checkPrintOnlyRegression" }
if (-not (Test-Path $checkPyCompile)) { throw "Missing: $checkPyCompile" }
if (-not (Test-Path $checkFixtures)) { throw "Missing: $checkFixtures" }

pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $checkPyCompile
pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $checkFixtures
pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $checkPrintOnly
pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $checkPrintOnlyRegression

Write-Host "[check_preflight] OK"