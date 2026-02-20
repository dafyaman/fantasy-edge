param(
  [string]$OutDir = 'progress'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Repo root is two levels up from this script's directory: slm-tool/scripts -> slm-tool -> <repo>
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

$ts = Get-Date -Format 'yyyy-MM-dd_HHmm'
$outFile = "pending_push_files_${ts}.json"
$outPath = Join-Path $OutDir $outFile
$fullOutPath = [System.IO.Path]::GetFullPath($outPath, (Get-Location).Path)

$result = & (Join-Path $PSScriptRoot 'pending_push_files.ps1')

# Normalize to a single-line JSON object/array, UTF-8 without BOM.
$json = $result | ConvertTo-Json -Depth 20 -Compress

$parent = Split-Path -Parent $fullOutPath
if (-not (Test-Path -LiteralPath $parent)) {
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
}

[System.IO.File]::WriteAllText(
  $fullOutPath,
  $json + "`n",
  (New-Object System.Text.UTF8Encoding($false))
)

Write-Output $fullOutPath
