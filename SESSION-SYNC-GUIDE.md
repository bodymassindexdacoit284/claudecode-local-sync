# Claude Session Sync Guide

## What This System Does

Everything in your `~/.claude/` directory syncs across Mac and Windows — sessions, memory, plugins, agents, skills, rules, hooks, commands, MCP configs, project settings. It's designed so switching PCs feels like using the same machine.

Two types of data are synced via separate GitHub repos:

| What | Tag Prefix | GitHub Repo | Local Path |
|------|-----------|-------------|------------|
| Project code | v1, v2... | Per-project repos (e.g., `YOUR-ORG/n8n`) | `CLAUDECODE/<project>/` |
| Everything else | s1, s2... | `YOUR-ORG/claude-dotfiles` | `~/.claude/` |

---

## What Syncs

| Synced | NOT Synced (machine-local) |
|--------|---------------------------|
| Session files (.jsonl) | `.credentials.json` (OAuth tokens) |
| Subagent sessions | `settings.local.json` (permissions) |
| Tool-results (cached outputs) | `stats-cache.json` |
| Memory directories (MEMORY.md etc) | `sessions/` (IDE process state) |
| Plugin observer sessions (claude-mem) | `cache/`, `debug/`, `telemetry/` |
| Plugins + plugin data | `shell-snapshots/`, `session-env/` |
| Agents, skills, rules, hooks, commands | `*.untrimmed` (temp trim backups) |
| MCP server configs | |
| Plans, todos, contexts | |
| Settings, keybindings | |
| Project settings (MCP servers, allowedTools) | |
| Command history | |

Any new plugin, agent, skill, rule, hook, or command you install automatically syncs — no config changes needed.

---

## Scripts

### Root scripts (CLAUDECODE/scripts/) — sync ALL projects:

| Script | Purpose |
|--------|---------|
| `push-all-sessions.sh/.bat` | Push ALL sessions to GitHub (force push, squash history) |
| `pull-all-sessions.sh/.bat` | Pull ALL sessions + full 12-step migration pipeline |
| `rollback-all-sessions.sh/.bat` | Rollback ALL sessions to a previous sync tag |
| `new-project.sh/.bat` | Create a new project (clone + generate scripts) |

### Per-project scripts — sync ONE project:

| Script | Purpose |
|--------|---------|
| `push.sh/.bat` | Push project code + sync only THIS project's sessions (incremental) |
| `pull.sh/.bat` | Pull project code + sync only THIS project's sessions |
| `rollback.sh/.bat` | Rollback project code to a previous version |

Every script shows a status box before doing anything:
- **PROJECT CODE STATUS**: local vs remote commits, ahead/behind count
- **SESSION SYNC STATUS**: local vs remote sessions, latest tag
- Warns and asks "are you sure?" if remote has unmerged data

---

## How Per-Project Sync Works

Each per-project script has `--project your-org/<repo>` baked in. This tells the engine to only process that project's sessions:

```
n8n/scripts/push.sh
  → pushes n8n code to YOUR-ORG/n8n
  → calls sync-sessions.py push --project your-org/n8n
    → only stages n8n session dirs + shared configs
    → incremental commit (not force push)
    → regular push with rebase retry
```

Root scripts (push-all-sessions, pull-all-sessions) call sync-sessions.py WITHOUT --project, which processes everything.

---

## Pull Pipeline (12 Steps)

When you pull (per-project or all):

```
 1. Fix .gitignore           Enforce security rules on all machines
 2. Backup large files       Save >90MB sessions before pull
 3. Git pull                 Fetch latest from GitHub
 4. Materialize symlinks     Convert old symlinks to real dirs
 5. Merge sessions           Recursive copy: .jsonl, subagents, tool-results, memory
 6. Detect renamed projects  Match by git remote URL
 7. Fix cwd paths            Rewrite paths in ALL .jsonl (including subagents)
 8. Fix platform configs     Fix plugin installLocation/installPath
 9. Restore large history    Merge backup with pulled version
10. Clean up other-PC dirs   Delete merged dirs, free disk space
11. Fix timestamps           Set correct dates for claude --resume
12. Import project settings  Apply MCP servers, allowedTools from other machine
```

## Push Pipeline (6 Steps)

```
 1. Fix .gitignore           Enforce security rules
 2. Export project settings   Save MCP/tools keyed by git remote
 3. Trim oversized files      Sessions >90MB trimmed to last 90MB
 4. Stage + commit            Per-project: incremental. Root: soft-reset + force push
 5. Push                      Per-project: regular push. Root: force push with tag
 6. Restore originals         Put untrimmed files back on disk
```

---

## Setting Up a New PC

### Prerequisites
- Git, Python, Node.js, Claude Code (`npm install -g @anthropic-ai/claude-code`)

### Steps
1. Create `CLAUDECODE` folder, get root scripts
2. `scripts\pull-all-sessions.bat` (or `.sh`) — pulls everything, runs full migration
3. `scripts\new-project.bat` for each project — clones code, generates push/pull/rollback scripts
4. `npm install` in `~/.claude/plugins/cache/thedotmack/claude-mem/<version>/` (if using claude-mem)
5. `claude --resume` — all sessions visible

---

## Switching PCs (Daily Workflow)

```
Arrive  →  pull (per-project or all)
Work    →  work
Leave   →  push (per-project or all)
```

| What you want | Command |
|---|---|
| Push one project | `cd project && ./scripts/push.sh` |
| Pull one project | `cd project && ./scripts/pull.sh` |
| Push ALL sessions | `cd CLAUDECODE && ./scripts/push-all-sessions.sh` |
| Pull ALL sessions | `cd CLAUDECODE && ./scripts/pull-all-sessions.sh` |

---

## Large Files (>90MB)

Sessions over 90MB are trimmed for push. The full file stays local. On pull, if the local machine had a larger version, it's merged with the new data to preserve full history.

---

## Project Settings Sync

MCP servers and allowedTools configured per-project are synced via git remote matching:
1. Push exports settings keyed by `your-org/<repo>`
2. Pull imports by matching git remotes to local project paths
3. Only fills in empty settings — never overwrites

---

## Session Versioning + Rollback

Every root push creates a tag (s1, s2, s3...). To rollback:
```bash
./scripts/rollback-all-sessions.sh
```
Shows version history, pick a tag, confirm. History is never deleted.

---

## Cross-Platform Notes

- `.sh` for Mac, `.bat` for Windows
- Path encoding consistent: `\ / : .` all become `-`
- `.gitignore` security rules enforced on every push/pull on every machine
- `.credentials.json` never leaves your machine
- `settings.local.json` is machine-specific
- Plugin paths auto-fixed on pull
- CWD paths in all session files (including subagents) auto-fixed

---

## Repos

| Repo | Purpose |
|------|---------|
| `YOUR-ORG/claude-dotfiles` | Everything in ~/.claude/ |
| `YOUR-ORG/my-project` | My Project |
| `YOUR-ORG/my-other-project` | My Other Project |
| `YOUR-ORG/my-third-project` | My Third Project |
| `YOUR-ORG/n8n` | My Automation |
| `YOUR-ORG/my-webapp` | My Web App |
| `YOUR-ORG/promptengineer` | My Tool |
| `YOUR-ORG/prompt-machine` | My Tool 2 |
| `YOUR-ORG/my-accounting-app` | My Accounting App |
