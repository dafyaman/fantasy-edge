param(
  [Parameter(Mandatory=$false)]
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..") ).Path
)

$ErrorActionPreference = 'Stop'

$fixturesDir = Join-Path $RepoRoot 'slm-tool\fixtures'
$readme = Join-Path $fixturesDir 'README.md'
$cubeObj = Join-Path $fixturesDir 'cube.obj'

Write-Host "[check_fixtures] RepoRoot=$RepoRoot"
Write-Host "[check_fixtures] FixturesDir=$fixturesDir"

if (-not (Test-Path $fixturesDir)) { throw "Missing fixtures dir: $fixturesDir" }
if (-not (Test-Path $readme)) { throw "Missing fixture README: $readme" }
if (-not (Test-Path $cubeObj)) { throw "Missing required fixture: $cubeObj" }

$info = Get-Item -LiteralPath $cubeObj
if ($info.Length -le 0) { throw "Fixture is empty: $cubeObj" }
if ($info.Length -gt 1048576) { throw "Fixture is unexpectedly large (>1MB): $cubeObj ($($info.Length) bytes)" }

Write-Host "[check_fixtures] OK: cube.obj bytes=$($info.Length)"
