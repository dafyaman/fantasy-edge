@echo off
setlocal

REM Repo-root convenience wrapper for the SLM CLI shim.
REM Usage: slm <command> [args]

set "SCRIPT_DIR=%~dp0"
call "%SCRIPT_DIR%slm-tool\scripts\slm.cmd" %*
