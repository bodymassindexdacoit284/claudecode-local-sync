#!/bin/bash
# Pull ALL CLI Sessions from GitHub

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDECODE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
echo "  ══════════════════════════════════════════════════"
echo "  Pull ALL Sessions from GitHub"
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

"$PY_CMD" "$SCRIPT_DIR/sync-sessions.py" pull "$CLAUDECODE_DIR"
read -p "  Press Enter to close..." _
