@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: The .py file always lives in CLAUDECODE\scripts\
:: This .bat can be in CLAUDECODE\, CLAUDECODE\scripts\, or CLAUDECODE\<project>\scripts\

set "BAT_DIR=%~dp0"
set "BAT_DIR=!BAT_DIR:~0,-1!"

:: Walk up to find the CLAUDECODE root by looking for the scripts\claude-launch.py
set "PY_FILE="

:: Check 1: .py is right next to this .bat (we're in CLAUDECODE\scripts\)
if exist "!BAT_DIR!\claude-launch.py" (
    set "PY_FILE=!BAT_DIR!\claude-launch.py"
    goto :found
)

:: Check 2: we're in CLAUDECODE root, .py is in scripts\ subfolder
if exist "!BAT_DIR!\scripts\claude-launch.py" (
    set "PY_FILE=!BAT_DIR!\scripts\claude-launch.py"
    goto :found
)

:: Check 3: we're in <project>\scripts\, go up two levels to CLAUDECODE\scripts\
for %%P in ("!BAT_DIR!") do set "PROJ_ROOT=%%~dpP"
set "PROJ_ROOT=!PROJ_ROOT:~0,-1!"
for %%R in ("!PROJ_ROOT!") do set "CODE_ROOT=%%~dpR"
set "CODE_ROOT=!CODE_ROOT:~0,-1!"
if exist "!CODE_ROOT!\scripts\claude-launch.py" (
    set "PY_FILE=!CODE_ROOT!\scripts\claude-launch.py"
    goto :found
)

:: Not found
echo  [ERROR] Could not find claude-launch.py
echo  Expected in: CLAUDECODE\scripts\claude-launch.py
pause
exit /b 1

:found
:: Find Python (try py launcher first — most reliable on Windows)
set "PYTHON_CMD="
where py >nul 2>&1
if not errorlevel 1 set "PYTHON_CMD=py"
if "!PYTHON_CMD!"=="" (
    where python >nul 2>&1
    if not errorlevel 1 set "PYTHON_CMD=python"
)
if "!PYTHON_CMD!"=="" (
    where python3 >nul 2>&1
    if not errorlevel 1 set "PYTHON_CMD=python3"
)
if "!PYTHON_CMD!"=="" (
    echo  [ERROR] Python not found. Install from python.org
    pause
    exit /b 1
)

:: Launch — pass this .bat's directory so Python knows the project path
!PYTHON_CMD! "!PY_FILE!" "!BAT_DIR!"
endlocal
