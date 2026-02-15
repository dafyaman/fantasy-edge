param(
  # Path to blender.exe (overrides env:BLENDER_EXE). If omitted, we try env:BLENDER_EXE and common install paths.
  [string]$BlenderExe = $env:BLENDER_EXE,

  # Mesh input (OBJ/FBX/etc supported by Blender). If omitted, falls back to the cube fixture.
  [string]$InputPath = "$PSScriptRoot\..\fixtures\cube.obj",

  # Output directory. Defaults to slm-tool/_runs/run-<timestamp>.
  [string]$OutDir = "$PSScriptRoot\..\_runs\run-$(Get-Date -Format 'yyyyMMdd-HHmmss')",

  # Pipeline preset (see blender_sl_pipeline.py).
  [string]$Preset = "prop",

  # Export toggles.
  [bool]$NoExport = $true,
  [bool]$SaveBlend = $false,

  # Print the Blender command line and exit 0 (does not require Blender to exist).
  [switch]$PrintOnly,

  # Emit a single machine-readable JSON summary line to stdout.
  [switch]$SummaryOnly
)

$ErrorActionPreference = 'Stop'

function Resolve-BlenderExe {
  param([string]$Candidate)
  if ($Candidate -and (Test-Path $Candidate)) { return (Resolve-Path $Candidate).Path }

  $common = @(
    "$env:ProgramFiles\Blender Foundation\Blender\blender.exe",
    "$env:ProgramFiles\Blender Foundation\Blender 4.2\blender.exe",
    "$env:ProgramFiles\Blender Foundation\Blender 4.3\blender.exe",
    "$env:ProgramFiles\Blender Foundation\Blender 4.4\blender.exe",
    "$env:ProgramFiles\Blender Foundation\Blender 5.0\blender.exe",
    "$env:ProgramFiles(x86)\Steam\steamapps\common\Blender\blender.exe",
    "$PSScriptRoot\..\..\tools\blender\4.2.14\blender.exe",
    "$PSScriptRoot\..\..\tools\blender\4.2.14\extracted\blender-4.2.14-windows-x64\blender.exe"
  )

  foreach ($p in $common) {
    if ($p -and (Test-Path $p)) { return (Resolve-Path $p).Path }
  }

  $cmd = Get-Command blender -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  return $null
}

$commonChecked = @(
  "$env:ProgramFiles\Blender Foundation\Blender\blender.exe",
  "$env:ProgramFiles\Blender Foundation\Blender 4.2\blender.exe",
  "$env:ProgramFiles\Blender Foundation\Blender 4.3\blender.exe",
  "$env:ProgramFiles\Blender Foundation\Blender 4.4\blender.exe",
  "$env:ProgramFiles\Blender Foundation\Blender 5.0\blender.exe",
  "$env:ProgramFiles(x86)\Steam\steamapps\common\Blender\blender.exe",
  "$PSScriptRoot\..\..\tools\blender\4.2.14\blender.exe",
  "$PSScriptRoot\..\..\tools\blender\4.2.14\extracted\blender-4.2.14-windows-x64\blender.exe"
)

$blender = Resolve-BlenderExe -Candidate $BlenderExe
if (-not $blender) {
  if ($PrintOnly) {
    $blender = '<BLENDER_EXE_NOT_FOUND>'
  } else {
    if (-not $SummaryOnly) {
      Write-Host "ERROR: Blender not found." -ForegroundColor Red
      Write-Host "  - Pass -BlenderExe 'C:\\Path\\To\\blender.exe'" -ForegroundColor Red
      Write-Host "  - Or set env:BLENDER_EXE" -ForegroundColor Red
      Write-Host "Checked common locations:" -ForegroundColor DarkGray
      $commonChecked | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkGray }
      Write-Host "Tip: install via winget: winget install --id BlenderFoundation.Blender -e" -ForegroundColor DarkGray
    }
    exit 2
  }
}

$pipeline = Resolve-Path "$PSScriptRoot\blender_sl_pipeline.py"
if (-not (Test-Path $pipeline)) { throw "Pipeline script missing: $pipeline" }
if (-not (Test-Path $InputPath)) { throw "Input missing: $InputPath" }
$InputPath = (Resolve-Path $InputPath).Path

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path

$args = @(
  '-b',
  '-noaudio',
  '--python', $pipeline.Path,
  '--',
  '--input', $InputPath,
  '--out-dir', $OutDir,
  '--preset', $Preset
)

if ($NoExport) { $args += '--no-export' }
if ($SaveBlend) { $args += '--save-blend' }

if (-not $SummaryOnly) {
  Write-Host "Running: $blender $($args -join ' ')"
}

if ($PrintOnly) {
  if (-not $SummaryOnly) {
    Write-Host "PrintOnly enabled: not executing Blender." -ForegroundColor DarkGray
  }
  exit 0
}

if ($SummaryOnly) {
  & $blender @args *> $null
} else {
  & $blender @args
}

$report = Join-Path $OutDir 'report.json'
if (Test-Path $report) {
  if ($SummaryOnly) {
    $reportObj = Get-Content $report -Raw | ConvertFrom-Json

    $dae = Join-Path $OutDir 'model.dae'
    $blend = Join-Path $OutDir 'model.blend'

    $summary = [ordered]@{
      ok        = $true
      input     = $InputPath
      outDir    = $OutDir
      report    = $report
      preset    = $Preset
      noExport  = [bool]$NoExport
      saveBlend = [bool]$SaveBlend
      artifacts = [ordered]@{
        dae   = (Test-Path $dae) ? $dae : $null
        blend = (Test-Path $blend) ? $blend : $null
      }
      metrics = [ordered]@{
        export_collada_dae_bytes = $reportObj.export.collada_dae_bytes
        export_collada_dae       = $reportObj.export.collada_dae
      }
    }

    $summary | ConvertTo-Json -Depth 6 -Compress
  } else {
    Write-Host "OK: report.json written: $report"
    Get-Content $report | Select-Object -First 40
  }
} else {
  if (-not $SummaryOnly) {
    Write-Host "WARN: report.json not found: $report" -ForegroundColor Yellow
  }
  exit 3
}
