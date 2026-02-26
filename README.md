# Claude Code Toolkit — Bonitasoft Development Methodology

> A catalog of **skills**, **commands**, **hooks**, and **configurations** for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that defines how Bonitasoft builds software with AI.

**Clone this repository. Pick what you need. Install at the right scope. Code better.**

```
git clone https://github.com/bonitasoft-ps/claude-code-toolkit.git
```

---

## Table of Contents

- [What is this?](#what-is-this)
- [The 3 Scopes + Priority System](#the-3-scopes--priority-system)
  - [Enterprise Scope](#-enterprise-scope--priority-1)
  - [Personal Scope](#-personal-scope--priority-2)
  - [Project Scope](#-project-scope--priority-3)
  - [Plugin Scope](#-plugin-scope--priority-4)
- [Resource Catalog by Scope](#resource-catalog-by-scope)
  - [Enterprise Resources](#enterprise-resources)
  - [Personal Resources](#personal-resources)
  - [Project Resources](#project-resources)
- [Installation Guide](#installation-guide)
- [What are Commands, Hooks, Skills?](#what-are-commands-hooks-skills)
- [Where to Define Things](#where-to-define-things)
- [Repository Structure](#repository-structure)
- [Contributing](#contributing)
- [Projects Using This Toolkit](#projects-using-this-toolkit)

---

## What is this?

This repository is the **single source of truth** for Bonitasoft's AI-assisted development methodology. It contains:

| What | Purpose | How many |
|------|---------|----------|
| **Skills** | Expert knowledge that Claude auto-activates (BDM, REST API, Documents, Testing...) | 7 |
| **Commands** | Slash commands for common tasks (`/run-tests`, `/generate-tests`) | 15 |
| **Hooks** | Automatic checks that fire without user action (format, style, compile) | 10 |
| **Configs** | Standard rule files (Checkstyle, PMD, EditorConfig) | 3 |
| **Templates** | Ready-to-use settings and CLAUDE.md starter | 3 |

### Why this exists

Without a shared methodology, each developer writes code differently, forgets quality checks, and reinvents solutions. This toolkit:

1. **Homogenizes development** — Everyone follows the same standards, automatically
2. **Prevents errors** — Hooks catch issues during development, not in code review
3. **Ensures testing** — Auto-test agents create and run tests when Claude finishes
4. **Avoids duplication** — Commands check for existing implementations before creating new ones
5. **Onboards instantly** — New team members get everything by cloning the project

### How to use it

1. **Clone** this repository
2. **Choose** which resources you need (see the catalog below)
3. **Install** at the right scope (Enterprise, Personal, or Project)
4. **Restart** Claude Code

You can also use the automated installer:
```bash
bash install.sh
```

---

## The 3 Scopes + Priority System

Claude Code uses a **priority system** for skills, commands, hooks, and settings. When two resources share the same name, the higher-priority scope wins:

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│   PRIORITY 1 ★★★  Enterprise                                │
│   Organization-wide. Cannot be overridden. Maximum control.  │
│                                                              │
│   PRIORITY 2 ★★☆  Personal                                  │
│   Your home directory. Available in ALL your projects.       │
│                                                              │
│   PRIORITY 3 ★☆☆  Project                                   │
│   Inside the repo. Shared with team via git.                 │
│                                                              │
│   PRIORITY 4 ☆☆☆  Plugin                                    │
│   Namespaced (plugin-name:skill-name). Lowest priority.      │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

> **Example:** If you have a skill called `bonita-bdm-expert` at the Enterprise level AND at the Project level, the **Enterprise version always wins**. This lets the organization enforce standards that individuals cannot override.

---

### ★★★ Enterprise Scope — Priority 1

**What:** Organization-wide configuration managed by administrators. **Cannot be overridden** by Personal or Project settings.

**Where it lives:**

| OS | Path |
|----|------|
| Windows | `C:\ProgramData\ClaudeCode\managed-settings.json` |
| Linux/WSL | `/etc/claude-code/managed-settings.json` |
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` |

**Who manages it:** System administrators / DevOps team.

**Best for:** Non-negotiable standards that the organization wants to enforce for everyone:
- Code formatting rules (Checkstyle, PMD)
- Style enforcement hooks
- Compilation checks before commit
- Domain expertise skills (BDM, REST API patterns)

**How Enterprise resources are deployed:**
1. IT/DevOps creates the `managed-settings.json` file at the system path
2. Skills can be uploaded via the Claude Skills API for organization-wide availability
3. Configuration cannot be modified by individual developers

---

### ★★☆ Personal Scope — Priority 2

**What:** Your personal commands, skills, and settings. Available in **every project** you open. Not shared with anyone.

**Where it lives:**

```
~/.claude/                     # Windows: C:\Users\YourName\.claude\
├── CLAUDE.md                  # Your global instructions for Claude
├── commands/                  # Your personal commands (all projects)
│   └── my-shortcut.md
├── skills/                    # Your personal skills (all projects)
│   └── my-skill/
│       └── SKILL.md
└── settings.json              # Your personal hooks + permissions
```

**Who manages it:** You.

**Best for:** Developer productivity tools and personal preferences:
- Compilation shortcuts
- Test execution commands
- Code generation helpers
- Quality inspection tools
- Personal workflow preferences

---

### ★☆☆ Project Scope — Priority 3

**What:** Project-specific configuration committed to git. **Shared automatically** with the whole team when they pull.

**Where it lives:**

```
your-project/
├── CLAUDE.md                  # Project instructions (shared)
├── CLAUDE.local.md            # Your personal overrides (NOT committed)
└── .claude/
    ├── commands/              # Project commands (shared)
    ├── hooks/                 # Project hook scripts (shared)
    ├── skills/                # Project skills (shared)
    ├── settings.json          # Project hooks config (shared)
    └── settings.local.json    # Your personal overrides (NOT committed)
```

**Who manages it:** The team (via git).

**Best for:** Resources that depend on the specific project:
- Bonita-specific checks (BDM, controllers, processes)
- Project-type-specific hooks (library test pairs, BDM validation)
- Settings templates tailored to the project

---

### ☆☆☆ Plugin Scope — Priority 4

**What:** Skills bundled within Claude Code plugins. Use **namespaced names** (`plugin-name:skill-name`) so they never conflict with other scopes.

**Best for:** Third-party or optional extensions distributed as packages.

---

## Resource Catalog by Scope

### Enterprise Resources

These resources enforce **organization-wide standards**. We recommend deploying them at the Enterprise level so they apply to all developers on all projects, and **cannot be overridden**.

#### Enterprise Skills

| Skill | Auto-invokes when... | What it enforces |
|-------|---------------------|-----------------|
| `bonita-bdm-expert` | User asks about BDM, queries, JPQL, data model | countFor rule, naming conventions (`PB` prefix), descriptions, indexes |
| `bonita-rest-api-expert` | User asks about REST API extensions, controllers | Abstract/Concrete pattern, README.md, Javadoc, test requirements |
| `bonita-document-expert` | User asks about PDF, HTML reports, Word/Excel export, documents | Corporate branding (colors, logo, header/footer), BrandingConfig pattern, OpenPDF/Thymeleaf/POI stack |
| `bonita-groovy-expert` | User asks about Groovy scripts in Bonita processes | Script standards, API accessor patterns, DAO access, null handling, max 30 lines |
| `bonita-process-expert` | User asks about process modeling, .proc files, subprocesses | Process architecture, contracts, connectors, variables, subprocess reuse |
| `testing-expert` | User asks about testing, unit tests, coverage, mutation testing | JUnit 5 + Mockito + AssertJ + jqwik + PIT, `should_do_X_when_Y` naming |
| `skill-creator` | User asks to create a new skill or SKILL.md | Anthropic methodology, frontmatter rules, naming, progressive disclosure |

#### Enterprise Hooks

| Hook | Event | What it enforces |
|------|-------|-----------------|
| `pre-commit-compile.sh` | PreToolUse (Bash) | **Blocks** `git commit` if `mvn clean compile` fails |
| `check-code-format.sh` | PostToolUse (Edit/Write) | Tabs, trailing whitespace, line length > 120, wildcard imports, blank lines |
| `check-code-style.sh` | PostToolUse (Edit/Write) | System.out.println, empty catch, methods > 30 lines, missing @Override |
| `check-hardcoded-strings.sh` | PostToolUse (Edit) | Magic strings in comparisons and switch cases |
| `check-document-pattern.sh` | PostToolUse (Edit/Write) | Document generation without BrandingConfig, hardcoded colors/fonts, iText usage |
| `check-skill-structure.sh` | PostToolUse (Write/Edit) | SKILL.md structure validation: frontmatter, naming, description, required sections |

#### Enterprise Configs

| Config | Purpose | Maven plugin |
|--------|---------|-------------|
| `checkstyle.xml` | Code style rules (Google-based, team-adjusted) | `maven-checkstyle-plugin` |
| `pmd-ruleset.xml` | Static analysis (complexity, best practices, errors) | `maven-pmd-plugin` |
| `.editorconfig` | Editor formatting (indent, line endings, charset) | Native IDE support |

---

### Personal Resources

These are **developer productivity tools**. Install them in `~/.claude/` so they're available in every project without cluttering project repos.

#### Personal Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `/compile` | Compile project with Maven | `/compile` or `/compile extensions` |
| `/run-tests` | Run unit/integration/property tests | `/run-tests`, `/run-tests integration`, `/run-tests MyClass` |
| `/run-mutation-tests` | Run PIT mutation testing | `/run-mutation-tests MyModule` |
| `/generate-tests` | Generate unit + property tests for a class | `/generate-tests MyController` |
| `/check-coverage` | Run JaCoCo and verify coverage thresholds | `/check-coverage` |
| `/check-code-quality` | Check Javadoc, method length, code smells | `/check-code-quality src/main/java/` |
| `/audit-compliance` | Full project compliance audit | `/audit-compliance` |
| `/refactor-method-signature` | Refactor method + update ALL call sites | `/refactor-method-signature setName add param` |
| `/create-constants` | Extract hardcoded strings to constants | `/create-constants MyService.java` |

---

### Project Resources

These resources **depend on the project type**. Install them in `.claude/` within the specific repository and commit to git.

#### Project Commands (Bonita BPM)

| Command | Description | Usage |
|---------|-------------|-------|
| `/check-bdm-queries` | Search existing BDM queries before creating new ones | `/check-bdm-queries PBProcess` |
| `/validate-bdm` | Full BDM compliance audit (countFor, descriptions, indexes) | `/validate-bdm` |
| `/check-existing-extensions` | Search extensions for similar functionality | `/check-existing-extensions cancel process` |
| `/check-existing-processes` | Search processes for similar logic | `/check-existing-processes notification` |
| `/generate-readme` | Generate README.md for a REST API controller | `/generate-readme CancelController` |
| `/generate-document` | Scaffold corporate document service (PDF/HTML/DOCX/XLSX) | `/generate-document PDF InvoiceReport` |

#### Project Hooks

| Hook | For project type | What it does |
|------|-----------------|-------------|
| `check-bdm-countfor.sh` | Bonita BPM | Warns about missing countFor queries when editing bom.xml |
| `check-controller-readme.sh` | Bonita BPM | Warns when creating a controller without README.md |
| `check-method-usages.sh` | Multi-module Java | Lists files calling a method when its signature changes |
| `check-test-pair.sh` | Java libraries | Warns if *Test.java or *PropertyTest.java is missing |

#### Project Templates

| Template | For project type | What it includes |
|----------|-----------------|-----------------|
| `bonita-project.json` | Bonita BPM | All enterprise hooks + BDM/controller hooks + auto-test agent |
| `java-library.json` | Java libraries | Enterprise hooks + test-pair check + auto-test agent |
| `CLAUDE.md.template` | Any project | Starter CLAUDE.md with team standards and TODO markers |

#### Agent Hooks (in templates)

| Agent | Trigger | What it does |
|-------|---------|-------------|
| Auto-test agent (Bonita) | Stop (Claude finishes) | Finds modified files, creates/updates tests, runs `mvn test` |
| Auto-test agent (Library) | Stop (Claude finishes) | Same + ensures PropertyTest files exist for jqwik |

---

## Installation Guide

### Option 1: Automated Installer

```bash
cd /path/to/claude-code-toolkit
bash install.sh
```

The script will ask you:
1. Which scope (Enterprise / Personal / Project)
2. Which project type (Bonita BPM / Java Library / Generic)
3. Where to install (path)

### Option 2: Manual Installation

#### Install Enterprise Resources

Deploy to the system-wide managed settings path:

**Skills** — Upload via Claude Skills API or copy to managed enterprise directory:
```bash
# Copy skills to a shared enterprise location
sudo mkdir -p /etc/claude-code/skills
sudo cp -r skills/bonita-bdm-expert /etc/claude-code/skills/
sudo cp -r skills/bonita-rest-api-expert /etc/claude-code/skills/
```

**Hooks + Configs** — Add to `managed-settings.json`:
```bash
# Windows (run as Administrator):
mkdir -p "C:\ProgramData\ClaudeCode"
cp configs/checkstyle.xml "C:\ProgramData\ClaudeCode\"
cp configs/pmd-ruleset.xml "C:\ProgramData\ClaudeCode\"
# Edit C:\ProgramData\ClaudeCode\managed-settings.json to include hook definitions

# Linux:
sudo mkdir -p /etc/claude-code
sudo cp configs/* /etc/claude-code/
# Edit /etc/claude-code/managed-settings.json
```

#### Install Personal Resources

Copy commands and settings to your home directory:
```bash
# Create directories
mkdir -p ~/.claude/commands

# Copy productivity commands
cp commands/java-maven/* ~/.claude/commands/
cp commands/quality/* ~/.claude/commands/
cp commands/testing/* ~/.claude/commands/

# Optional: copy personal settings with enterprise hooks
cp templates/bonita-project.json ~/.claude/settings.json
```

#### Install Project Resources

Copy to your project's `.claude/` directory and commit:
```bash
cd your-project
mkdir -p .claude/commands .claude/hooks .claude/skills

# Copy project-specific commands (Bonita example)
cp /path/to/toolkit/commands/bonita/* .claude/commands/

# Copy hook scripts
cp /path/to/toolkit/hooks/scripts/* .claude/hooks/
chmod +x .claude/hooks/*.sh

# Copy skills
cp -r /path/to/toolkit/skills/* .claude/skills/

# Copy settings template
cp /path/to/toolkit/templates/bonita-project.json .claude/settings.json

# Copy config files to project root
cp /path/to/toolkit/configs/checkstyle.xml .
cp /path/to/toolkit/configs/pmd-ruleset.xml .
cp /path/to/toolkit/configs/.editorconfig .

# Copy and customize CLAUDE.md
cp /path/to/toolkit/templates/CLAUDE.md.template CLAUDE.md

# Commit to share with team
git add .claude/ checkstyle.xml pmd-ruleset.xml .editorconfig CLAUDE.md
git commit -m "chore: adopt Claude Code toolkit methodology"
```

Then **restart Claude Code** to load the new hooks.

---

## What are Commands, Hooks, Skills?

### Commands (Slash Commands)

**What:** Instructions you invoke by typing `/command-name` in Claude Code.

**How:** Markdown files in `.claude/commands/` or `~/.claude/commands/`. Use `$ARGUMENTS` for parameters.

```markdown
# Run Tests
## Arguments
- `$ARGUMENTS`: test type (unit, integration, property) or class name
## Instructions
1. Execute: `mvn test -f extensions/pom.xml`
2. Show summary of results
```

```
You: /run-tests                    → runs all tests
You: /run-tests integration       → runs integration tests
You: /run-tests MyControllerTest  → runs specific class
```

### Hooks (Automatic Checks)

**What:** Scripts that fire **automatically** on events. No user action required.

**How:** Defined in `settings.json`. Scripts receive JSON on stdin, return exit codes.

| Event | When | Use |
|-------|------|-----|
| `PreToolUse` | Before Claude uses a tool | Block dangerous actions |
| `PostToolUse` | After Claude uses a tool | Lint, validate, warn |
| `Stop` | Claude finishes responding | Auto-run tests |

| Exit code | Meaning |
|-----------|---------|
| `exit 0` | Allow (warnings via stderr) |
| `exit 2` | **Block** the action (PreToolUse only) |

**Types:** `command` (shell script), `prompt` (AI judgment), `agent` (full Claude agent with tools)

### Skills (Expert Assistants)

**What:** Advanced commands with YAML frontmatter. Claude **auto-invokes** them when it detects a relevant task.

**How:** `SKILL.md` files in `.claude/skills/skill-name/`.

```yaml
---
name: bonita-bdm-expert
description: Use when the user asks about BDM queries or data model.
allowed-tools: Read, Grep, Glob
---
You are an expert in Bonita BDM design...
```

| Feature | Command | Skill |
|---------|---------|-------|
| Format | `.md` | `SKILL.md` (YAML frontmatter) |
| Location | `.claude/commands/` | `.claude/skills/name/` |
| Tool restrictions | No | Yes (`allowed-tools`) |
| Auto-invocation | No (user types `/`) | Yes (Claude detects context) |

### Configurations

**What:** Standard rule files for code quality tools (Checkstyle, PMD, EditorConfig).

**How:** Copy to project root. Reference from Maven plugins:

```xml
<!-- Checkstyle -->
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-checkstyle-plugin</artifactId>
  <version>3.3.1</version>
  <configuration>
    <configLocation>checkstyle.xml</configLocation>
    <failsOnError>true</failsOnError>
  </configuration>
</plugin>

<!-- PMD -->
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-pmd-plugin</artifactId>
  <version>3.21.2</version>
  <configuration>
    <rulesets><ruleset>pmd-ruleset.xml</ruleset></rulesets>
    <failOnViolation>true</failOnViolation>
  </configuration>
</plugin>
```

---

## Where to Define Things

### Context Files (CLAUDE.md)

| File | Shared? | Scope | Purpose |
|------|---------|-------|---------|
| `CLAUDE.md` | Yes (git) | Project | Team rules, architecture. `/init` to generate. |
| `CLAUDE.local.md` | No | Project (personal) | Your tweaks. NOT committed. |
| `~/.claude/CLAUDE.md` | No | Global (personal) | Rules for ALL your projects. |

### Priority: Project `CLAUDE.md` > `~/.claude/CLAUDE.md`. `CLAUDE.local.md` adds/overrides for your session.

### Full Scope Matrix

| What | Enterprise | Personal | Project (shared) | Project (personal) |
|------|-----------|----------|-----------------|-------------------|
| **Skills** | Skills API / managed | `~/.claude/skills/` | `.claude/skills/` | — |
| **Commands** | — | `~/.claude/commands/` | `.claude/commands/` | — |
| **Hooks** | `managed-settings.json` | `~/.claude/settings.json` | `.claude/settings.json` | `.claude/settings.local.json` |
| **Instructions** | — | `~/.claude/CLAUDE.md` | `CLAUDE.md` | `CLAUDE.local.md` |
| **Configs** | System path | — | Project root | — |

### Quick Decision Guide

| You want to... | Scope | Location |
|----------------|-------|----------|
| Enforce standards for ALL developers | Enterprise | `managed-settings.json` |
| Have personal productivity tools | Personal | `~/.claude/commands/` |
| Share team rules for a project | Project | `CLAUDE.md` + `.claude/` |
| Override something just for you | Project (personal) | `CLAUDE.local.md` / `settings.local.json` |
| Set personal rules for ALL projects | Personal | `~/.claude/CLAUDE.md` |

---

## Repository Structure

```
claude-code-toolkit/
├── commands/
│   ├── java-maven/                    # ★★☆ Personal — developer productivity
│   │   ├── compile.md
│   │   ├── run-tests.md
│   │   └── run-mutation-tests.md
│   ├── bonita/                        # ★☆☆ Project — Bonita-specific
│   │   ├── check-bdm-queries.md
│   │   ├── validate-bdm.md
│   │   ├── check-existing-extensions.md
│   │   ├── check-existing-processes.md
│   │   ├── generate-readme.md
│   │   └── generate-document.md
│   ├── quality/                       # ★★☆ Personal — quality tools
│   │   ├── audit-compliance.md
│   │   ├── check-code-quality.md
│   │   ├── create-constants.md
│   │   └── refactor-method-signature.md
│   └── testing/                       # ★★☆ Personal — testing tools
│       ├── generate-tests.md
│       └── check-coverage.md
├── hooks/
│   └── scripts/
│       ├── pre-commit-compile.sh      # ★★★ Enterprise — never commit broken code
│       ├── check-code-format.sh       # ★★★ Enterprise — uniform formatting
│       ├── check-code-style.sh        # ★★★ Enterprise — style standards
│       ├── check-hardcoded-strings.sh # ★★★ Enterprise — constants policy
│       ├── check-document-pattern.sh  # ★★★ Enterprise — corporate branding in documents
│       ├── check-skill-structure.sh   # ★★★ Enterprise — SKILL.md methodology validation
│       ├── check-bdm-countfor.sh      # ★☆☆ Project — Bonita BDM only
│       ├── check-controller-readme.sh # ★☆☆ Project — Bonita REST API only
│       ├── check-method-usages.sh     # ★☆☆ Project — multi-module only
│       └── check-test-pair.sh         # ★☆☆ Project — libraries only
├── skills/
│   ├── bonita-bdm-expert/             # ★★★ Enterprise — company BDM knowledge
│   │   └── SKILL.md
│   ├── bonita-rest-api-expert/        # ★★★ Enterprise — company REST API patterns
│   │   └── SKILL.md
│   ├── bonita-document-expert/        # ★★★ Enterprise — corporate document generation
│   │   └── SKILL.md
│   ├── bonita-groovy-expert/          # ★★★ Enterprise — Groovy scripts in Bonita
│   │   └── SKILL.md
│   ├── bonita-process-expert/         # ★★★ Enterprise — process modeling patterns
│   │   └── SKILL.md
│   ├── testing-expert/                # ★★★ Enterprise — comprehensive testing strategy
│   │   └── SKILL.md
│   └── skill-creator/                 # ★★★ Enterprise — meta-skill for creating skills
│       └── SKILL.md
├── configs/
│   ├── checkstyle.xml                 # ★★★ Enterprise — code style rules
│   ├── pmd-ruleset.xml                # ★★★ Enterprise — static analysis
│   └── .editorconfig                  # ★★★ Enterprise — editor formatting
├── templates/
│   ├── bonita-project.json            # ★☆☆ Project — Bonita settings template
│   ├── java-library.json              # ★☆☆ Project — Library settings template
│   └── CLAUDE.md.template             # ★☆☆ Project — Starter instructions
├── install.sh                         # Automated installer script
├── README.md                          # This file
├── CONTRIBUTING.md                    # How to contribute to the toolkit
└── ADOPTION_GUIDE.md                  # Step-by-step adoption guide
```

**Legend:** ★★★ Enterprise | ★★☆ Personal | ★☆☆ Project

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed instructions on:
- How to add new commands, hooks, skills, and configs
- How to classify resources by scope
- Naming conventions and quality checklist
- Ideas for future contributions

### Quick contribution guide

1. Clone this repo
2. Add or improve a resource
3. Classify it by scope (Enterprise / Personal / Project) in the README
4. Test in a real project
5. Submit a PR

---

## Projects Using This Toolkit

- [ps-process-builder](https://github.com/bonitasoft-presales/ps-process-builder) — Bonita BPM Process Builder
- [process-builder-extension-library](https://github.com/bonitasoft-presales/process-builder-extension-library) — Shared Java library

---

## License

Internal use — Bonitasoft Professional Services
