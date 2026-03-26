#!/bin/bash
# Push ALL CLI Sessions to GitHub

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDECODE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
echo "  ══════════════════════════════════════════════════"
echo "  Push ALL Sessions to GitHub"
echo "  ══════════════════════════════════════════════════"
echo ""

PY_CMD=""
if command -v python3 &>/dev/null; then PY_CMD="python3"
elif command -v python &>/dev/null; then PY_CMD="python"
elif command -v py &>/dev/null; then PY_CMD="py"
fi

if [ -z "$PY_CMD" ]; then
    echo "  [ERROR] Python not found."
    read -p "  Press Enter to close..." _
    exit 1
fi

"$PY_CMD" "$SCRIPT_DIR/sync-sessions.py" push "$CLAUDECODE_DIR"
read -p "  Press Enter to close..." _
