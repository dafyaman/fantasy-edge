param(
  [Parameter(Mandatory=$true)][string]$ArtifactsDir,
  [switch]$RequireRunSummary
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ArtifactsDir)) {
  throw "[check_ci_artifacts] ERROR: ArtifactsDir not found: $ArtifactsDir"
}

$summary = [ordered]@{
  ok = $true
  artifacts_dir = (Resolve-Path -LiteralPath $ArtifactsDir).Path
  has_smoke_summary = $false
  smoke_summary_path = $null
  has_run_summary = $false
  run_summary_path = $null
}

$smoke = Get-ChildItem -LiteralPath $ArtifactsDir -Recurse -File -Filter 'smoke_summary_ci.json' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($smoke) {
  $summary.has_smoke_summary = $true
  $summary.smoke_summary_path = $smoke.FullName
}

$run = Get-ChildItem -LiteralPath $ArtifactsDir -Recurse -File -Filter 'run_summary_ci.json' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($run) {
  $summary.has_run_summary = $true
  $summary.run_summary_path = $run.FullName
}

if ($RequireRunSummary -and (-not $summary.has_run_summary)) {
  $summary.ok = $false
}

# Machine-readable single line for cron/CI logs
$summary | ConvertTo-Json -Compress | Write-Output

if (-not $summary.ok) {
  throw "[check_ci_artifacts] FAIL: run_summary_ci.json missing under: $ArtifactsDir"
}
