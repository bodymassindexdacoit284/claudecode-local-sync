#!/bin/bash
# Claude CLI Sessions — Rollback to Previous Sync

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "══════════════════════════════════════════════════════════════════════════════"
echo "  CLAUDE CLI SESSIONS — Rollback to Previous Sync"
echo "══════════════════════════════════════════════════════════════════════════════"
echo ""

if ! command -v git &>/dev/null; then
    echo -e "${RED}  [ERROR] git is not installed.${NC}"
    exit 1
fi

CLAUDE_DIR="$HOME/.claude"
cd "$CLAUDE_DIR" 2>/dev/null

if [ ! -d ".git" ]; then
    echo -e "${RED}  [ERROR] No session repo at $CLAUDE_DIR${NC}"
    exit 1
fi

# ── Remote status check ──
git fetch origin main --tags >/dev/null 2>&1
AHEAD=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)
BEHIND=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo 0)
LOCAL_INFO=$(git log -1 --format="%h  %ad  %s" --date=format:"%Y-%m-%d %H:%M" 2>/dev/null)
REMOTE_INFO=$(git log -1 --format="%h  %ad  %s" --date=format:"%Y-%m-%d %H:%M" origin/main 2>/dev/null)

echo "  ┌─────────────────────────────────────────────────┐"
echo "  │  SESSION SYNC STATUS                            │"
echo "  ├─────────────────────────────────────────────────┤"
echo "  │  Local:  $LOCAL_INFO"
echo "  │  Remote: $REMOTE_INFO"
echo "  │  Ahead: $AHEAD commit(s)  Behind: $BEHIND commit(s)"
echo "  └─────────────────────────────────────────────────┘"
echo ""

if [ "$BEHIND" -gt 0 ] 2>/dev/null; then
    echo -e "${YELLOW}  [WARNING] Remote has $BEHIND commit(s) you haven't pulled.${NC}"
    echo "  Rolling back without pulling first means those remote sessions are lost."
    echo ""
fi

echo "  CURRENT STATE:"
echo "──────────────────────────────────────────────────────────────────────────────"
git log -1 --format="  %h  %ad  %s" --date=short
echo "──────────────────────────────────────────────────────────────────────────────"
echo ""

echo "  SESSION SYNC HISTORY (most recent first):"
echo "══════════════════════════════════════════════════════════════════════════════"
echo ""

TAG_COUNT=0
for t in $(git tag --sort=-version:refname -l "s*"); do
    TAG_COUNT=$((TAG_COUNT + 1))
    TDATE=$(git log -1 --format="%ad" --date=short "$t" 2>/dev/null)
    TMSG=$(git tag -l --format="%(contents:subject)" "$t" 2>/dev/null)
    [ -z "$TMSG" ] && TMSG=$(git log -1 --format="%s" "$t" 2>/dev/null)
    printf "  %-10s %s   %s\n" "$t" "$TDATE" "$TMSG"
done

if [ $TAG_COUNT -eq 0 ]; then
    echo "  (no session sync tags found)"
    echo ""
    echo "  FULL COMMIT LOG (last 10):"
    echo "──────────────────────────────────────────────────────────────────────────────"
    git log --format="  %h  %ad  %s" --date=short -10
    echo "──────────────────────────────────────────────────────────────────────────────"
fi

echo ""
echo "══════════════════════════════════════════════════════════════════════════════"
echo ""

echo "  Enter a session tag (e.g. s3) or a commit hash"
echo "  Type \"quit\" to cancel."
echo ""
read -p "  Rollback to: " TARGET

if [ -z "$TARGET" ] || [ "$TARGET" = "quit" ]; then
    echo "  Cancelled."
    exit 0
fi

if ! git rev-parse "$TARGET" >/dev/null 2>&1; then
    echo -e "${RED}  [ERROR] Version \"$TARGET\" not found.${NC}"
    exit 1
fi

UNDO_COUNT=$(git rev-list "$TARGET..HEAD" --count 2>/dev/null)
if [ "$UNDO_COUNT" = "0" ]; then
    echo "  Already at this version."
    exit 0
fi

echo ""
echo "  $UNDO_COUNT sync(s) will be reverted."
echo ""
read -p "  Proceed? (Y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "  Cancelled."
    exit 0
fi

git checkout "$TARGET" -- .
git add -A
git commit -m "[ROLLBACK] Sessions reverted to $TARGET"

echo ""
read -p "  Push session rollback? (Y/N): " PUSHIT
if [[ "$PUSHIT" =~ ^[Yy]$ ]]; then
    git push origin main --tags
fi

echo ""
echo -e "${GREEN}  SUCCESS! Sessions rolled back to $TARGET${NC}"
echo ""
read -p "  Press Enter to close..." _
