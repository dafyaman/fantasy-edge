param(
  [string]$OutPath = "progress/worker_exec_selftest_latest.json"
)

$ErrorActionPreference = 'Stop'

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$payload = [ordered]@{
  kind = 'worker_exec_selftest'
  generated_at = $ts
  pwsh_version = $PSVersionTable.PSVersion.ToString()
  edition = $PSVersionTable.PSEdition
  cwd = (Get-Location).Path
  hostname = $env:COMPUTERNAME
}

$json = ($payload | ConvertTo-Json -Compress)

# Always emit a single JSON line to stdout for capture.
Write-Output $json

# And write a deterministic file for proof-of-work.
$dir = Split-Path -Parent $OutPath
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
$fullOutPath = [System.IO.Path]::GetFullPath($OutPath, (Get-Location).Path)
[System.IO.File]::WriteAllText($fullOutPath, $json + "`n", (New-Object System.Text.UTF8Encoding($false)))
