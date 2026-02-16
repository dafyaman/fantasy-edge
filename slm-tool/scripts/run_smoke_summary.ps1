param(
  [string]$BlenderExe = $env:BLENDER_EXE,
  [string]$Preset = 'prop',
  [string]$InputPath = "$PSScriptRoot\..\fixtures\cube.obj",
  [string]$OutDir,
  # Optional: write the single-line JSON summary to a deterministic file path.
  [string]$OutPath,
  [switch]$Quiet
)

function Resolve-BlenderExe {
  param([string]$Candidate)
  if ($Candidate -and (Test-Path $Candidate)) { return (Resolve-Path $Candidate).Path }

  $roots = @(
    (Resolve-Path (Join-Path $PSScriptRoot '..\..') -ErrorAction SilentlyContinue)?.Path,
    (Resolve-Path (Join-Path $PSScriptRoot '..\..\..') -ErrorAction SilentlyContinue)?.Path
  ) | Where-Object { $_ }

  foreach ($root in $roots) {
    $pinned = @(
      (Join-Path $root 'tools\blender\4.2.14\extracted\blender-4.2.14-windows-x64\blender.exe'),
      (Join-Path $root 'tools\blender\4.2.14\blender-4.2.14-windows-x64\blender.exe'),
      (Join-Path $root 'tools\blender\4.2.14\blender.exe')
    )
    foreach ($p in $pinned) {
      if (Test-Path $p) { return (Resolve-Path $p).Path }
    }
  }

  return $null
}

$ErrorActionPreference = 'Stop'

$smoke = Join-Path $PSScriptRoot 'run_blender_pipeline_smoke.ps1'
if (-not (Test-Path $smoke)) { throw "Missing smoke runner: $smoke" }

if (-not $OutDir) {
  $OutDir = "$PSScriptRoot\..\_runs\smoke-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

$resolvedBlender = Resolve-BlenderExe -Candidate $BlenderExe
if (-not $resolvedBlender) {
  throw "BlenderExe not found. Pass -BlenderExe or set BLENDER_EXE. Expected portable Blender at tools\\blender\\4.2.14\\..."
}

# Run the smoke pipeline and capture the single JSON line.
$jsonLine = & pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $smoke `
  -BlenderExe $resolvedBlender `
  -Preset $Preset `
  -InputPath $InputPath `
  -OutDir $OutDir `
  -SummaryOnly

if (-not $jsonLine) { throw 'Smoke summary produced no output.' }

try {
  $obj = $jsonLine | ConvertFrom-Json
} catch {
  throw "Smoke summary was not valid JSON. Raw: $jsonLine"
}

function Assert-HasKey {
  param($o, [string]$k, [string]$path)
  if (-not ($o.PSObject.Properties.Name -contains $k)) {
    throw "Missing key: $path$k"
  }
}

# Minimal schema validation (stable keys + expected nesting).
Assert-HasKey $obj 'ok' ''
Assert-HasKey $obj 'input' ''
Assert-HasKey $obj 'outDir' ''
Assert-HasKey $obj 'report' ''
Assert-HasKey $obj 'preset' ''
Assert-HasKey $obj 'noExport' ''
Assert-HasKey $obj 'saveBlend' ''
Assert-HasKey $obj 'artifacts' ''
Assert-HasKey $obj 'metrics' ''

Assert-HasKey $obj.artifacts 'dae' 'artifacts.'
Assert-HasKey $obj.artifacts 'blend' 'artifacts.'

Assert-HasKey $obj.metrics 'export_collada_dae_bytes' 'metrics.'
Assert-HasKey $obj.metrics 'export_collada_dae' 'metrics.'

if (-not $Quiet) {
  Write-Host 'OK: smoke summary schema validated.' -ForegroundColor Green
}

if ($OutPath) {
  $parent = Split-Path -Parent $OutPath
  if ($parent -and -not (Test-Path $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }
  # Ensure downstream tools get a clean, single-line UTF-8 JSON artifact.
  Set-Content -Path $OutPath -Value $jsonLine -Encoding utf8
  if (-not $Quiet) {
    Write-Host "OK: wrote smoke summary to: $OutPath" -ForegroundColor DarkGreen
  }
}

# Echo the JSON line so downstream tools can consume it.
$jsonLine
