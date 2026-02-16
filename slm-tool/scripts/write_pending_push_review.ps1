# Write a pending-push review artifact as UTF-8 (avoids UTF-16/NUL text when using Tee-Object).
# Usage:
#   pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File slm-tool/scripts/write_pending_push_review.ps1

$ErrorActionPreference = 'Stop'

$repoRoot = (git rev-parse --show-toplevel).Trim()
$ts = Get-Date -Format 'yyyy-MM-dd_HHmm'
$outPath = Join-Path $repoRoot ("progress/pending_push_review_{0}.txt" -f $ts)

# Run the existing read-only review helper and capture combined output.
$cmd = @(
  'pwsh',
  '-NoProfile',
  '-NonInteractive',
  '-ExecutionPolicy','Bypass',
  '-File','slm-tool/scripts/review_pending_wrapper_push.ps1'
)

Write-Host ("> " + ($cmd -join ' ')) -ForegroundColor DarkGray
$out = & $cmd[0] $cmd[1..($cmd.Length-1)] 2>&1

# Echo to console for interactive use.
$out | ForEach-Object { Write-Host $_ }

# Persist as UTF-8 (no BOM) for clean diffs + sane viewing.
$out | Out-File -FilePath $outPath -Encoding utf8NoBOM

Write-Host ("WROTE={0}" -f $outPath) -ForegroundColor Green
