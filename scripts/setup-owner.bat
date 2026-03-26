@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
title CLAUDECODE — Owner Setup
color 0B

echo ══════════════════════════════════════════════════
echo   CLAUDECODE — Owner Setup
echo ══════════════════════════════════════════════════
echo.
echo  This configures the scripts for your GitHub account
echo  and Claude Code directory. Run again anytime to update.
echo.
echo ══════════════════════════════════════════════════
echo.

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"
set "DEFAULT_CLAUDE_DIR=%USERPROFILE%\.claude"

:: ══════════════════════════════════════════════════════
::  STEP 1: Locate Claude CLI directory
:: ══════════════════════════════════════════════════════
echo  -- Step 1: Claude Code CLI Directory --
echo.

:: Auto-detect
set "DETECTED_DIR="
if exist "%USERPROFILE%\.claude\projects" (
    set "DETECTED_DIR=%USERPROFILE%\.claude"
) else if exist "%USERPROFILE%\.claude" (
    set "DETECTED_DIR=%USERPROFILE%\.claude"
) else if exist "%USERPROFILE%\.config\claude\projects" (
    set "DETECTED_DIR=%USERPROFILE%\.config\claude"
)

:ask_claude_dir
if defined DETECTED_DIR (
    echo  [FOUND] Claude CLI directory detected at:
    echo    !DETECTED_DIR!
    echo.
    if exist "!DETECTED_DIR!\projects" (
        set "PROJ_COUNT=0"
        for /d %%D in ("!DETECTED_DIR!\projects\*") do set /a PROJ_COUNT+=1
        echo  Contains: !PROJ_COUNT! session folder(s^)
    )
    if exist "!DETECTED_DIR!\settings.json" echo  Has: settings.json
    if exist "!DETECTED_DIR!\plugins" echo  Has: plugins\
    echo.
    set /p DIR_CONFIRM="  Is this correct? (Y/N): "
    if /i "!DIR_CONFIRM!"=="Y" (
        set "CLAUDE_DIR=!DETECTED_DIR!"
        goto :claude_dir_done
    )
    echo.
    echo  Enter the path to your Claude CLI directory:
    set /p CUSTOM_DIR="  Path: "
    if "!CUSTOM_DIR!"=="" (
        echo  [ERROR] No path entered.
        echo.
        goto :ask_claude_dir
    )
    if exist "!CUSTOM_DIR!" (
        set "CLAUDE_DIR=!CUSTOM_DIR!"
        goto :claude_dir_done
    )
    echo  [ERROR] Directory does not exist: !CUSTOM_DIR!
    echo  Please check the path and try again.
    echo.
    set "DETECTED_DIR="
    goto :ask_claude_dir
) else (
    echo  [NOT FOUND] Could not auto-detect Claude CLI directory.
    echo.
    echo  Claude Code CLI typically stores its data at:
    echo    Windows: %USERPROFILE%\.claude
    echo    Mac:     ~/.claude
    echo.
    :ask_custom_dir
    echo  Enter the path to your Claude CLI directory:
    set /p CUSTOM_DIR="  Path: "
    if "!CUSTOM_DIR!"=="" (
        echo  [ERROR] No path entered.
        echo.
        goto :ask_custom_dir
    )
    if exist "!CUSTOM_DIR!" (
        set "CLAUDE_DIR=!CUSTOM_DIR!"
        goto :claude_dir_done
    )
    echo  [INFO] Directory does not exist yet: !CUSTOM_DIR!
    echo  It will be created when you first run pull-all-sessions.
    set "CLAUDE_DIR=!CUSTOM_DIR!"
    goto :claude_dir_done
)

:claude_dir_done
echo.

:: ══════════════════════════════════════════════════════
::  STEP 2: Dotfiles repo
:: ══════════════════════════════════════════════════════
echo  -- Step 2: Dotfiles Repository --
echo.
echo  Your Claude dotfiles repo stores sessions, memory,
echo  plugins, and settings across machines.
echo.
echo  Create a PRIVATE repo on GitHub for this, e.g.:
echo    https://github.com/your-org/claude-dotfiles
echo.
set /p DOTFILES_URL="  Dotfiles repo URL: "

if "!DOTFILES_URL!"=="" (
    color 0C
    echo  [ERROR] No URL provided.
    pause
    exit /b 1
)

if "!DOTFILES_URL:~-4!"==".git" set "DOTFILES_URL=!DOTFILES_URL:~0,-4!"
if "!DOTFILES_URL:~-1!"=="/" set "DOTFILES_URL=!DOTFILES_URL:~0,-1!"
set "DOTFILES_GIT=!DOTFILES_URL!.git"

