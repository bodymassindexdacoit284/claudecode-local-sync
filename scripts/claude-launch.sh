#!/bin/bash
# Claude Code Launcher — finds claude-launch.py and runs it

# The .py file always lives in CLAUDECODE/scripts/
# This .sh can be in CLAUDECODE/, CLAUDECODE/scripts/, or CLAUDECODE/<project>/scripts/

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PY_FILE=""

# Check 1: .py is right next to this .sh (we're in CLAUDECODE/scripts/)
if [ -f "$SCRIPT_DIR/claude-launch.py" ]; then
    PY_FILE="$SCRIPT_DIR/claude-launch.py"

# Check 2: we're in CLAUDECODE root, .py is in scripts/ subfolder
elif [ -f "$SCRIPT_DIR/scripts/claude-launch.py" ]; then
    PY_FILE="$SCRIPT_DIR/scripts/claude-launch.py"

# Check 3: we're in <project>/scripts/, go up two levels to CLAUDECODE/scripts/
else
    PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    CODE_ROOT="$(cd "$PROJ_ROOT/.." && pwd)"
    if [ -f "$CODE_ROOT/scripts/claude-launch.py" ]; then
        PY_FILE="$CODE_ROOT/scripts/claude-launch.py"
    fi
fi

if [ -z "$PY_FILE" ]; then
    echo "  [ERROR] Could not find claude-launch.py"
    echo "  Expected in: CLAUDECODE/scripts/claude-launch.py"
    exit 1
fi

# Find Python
PYTHON_CMD=""
if command -v python3 &>/dev/null; then PYTHON_CMD="python3"
elif command -v python &>/dev/null; then PYTHON_CMD="python"
elif command -v py &>/dev/null; then PYTHON_CMD="py"
fi

if [ -z "$PYTHON_CMD" ]; then
    echo "  [ERROR] Python not found. Install from python.org"
    exit 1
fi

# Launch — pass this .sh's directory so Python knows the project path
"$PYTHON_CMD" "$PY_FILE" "$SCRIPT_DIR"
read -p "  Press Enter to close..." _
