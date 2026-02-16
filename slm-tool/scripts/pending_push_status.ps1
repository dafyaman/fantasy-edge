<#
SLM-001 helper: emit a machine-readable JSON summary of the current branch vs origin.

This is intended for review/approval of the pending push set while the cron worker
keeps touching tracking docs.

Outputs a single JSON object to stdout.
#>

[CmdletBinding()]
param(
  # Ignore these files when deciding if the working tree is "effectively dirty".
  [string[]]$IgnorePaths = @('TASK_QUEUE.md', 'progress/PROGRESS_LOG.md')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Exec([string]$cmd) {
  $out = & git @('rev-parse','--is-inside-work-tree') 2>$null
  if ($LASTEXITCODE -ne 0) { throw 'Not inside a git work tree.' }
  return & cmd /c $cmd
}

# Ensure we have up-to-date origin/<branch> refs without touching work tree.
& git fetch --quiet --prune | Out-Null

$branch = (& git rev-parse --abbrev-ref HEAD).Trim()
$statusLine = (& git status -sb).Split("`n")[0].Trim()

# Example statusLine: "## slm-workflow-only...origin/slm-workflow-only [ahead 10]"
$ahead = 0
$behind = 0
if ($statusLine -match '\[ahead\s+(\d+)\]') { $ahead = [int]$Matches[1] }
if ($statusLine -match '\[behind\s+(\d+)\]') { $behind = [int]$Matches[1] }

# Raw porcelain (tracked modifications + untracked)
$porcelain = & git status --porcelain=v1
$dirtyRaw = ($porcelain | Measure-Object).Count -gt 0

# Effective dirty: ignore the tracking docs that this worker touches every tick.
$uncommitted = @()
foreach ($line in $porcelain) {
  if (-not $line) { continue }
  # Format: "XY path" or "?? path"
  $path = $line.Substring(3).Trim()
  if ($IgnorePaths -contains $path) { continue }
  $uncommitted += $path
}
$dirtyEffective = $uncommitted.Count -gt 0

$commitsAhead = @()
if ($ahead -gt 0) {
  $range = "origin/$branch..HEAD"
  $logLines = & git log --oneline $range
  foreach ($l in $logLines) {
    if ($l -match '^(?<sha>[0-9a-f]+)\s+(?<msg>.*)$') {
      $commitsAhead += [pscustomobject]@{ sha = $Matches['sha']; msg = $Matches['msg'] }
    }
  }
}

$obj = [pscustomobject]@{
  branch = $branch
  status = $statusLine
  ahead = $ahead
  behind = $behind
  dirty_raw = $dirtyRaw
  dirty_effective = $dirtyEffective
  uncommitted_relevant = $uncommitted
  commits_ahead = $commitsAhead
  generated_at = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')
}

# Single-line JSON for easy copy/paste into issues/approvals.
$obj | ConvertTo-Json -Depth 6 -Compress
