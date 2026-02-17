<#
SLM-001 minimal CLI shim.

Examples:
  pwsh -NoProfile -File slm-tool/scripts/slm.ps1 run -PrintOnly
  pwsh -NoProfile -File slm-tool/scripts/slm.ps1 run -SummaryOnly -NoExport:$false
  pwsh -NoProfile -File slm-tool/scripts/slm.ps1 smoke -PrintOnly
  pwsh -NoProfile -File slm-tool/scripts/slm.ps1 export-smoke
#>

[CmdletBinding(PositionalBinding=$true)]
param(
  [Parameter(Position=0)]
  [ValidateSet('run','smoke','smoke-summary','smoke-summary-schema','export-smoke','preflight','fixtures','validate-obj','find-blender','check-collada','help','/?')]
  [string]$Command = 'run',

  # Common passthrough args (forwarded when the target script supports them)
  [string]$BlenderExe = $env:BLENDER_EXE,
  [string]$InputPath,
  [string]$OutDir,
  [string]$Preset,
  [Nullable[bool]]$NoExport,
  [Nullable[bool]]$SaveBlend,
  [switch]$PrintOnly,
  [switch]$SummaryOnly,

  # smoke-summary only
  [string]$OutPath,
  [switch]$Schema
)

$ErrorActionPreference = 'Stop'

if ($Command -eq 'help' -or $Command -eq '/?') {
  @(
    'SLM-001 CLI shim',
    '',
    'Usage:',
    '  slm <command> [args]',
    '  pwsh -NoProfile -File slm-tool/scripts/slm.ps1 <command> [args]',
    '',
    'Commands:',
    '  help | /?             Show this help',
    '  run                   Run pipeline (see run_blender_pipeline.ps1 params)',
    '  smoke                 Run pipeline smoke (see run_blender_pipeline_smoke.ps1 params)',
    '  export-smoke          Smoke run with export enabled (portable Blender 4.2.14 LTS wrapper)',
    '  smoke-summary         Emit one-line JSON summary (Schema validation; supports -OutPath)',
    '  smoke-summary-schema  Print path to smoke summary JSON schema',
    '  preflight             Blender-free checks (py_compile + PrintOnly regression + fixtures sanity)',
    '  fixtures              Print fixtures dir + list available tiny inputs',
    '  validate-obj          Blender-free OBJ sanity check (requires -InputPath)',
    '  find-blender          Locate Blender executable candidates',
    '  check-collada         Check whether Blender has io_scene_dae (Collada) addon'
  ) | Write-Output
  exit 0
}

if ($PrintOnly) {
  Write-Host "[slm] PrintOnly requested" -ForegroundColor DarkGray
}

function Invoke-Runner {
  param(
    [Parameter(Mandatory=$true)][string]$ScriptPath,
    # Use [object[]] so we can pass typed values (e.g., [bool]) through to child scripts.
    [object[]]$ExtraArgs = @(),

    # Passthrough values (captured explicitly; avoids any scope surprises).
    [string]$BlenderExe,
    [string]$InputPath,
    [string]$OutDir,
    [string]$Preset,
    [Nullable[bool]]$NoExport,
    [Nullable[bool]]$SaveBlend,
    [switch]$PrintOnly,
    [switch]$SummaryOnly
  )

  # Prefer a hashtable for named-parameter splatting; avoids edge-cases where an array-based splat
  # drops/ignores switch parameters when the callee is a .ps1 script.
  $invokeHash = @{}
  if ($BlenderExe) { $invokeHash['BlenderExe'] = $BlenderExe }
  if ($InputPath)  { $invokeHash['InputPath']  = $InputPath }
  if ($OutDir)     { $invokeHash['OutDir']     = $OutDir }
  if ($Preset)     { $invokeHash['Preset']     = $Preset }
  if ($NoExport -ne $null)  { $invokeHash['NoExport']  = [bool]$NoExport }
  if ($SaveBlend -ne $null) { $invokeHash['SaveBlend'] = [bool]$SaveBlend }
  if ($PrintOnly)  { $invokeHash['PrintOnly']  = $true }
  if ($SummaryOnly){ $invokeHash['SummaryOnly']= $true }

  if ($PrintOnly) {
    $pretty = @($invokeHash.GetEnumerator() | Sort-Object Name | ForEach-Object { "-$($_.Name) $($_.Value)" }) -join ' '
    Write-Host "[slm] Invoke-Runner: $ScriptPath $pretty $($ExtraArgs -join ' ')" -ForegroundColor DarkGray
  }

  & $ScriptPath @invokeHash @ExtraArgs
}

