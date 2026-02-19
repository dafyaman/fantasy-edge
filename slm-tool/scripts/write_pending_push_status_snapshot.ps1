param(
  [string]$OutDir = "progress",
  [string]$Prefix = "pending_push_status_"
)

$ErrorActionPreference = 'Stop'

$ts = (Get-Date).ToString('yyyy-MM-dd_HHmm')
$outPath = Join-Path $OutDir ("{0}{1}.json" -f $Prefix, $ts)

# Run the existing status generator and capture its stdout as a single string
$json = & "$PSScriptRoot\pending_push_status.ps1"
if ($LASTEXITCODE -ne 0) { throw "pending_push_status.ps1 exited with $LASTEXITCODE" }

# Write UTF-8 without BOM, ensure trailing newline
# NOTE: use the single-arg overload for Windows PowerShell (Full .NET Framework) compatibility
$fullOutPath = [System.IO.Path]::GetFullPath($outPath)
[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($fullOutPath)) | Out-Null
[System.IO.File]::WriteAllText($fullOutPath, $json + "`n", (New-Object System.Text.UTF8Encoding($false)))

Write-Output $fullOutPath
