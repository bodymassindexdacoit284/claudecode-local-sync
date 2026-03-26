"""Fix platform-specific paths in Claude config files after cross-OS pull.

Updates installLocation/installPath in plugin config files to match the
current OS's home directory, so configs created on Windows work on Mac
and vice versa.

Usage: platform-fix.py
"""
import os, sys, json


def get_claude_dir():
    """Get Claude CLI directory. Checks: CLAUDE_DIR env, .claude-dir file, default."""
    env_dir = os.environ.get("CLAUDE_DIR")
    if env_dir and os.path.isdir(env_dir):
        return os.path.normpath(env_dir)
    config_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".claude-dir")
    if os.path.isfile(config_file):
        try:
            with open(config_file, "r", encoding="utf-8") as f:
                custom_dir = f.read().strip()
            if custom_dir and os.path.isdir(custom_dir):
                return os.path.normpath(custom_dir)
        except Exception:
            pass
    default = os.path.join(os.path.expanduser("~"), ".claude")
    if not os.path.isdir(default):
        print(f"  [WARNING] Claude directory not found at: {default}")
        print("  Run setup-owner to configure, or set CLAUDE_DIR environment variable.")
    return default


def main():
    claude_dir = get_claude_dir()
    fixed = []

    # ── known_marketplaces.json ──
    km_path = os.path.join(claude_dir, "plugins", "known_marketplaces.json")
    if os.path.isfile(km_path):
        try:
            with open(km_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            changed = False
            for name, info in data.items():
                if "installLocation" in info:
                    expected = os.path.join(claude_dir, "plugins", "marketplaces", name)
                    if os.path.normpath(info["installLocation"]) != os.path.normpath(expected):
                        info["installLocation"] = expected
                        changed = True
            if changed:
                with open(km_path, "w", encoding="utf-8", newline="\n") as f:
                    json.dump(data, f, indent=2)
                    f.write("\n")
                fixed.append("known_marketplaces.json")
        except Exception as e:
            print(f"  [WARNING] Could not fix known_marketplaces.json: {e}")

    # ── installed_plugins.json ──
    ip_path = os.path.join(claude_dir, "plugins", "installed_plugins.json")
    if os.path.isfile(ip_path):
        try:
            with open(ip_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            changed = False
            plugins = data.get("plugins", {})
            home_prefix = os.path.expanduser("~").replace("\\", "/") + "/.claude/"
            for plugin_name, installs in plugins.items():
                if not isinstance(installs, list):
                    continue
                for install in installs:
                    if not isinstance(install, dict) or "installPath" not in install:
                        continue
                    old_path = install["installPath"]
                    # Extract relative part using known home prefix
                    normalized = old_path.replace("\\", "/")
                    if normalized.startswith(home_prefix):
                        continue  # Already correct for this platform
                    # Find .claude/ anchored after a path separator
                    anchor = "/.claude/"
                    idx = normalized.find(anchor)
                    if idx >= 0:
                        relative = normalized[idx + len(anchor):]
                        relative_native = relative.replace("/", os.sep)
                        expected = os.path.join(claude_dir, relative_native)
                        install["installPath"] = expected
                        changed = True
            if changed:
                with open(ip_path, "w", encoding="utf-8", newline="\n") as f:
                    json.dump(data, f, indent=2)
                    f.write("\n")
                fixed.append("installed_plugins.json")
        except Exception as e:
            print(f"  [WARNING] Could not fix installed_plugins.json: {e}")

    if fixed:
        print(f"  [OK] Fixed platform paths in: {', '.join(fixed)}")
    else:
        print("  All config paths already correct for this platform.")


if __name__ == "__main__":
    main()
