#!/bin/bash
# Configure CLAUDECODE for a new owner
# Run once after copying the scripts/ folder to a new machine
# Safe to run again if anything changes

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "══════════════════════════════════════════════════"
echo "  CLAUDECODE — Owner Setup"
echo "══════════════════════════════════════════════════"
echo ""
echo "  This configures the scripts for your GitHub account"
echo "  and Claude Code directory. Run again anytime to update."
echo ""
echo "══════════════════════════════════════════════════"
echo ""

# ══════════════════════════════════════════════════════
#  STEP 1: Locate Claude CLI directory
# ══════════════════════════════════════════════════════
echo "  ── Step 1: Claude Code CLI Directory ──"
echo ""

# Auto-detect by searching common locations
DETECTED_DIR=""
for candidate in \
    "$HOME/.claude" \
    "$HOME/.config/claude" \
    "$USERPROFILE/.claude" \
; do
    if [ -d "$candidate" ] && [ -d "$candidate/projects" ]; then
        DETECTED_DIR="$candidate"
        break
    fi
done

# Fallback: check if directory exists even without projects/
if [ -z "$DETECTED_DIR" ]; then
    for candidate in "$HOME/.claude" "$HOME/.config/claude"; do
        if [ -d "$candidate" ]; then
            DETECTED_DIR="$candidate"
            break
        fi
    done
fi

