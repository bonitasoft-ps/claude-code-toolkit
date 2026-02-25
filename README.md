# Claude Code Toolkit - Team Methodology for AI-Assisted Development

A shared **methodology repository** that defines how our team builds software with [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Contains reusable **commands**, **hooks**, **skills**, **configurations**, and **templates** to ensure consistency, quality, and productivity across all Bonita BPM/BPA and Java projects.

> **Goal:** Every team member, on every project, follows the same standards -- automatically enforced by AI-powered hooks and commands.

---

## Table of Contents

- [Why This Toolkit Exists](#why-this-toolkit-exists)
- [Our Methodology](#our-methodology)
- [Key Concepts](#key-concepts)
  - [Commands (Slash Commands)](#1-commands-slash-commands)
  - [Hooks (Automatic Checks)](#2-hooks-automatic-checks)
  - [Skills (Expert Assistants)](#3-skills-expert-assistants)
  - [Configurations (Standard Files)](#4-configurations-standard-files)
- [Where to Define Things (Scopes)](#where-to-define-things-scopes)
  - [Context Files (CLAUDE.md)](#context-files-claudemd)
  - [Commands, Hooks, and Settings](#commands-hooks-and-settings)
  - [The 4 Levels at a Glance](#the-4-levels-at-a-glance)
- [Toolkit Structure](#toolkit-structure)
- [Quick Start](#quick-start)
- [Catalog: Commands](#catalog-commands)
- [Catalog: Hooks](#catalog-hooks)
- [Catalog: Skills](#catalog-skills)
- [Catalog: Configuration Files](#catalog-configuration-files)
- [Catalog: Templates](#catalog-templates)
- [How to Adopt in Your Project](#how-to-adopt-in-your-project)
- [Contributing](#contributing)
- [Projects Using This Toolkit](#projects-using-this-toolkit)

---

## Why This Toolkit Exists

Without a shared methodology, each developer writes code differently, forgets quality checks, and has to re-learn project conventions. This toolkit solves that by:

1. **Automating quality checks** - Hooks fire automatically when you edit code, commit, or finish a task
2. **Standardizing practices** - Everyone uses the same Checkstyle, PMD, and EditorConfig rules
3. **Providing expert guidance** - Skills give Claude domain knowledge about Bonita BDM, REST APIs, etc.
4. **Sharing workflows** - Commands like `/run-tests`, `/generate-tests` work the same in every project
5. **Onboarding instantly** - New team members get everything just by cloning the project

---

## Our Methodology

### Core Principles

| Principle | Meaning |
|-----------|---------|
| **Consistency first** | All projects follow the same standards, formatting, and naming |
| **Automate everything** | If a check can be automated, it becomes a hook |
| **Fail fast** | Catch issues during development, not in code review |
| **Document as you go** | Every controller has a README, every method has Javadoc |
| **Share and reuse** | Useful patterns go in the toolkit for everyone |

### Development Workflow

```
1. Start task          -->  Claude reads CLAUDE.md + AGENTS.md + context files
2. Write code          -->  Hooks auto-check: formatting, style, strings, methods
3. Edit BDM            -->  Hook auto-validates countFor queries
4. Create controller   -->  Hook reminds about README.md
5. Use commands        -->  /run-tests, /check-bdm-queries, /generate-tests
6. Finish task         -->  Agent auto-creates/updates tests, runs them
7. Commit              -->  Hook blocks if mvn clean compile fails
```

### Mandatory Quality Standards

- **Java 17** features (records, sealed classes, pattern matching)
- **Max 30 lines per method** (SRP)
- **Javadoc on all public methods**
- **Constants for all literal strings** (no magic strings)
- **No wildcard imports**, no `System.out.println`
- **Checkstyle** + **PMD** = zero violations policy
- **JaCoCo** >= 80% line coverage on new code
- **Test naming:** `should_do_X_when_condition_Y`

---

## Key Concepts

### 1. Commands (Slash Commands)

**What:** Custom instructions invoked by typing `/command-name` in Claude Code.

**How:** Each command is a Markdown file (`.md`) in `.claude/commands/`. Claude reads it and follows the instructions. Use `$ARGUMENTS` to accept parameters.

**Example file** (`.claude/commands/run-tests.md`):
```markdown
# Run Tests
Run tests in the extensions module.
## Arguments
- `$ARGUMENTS`: test type (unit, integration, property, all) or class name
## Instructions
1. Execute: `mvn test -f extensions/pom.xml`
2. Show a summary of passed/failed/skipped tests
```

**How to use:**
```
You: /run-tests
You: /run-tests integration
You: /run-tests MyControllerTest
```

### 2. Hooks (Automatic Checks)

**What:** Scripts that fire **automatically** on specific events. The user does NOT invoke them -- they run on their own.

**How:** Defined in `settings.json`, hooks run shell scripts that receive JSON context via stdin.

**Events:**

| Event | When it fires | Typical use |
|-------|--------------|-------------|
| `PreToolUse` | Before Claude uses a tool | Block dangerous actions |
| `PostToolUse` | After Claude uses a tool | Lint, validate, warn |
| `Stop` | When Claude finishes responding | Auto-run tests, create files |
| `Notification` | When Claude needs attention | Desktop alerts |
| `SessionStart` | Session begins or resumes | Reinject context |

**Exit codes:**
- `exit 0` = Allow (send warnings via stderr)
- `exit 2` = **Block** the action (PreToolUse only)

**Hook types:**
- `command` - Shell script (fast, deterministic)
- `prompt` - Claude evaluates a text prompt (uses AI judgment)
- `agent` - Spawns a full Claude agent with tool access (most powerful)

**Example** (`pre-commit-compile.sh`):
```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))")

if ! echo "$COMMAND" | grep -qE "git\s+commit"; then exit 0; fi

mvn clean compile 2>&1
if [ $? -ne 0 ]; then
    echo "BLOCKED: Compilation failed. Fix errors before committing." >&2
    exit 2
fi
exit 0
```

### 3. Skills (Expert Assistants)

**What:** Advanced commands with YAML frontmatter that Claude can **auto-invoke** when it detects a relevant task.

**How:** Skills live in `.claude/skills/skill-name/SKILL.md` and offer:
- Tool restrictions (`allowed-tools: Read, Grep, Glob`)
- Auto-invocation (Claude activates them without the user typing `/`)
- Isolated context (`context: fork`)
- Scoped hooks

**Comparison with commands:**

| Feature | Command | Skill |
|---------|---------|-------|
| File format | `.md` (plain) | `SKILL.md` (YAML + markdown) |
| Location | `.claude/commands/` | `.claude/skills/name/` |
| Tool restrictions | No | Yes |
| Auto-invocation | No | Yes |
| Isolated context | No | Yes |

**Example** (`bonita-bdm-expert/SKILL.md`):
```yaml
---
name: bonita-bdm-expert
description: Use when the user asks about BDM queries, data model, or JPQL.
allowed-tools: Read, Grep, Glob
---

You are an expert in Bonita BDM design.
When asked about queries:
1. Read bdm/bom.xml
2. Check for existing queries
3. Ensure countFor queries exist for collections
```

### 4. Configurations (Standard Files)

**What:** Reference configuration files (Checkstyle, PMD, EditorConfig) that define team-wide formatting and style rules.

**How:** Copy from `configs/` to your project root. Configure Maven plugins to use them.

**Why:** Everyone's code looks the same, regardless of IDE or personal preferences.

---

## Where to Define Things (Scopes)

Claude Code uses a **layered scope system**. Understanding it is key to proper configuration.

### Context Files (CLAUDE.md)

Claude reads instructions from **three** context files, merged together:

| File | Shared? | Scope | Purpose |
|------|---------|-------|---------|
| **`CLAUDE.md`** | Yes (git) | Project | Team rules, architecture, conventions. Generated with `/init`. Committed to version control. |
| **`CLAUDE.local.md`** | No | Project (personal) | Your personal tweaks for this project. NOT committed. Only you see this. |
| **`~/.claude/CLAUDE.md`** | No | Global (personal) | Rules you want Claude to follow in ALL projects (e.g., "prefer Spanish", "always use bun"). |

**Priority:** Project `CLAUDE.md` > `~/.claude/CLAUDE.md`. Your `CLAUDE.local.md` adds to or overrides for your session only.

### Commands, Hooks, and Settings

Commands, hooks, and settings also have three levels:

#### Level 1: Project (shared with team via git)

```
your-project/
├── CLAUDE.md                  # Project instructions (shared)
├── CLAUDE.local.md            # Personal instructions (NOT committed)
└── .claude/
    ├── commands/              # Commands for this project (shared)
    ├── hooks/                 # Hook scripts for this project (shared)
    ├── skills/                # Skills for this project (shared)
    ├── settings.json          # Hooks config (shared via git)
    └── settings.local.json    # Personal overrides (NOT committed)
```

- Teammates get commands/hooks/skills automatically on `git pull`
- `settings.local.json` and `CLAUDE.local.md` are personal, NOT shared

#### Level 2: User / Personal (all your projects)

```
~/.claude/
├── CLAUDE.md                  # Global instructions for all projects
├── commands/                  # Commands available everywhere
├── skills/                    # Skills available everywhere
└── settings.json              # Global hooks + permissions
```

- NOT shared with anyone
- Available in every project you open

#### Level 3: Shared Toolkit (this repository)

```
claude-code-toolkit/           # This repo
├── commands/                  # Catalog of commands to copy
├── hooks/scripts/             # Catalog of hook scripts to copy
├── skills/                    # Catalog of skills to copy
├── configs/                   # Standard config files to copy
└── templates/                 # Ready-to-use settings.json + CLAUDE.md
```

- A **catalog** to copy from into Level 1 or Level 2
- Shared via git with the whole team
- Defines the team methodology

### The 4 Levels at a Glance

| What | Project (shared) | Project (personal) | Global (personal) | Toolkit (catalog) |
|------|-----------------|-------------------|-------------------|--------------------|
| **Instructions** | `CLAUDE.md` | `CLAUDE.local.md` | `~/.claude/CLAUDE.md` | `templates/CLAUDE.md.template` |
| **Commands** | `.claude/commands/` | -- | `~/.claude/commands/` | `commands/` |
| **Skills** | `.claude/skills/` | -- | `~/.claude/skills/` | `skills/` |
| **Settings** | `.claude/settings.json` | `.claude/settings.local.json` | `~/.claude/settings.json` | `templates/*.json` |
| **Configs** | `checkstyle.xml`, etc. | -- | -- | `configs/` |

### Decision Guide

| You want to... | Put it in... |
|----------------|-------------|
| Set project rules for the whole team | `CLAUDE.md` (project, committed) |
| Set personal preferences for this project | `CLAUDE.local.md` (project, NOT committed) |
| Set personal rules for ALL your projects | `~/.claude/CLAUDE.md` (global) |
| Share a command with your team for this project | `.claude/commands/` (project level) |
| Have a personal shortcut for all projects | `~/.claude/commands/` (user level) |
| Enforce a hook for the whole team | `.claude/settings.json` (project level) |
| Have a personal hook only for you | `.claude/settings.local.json` (project, not committed) |
| Standardize practices across all team projects | This toolkit (copy to each project) |

---

## Toolkit Structure

```
claude-code-toolkit/
├── commands/
│   ├── java-maven/                    # Generic Java + Maven
│   │   ├── compile.md                 # /compile
│   │   ├── run-tests.md              # /run-tests
│   │   └── run-mutation-tests.md     # /run-mutation-tests
│   ├── bonita/                        # Bonita BPM specific
│   │   ├── check-bdm-queries.md      # /check-bdm-queries
│   │   ├── validate-bdm.md           # /validate-bdm
│   │   ├── check-existing-extensions.md  # /check-existing-extensions
│   │   ├── check-existing-processes.md   # /check-existing-processes
│   │   └── generate-readme.md        # /generate-readme
│   ├── quality/                       # Code quality
│   │   ├── audit-compliance.md       # /audit-compliance
│   │   ├── check-code-quality.md     # /check-code-quality
│   │   ├── create-constants.md       # /create-constants
│   │   └── refactor-method-signature.md  # /refactor-method-signature
│   └── testing/                       # Testing
│       ├── generate-tests.md         # /generate-tests
│       └── check-coverage.md         # /check-coverage
├── hooks/
│   └── scripts/
│       ├── pre-commit-compile.sh     # Block commit if compilation fails
│       ├── check-method-usages.sh    # Detect method signature changes
│       ├── check-bdm-countfor.sh     # Validate countFor queries
│       ├── check-hardcoded-strings.sh # Detect magic strings
│       ├── check-controller-readme.sh # Warn if controller lacks README
│       ├── check-test-pair.sh        # Verify Test + PropertyTest exist
│       ├── check-code-format.sh      # Formatting: tabs, whitespace, line length, imports
│       └── check-code-style.sh       # Style: System.out, empty catch, method length, @Override
├── configs/
│   ├── checkstyle.xml                # Checkstyle rules (Google-based, team-adjusted)
│   ├── pmd-ruleset.xml               # PMD rules (best practices, design, error-prone)
│   └── .editorconfig                 # Editor formatting (indent, line endings, charset)
├── skills/
│   ├── bonita-bdm-expert/            # Auto-invoked BDM expert
│   │   └── SKILL.md
│   └── bonita-rest-api-expert/       # Auto-invoked REST API expert
│       └── SKILL.md
├── templates/
│   ├── bonita-project.json           # settings.json for Bonita projects
│   ├── java-library.json             # settings.json for Java libraries
│   └── CLAUDE.md.template            # Starter CLAUDE.md for new projects
├── README.md                         # This file
├── CONTRIBUTING.md                   # How to add commands, hooks, skills
└── ADOPTION_GUIDE.md                 # Step-by-step adoption guide
```

---

## Quick Start

### For a Bonita BPM project

```bash
# Clone the toolkit (one time)
git clone https://github.com/bonitasoft-ps/claude-code-toolkit.git

# Go to your project
cd your-bonita-project
mkdir -p .claude/commands .claude/hooks .claude/skills

# Copy the template settings
cp /path/to/claude-code-toolkit/templates/bonita-project.json .claude/settings.json

# Copy commands (all categories)
cp /path/to/claude-code-toolkit/commands/java-maven/* .claude/commands/
cp /path/to/claude-code-toolkit/commands/bonita/* .claude/commands/
cp /path/to/claude-code-toolkit/commands/quality/* .claude/commands/
cp /path/to/claude-code-toolkit/commands/testing/* .claude/commands/

# Copy hook scripts
cp /path/to/claude-code-toolkit/hooks/scripts/* .claude/hooks/
chmod +x .claude/hooks/*.sh

# Copy skills
cp -r /path/to/claude-code-toolkit/skills/* .claude/skills/

# Copy config files to project root
cp /path/to/claude-code-toolkit/configs/checkstyle.xml .
cp /path/to/claude-code-toolkit/configs/pmd-ruleset.xml .
cp /path/to/claude-code-toolkit/configs/.editorconfig .

# Copy CLAUDE.md template (customize after copying)
cp /path/to/claude-code-toolkit/templates/CLAUDE.md.template CLAUDE.md

# Commit to share with team
git add .claude/ checkstyle.xml pmd-ruleset.xml .editorconfig CLAUDE.md
git commit -m "chore: adopt Claude Code toolkit for team methodology"
```

### For a Java library

```bash
cp /path/to/claude-code-toolkit/templates/java-library.json .claude/settings.json
cp /path/to/claude-code-toolkit/commands/java-maven/* .claude/commands/
cp /path/to/claude-code-toolkit/commands/quality/* .claude/commands/
cp /path/to/claude-code-toolkit/commands/testing/* .claude/commands/
cp /path/to/claude-code-toolkit/hooks/scripts/*.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
cp /path/to/claude-code-toolkit/configs/* .
cp /path/to/claude-code-toolkit/templates/CLAUDE.md.template CLAUDE.md
```

Then **restart Claude Code** to load the new hooks.

---

## Catalog: Commands

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

## Catalog: Hooks

### Automatic Hooks (fire without user action)

| Hook Script | Event | Trigger | Behavior |
|-------------|-------|---------|----------|
| `pre-commit-compile.sh` | PreToolUse (Bash) | `git commit` | **Blocks** commit if `mvn clean compile` fails |
| `check-controller-readme.sh` | PreToolUse (Write) | Creating a controller `.java` file | **Warns** if no README.md in controller directory |
| `check-method-usages.sh` | PostToolUse (Edit) | Editing Java/Groovy | **Warns** about files calling modified methods |
| `check-bdm-countfor.sh` | PostToolUse (Edit) | Editing `bom.xml` | **Warns** about missing countFor queries |
| `check-hardcoded-strings.sh` | PostToolUse (Edit) | Editing Java/Groovy | **Warns** about magic strings in comparisons/switch |
| `check-test-pair.sh` | PostToolUse (Edit/Write) | Editing source files | **Warns** if Test or PropertyTest file is missing |
| `check-code-format.sh` | PostToolUse (Edit/Write) | Editing Java/Groovy | **Warns** about tabs, trailing spaces, line length, wildcard imports |
| `check-code-style.sh` | PostToolUse (Edit/Write) | Editing Java | **Warns** about System.out, empty catch, long methods, missing @Override |

### Agent Hooks (in templates)

| Hook | Event | Behavior |
|------|-------|----------|
| Auto-test agent (Bonita) | Stop | Finds modified files, creates/updates tests, runs `mvn test` |
| Auto-test agent (Library) | Stop | Same + ensures PropertyTest files exist for jqwik |

---

## Catalog: Skills

| Skill | Auto-invokes when... | What it does |
|-------|---------------------|-------------|
| `bonita-bdm-expert` | User asks about BDM, queries, JPQL, data model | Reads bom.xml, enforces countFor rule, naming, descriptions, indexes |
| `bonita-rest-api-expert` | User asks about REST API extensions | Enforces Abstract/Concrete pattern, README.md, DTOs, test requirements |

**Install:** `cp -r /path/to/claude-code-toolkit/skills/* .claude/skills/`

---

## Catalog: Configuration Files

| File | Purpose | How to use |
|------|---------|------------|
| `configs/checkstyle.xml` | Code style rules (Google-based) | Copy to project root. Add `maven-checkstyle-plugin` to pom.xml |
| `configs/pmd-ruleset.xml` | Static analysis rules | Copy to project root. Add `maven-pmd-plugin` to pom.xml |
| `configs/.editorconfig` | Editor formatting (indent, line endings) | Copy to project root. Most IDEs support natively |

### Maven plugin snippets

**Checkstyle:**
```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-checkstyle-plugin</artifactId>
  <version>3.3.1</version>
  <configuration>
    <configLocation>checkstyle.xml</configLocation>
    <consoleOutput>true</consoleOutput>
    <failsOnError>true</failsOnError>
  </configuration>
</plugin>
```

**PMD:**
```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-pmd-plugin</artifactId>
  <version>3.21.2</version>
  <configuration>
    <rulesets>
      <ruleset>pmd-ruleset.xml</ruleset>
    </rulesets>
    <failOnViolation>true</failOnViolation>
    <printFailingErrors>true</printFailingErrors>
  </configuration>
</plugin>
```

---

## Catalog: Templates

| Template | Target | Includes |
|----------|--------|----------|
| `bonita-project.json` | Bonita BPM projects | All 8 hooks + auto-test agent |
| `java-library.json` | Java libraries | 5 hooks + test-pair validation + auto-test agent |
| `CLAUDE.md.template` | Any project | Starter CLAUDE.md with team standards and TODO markers |

---

## How to Adopt in Your Project

See [ADOPTION_GUIDE.md](ADOPTION_GUIDE.md) for detailed step-by-step instructions.

**Summary:**
1. Copy template settings + commands + hooks + skills + configs to your project
2. `chmod +x .claude/hooks/*.sh`
3. Customize `CLAUDE.md` for your project
4. `git commit` to share with team
5. Restart Claude Code

New team members get everything automatically when they clone the project.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- How to add new commands, hooks, skills, and configs
- Team methodology principles
- Naming conventions and quality checklist
- Ideas for future contributions

---

## Projects Using This Toolkit

- [ps-process-builder](https://github.com/bonitasoft-presales/ps-process-builder) - Bonita BPM Process Builder
- [process-builder-extension-library](https://github.com/bonitasoft-presales/process-builder-extension-library) - Shared Java library

---

## License

Internal use - Bonitasoft Professional Services
