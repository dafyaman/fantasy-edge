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
