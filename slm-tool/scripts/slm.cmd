@echo off
setlocal

rem SLM-001 convenience wrapper for Windows cmd.exe users.
rem For full usage, see slm-tool\scripts\slm.ps1

set "SCRIPT_DIR=%~dp0"
set "SLM_PS1=%SCRIPT_DIR%slm.ps1"

pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SLM_PS1%" %*
set EXITCODE=%ERRORLEVEL%
endlocal & exit /b %EXITCODE%
