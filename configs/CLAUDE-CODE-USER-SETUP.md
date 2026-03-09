# Claude Code — User-Level Configuration Guide

This guide explains the configuration files we provide for Claude Code and **why each one exists**.

## Overview

| File | Location | Purpose |
|------|----------|---------|
| `settings.json` | `~/.claude/settings.json` | Permissions, env vars, auto-update channel |
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | Global instructions for all Claude Code sessions |
| `.claudeignore` | Project root (each repo) | Files Claude should skip reading |
| Playwright MCP | Installed via CLI | Browser automation for testing and debugging |

## Quick Setup

**Linux / macOS / Git Bash:**
```bash
bash configs/setup-claude-code-user.sh
```

**Windows (cmd or PowerShell):**
```cmd
configs\setup-claude-code-user.bat
```

Both scripts are safe to re-run — they back up existing files before overwriting.

---

## File 1: `~/.claude/settings.json`

### What it does

Configures Claude Code behavior at the **user level** (applies to all projects).

### Why we created it

By default, Claude Code asks for permission on **every operation**: reading a file, running `git status`, executing tests. This interrupts the workflow constantly. Our settings pre-approve **safe, read-only operations** while keeping approval for anything that modifies the codebase.

### What's allowed without prompts

| Category | Commands | Why safe |
|----------|----------|----------|
| **Read files** | `Read`, `Glob`, `Grep` | Read-only, never modifies anything |
| **List/inspect** | `ls`, `find`, `cat`, `head`, `tail`, `wc`, `du` | Read-only shell commands |
| **Git read** | `git status`, `git log`, `git diff`, `git branch`, `git remote`, `git show` | Never modifies repo state |
| **Tests** | `npm test`, `mvn test`, `node --test`, `mvn compile`, `mvn verify` | Build/test, doesn't affect production |
| **Linting** | `npm run check`, `npm run lint`, `npm run build` | Quality checks, safe to run |

### What still requires approval

- `git commit`, `git push`, `git checkout` — modifies repo state
- `Edit`, `Write` — modifies files
- `npm install`, `pip install` — installs dependencies
- Any unknown script execution
- Destructive commands (`rm`, `git reset --hard`)

### Agent Teams

The setting `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` enables the experimental Agent Teams feature, which allows coordinating multiple Claude Code instances working in parallel on different parts of a task. This only works from the terminal CLI (`claude` command), not from VS Code.

---

## File 2: `~/.claude/CLAUDE.md`

### What it does

Provides **global instructions** that Claude Code follows in every session, regardless of which project you're in.

### Why we created it

Without this file, you'd have to repeat preferences in every conversation: "speak in Spanish", "use Java 17", "don't add emojis", "run tasks in parallel". The global CLAUDE.md sets these defaults once.

### What it includes

- **Language**: Conversation in user's language, docs in English
- **Autonomy rules**: What Claude can do without asking (mirrors settings.json permissions)
- **Code standards**: Java 17 features, ES Modules, JUnit 5, test naming conventions
- **Bonitasoft context**: PS team role, 7-repo ecosystem, version formats, connector lifecycle
- **Security**: Never commit secrets, proposals stay local

### How it relates to project-level CLAUDE.md

| Level | File | Scope |
|-------|------|-------|
| **User** | `~/.claude/CLAUDE.md` | Applies to ALL sessions |
| **Project** | `<project>/CLAUDE.md` | Applies only to that project |

Both are loaded. Project-level instructions can override or extend user-level ones.

---

## File 3: `.claudeignore`

### What it does

Tells Claude Code to **skip certain files during automatic codebase scanning**, similar to `.gitignore`.

**Important distinction:** `.claudeignore` only affects automatic scanning. Claude **can still read any file** if you explicitly ask it to (e.g., "read this PDF", "look at this screenshot"). Claude is multimodal and reads PDFs, images, etc. on demand.

### Why we created it

Claude Code has a limited context window. If it auto-scans `node_modules/` (500MB+) or `vectordb/` (128MB binary data), it wastes context on irrelevant content and slows down responses. `.claudeignore` ensures auto-scanning focuses on code that matters.

### What we exclude and why

