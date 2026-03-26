# Contributing to Claude Sync

Thank you for your interest in improving Claude Sync. This guide explains the architecture so you can contribute effectively.

## Architecture Overview

```
sync-sessions.py          <- The engine. All sync logic lives here (~1500 lines).
new-project-gen.py         <- Template generator. Per-project scripts are generated from here.
setup-owner.sh/.bat        <- First-time configuration. Updates hardcoded refs in other files.
platform-fix.py            <- Standalone plugin path fixer (also embedded in sync-sessions.py).
push-all-sessions.sh/.bat  <- Thin wrappers that call sync-sessions.py push.
pull-all-sessions.sh/.bat  <- Thin wrappers that call sync-sessions.py pull.
```

### Key Design Decisions

- **sync-sessions.py is the single source of truth** for all sync logic. The shell/batch scripts are thin wrappers.
- **new-project-gen.py is the single source of truth** for per-project scripts. Never edit a generated `push.sh` or `pull.bat` directly — edit the template in `new-project-gen.py` instead.
- **Projects are matched by git remote**, not by folder name or path. This allows the same project to have different folder names on different machines.
- **Everything syncs by default.** The `.gitignore` exclusion list is intentionally short. New plugins, agents, skills, etc. sync automatically without config changes.
- **Per-project sync uses `--project org/repo`** flag to scope operations. Without the flag, all projects are synced.
- **All paths are dynamic.** Nothing is hardcoded to a specific directory. Scripts resolve their location relative to themselves.

### How the Pipeline Functions Work

Every pipeline function (merge, fix paths, cleanup, etc.) accepts an optional `project_filter` parameter:
- `None` (default) = process everything (used by root push/pull)
- `"project-name"` = process only dirs matching that project (used by per-project push/pull)

This means adding a new pipeline step is straightforward:
1. Add a function with `project_filter=None` parameter
2. Use `_dir_matches_project()` or `_walk_matches_project()` for filtering
3. Call it from both `push_sessions`/`pull_sessions` (without filter) and `push_project`/`pull_project` (with filter)

## How to Contribute

### Bug Fixes

1. Fork the repo
2. Create a branch: `git checkout -b fix/description`
3. Fix the bug in the appropriate file (usually `sync-sessions.py`)
4. If the fix affects per-project scripts, also update the template in `new-project-gen.py`
5. Test on both Mac and Windows if possible
6. Submit a PR with a clear description of what was broken and how you fixed it

### New Features

1. Open an issue first to discuss the feature
2. Follow the existing patterns:
   - Pipeline functions go in `sync-sessions.py` with `project_filter` support
   - Script template changes go in `new-project-gen.py`
   - Both `.sh` and `.bat` versions must be updated in parallel
3. Keep the "everything syncs by default" philosophy — avoid adding things to `.gitignore`
4. Test the full cycle: push from Mac, pull on Windows (or vice versa)

### Adding Platform Support (e.g., Linux)

The system currently supports macOS and Windows. To add Linux:
- `sync-sessions.py` should work as-is (it's Python, platform-agnostic)
- `.sh` scripts should work as-is (bash is standard on Linux)
- `.bat` scripts are Windows-only (no change needed)
- Test path encoding: Linux paths are similar to Mac (`/home/user/...`)
- Test symlink behavior: Linux uses symlinks like Mac

### Code Style

- **Python**: Standard library only (no pip dependencies). The engine must run on any machine with Python 3.8+.
- **Shell (.sh)**: Bash-compatible. Quote all variables. Use `read -p` for pauses.
- **Batch (.bat)**: Use `setlocal enabledelayedexpansion`. Use `pushd/popd` for path resolution (not `for %%I` with `%%~dpI`).
- **Templates in new-project-gen.py**: Use `{{` and `}}` to escape braces in `.format()` strings. Use `{display}`, `{repo}`, `{remote_slug}` as template variables.

### Testing

There's no automated test suite (yet). To test changes:

1. **Mac push → Windows pull**: Push from Mac, pull on Windows. Verify sessions appear in `claude --resume` with correct timestamps.
2. **Windows push → Mac pull**: Same in reverse.
3. **Per-project isolation**: Push from one project, verify other projects' sessions are untouched.
4. **Fresh machine**: Delete `~/.claude/`, run `pull-all-sessions`, verify everything restores.
5. **Large files**: Create a session >90MB, push, pull on another machine, verify history is preserved.

### File Inventory

| File | Role | Edit directly? |
|---|---|---|
| `sync-sessions.py` | Core engine | Yes — all sync logic |
| `new-project-gen.py` | Template generator | Yes — changes propagate to new projects |
| `setup-owner.sh/.bat` | First-time config | Yes |
| `platform-fix.py` | Plugin path fixer | Yes (also duplicated in sync-sessions.py) |
| `push-all-sessions.sh/.bat` | Root push wrapper | Yes |
| `pull-all-sessions.sh/.bat` | Root pull wrapper | Yes |
| `rollback-all-sessions.sh/.bat` | Root rollback | Yes |
| `new-project.sh/.bat` | Project creation wizard | Yes |
| `claude-launch.py` | Launcher TUI | Yes |
| `claude-launch.sh/.bat` | Launcher wrapper | Yes |
| Per-project `push/pull/rollback` | Generated scripts | **No** — edit `new-project-gen.py` instead |

## Questions?

Open an issue. We're happy to help.
