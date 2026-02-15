<#
.SYNOPSIS
  Summarize what would be pushed for the current branch (safe, read-only).

.DESCRIPTION
  Prints:
    - current branch
    - ahead/behind vs origin/<branch>
    - uncommitted changes
    - commits that would be pushed
    - file list for those commits
    - git push --dry-run output

  This script does NOT push anything.

.EXAMPLE
  pwsh -NoProfile -File slm-tool/scripts/review_pending_push.ps1
#>

$ErrorActionPreference = 'Stop'

function Exec([string]$Cmd) {
  Write-Host "`n> $Cmd" -ForegroundColor DarkGray
  & cmd /c $Cmd
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: $Cmd"
  }
}

# Ensure we run from repo root regardless of invocation location.
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Push-Location $repoRoot
try {
  $branch = (& git rev-parse --abbrev-ref HEAD).Trim()
  if (-not $branch) { throw 'Could not determine current git branch.' }

  Write-Host "REPO=$repoRoot" -ForegroundColor Cyan
  Write-Host "BRANCH=$branch" -ForegroundColor Cyan

  Exec "git status -sb"

  # Uncommitted changes (porcelain output makes this machine-readable).
  $porcelain = (& git status --porcelain)
  $dirtyCount = 0
  if ($porcelain) {
    $dirtyCount = ($porcelain | Measure-Object).Count
  }
  Write-Host ("DIRTY={0} (uncommitted entries={1})" -f ($dirtyCount -gt 0), $dirtyCount) -ForegroundColor Cyan

  # Ahead/behind counts.
  $upstream = "origin/$branch"
  $counts = (& git rev-list --left-right --count "$upstream...HEAD" 2>$null)
  if ($counts) {
    $parts = $counts.Trim().Split("`t")
    if ($parts.Count -eq 2) {
      Write-Host "BEHIND=$($parts[0]) AHEAD=$($parts[1]) vs $upstream" -ForegroundColor Cyan
    }
  } else {
    Write-Host "WARN: Upstream $upstream not found (branch not pushed yet?)." -ForegroundColor Yellow
  }

  # Commits to be pushed.
  Write-Host "`nCOMMITS_TO_PUSH ($upstream..HEAD):" -ForegroundColor Cyan
  & git log --oneline "$upstream..HEAD" 2>$null

  Write-Host "`nFILES_CHANGED_IN_PUSH_RANGE:" -ForegroundColor Cyan
  & git diff --name-status "$upstream..HEAD" 2>$null

  Write-Host "`nDRY_RUN_PUSH:" -ForegroundColor Cyan
  Exec "git push --dry-run origin $branch"

  Write-Host "`nOK: review complete (no push performed)." -ForegroundColor Green
}
finally {
  Pop-Location
}
