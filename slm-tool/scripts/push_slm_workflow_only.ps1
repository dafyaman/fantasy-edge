<#
SLM-001 helper: push the slm-workflow-only branch safely.

Default behavior is DRY-RUN only.
Use -ConfirmPush to perform the real push.
Refuses to push if the working tree is dirty (pass -AllowDirty to override).

Example:
  pwsh -NoProfile -File .\slm-tool\scripts\push_slm_workflow_only.ps1
  pwsh -NoProfile -File .\slm-tool\scripts\push_slm_workflow_only.ps1 -ConfirmPush
#>

[CmdletBinding()]
param(
  [switch]$ConfirmPush,
  [switch]$AllowDirty
)

$ErrorActionPreference = 'Stop'

function Info($msg) { Write-Host "[push_slm_workflow_only] $msg" }

# Resolve repo root from this script location.
# $MyInvocation can be null-ish in some non-interactive contexts; prefer $PSCommandPath when available.
$scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($scriptPath)) {
  throw "Unable to determine script path (PSCommandPath/MyInvocation empty)."
}
$ScriptDir = Split-Path -Parent $scriptPath
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path

Push-Location $RepoRoot
try {
  $branch = (& git rev-parse --abbrev-ref HEAD).Trim()
  Info "RepoRoot=$RepoRoot"
  Info "CurrentBranch=$branch"

  if ($branch -ne 'slm-workflow-only') {
    throw "Refusing to push: expected branch 'slm-workflow-only' but current is '$branch'."
  }

  Info "git status -sb:"
  & git status -sb

  $dirtyRaw = (& git status --porcelain)
  $dirty = if ($null -eq $dirtyRaw) { '' } else { ($dirtyRaw | Out-String).Trim() }
  if ($dirty -and (-not $AllowDirty)) {
    throw "Refusing to push: working tree is dirty. Commit/stash changes or pass -AllowDirty."
  }

  $remote = 'origin'
  $ref = 'slm-workflow-only'

  if (-not $ConfirmPush) {
    Info "Dry-run push (pass -ConfirmPush to actually push):"
    & git push --dry-run $remote $ref
    Info "DRY_RUN_ONLY"
    exit 0
  }

  Info "Pushing: git push $remote $ref"
  & git push $remote $ref
  Info "PUSH_OK"
}
finally {
  Pop-Location
}
