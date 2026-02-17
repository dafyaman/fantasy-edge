<#
SLM-001: Blender-free OBJ validator (minimal sanity).

Goals:
- Fail fast if an OBJ is missing or empty.
- Confirm it has at least one vertex (v) and one face (f).
- Avoid any heavy parsing; this is meant for tiny fixtures and quick preflight.

Exit codes:
- 0: OK
- 2: Invalid (missing/empty/no vertex/no face)

Example:
  pwsh -NoProfile -File slm-tool/scripts/validate_obj.ps1 -Path slm-tool/fixtures/cube.obj
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [Alias('InputPath')]
  [string]$Path
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
  Write-Error "[validate_obj] Missing file: $Path"
  exit 2
}

$fi = Get-Item -LiteralPath $Path
if ($fi.Length -le 0) {
  Write-Error "[validate_obj] Empty file: $Path"
  exit 2
}

# Read as text. OBJ is ASCII-ish; we don't need strict encoding here.
$lines = Get-Content -LiteralPath $Path -ErrorAction Stop

$hasVertex = $false
$hasFace = $false
foreach ($line in $lines) {
  if (-not $hasVertex -and $line -match '^\s*v\s+') { $hasVertex = $true }
  if (-not $hasFace   -and $line -match '^\s*f\s+') { $hasFace = $true }
  if ($hasVertex -and $hasFace) { break }
}

if (-not $hasVertex) {
  Write-Error "[validate_obj] Invalid OBJ: no vertex lines ('v ...') found: $Path"
  exit 2
}
if (-not $hasFace) {
  Write-Error "[validate_obj] Invalid OBJ: no face lines ('f ...') found: $Path"
  exit 2
}

Write-Output "[validate_obj] OK: $($fi.FullName) bytes=$($fi.Length) hasVertex=$hasVertex hasFace=$hasFace"
exit 0
