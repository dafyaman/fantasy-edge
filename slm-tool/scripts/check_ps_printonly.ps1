# SLM-001 preflight: ensure PowerShell smoke runner can generate a Blender command line.
# This is intentionally Blender-free; it runs with -PrintOnly.

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

Write-Host "[check_ps_printonly] repoRoot=$repoRoot"

$runner = Join-Path $repoRoot 'slm-tool\scripts\run_blender_pipeline_smoke.ps1'
if (-not (Test-Path $runner)) {
  throw "Runner not found: $runner"
}

# Execute in a clean session; do not rely on profile.
$cmd = @(
  'pwsh','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-Command',
  "& '$runner' -PrintOnly"
)

Write-Host "[check_ps_printonly] Running: $($cmd -join ' ')"

$proc = Start-Process -FilePath $cmd[0] -ArgumentList $cmd[1..($cmd.Length-1)] -NoNewWindow -Wait -PassThru
if ($proc.ExitCode -ne 0) {
  throw "PrintOnly preflight failed with exit code $($proc.ExitCode)"
}

Write-Host "[check_ps_printonly] OK"