$here = $PSScriptRoot
switch ($Command) {
  'run' {
    Invoke-Runner -ScriptPath (Join-Path $here 'run_blender_pipeline.ps1') -BlenderExe $BlenderExe -InputPath $InputPath -OutDir $OutDir -Preset $Preset -NoExport $NoExport -SaveBlend $SaveBlend -PrintOnly:([bool]$PrintOnly) -SummaryOnly:([bool]$SummaryOnly)
  }
  'smoke' {
    Invoke-Runner -ScriptPath (Join-Path $here 'run_blender_pipeline_smoke.ps1') -BlenderExe $BlenderExe -InputPath $InputPath -OutDir $OutDir -Preset $Preset -NoExport $NoExport -SaveBlend $SaveBlend -PrintOnly:([bool]$PrintOnly) -SummaryOnly:([bool]$SummaryOnly)
  }
  'smoke-summary' {
    # Runs the smoke pipeline in SummaryOnly mode and validates the JSON schema.
    # If -Schema is passed, prints the schema path and exits 0 without needing Blender.
    $p = if ($Preset) { $Preset } else { 'prop' }

    $args = @{
      Preset = $p
      Quiet  = $true
    }
    if ($Schema)    { $args.Schema    = $true }
    if ($BlenderExe) { $args.BlenderExe = $BlenderExe }
    if ($InputPath)  { $args.InputPath  = $InputPath }
    if ($OutDir)     { $args.OutDir     = $OutDir }
    if ($OutPath)    { $args.OutPath    = $OutPath }

    & (Join-Path $here 'run_smoke_summary.ps1') @args
  }
  'smoke-summary-schema' {
    # Convenience alias for: slm smoke-summary -Schema
    & (Join-Path $here 'slm.ps1') smoke-summary -Schema
  }
  'export-smoke' {
    # If user asks for PrintOnly/SummaryOnly (or overrides like -OutDir), run the underlying smoke runner
    # directly so we can honor those passthrough flags without executing Blender.
    if ($PrintOnly -or $SummaryOnly -or $OutDir -or $InputPath -or $BlenderExe -or $NoExport -ne $null -or $SaveBlend -ne $null) {
      # Force export enabled by default for this command, unless caller explicitly set -NoExport.
      $extra = @()
      if ($NoExport -eq $null) { $extra += @('-NoExport', $false) }
      if ($SaveBlend -eq $null) { $extra += @('-SaveBlend', $false) }

      Invoke-Runner -ScriptPath (Join-Path $here 'run_blender_pipeline_smoke.ps1') -ExtraArgs $extra -BlenderExe $BlenderExe -InputPath $InputPath -OutDir $OutDir -Preset $Preset -NoExport $NoExport -SaveBlend $SaveBlend -PrintOnly:([bool]$PrintOnly) -SummaryOnly:([bool]$SummaryOnly)
    } else {
      & (Join-Path $here 'check_ps_exec_export_smoke.ps1')
    }
  }
  'preflight' {
    & (Join-Path $here 'check_preflight.ps1')
  }
  'fixtures' {
    $fixturesDir = (Resolve-Path (Join-Path $here '..\fixtures')).Path
    Write-Output $fixturesDir
    Get-ChildItem -Path $fixturesDir -File | Sort-Object Name | ForEach-Object { $_.Name } | Write-Output
  }
  'validate-obj' {
    if (-not $InputPath) {
      throw "validate-obj requires -InputPath <path-to-obj>"
    }
    & (Join-Path $here 'validate_obj.ps1') -Path $InputPath
  }
  'find-blender' {  
    & (Join-Path $here 'find_blender.ps1')
  }
  'check-collada' {
    & (Join-Path $here 'check_blender_collada.ps1')
  }
  default {
    throw "Unknown command: $Command"
  }
}