CLAUDE_DIR=""
while true; do
    if [ -n "$DETECTED_DIR" ]; then
        echo -e "  ${GREEN}[FOUND]${NC} Claude CLI directory detected at:"
        echo "    $DETECTED_DIR"
        echo ""

        # Show what's in it
        if [ -d "$DETECTED_DIR/projects" ]; then
            PROJ_COUNT=$(ls -d "$DETECTED_DIR/projects"/*/ 2>/dev/null | wc -l | tr -d ' ')
            echo "  Contains: $PROJ_COUNT session folder(s)"
        fi
        if [ -f "$DETECTED_DIR/settings.json" ]; then
            echo "  Has: settings.json"
        fi
        if [ -d "$DETECTED_DIR/plugins" ]; then
            echo "  Has: plugins/"
        fi
        echo ""

        read -p "  Is this correct? (Y/N): " DIR_CONFIRM
        if [[ "$DIR_CONFIRM" =~ ^[Yy]$ ]]; then
            CLAUDE_DIR="$DETECTED_DIR"
            break
        else
            echo ""
            echo "  Enter the path to your Claude CLI directory:"
            read -p "  Path: " CUSTOM_DIR
            if [ -z "$CUSTOM_DIR" ]; then
                echo -e "  ${RED}[ERROR] No path entered.${NC}"
                continue
            fi
            if [ -d "$CUSTOM_DIR" ]; then
                CLAUDE_DIR="$CUSTOM_DIR"
                break
            else
                echo -e "  ${RED}[ERROR] Directory does not exist: $CUSTOM_DIR${NC}"
                echo "  Please check the path and try again."
                echo ""
                DETECTED_DIR=""
                continue
            fi
        fi
    else
        echo -e "  ${YELLOW}[NOT FOUND]${NC} Could not auto-detect Claude CLI directory."
        echo ""
        echo "  Claude Code CLI typically stores its data at:"
        echo "    Mac/Linux: ~/.claude"
        echo "    Windows:   %USERPROFILE%\\.claude"
        echo ""
        echo "  Enter the path to your Claude CLI directory:"
        read -p "  Path: " CUSTOM_DIR
        if [ -z "$CUSTOM_DIR" ]; then
            echo -e "  ${RED}[ERROR] No path entered.${NC}"
            echo ""
            continue
        fi
        if [ -d "$CUSTOM_DIR" ]; then
            CLAUDE_DIR="$CUSTOM_DIR"
            break
        else
            echo -e "  ${YELLOW}[INFO]${NC} Directory does not exist yet: $CUSTOM_DIR"
            echo "  It will be created when you first run pull-all-sessions."
            CLAUDE_DIR="$CUSTOM_DIR"
            break
        fi
    fi
done

echo ""

# ══════════════════════════════════════════════════════
#  STEP 2: Dotfiles repo
# ══════════════════════════════════════════════════════
echo "  ── Step 2: Dotfiles Repository ──"
echo ""
echo "  Your Claude dotfiles repo stores sessions, memory,"
echo "  plugins, and settings across machines."
echo ""
echo "  Create a PRIVATE repo on GitHub for this, e.g.:"
echo "    https://github.com/your-org/claude-dotfiles"
echo ""
read -p "  Dotfiles repo URL: " DOTFILES_URL

if [ -z "$DOTFILES_URL" ]; then
    echo -e "${RED}  [ERROR] No URL provided.${NC}"
    read -p "  Press Enter to close..." _
    exit 1
fi

DOTFILES_URL="${DOTFILES_URL%.git}"
DOTFILES_URL="${DOTFILES_URL%/}"
DOTFILES_GIT="${DOTFILES_URL}.git"

# ══════════════════════════════════════════════════════
#  STEP 3: GitHub org
# ══════════════════════════════════════════════════════
echo ""
echo "  ── Step 3: GitHub Organization ──"
echo ""
echo "  Your GitHub org or username (for project repo examples)."
echo "  Example: my-company, my-username"
echo ""
read -p "  GitHub org/username: " GH_ORG

if [ -z "$GH_ORG" ]; then
    echo -e "${RED}  [ERROR] No org provided.${NC}"
    read -p "  Press Enter to close..." _
    exit 1
fi

# ══════════════════════════════════════════════════════
#  Confirmation
# ══════════════════════════════════════════════════════
DEFAULT_CLAUDE_DIR="$HOME/.claude"
echo ""
echo "  ══════════════════════════════════════════════════"
echo "  Claude directory: $CLAUDE_DIR"
echo "  Dotfiles repo:    $DOTFILES_URL"
echo "  GitHub org:        $GH_ORG"
echo "  ══════════════════════════════════════════════════"
echo ""
read -p "  Apply these settings? (Y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "  Cancelled."
    read -p "  Press Enter to close..." _
    exit 0
fi

echo ""
echo "  Applying..."

# ── Save Claude directory override ──
CLAUDE_DIR_FILE="$SCRIPT_DIR/.claude-dir"
NORM_CLAUDE=$(cd "$CLAUDE_DIR" 2>/dev/null && pwd || echo "$CLAUDE_DIR")
NORM_DEFAULT=$(cd "$DEFAULT_CLAUDE_DIR" 2>/dev/null && pwd || echo "$DEFAULT_CLAUDE_DIR")

if [ "$NORM_CLAUDE" != "$NORM_DEFAULT" ]; then
    echo "$CLAUDE_DIR" > "$CLAUDE_DIR_FILE"
    echo -e "  ${GREEN}[OK]${NC} Custom Claude directory: $CLAUDE_DIR"
else
    rm -f "$CLAUDE_DIR_FILE"
    echo -e "  ${GREEN}[OK]${NC} Default Claude directory: $DEFAULT_CLAUDE_DIR"
fi

# ── Update sync-sessions.py ──
SYNC_PY="$SCRIPT_DIR/sync-sessions.py"
if [ -f "$SYNC_PY" ]; then
    sed -i '' "s|CLI_REPO = \".*\"|CLI_REPO = \"${DOTFILES_GIT}\"|" "$SYNC_PY"
    echo -e "  ${GREEN}[OK]${NC} sync-sessions.py"
fi

# ── Update new-project.sh ──
NP_SH="$SCRIPT_DIR/new-project.sh"
if [ -f "$NP_SH" ]; then
    sed -i '' "s|https://github.com/YOUR-ORG/claude-dotfiles|${DOTFILES_URL}|g" "$NP_SH"
    sed -i '' "s|https://github.com/YOUR-ORG/|https://github.com/${GH_ORG}/|g" "$NP_SH"
    echo -e "  ${GREEN}[OK]${NC} new-project.sh"
fi

# ── Update new-project.bat ──
NP_BAT="$SCRIPT_DIR/new-project.bat"
if [ -f "$NP_BAT" ]; then
    sed -i '' "s|https://github.com/YOUR-ORG/claude-dotfiles|${DOTFILES_URL}|g" "$NP_BAT"
    sed -i '' "s|https://github.com/YOUR-ORG/|https://github.com/${GH_ORG}/|g" "$NP_BAT"
    echo -e "  ${GREEN}[OK]${NC} new-project.bat"
fi

# ── Update docs ──
for doc in "$SCRIPT_DIR/../SESSION-SYNC-GUIDE.md" "$SCRIPT_DIR/../NEW-PROJECT-INSTRUCTIONS.md" "$SCRIPT_DIR/../README.md"; do
    if [ -f "$doc" ]; then
        sed -i '' "s|YOUR-ORG/claude-dotfiles|$(echo "$DOTFILES_URL" | sed 's|https://github.com/||')|g" "$doc"
        sed -i '' "s|YOUR-ORG|${GH_ORG}|g" "$doc"
        echo -e "  ${GREEN}[OK]${NC} $(basename "$doc")"
    fi
done

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Done! Scripts configured for: ${GH_ORG}${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo ""
echo "  Next steps:"
echo "    1. Create the dotfiles repo: $DOTFILES_URL"
echo "    2. Run ./scripts/new-project.sh to set up your first project"
if [ "$NORM_CLAUDE" != "$NORM_DEFAULT" ]; then
    echo ""
    echo "  Custom Claude directory: $CLAUDE_DIR"
fi
echo ""
echo "  To change any setting, run setup-owner again."
echo ""
read -p "  Press Enter to close..." _
