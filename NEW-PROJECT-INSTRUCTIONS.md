# New Project Setup Instructions

## Quick Setup (Automated)

**Mac:**
```bash
cd ~/Desktop/CLAUDECODE
./scripts/new-project.sh
```

**Windows:**
```
cd C:\Users\YourName\Desktop\CLAUDECODE
scripts\new-project.bat
```

The script will:
1. Pull CLI sessions from GitHub on first run (includes full migration pipeline)
2. Ask for the GitHub repo URL
3. Clone or initialize the repo
4. Generate 6 scripts in the project's `scripts/` folder:
   - `push.sh` + `push.bat` — push code + sync this project's sessions
   - `pull.sh` + `pull.bat` — pull code + sync this project's sessions
   - `rollback.sh` + `rollback.bat` — rollback code to previous version
5. Copy `claude-launch.sh/.bat` and `SESSION-SYNC-GUIDE.md`

Each generated push/pull script has `--project your-org/<repo>` baked in for per-project session sync.

Repeat for each project.

---

## What the Generated Scripts Do

### push.sh / push.bat
1. Shows **PROJECT CODE STATUS** box (local vs remote, ahead/behind)
2. Warns if remote has commits you haven't pulled — asks to confirm
3. Shows changed files, asks for commit message
4. If no code changes, skips to session sync (doesn't exit)
5. Pushes code with version tag (v1, v2...)
6. Shows **SESSION SYNC STATUS** box
7. Syncs only this project's sessions (incremental push via `--project`)

### pull.sh / pull.bat
1. Shows **PROJECT CODE STATUS** box
2. Stashes local changes if any (asks first)
3. Pulls code from GitHub
4. Restores stashed changes (`git stash pop`)
5. Shows **SESSION SYNC STATUS** box
6. Syncs only this project's sessions via `--project`:
   - Merges sessions, subagents, tool-results, memory from other PC
   - Fixes paths, timestamps, plugin configs
   - Cleans up other-PC dirs
   - Imports MCP server configs

### rollback.sh / rollback.bat
1. Shows **CURRENT STATE** box with remote status warning
2. Shows version history
3. Shows **ROLLBACK PLAN** — what commits will be undone, what files will change
4. Asks to confirm
5. Creates rollback commit (history preserved)
6. Optionally pushes

---

## Manual Setup (For AI Assistants)

```bash
# Extract info from URL
# https://github.com/YOUR-ORG/my-project → name: my-project, display: My Project

# Create and clone
mkdir -p ~/Desktop/CLAUDECODE/my-project
cd ~/Desktop/CLAUDECODE/my-project
git clone https://github.com/YOUR-ORG/my-project.git .

# Generate scripts
python3 ~/Desktop/CLAUDECODE/scripts/new-project-gen.py "My Project" "https://github.com/YOUR-ORG/my-project" "$(pwd)"
chmod +x scripts/*.sh
```

---

## Folder Structure

```
CLAUDECODE/
├── scripts/                              <- Root scripts (all-project sync)
│   ├── push-all-sessions.sh / .bat       <- Push ALL sessions
│   ├── pull-all-sessions.sh / .bat       <- Pull ALL sessions
│   ├── rollback-all-sessions.sh / .bat   <- Rollback ALL sessions
│   ├── new-project.sh / .bat             <- Create new project
│   ├── new-project-gen.py                <- Script template generator
│   ├── sync-sessions.py                  <- Core engine (push/pull/--project)
│   ├── claude-launch.sh / .bat           <- Interactive launcher
│   └── (legacy .py helpers)
├── SESSION-SYNC-GUIDE.md
├── NEW-PROJECT-INSTRUCTIONS.md
├── n8n/
│   ├── scripts/
│   │   ├── push.sh / push.bat            <- Push code + n8n sessions
│   │   ├── pull.sh / pull.bat            <- Pull code + n8n sessions
│   │   ├── rollback.sh / rollback.bat    <- Rollback code
│   │   └── claude-launch.sh / .bat
│   ├── SESSION-SYNC-GUIDE.md
│   └── (project files...)
├── my-project/                       <- Same structure
├── my-other-project/
├── my-third-project/
├── my-webapp/
└── ...
```

---

## Scenarios

### Brand new PC
1. Install git, Python, Node.js, Claude Code
2. Create CLAUDECODE folder, get root scripts
3. `pull-all-sessions.bat` — pulls and migrates everything
4. `new-project.bat` for each project
5. `npm install` in claude-mem plugin dir
6. `claude --resume`

### Existing PC (returning after working on another machine)
1. `pull.bat` from each project — pulls code + that project's sessions
2. Or `pull-all-sessions.bat` for everything at once

### End of workday
1. `push.bat` from each project you worked on
2. Optionally `push-all-sessions.bat` for root-level sessions

---

## What Auto-Syncs (No Config Needed)

Any plugin, agent, skill, rule, hook, command, or MCP config you install goes into a tracked directory and syncs automatically. The only excluded files are:
- `.credentials.json` (OAuth tokens — security)
- `settings.local.json` (machine-specific permissions)
- `cache/`, `debug/`, `telemetry/` (temp data)
- `sessions/` (IDE process state, not session history)
- `stats-cache.json`, `*.untrimmed` (ephemeral)

Everything else syncs by default.

---

## Important Rules

1. All projects go under `CLAUDECODE/`
2. All projects use `main` branch
3. Per-project push/pull only syncs that project's sessions (via `--project`)
4. Root push/pull syncs ALL sessions
5. `.bat` needs CRLF line endings; `.sh` uses LF
6. Scripts generated by `new-project-gen.py` (single source of truth)
7. Push warns if remote has unmerged data
8. Every operation shows status before proceeding
