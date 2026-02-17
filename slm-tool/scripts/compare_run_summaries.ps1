<#!
Compare two one-line JSON run summaries (typically produced by `slm summarize-run`).

Outputs:
  - On match: writes `[compare_run_summaries] OK` and exits 0
  - On mismatch: throws with a short mismatch report
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$A,
  [Parameter(Mandatory=$true)][string]$B
)

$ErrorActionPreference = 'Stop'

function Read-OneLineJson {
  param([Parameter(Mandatory=$true)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing file: $Path"
  }

  $raw = Get-Content -LiteralPath $Path -Raw
  if (-not $raw) { throw "Empty file: $Path" }

  try {
    return ($raw | ConvertFrom-Json -Depth 50)
  } catch {
    throw "Invalid JSON in ${Path}: $($_.Exception.Message)"
  }
}

$aObj = Read-OneLineJson -Path $A
$bObj = Read-OneLineJson -Path $B

# Compare in a stable way: compare the set of keys + values for scalar leaves.
# (We keep it intentionally shallow/simple for the current summaries.)

$aProps = @($aObj.PSObject.Properties | Sort-Object Name)
$bProps = @($bObj.PSObject.Properties | Sort-Object Name)

$aKeys = @($aProps | ForEach-Object { $_.Name })
$bKeys = @($bProps | ForEach-Object { $_.Name })

$missingInB = @($aKeys | Where-Object { $_ -notin $bKeys })
$missingInA = @($bKeys | Where-Object { $_ -notin $aKeys })

$mismatched = @()
foreach ($k in $aKeys) {
  if ($k -notin $bKeys) { continue }
  $av = $aObj.$k
  $bv = $bObj.$k

  # Normalize simple arrays/objects to JSON for comparison.
  $avNorm = if ($av -is [string] -or $av -is [ValueType] -or $av -eq $null) { $av } else { ($av | ConvertTo-Json -Compress -Depth 50) }
  $bvNorm = if ($bv -is [string] -or $bv -is [ValueType] -or $bv -eq $null) { $bv } else { ($bv | ConvertTo-Json -Compress -Depth 50) }

  if ($avNorm -ne $bvNorm) {
    $mismatched += @{ key=$k; a=$avNorm; b=$bvNorm }
  }
}

if ($missingInB.Count -eq 0 -and $missingInA.Count -eq 0 -and $mismatched.Count -eq 0) {
  Write-Output "[compare_run_summaries] OK: keys=$($aKeys.Count)"
  exit 0
}

$report = [ordered]@{
  ok = $false
  a = (Resolve-Path -LiteralPath $A).Path
  b = (Resolve-Path -LiteralPath $B).Path
  missing_in_b = $missingInB
  missing_in_a = $missingInA
  mismatched = $mismatched
}

throw ("[compare_run_summaries] MISMATCH\n" + ($report | ConvertTo-Json -Depth 50 -Compress))
