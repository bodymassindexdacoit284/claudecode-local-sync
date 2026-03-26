@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
title Claude Sessions — Rollback
color 0E

echo ══════════════════════════════════════════════════════════════════════════════
echo   CLAUDE SESSIONS — Rollback to Previous Sync
echo ══════════════════════════════════════════════════════════════════════════════
echo.

where git >nul 2>&1
if errorlevel 1 (
    color 0C
    echo  [ERROR] git is not installed or not in PATH.
    pause
    exit /b 1
)

cd /d "%USERPROFILE%\.claude"

if not exist ".git" (
    color 0C
    echo  [ERROR] No session repo found at %USERPROFILE%\.claude
    echo  See SESSION-SYNC-GUIDE.md for setup instructions.
    pause
    exit /b 1
)

:: ── Remote status check ──
git fetch origin main --tags >nul 2>&1
set "BEHIND=0"
for /f %%n in ('git rev-list --count HEAD..origin/main 2^>nul') do set "BEHIND=%%n"
if !BEHIND! GTR 0 (
    echo  [WARNING] Remote has !BEHIND! commit(s^) you haven't pulled.
    echo  Rolling back without pulling first means those remote sessions are lost.
    echo.
)

:: ── Current state ──
echo  CURRENT STATE:
echo ──────────────────────────────────────────────────────────────────────────────
for /f "tokens=*" %%c in ('git log -1 --format^="  %%h  %%ad  %%s" --date^=short') do echo %%c
echo ──────────────────────────────────────────────────────────────────────────────
echo.

:: ── Show session sync history ──
echo  SESSION SYNC HISTORY (most recent first):
echo ══════════════════════════════════════════════════════════════════════════════
echo.
echo  TAG        DATE         MESSAGE
echo  ───────    ──────────   ─────────────────────────────────────────
echo.

set TAG_COUNT=0
for /f "tokens=*" %%t in ('git tag --sort^=-version:refname -l "s*"') do (
    set "TAG=%%t"
    set /a TAG_COUNT+=1

    for /f "tokens=*" %%d in ('git log -1 --format^="%%ad" --date^=short "%%t" 2^>nul') do set "TDATE=%%d"

    for /f "tokens=*" %%m in ('git tag -l --format^="%%(contents:subject)" "%%t" 2^>nul') do set "TMSG=%%m"
    if "!TMSG!"=="" (
        for /f "tokens=*" %%m in ('git log -1 --format^="%%s" "%%t" 2^>nul') do set "TMSG=%%m"
    )

    set "PADTAG=!TAG!          "
    set "PADTAG=!PADTAG:~0,10!"

    echo   !PADTAG! !TDATE!   !TMSG!
)

if !TAG_COUNT!==0 (
    echo    (no session sync tags found)
    echo.
    echo  FULL COMMIT LOG (last 10):
    echo ──────────────────────────────────────────────────────────────────────────────
    git log --format="  %%h  %%ad  %%s" --date=short -10
    echo ──────────────────────────────────────────────────────────────────────────────
)

echo.
echo ══════════════════════════════════════════════════════════════════════════════
echo.

:: ── Ask for rollback target ──
echo  Enter a session tag (e.g. s3) or a commit hash (e.g. 5d8c50a)
echo  Type "quit" to cancel.
echo.
set /p TARGET="  Rollback to: "
if /i "!TARGET!"=="quit" ( echo  Cancelled. & pause & exit /b 0 )
if "!TARGET!"=="" ( echo  Cancelled. & pause & exit /b 0 )

:: ── Verify target exists ──
git rev-parse "!TARGET!" >nul 2>&1
if errorlevel 1 (
    color 0C
    echo.
    echo  [ERROR] Version "!TARGET!" not found.
    pause
    exit /b 1
)

:: ── Show what will happen ──
echo.
echo ══════════════════════════════════════════════════════════════════════════════
echo  TARGET: !TARGET!
echo ══════════════════════════════════════════════════════════════════════════════
echo.
git log -1 --format="    Hash:    %%H%%n    Date:    %%ad%%n    Message: %%s" --date=format:"%%Y-%%m-%%d %%H:%%M" "!TARGET!"
echo.

set UNDO_COUNT=0
for /f %%n in ('git rev-list "!TARGET!..HEAD" --count 2^>nul') do set UNDO_COUNT=%%n
if !UNDO_COUNT!==0 (
    echo  (none — you are already at this version)
    pause
    exit /b 0
)

echo  !UNDO_COUNT! sync(s) will be reverted.
echo.
echo  WARNING: This will restore your sessions to how they were at !TARGET!.
echo  Any sessions created after this point will be removed locally.
echo  A new commit will be created — you can undo this rollback later.
echo.
set /p CONFIRM="  Proceed with rollback to !TARGET!? (Y/N): "
if /i not "!CONFIRM!"=="Y" ( echo  Cancelled. & pause & exit /b 0 )

:: ── Perform rollback ──
echo.
echo  Rolling back sessions...

git checkout "!TARGET!" -- .
if errorlevel 1 ( color 0C & echo  [ERROR] Rollback failed. & pause & exit /b 1 )

git add -A
git commit -m "[ROLLBACK] Sessions reverted to !TARGET!"
if errorlevel 1 ( color 0C & echo  [ERROR] Commit failed. & pause & exit /b 1 )

echo.
set /p PUSHIT="  Push session rollback to cloud? (Y/N): "
if /i "!PUSHIT!"=="Y" (
    git push origin main --tags
    if errorlevel 1 ( color 0C & echo  [ERROR] Push failed. Rollback saved locally. & pause & exit /b 1 )
)

echo.
color 0A
echo ══════════════════════════════════════════════════════════════════════════════
echo  SUCCESS! Sessions rolled back to !TARGET!
echo ══════════════════════════════════════════════════════════════════════════════
echo.
echo  Your sessions are now at version !TARGET!. History preserved.
echo.

endlocal
pause
