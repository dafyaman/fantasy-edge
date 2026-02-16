param(
  [string]$Path = (Join-Path $PSScriptRoot 'PROGRESS_LOG.md')
)

if (!(Test-Path $Path)) {
  throw "File not found: $Path"
}

# Read bytes -> decode UTF-8 -> strip any embedded NULs -> write UTF-8 (no BOM)
$bytes = [System.IO.File]::ReadAllBytes($Path)
$text  = [System.Text.Encoding]::UTF8.GetString($bytes)

$beforeLen = $text.Length
$text2 = $text -replace [char]0, ''
$afterLen = $text2.Length

$removed = $beforeLen - $afterLen
Write-Host "RemovedNUL=$removed"

[System.IO.File]::WriteAllText($Path, $text2, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "WroteUTF8NoBOM=$Path"