| Pattern | Why | Can Claude still read it on demand? |
|---------|-----|-------------------------------------|
| `node_modules/`, `target/`, `dist/` | Dependencies and build outputs | Yes, but rarely useful |
| `.git/` | Git internals — thousands of objects | Yes, but use git commands instead |
| `vectordb/`, `*.lance` | LanceDB binary data (128MB), used by code not Claude | No (binary format) |
| `raw/` | Cloned doc branches (1.4GB) | Yes, but use search tools instead |
| `.env`, `*.pem`, `*.key` | Secrets | **Should never be read** |
| `*.log` | Log files — usually too large | Yes, if you ask explicitly |
| `*.mp4`, `*.zip`, `*.tar.gz` | Large binary files | No (not text/image) |
| `.cache/`, `.huggingface/` | Cache directories | Yes, but rarely useful |

### What we do NOT exclude

| Pattern | Why it stays readable |
|---------|----------------------|
| `*.pdf` | Proposals, audit reports, Bonita documentation — Claude reads PDFs natively |
| `*.png`, `*.jpg`, `*.svg` | Screenshots, UI mockups, diagrams — Claude is multimodal |
| `*.jar`, `*.war` | May need to inspect Bonita connectors or deployments |

### Where to put it

Copy the template to the **root of each project**:

```bash
cp configs/.claudeignore /path/to/your/project/.claudeignore
```

Each project may need customization (add or remove patterns based on your needs).

---

## Configuration Scope Reference

```
~/.claude/
├── settings.json          ← User-level: permissions, env vars (THIS GUIDE)
├── CLAUDE.md              ← User-level: global instructions (THIS GUIDE)
└── projects/
    └── <project>/
        └── memory/
            └── MEMORY.md  ← Auto-memory per project (managed by Claude)

<project>/
├── CLAUDE.md              ← Project-level: project-specific instructions
├── .claudeignore          ← Project-level: files to skip (THIS GUIDE)
└── .claude/
    ├── settings.json      ← Project-level: permissions, hooks
    ├── skills/            ← Project-level: custom skills
    ├── commands/          ← Project-level: custom commands
    ├── hooks/             ← Project-level: pre/post tool hooks
    └── agents/            ← Project-level: agent definitions
```

---

## File 4: Playwright MCP Server

### What it does

Installs a **browser automation server** (by Microsoft) that Claude can control: navigate pages, click buttons, fill forms, take screenshots, and generate Playwright tests.

### Why we include it (mandatory)

Bonitasoft PS works heavily with web UIs: the Bonita portal, UI Builder, Living Applications. Playwright MCP lets Claude:

| Use case | How it helps |
|----------|-------------|
| **Test Bonita forms** | Claude navigates the portal, fills forms, validates behavior |
| **Debug UI issues** | Claude reads console errors, inspects DOM, checks network |
| **Generate E2E tests** | Claude creates Playwright test scripts automatically |
| **Verify deployments** | Claude opens the app and confirms it works |
| **Auth-safe** | You log in visually; Claude continues with your session |
| **PDF generation** | Save any page as PDF directly |

Unlike screenshot-based approaches, Playwright MCP uses the **accessibility tree** (2-5KB structured data) instead of pixel images — making it 10-100x faster and more accurate.

### How it's installed

The setup script runs:
```bash
claude mcp add playwright -- npx @playwright/mcp@latest
```

For Claude Desktop, the script in `bonita-ai-agent-mcp/scripts/setup-ps-tools.sh` adds it to `claude_desktop_config.json`:
```json
"playwright": {
  "command": "npx",
  "args": ["@playwright/mcp@latest"]
}
```

### How to use it

In any Claude Code session:
```
Open a browser to https://my-bonita-server:8080/bonita and take a screenshot
```

Claude will launch a visible Chrome window, navigate, and capture the result.

---

## FAQ

**Q: Does this work in VS Code?**
A: `settings.json`, `CLAUDE.md`, and `.claudeignore` work everywhere (CLI, VS Code, Claude Desktop). Agent Teams only works in CLI.

**Q: Can I add project-specific permissions?**
A: Yes. Add them to `<project>/.claude/settings.json`. They merge with user-level settings.

**Q: What if I want Claude to ask before reading a specific file?**
A: Add it to your `.claudeignore`. Claude won't even see it.

**Q: Is it safe to share these settings with the team?**
A: Yes. The scripts don't contain secrets. Each team member runs the setup once on their machine.

**Q: Can teammates customize their own CLAUDE.md?**
A: Absolutely. The user-level CLAUDE.md is personal. They can change language, add preferences, etc.
