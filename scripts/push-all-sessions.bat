@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
title Push ALL Sessions to GitHub
color 0A

echo ══════════════════════════════════════════════════
echo   Push ALL Sessions to GitHub
echo ══════════════════════════════════════════════════
echo.

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"
for %%I in ("!SCRIPT_DIR!") do set "CLAUDECODE_DIR=%%~dpI"
set "CLAUDECODE_DIR=!CLAUDECODE_DIR:~0,-1!"

set "PY_CMD="
for /f "tokens=*" %%P in ('where py 2^>nul') do if not defined PY_CMD set "PY_CMD=%%P"
if not defined PY_CMD for /f "tokens=*" %%P in ('where python 2^>nul') do if not defined PY_CMD set "PY_CMD=%%P"
if not defined PY_CMD for /f "tokens=*" %%P in ('where python3 2^>nul') do if not defined PY_CMD set "PY_CMD=%%P"

if not defined PY_CMD (
    color 0C
    echo  [ERROR] Python not found.
    pause
    exit /b 1
)

"!PY_CMD!" "!SCRIPT_DIR!\sync-sessions.py" push "!CLAUDECODE_DIR!"

endlocal
pause
