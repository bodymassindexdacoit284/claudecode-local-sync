"""Claude Code Launcher — Interactive TUI for launching Claude Code with common flags.

Part of the CLAUDECODE session sync system. This launcher provides a menu-driven
interface for selecting session options, model, and mode before launching Claude Code.

Works on macOS (Terminal/iTerm2) and Windows (cmd/PowerShell/Windows Terminal).
"""
import os, sys

if sys.platform == "win32":
    import msvcrt
else:
    import tty, termios

# ── Colors (ANSI) ──
RESET  = "\033[0m"
BOLD   = "\033[1m"
DIM    = "\033[2m"
CYAN   = "\033[36m"
GREEN  = "\033[32m"
YELLOW = "\033[33m"
WHITE  = "\033[97m"
BG_CYAN = "\033[46m"
INVERT = "\033[7m"

# ── Detect launch dir ──
# The .bat/.sh wrapper passes its directory as argv[1] so we know the project path
if len(sys.argv) > 1:
    launch_dir = os.path.abspath(sys.argv[1])
else:
    launch_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
if os.path.basename(launch_dir).lower() == "scripts":
    launch_dir = os.path.dirname(launch_dir)
os.chdir(launch_dir)

# ── Menu items ──
# Checkboxes: toggle on/off with Space/Enter
checkboxes = [
    {"key": "resume",     "label": "Resume session",              "flag": "--resume",       "on": False,
     "desc": "--resume"},
    {"key": "continue",   "label": "Continue last session",        "flag": "--continue",     "on": False,
     "desc": "--continue"},
    {"key": "auto",       "label": "Auto mode (accept all)",       "flag": "--enable-auto-mode", "on": False,
     "desc": "--enable-auto-mode"},
    {"key": "dangerous",  "label": "Skip permissions (dangerous)", "flag": "--dangerously-skip-permissions", "on": False,
     "desc": "--dangerously-skip-permissions"},
]

# Models: select one with Space/Enter
models = [
    {"label": "Default",      "flag": None,     "desc": "(no flag)"},
    {"label": "Opus 4.6",     "flag": "opus",   "desc": "--model opus"},
    {"label": "Sonnet 4.6",   "flag": "sonnet", "desc": "--model sonnet"},
    {"label": "Haiku 4.5",    "flag": "haiku",  "desc": "--model haiku"},
]

# Mutually exclusive checkbox keys
EXCLUSIVE_PAIRS = [("resume", "continue")]

selected_model = 0
cursor = 0
# Total items: checkboxes + models + launch button
TOTAL_ITEMS = len(checkboxes) + len(models) + 1


def get_key():
    """Read a single keypress. Returns 'up', 'down', 'enter', 'space', 'esc', or a character."""
    if sys.platform == "win32":
        ch = msvcrt.getwch()
        if ch == '\r': return 'enter'
        if ch == '\x1b': return 'esc'
        if ch == ' ': return 'space'
        if ch in ('\x00', '\xe0'):
            ch2 = msvcrt.getwch()
            if ch2 == 'H': return 'up'
            if ch2 == 'P': return 'down'
            return None
        return ch.lower()
    else:
        fd = sys.stdin.fileno()
        old = termios.tcgetattr(fd)
        try:
            tty.setraw(fd)
            ch = sys.stdin.read(1)
            if ch in ('\r', '\n'): return 'enter'
            if ch == ' ': return 'space'
            if ch == '\x1b':
                ch2 = sys.stdin.read(1)
                if ch2 == '[':
                    ch3 = sys.stdin.read(1)
                    if ch3 == 'A': return 'up'
                    if ch3 == 'B': return 'down'
                    return None
                return 'esc'
            return ch.lower()
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old)


def clear():
    """Clear the terminal screen."""
    os.system('cls' if sys.platform == 'win32' else 'clear')


def build_command():
    """Build the claude CLI command string from current selections."""
    parts = ["claude"]
    for cb in checkboxes:
        if cb["on"]:
            parts.append(cb["flag"])
    if models[selected_model]["flag"]:
        parts.extend(["--model", models[selected_model]["flag"]])
    return " ".join(parts)


