param(
  [string]$Branch = 'slm-workflow-only',
  [string]$Remote = 'origin'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Push-Location $repoRoot
try {
  $range = "$Remote/$Branch..HEAD"

  # Ensure git exists
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git not found on PATH.'
  }

  # Basic sanity: range should resolve even if branch doesn't exist locally
  $null = git rev-parse --verify "$Remote/$Branch" 2>$null

  $files = @(git diff --name-only $range)
  $files = $files | Where-Object { $_ -and $_.Trim().Length -gt 0 }

  $payload = [ordered]@{
    branch = $Branch
    remote = $Remote
    range  = $range
    file_count = $files.Count
    files = $files
  }

  # Single-line JSON for easy copy/paste
  $payload | ConvertTo-Json -Compress
}
finally {
  Pop-Location
}
