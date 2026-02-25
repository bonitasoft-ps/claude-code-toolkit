# Claude Code Toolkit for Bonita Projects

Shared reusable **commands**, **hooks**, **skills**, and **templates** for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) across Bonita BPM/BPA projects.

This toolkit provides automated quality checks, code generation, and development workflows that can be adopted by any team member in any project.

---

## Table of Contents

- [What is Claude Code?](#what-is-claude-code)
- [Key Concepts](#key-concepts)
  - [Commands (Slash Commands)](#1-commands-slash-commands)
  - [Hooks](#2-hooks)
  - [Skills](#3-skills)
- [Where to Define Things (Scopes)](#where-to-define-things-scopes)
- [Toolkit Structure](#toolkit-structure)
- [Quick Start](#quick-start)
- [Available Commands](#available-commands)
- [Available Hooks](#available-hooks)
- [Settings Templates](#settings-templates)
- [How to Adopt in Your Project](#how-to-adopt-in-your-project)
- [Available Skills](#available-skills)
- [Customizing](#customizing)
- [Projects Using This Toolkit](#projects-using-this-toolkit)

---

## What is Claude Code?

Claude Code is Anthropic's official CLI (Command Line Interface) for Claude AI. It runs in your terminal or IDE (VS Code, JetBrains) and helps you with software engineering tasks: writing code, debugging, refactoring, testing, and more.

Claude Code can be extended with three mechanisms: **Commands**, **Hooks**, and **Skills**.

---

## Key Concepts

### 1. Commands (Slash Commands)

**What are they?** Custom instructions that you invoke by typing `/command-name` in Claude Code's prompt.

**How do they work?** Each command is a simple **Markdown file** (`.md`) that contains instructions for Claude. When you type `/my-command`, Claude reads the file and follows those instructions.

**Example:** A file `.claude/commands/run-tests.md`:
```markdown
# Run Tests
Run all unit tests in the extensions module.
## Instructions
1. Execute: `mvn test -f extensions/pom.xml`
2. Show a summary of passed/failed/skipped tests
```

**How to use:**
```
You: /run-tests
Claude: Running tests... [executes the instructions]

You: /run-tests integration
Claude: Running integration tests... [$ARGUMENTS = "integration"]
```

**Parameters:** Use `$ARGUMENTS` in the Markdown to accept user input:
```markdown
Run tests for class: $ARGUMENTS
```

### 2. Hooks

**What are they?** Automated scripts that run **automatically** when specific events happen in Claude Code. Unlike commands, the user does NOT need to invoke them -- they fire on their own.

**How do they work?** Hooks are defined in `settings.json` and associated with events. Each hook runs a shell script that receives JSON context via stdin.

**Available Events:**

| Event | When it fires | Common use |
|-------|--------------|------------|
| `PreToolUse` | **Before** Claude uses a tool (Edit, Write, Bash...) | Block dangerous actions, validate inputs |
| `PostToolUse` | **After** Claude uses a tool successfully | Run linters, check types, detect issues |
| `Stop` | When Claude finishes responding | Auto-run tests, create missing files |
| `Notification` | When Claude needs user attention | Desktop notifications |
| `SessionStart` | When a session begins or resumes | Reinject context after compaction |
| `SessionEnd` | When a session terminates | Cleanup, logging |

**Exit codes:**
- `exit 0` = Allow the action to proceed
- `exit 2` = **Block** the action (only for PreToolUse)
- `stderr` = Send feedback message to Claude

**Example hook script** (`pre-commit-compile.sh`):
```bash
#!/bin/bash
INPUT=$(cat)  # JSON from Claude Code on stdin
COMMAND=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))")

# Only intercept git commit commands
if ! echo "$COMMAND" | grep -qE "git\s+commit"; then
    exit 0  # Not a commit, allow
fi

# Run compilation check
mvn clean compile 2>&1
if [ $? -ne 0 ]; then
    echo "BLOCKED: Compilation failed. Fix errors before committing." >&2
    exit 2  # Block the commit
fi

exit 0  # Compilation passed, allow commit
```

**Hook types:**
- `command` - Runs a shell script (deterministic, fast)
- `prompt` - Claude evaluates a prompt and decides (uses AI judgment)
- `agent` - Spawns a full Claude agent that can use tools (most powerful, for complex tasks)

### 3. Skills

**What are they?** An advanced version of commands with more control. Skills are defined using a `SKILL.md` file with YAML frontmatter that controls behavior, permissions, and invocation.

**How do they work?** Skills live in `.claude/skills/skill-name/SKILL.md` and offer additional features over simple commands:
- Can restrict which tools Claude uses (`allowed-tools`)
- Can run in isolated context (`context: fork`)
- Can be auto-invoked by Claude when relevant (`disable-model-invocation: false`)
- Can include hook definitions scoped to the skill

**Example:** `.claude/skills/bonita-bdm-expert/SKILL.md`:
```yaml
---
name: bonita-bdm-expert
description: Use when the user asks about BDM queries, data model, or JPQL.
  Provides expert guidance on Bonita Business Data Model design.
allowed-tools: Read, Grep, Glob
---

You are an expert in Bonita BDM (Business Data Model) design.

When asked about queries or data model:
1. Read bdm/bom.xml to understand the current model
2. Apply rules from context-ia/02-datamodel.mdc
3. Ensure countFor queries exist for all collection queries
4. Verify all elements have description tags
```

**Key difference from commands:**

| Feature | Command | Skill |
|---------|---------|-------|
| File format | `.md` (plain markdown) | `SKILL.md` (YAML frontmatter + markdown) |
| Location | `.claude/commands/` | `.claude/skills/skill-name/` |
| Tool restrictions | No | Yes (`allowed-tools`) |
| Auto-invocation | No (user must type `/`) | Yes (Claude can decide to use it) |
| Isolated context | No | Yes (`context: fork`) |
| Scoped hooks | No | Yes |

---

## Where to Define Things (Scopes)

There are **three levels** where you can place commands, hooks, and settings. Each level has different visibility:

### Level 1: Project (shared with team via git)

```
your-project/
└── .claude/
    ├── commands/          # Commands available in this project
    │   └── run-tests.md
    ├── hooks/             # Hook scripts for this project
    │   └── pre-commit.sh
    ├── skills/            # Skills for this project
    │   └── bonita-expert/
    │       └── SKILL.md
    ├── settings.json      # Hooks config + permissions (committed to git)
    └── settings.local.json # Personal overrides (NOT committed, gitignored)
```

- **Committed to git** = teammates get them automatically when they pull
- `settings.local.json` is personal and NOT shared
- **Best for:** Project-specific commands and hooks

### Level 2: User / Personal (all your projects)

```
~/.claude/                     # Windows: C:\Users\YourName\.claude\
├── commands/                  # Commands available in ALL your projects
│   └── my-shortcut.md
├── skills/                    # Skills available in ALL your projects
│   └── my-skill/
│       └── SKILL.md
├── settings.json              # Global hooks + permissions
└── CLAUDE.md                  # Global instructions for Claude
```

- **NOT shared** with anyone
- Available in **every project** you open
- **Best for:** Personal shortcuts and preferences

### Level 3: Shared Toolkit (this repository)

```
claude-code-toolkit/           # This repo
├── commands/                  # Catalog of reusable commands
├── hooks/scripts/             # Catalog of reusable hook scripts
└── templates/                 # Ready-to-use settings.json files
```

- A **catalog** that you copy from into Level 1 or Level 2
- Shared via git with the whole team
- **Best for:** Standardizing practices across multiple projects

### Summary

| Scope | Location | Shared? | Available in |
|-------|----------|---------|-------------|
| **Project** | `your-project/.claude/` | Yes (git) | This project only |
| **Personal** | `~/.claude/` | No | All your projects |
| **Toolkit** | This repo | Yes (git) | Copy to project or personal |

### Decision Guide

| You want to... | Put it in... |
|----------------|-------------|
| Share a command with your team for this project | `.claude/commands/` (project level) |
| Have a personal shortcut for all projects | `~/.claude/commands/` (user level) |
| Enforce a hook for the whole team | `.claude/settings.json` (project level) |
| Have a personal hook only for you | `.claude/settings.local.json` (project level, not committed) |
| Share a reusable command across all Bonita projects | This toolkit (copy to each project) |

---

## Toolkit Structure

```
claude-code-toolkit/
├── commands/
│   ├── java-maven/                    # Generic Java + Maven
│   │   ├── compile.md                 # /compile - Maven compilation
│   │   ├── run-tests.md              # /run-tests - Unit/integration/property tests
│   │   └── run-mutation-tests.md     # /run-mutation-tests - PIT mutation testing
│   ├── bonita/                        # Bonita BPM specific
│   │   ├── check-bdm-queries.md      # /check-bdm-queries - Search existing BDM queries
│   │   ├── validate-bdm.md           # /validate-bdm - Full BDM compliance check
│   │   ├── check-existing-extensions.md  # /check-existing-extensions - Avoid duplicates
│   │   ├── check-existing-processes.md   # /check-existing-processes - Reuse subprocesses
│   │   └── generate-readme.md        # /generate-readme - Controller README.md
│   ├── quality/                       # Code quality
│   │   ├── audit-compliance.md       # /audit-compliance - Full project audit
│   │   ├── check-code-quality.md     # /check-code-quality - Javadoc, method length, smells
│   │   ├── create-constants.md       # /create-constants - Extract hardcoded strings
│   │   └── refactor-method-signature.md  # /refactor-method-signature - Safe refactoring
│   └── testing/                       # Testing
│       ├── generate-tests.md         # /generate-tests - Generate unit + property tests
│       └── check-coverage.md         # /check-coverage - JaCoCo coverage check
├── hooks/
│   └── scripts/                       # Reusable hook scripts
│       ├── pre-commit-compile.sh     # Block commit if compilation fails
│       ├── check-method-usages.sh    # Detect method signature changes
│       ├── check-bdm-countfor.sh     # Validate countFor queries on bom.xml edit
│       ├── check-hardcoded-strings.sh # Detect magic strings in code
│       ├── check-controller-readme.sh # Warn if controller lacks README.md
│       └── check-test-pair.sh        # Verify Test + PropertyTest files exist
├── templates/
│   ├── bonita-project.json           # settings.json for Bonita BPM projects
│   └── java-library.json            # settings.json for Java libraries
├── skills/
│   ├── bonita-bdm-expert/            # Auto-invoked BDM expert skill
│   │   └── SKILL.md
│   └── bonita-rest-api-expert/       # Auto-invoked REST API expert skill
│       └── SKILL.md
├── ADOPTION_GUIDE.md                 # Step-by-step adoption guide
└── README.md                         # This file
```

---

## Quick Start

### For a Bonita BPM project:
```bash
git clone https://github.com/bonitasoft-ps/claude-code-toolkit.git

cd your-bonita-project
mkdir -p .claude/commands .claude/hooks

# Copy everything
cp /path/to/claude-code-toolkit/templates/bonita-project.json .claude/settings.json
cp /path/to/claude-code-toolkit/commands/java-maven/* .claude/commands/
cp /path/to/claude-code-toolkit/commands/bonita/* .claude/commands/
cp /path/to/claude-code-toolkit/commands/quality/* .claude/commands/
cp /path/to/claude-code-toolkit/commands/testing/* .claude/commands/
cp /path/to/claude-code-toolkit/hooks/scripts/* .claude/hooks/
chmod +x .claude/hooks/*.sh

# Commit to share with team
git add .claude/
git commit -m "chore: add Claude Code commands and hooks from toolkit"
```

### For a Java library:
```bash
cp /path/to/claude-code-toolkit/templates/java-library.json .claude/settings.json
cp /path/to/claude-code-toolkit/commands/java-maven/* .claude/commands/
cp /path/to/claude-code-toolkit/commands/quality/* .claude/commands/
cp /path/to/claude-code-toolkit/commands/testing/* .claude/commands/
cp /path/to/claude-code-toolkit/hooks/scripts/check-test-pair.sh .claude/hooks/
cp /path/to/claude-code-toolkit/hooks/scripts/check-hardcoded-strings.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
```

Then **restart Claude Code** to load the new hooks.

---

## Available Commands

### Java / Maven

| Command | Description |
|---------|-------------|
| `/compile` | Compile project with Maven (`mvn clean compile`) |
| `/run-tests [unit\|integration\|property\|all\|ClassName]` | Run tests with Maven |
| `/run-mutation-tests [module\|class]` | Run PIT mutation testing |

### Bonita Specific

| Command | Description |
|---------|-------------|
| `/check-bdm-queries [ObjectName]` | Search existing BDM queries before creating new ones |
| `/validate-bdm` | Full BDM compliance audit (countFor, descriptions, indexes) |
| `/check-existing-extensions [description]` | Search extensions for similar functionality |
| `/check-existing-processes [description]` | Search processes/subprocesses for similar logic |
| `/generate-readme [controller]` | Generate README.md for a REST API controller |

### Code Quality

| Command | Description |
|---------|-------------|
| `/audit-compliance` | Full project compliance audit (tests, docs, BDM, quality) |
| `/check-code-quality [file\|dir]` | Check Javadoc, method length, code smells |
| `/create-constants [file]` | Extract hardcoded strings to constants classes |
| `/refactor-method-signature [method + change]` | Refactor method and update ALL call sites |

### Testing

| Command | Description |
|---------|-------------|
| `/generate-tests [ClassName]` | Generate unit + property tests for a class |
| `/check-coverage` | Run JaCoCo and verify coverage thresholds |

---

## Available Hooks

### Automatic hooks (fire without user action)

| Hook | Event | What it does |
|------|-------|-------------|
| `pre-commit-compile.sh` | PreToolUse (Bash) | **Blocks** `git commit` if `mvn clean compile` fails |
| `check-method-usages.sh` | PostToolUse (Edit) | Lists files using a method when its signature changes |
| `check-bdm-countfor.sh` | PostToolUse (Edit) | Warns about missing countFor queries when editing bom.xml |
| `check-hardcoded-strings.sh` | PostToolUse (Edit) | Detects magic strings in Java/Groovy comparisons and switch cases |
| `check-controller-readme.sh` | PreToolUse (Write) | Warns when creating a controller Java file without README.md |
| `check-test-pair.sh` | PostToolUse (Edit/Write) | Warns when source files lack Test + PropertyTest counterparts |

### Agent hooks (in templates)

| Hook | Event | What it does |
|------|-------|-------------|
| Auto-test agent | Stop | When Claude finishes: finds modified files, creates/updates tests, runs them |

---

## Settings Templates

### `bonita-project.json`
Full configuration for Bonita BPM projects. Includes:
- Pre-commit compilation check
- Controller README.md validation
- Method usage detection on edit
- BDM countFor validation on edit
- Hardcoded strings detection on edit
- Auto-test agent on Stop

### `java-library.json`
Configuration for Java libraries. Includes:
- Pre-commit test execution (not just compile)
- Test pair validation (Test + PropertyTest)
- Hardcoded strings detection
- Auto-test agent on Stop (with property tests)

---

## Available Skills

Skills are advanced commands that Claude can **auto-invoke** when it detects a relevant task. Copy the skill directories to your project's `.claude/skills/`.

| Skill | Auto-invokes when... | What it does |
|-------|---------------------|-------------|
| `bonita-bdm-expert` | User asks about BDM, queries, JPQL, data model | Reads bom.xml, enforces countFor rule, naming, descriptions, indexes |
| `bonita-rest-api-expert` | User asks about REST API extensions | Enforces Abstract/Concrete pattern, README.md, DTOs, test requirements |

**To install skills:**
```bash
cp -r /path/to/claude-code-toolkit/skills/* your-project/.claude/skills/
```

---

## How to Adopt in Your Project

See [ADOPTION_GUIDE.md](ADOPTION_GUIDE.md) for detailed step-by-step instructions.

**TL;DR:**
1. Copy template + commands + hooks to your project's `.claude/` directory
2. `chmod +x .claude/hooks/*.sh`
3. `git commit` to share with team
4. Restart Claude Code

New team members get everything automatically when they clone the project.

---

## Customizing

- **Commands** are Markdown files. Edit them to match your project's specific paths, modules, and conventions.
- **Hook scripts** check file paths with grep. Update the path patterns if your project structure differs.
- **Settings templates** include all hooks. Remove any you don't need.
- **Create new commands** by adding a `.md` file to `.claude/commands/` in your project.

---

## Projects Using This Toolkit

- [ps-process-builder](https://github.com/bonitasoft-presales/ps-process-builder) - Bonita BPM Process Builder
- [process-builder-extension-library](https://github.com/bonitasoft-presales/process-builder-extension-library) - Shared Java library

---

## Contributing

1. Clone this repo
2. Add or improve commands/hooks
3. Test in a real project
4. Submit a PR

## License

Internal use - Bonitasoft Professional Services
