# Review pending CI-wrapper commits on branch slm-workflow-only.
# Read-only helper to make push-approval easy.
# Usage:
#   pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File slm-tool/scripts/review_pending_wrapper_push.ps1

$ErrorActionPreference = 'Stop'

function Exec([string]$Cmd) {
  Write-Host "> $Cmd" -ForegroundColor DarkGray
  & git @("-c","core.quotepath=false") -c advice.detachedHead=false -c color.ui=false $Cmd.Split(' ') 2>&1
  if ($LASTEXITCODE -ne 0) { throw "Command failed: git $Cmd" }
}

try {
  $branch = (git rev-parse --abbrev-ref HEAD).Trim()
  if ($branch -ne 'slm-workflow-only') {
    Write-Host "BRANCH=$branch (expected slm-workflow-only)" -ForegroundColor Yellow
  } else {
    Write-Host "BRANCH=$branch" -ForegroundColor Green
  }

  $status = (git status -sb).Trim()
  Write-Host "STATUS=$status"

  $porcelain = @(git status --porcelain)

  # Note: this worker updates tracking docs every tick, so it's useful to distinguish
  # "raw dirty" from "effective dirty" (ignoring known-tracking files).
  $ignoredPaths = @(
    'TASK_QUEUE.md',
    'progress/PROGRESS_LOG.md'
  )

  $porcelainIgnored = @()
  $porcelainRelevant = @()
  foreach ($line in $porcelain) {
    $isIgnored = $false
    foreach ($p in $ignoredPaths) {
      if ($line -match ([regex]::Escape($p) + '$')) { $isIgnored = $true; break }
    }
    if ($isIgnored) { $porcelainIgnored += $line } else { $porcelainRelevant += $line }
  }

  $dirtyRaw = ($porcelain.Count -gt 0)
  $dirtyEffective = ($porcelainRelevant.Count -gt 0)

  $dirtyColor = 'Green'
  if ($dirtyEffective) { $dirtyColor = 'Yellow' }

  Write-Host ("DIRTY_RAW={0} (uncommitted entries={1})" -f $dirtyRaw, $porcelain.Count)
  Write-Host ("DIRTY_EFFECTIVE={0} (uncommitted entries={1})" -f $dirtyEffective, $porcelainRelevant.Count) -ForegroundColor $dirtyColor

  if ($dirtyRaw) {
    Write-Host "UNCOMMITTED_RELEVANT:" -ForegroundColor Yellow
    if ($porcelainRelevant.Count -eq 0) { Write-Host "  (none)" } else { $porcelainRelevant | ForEach-Object { Write-Host "  $_" } }

    if ($porcelainIgnored.Count -gt 0) {
      Write-Host "UNCOMMITTED_IGNORED:" -ForegroundColor DarkYellow
      $porcelainIgnored | ForEach-Object { Write-Host "  $_" }
    }
  }

  Write-Host "COMMITS_AHEAD_OF_ORIGIN:" -ForegroundColor Cyan
  git log --oneline origin/slm-workflow-only..HEAD

  Write-Host "FILES_TOUCHED_IN_AHEAD_COMMITS:" -ForegroundColor Cyan
  git diff --name-only origin/slm-workflow-only..HEAD

  Write-Host "OK" -ForegroundColor Green
}
catch {
  Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}
