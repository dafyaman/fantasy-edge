# SLM-001: Blender pipeline static syntax check (no Blender needed)
# Compiles the Python source to bytecode to catch syntax errors.
# This does NOT import bpy or execute the script.

[CmdletBinding()]
param(
  [string]$PythonExe,
  [string]$SourcePath = (Join-Path $PSScriptRoot "blender_sl_pipeline.py")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (!(Test-Path -LiteralPath $SourcePath)) {
  throw "SourcePath not found: $SourcePath"
}

function Resolve-Python {
  param([string]$Explicit)

  if ($Explicit) {
    if (Test-Path -LiteralPath $Explicit) { return $Explicit }
    return $Explicit # allow PATH resolution if user passed a command
  }

  foreach ($candidate in @('py','python','python3')) {
    $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
  }

  throw "Python not found. Install Python 3 or pass -PythonExe (e.g. -PythonExe py)."
}

$py = Resolve-Python -Explicit $PythonExe

Write-Host "[check_py_compile] Using Python: $py"
Write-Host "[check_py_compile] Compiling: $SourcePath"

# Use python -c to run py_compile without importing the target module
& $py -c "import py_compile; py_compile.compile(r'$SourcePath', doraise=True); print('OK')"
if ($LASTEXITCODE -ne 0) {
  throw "py_compile failed with exit code $LASTEXITCODE"
}

Write-Host "[check_py_compile] OK"