def draw():
    """Render the full TUI to the terminal."""
    # Use ANSI cursor positioning instead of clear() to prevent scroll
    sys.stdout.write("\033[H\033[J")  # Move cursor home + clear screen
    sys.stdout.flush()

    row = 0
    lines = []
    lines.append("")
    lines.append(f"  {CYAN}{BOLD}CLAUDE CODE LAUNCHER{RESET}  {DIM}|{RESET}  {WHITE}{os.path.basename(launch_dir)}{RESET}  {DIM}({launch_dir}){RESET}")
    lines.append(f"  {DIM}{'─' * 60}{RESET}")
    lines.append("")

    # ── Checkboxes ──
    lines.append(f"  {BOLD}Options{RESET}")
    for i, cb in enumerate(checkboxes):
        is_cur = (cursor == row)
        check = f"{GREEN}X{RESET}" if cb["on"] else " "
        if is_cur:
            lines.append(f"  {INVERT} [{check}{INVERT}] {cb['label']:<28}{RESET}  {DIM}{cb['desc']}{RESET}")
        else:
            lines.append(f"   [{check}] {cb['label']:<28}  {DIM}{cb['desc']}{RESET}")
        row += 1

    lines.append("")
    lines.append(f"  {BOLD}Model{RESET}")

    # ── Model radio buttons ──
    for i, m in enumerate(models):
        is_cur = (cursor == row)
        radio = f"{GREEN}*{RESET}" if selected_model == i else " "
        if is_cur:
            lines.append(f"  {INVERT} ({radio}{INVERT}) {m['label']:<16}{RESET}  {DIM}{m['desc']}{RESET}")
        else:
            lines.append(f"   ({radio}) {m['label']:<16}  {DIM}{m['desc']}{RESET}")
        row += 1

    lines.append("")
    lines.append(f"  {DIM}{'─' * 60}{RESET}")

    # ── Launch button ──
    is_cur = (cursor == row)
    if is_cur:
        lines.append(f"  {BG_CYAN}{BOLD}{WHITE}  >>> LAUNCH <<<  {RESET}")
    else:
        lines.append(f"  {DIM}  >>> LAUNCH <<<  {RESET}")

    lines.append(f"  {DIM}{'─' * 60}{RESET}")

    # ── Command preview ──
    cmd = build_command()
    lines.append(f"  {BOLD}Command:{RESET} {GREEN}{cmd}{RESET}")
    lines.append(f"  {DIM}↑↓ Navigate  |  Space/Enter Select  |  Esc/Q Quit{RESET}")
    lines.append("")

    print("\n".join(lines))


def main():
    global cursor, selected_model

    # Enable ANSI escape codes on Windows
    os.system('')

    while True:
        draw()
        key = get_key()
        if key is None:
            continue
        if key in ('esc', 'q'):
            clear()
            print("\n  Cancelled.\n")
            sys.exit(0)

        if key == 'up':
            cursor = max(0, cursor - 1)
        elif key == 'down':
            cursor = min(TOTAL_ITEMS - 1, cursor + 1)
        elif key in ('space', 'enter'):
            # Checkbox zone
            if cursor < len(checkboxes):
                cb = checkboxes[cursor]
                cb["on"] = not cb["on"]
                # Enforce mutual exclusivity
                if cb["on"]:
                    for pair in EXCLUSIVE_PAIRS:
                        if cb["key"] in pair:
                            other_key = pair[1] if cb["key"] == pair[0] else pair[0]
                            for c in checkboxes:
                                if c["key"] == other_key:
                                    c["on"] = False
            # Model zone
            elif cursor < len(checkboxes) + len(models):
                selected_model = cursor - len(checkboxes)
            # Launch button
            elif cursor == TOTAL_ITEMS - 1:
                do_launch()
                return


def do_launch():
    """Build and execute the claude command."""
    clear()
    cmd = build_command()
    print()
    print(f"  {GREEN}{BOLD}Launching Claude Code...{RESET}")
    print(f"  {DIM}Path:    {launch_dir}{RESET}")
    print(f"  {DIM}Command: {cmd}{RESET}")
    print()

    parts = ["claude"]
    for cb in checkboxes:
        if cb["on"]:
            parts.append(cb["flag"])
    if models[selected_model]["flag"]:
        parts.extend(["--model", models[selected_model]["flag"]])

    os.execvp("claude", parts)


if __name__ == "__main__":
    main()