:: ══════════════════════════════════════════════════════
::  STEP 3: GitHub org
:: ══════════════════════════════════════════════════════
echo.
echo  -- Step 3: GitHub Organization --
echo.
echo  Your GitHub org or username (for project repo examples).
echo  Example: my-company, my-username
echo.
set /p GH_ORG="  GitHub org/username: "

if "!GH_ORG!"=="" (
    color 0C
    echo  [ERROR] No org provided.
    pause
    exit /b 1
)

:: ══════════════════════════════════════════════════════
::  Confirmation
:: ══════════════════════════════════════════════════════
echo.
echo  ══════════════════════════════════════════════════
echo   Claude directory: !CLAUDE_DIR!
echo   Dotfiles repo:    !DOTFILES_URL!
echo   GitHub org:        !GH_ORG!
echo  ══════════════════════════════════════════════════
echo.
set /p CONFIRM="  Apply these settings? (Y/N): "
if /i not "!CONFIRM!"=="Y" ( echo  Cancelled. & pause & exit /b 0 )

echo.
echo  Applying...

:: ── Save Claude directory override ──
set "CLAUDE_DIR_FILE=!SCRIPT_DIR!\.claude-dir"
if /i not "!CLAUDE_DIR!"=="!DEFAULT_CLAUDE_DIR!" (
    echo !CLAUDE_DIR!> "!CLAUDE_DIR_FILE!"
    echo  [OK] Custom Claude directory: !CLAUDE_DIR!
) else (
    if exist "!CLAUDE_DIR_FILE!" del "!CLAUDE_DIR_FILE!"
    echo  [OK] Default Claude directory: !DEFAULT_CLAUDE_DIR!
)

:: ── Find Python ──
set "PY_CMD="
for /f "tokens=*" %%P in ('where py 2^>nul') do if not defined PY_CMD set "PY_CMD=%%P"
if not defined PY_CMD for /f "tokens=*" %%P in ('where python 2^>nul') do if not defined PY_CMD set "PY_CMD=%%P"
if not defined PY_CMD for /f "tokens=*" %%P in ('where python3 2^>nul') do if not defined PY_CMD set "PY_CMD=%%P"

if not defined PY_CMD (
    color 0C
    echo  [ERROR] Python is required.
    pause
    exit /b 1
)

:: ── Update files via Python ──
"!PY_CMD!" -c "
import os, sys
script_dir = sys.argv[1]
dotfiles_url = sys.argv[2]
dotfiles_git = sys.argv[3]
gh_org = sys.argv[4]

files_to_update = [
    (os.path.join(script_dir, 'sync-sessions.py'), [
        ('CLI_REPO = \"https://github.com/YOUR-ORG/claude-dotfiles.git\"', f'CLI_REPO = \"{dotfiles_git}\"'),
    ]),
    (os.path.join(script_dir, 'new-project.sh'), [
        ('https://github.com/YOUR-ORG/claude-dotfiles', dotfiles_url),
        ('https://github.com/YOUR-ORG/', f'https://github.com/{gh_org}/'),
    ]),
    (os.path.join(script_dir, 'new-project.bat'), [
        ('https://github.com/YOUR-ORG/claude-dotfiles', dotfiles_url),
        ('https://github.com/YOUR-ORG/', f'https://github.com/{gh_org}/'),
    ]),
    (os.path.join(script_dir, '..', 'SESSION-SYNC-GUIDE.md'), [('YOUR-ORG', gh_org)]),
    (os.path.join(script_dir, '..', 'NEW-PROJECT-INSTRUCTIONS.md'), [('YOUR-ORG', gh_org)]),
    (os.path.join(script_dir, '..', 'README.md'), [('YOUR-ORG', gh_org)]),
]

for filepath, replacements in files_to_update:
    if not os.path.isfile(filepath):
        print(f'  [SKIP] {os.path.basename(filepath)} not found')
        continue
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    for old, new in replacements:
        content = content.replace(old, new)
    with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)
    print(f'  [OK] {os.path.basename(filepath)}')
" "!SCRIPT_DIR!" "!DOTFILES_URL!" "!DOTFILES_GIT!" "!GH_ORG!"

echo.
color 0A
echo ══════════════════════════════════════════════════
echo   Done^^! Scripts configured for: !GH_ORG!
echo ══════════════════════════════════════════════════
echo.
echo  Next steps:
echo    1. Create the dotfiles repo: !DOTFILES_URL!
echo    2. Run scripts\new-project.bat to set up your first project
if /i not "!CLAUDE_DIR!"=="!DEFAULT_CLAUDE_DIR!" (
    echo.
    echo  Custom Claude directory: !CLAUDE_DIR!
)
echo.
echo  To change any setting, run setup-owner again.
echo.

endlocal
pause
