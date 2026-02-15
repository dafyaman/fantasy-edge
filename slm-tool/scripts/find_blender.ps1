<#
.SYNOPSIS
  Locate Blender executable on Windows and print the best candidate path.

.DESCRIPTION
  Used by SLM-001 tooling to help users quickly supply -BlenderExe / BLENDER_EXE.
  This script does NOT install Blender.

.OUTPUTS
  Writes lines describing where it looked and the resolved path (if found).
  Exits 0 if found, 1 if not.
#>

[CmdletBinding()]
param(
  [string[]]$AdditionalPaths = @()
)

$ErrorActionPreference = 'Stop'

function Test-BlenderExe([string]$p) {
  if (-not $p) { return $false }
  try {
    $full = [System.IO.Path]::GetFullPath($p)
  } catch { return $false }
  return (Test-Path -LiteralPath $full -PathType Leaf) -and ($full.ToLowerInvariant().EndsWith('blender.exe'))
}

$checked = New-Object System.Collections.Generic.List[string]
$candidates = New-Object System.Collections.Generic.List[string]

# 1) Env var
if ($env:BLENDER_EXE) {
  $candidates.Add($env:BLENDER_EXE)
}

# 2) PATH
try {
  $cmd = Get-Command blender -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source) { $candidates.Add($cmd.Source) }
} catch {}

# 3) Repo portable location convention
$candidates.Add((Join-Path $PSScriptRoot '..\..\..\tools\blender\4.2.14\blender.exe'))

# 4) Common install locations
$pf = ${env:ProgramFiles}
$pfx86 = ${env:ProgramFiles(x86)}
$local = $env:LOCALAPPDATA

foreach ($p in @(
  (Join-Path $pf 'Blender Foundation\Blender\blender.exe'),
  (Join-Path $pf 'Blender Foundation\Blender 4.2\blender.exe'),
  (Join-Path $pf 'Blender Foundation\Blender 4.2 LTS\blender.exe'),
  (Join-Path $pfx86 'Blender Foundation\Blender\blender.exe'),
  (Join-Path $local 'Programs\Blender Foundation\Blender\blender.exe'),
  (Join-Path $local 'Programs\Blender Foundation\Blender 4.2\blender.exe')
)) {
  $candidates.Add($p)
}

# 4b) Versioned install folders (wildcards)
# Covers cases like:
#   C:\Program Files\Blender Foundation\Blender 4.3\blender.exe
#   C:\Program Files\Blender Foundation\Blender 4.2 LTS\blender.exe
foreach ($root in @(
  (Join-Path $pf 'Blender Foundation'),
  (Join-Path $pfx86 'Blender Foundation'),
  (Join-Path $local 'Programs\Blender Foundation')
)) {
  if (-not $root) { continue }
  if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
  try {
    Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like 'Blender*' } |
      ForEach-Object {
        $exe = Join-Path $_.FullName 'blender.exe'
        if ($exe) { $candidates.Add($exe) }
      }
  } catch {}
}

# 5) User-provided
if ($AdditionalPaths) {
  foreach ($p in $AdditionalPaths) { $candidates.Add($p) }
}

# De-dupe while preserving order
$seen = @{}
$unique = foreach ($p in $candidates) {
  if (-not $p) { continue }
  $key = $p.ToLowerInvariant()
  if ($seen.ContainsKey($key)) { continue }
  $seen[$key] = $true
  $p
}

$found = $null
foreach ($p in $unique) {
  $checked.Add($p)
  if (Test-BlenderExe $p) { $found = [System.IO.Path]::GetFullPath($p); break }
}

if ($found) {
  Write-Host "FOUND=$found"
  exit 0
}

Write-Host 'NOT_FOUND'
Write-Host 'Checked:'
$checked | ForEach-Object { Write-Host "  - $_" }
Write-Host ''
Write-Host 'Tip: install via winget:'
Write-Host '  winget install -e --id BlenderFoundation.Blender'
exit 1
