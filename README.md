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
- [Agents (Subagents)](#agents-subagents)
- [MCP Skills](#mcp-skills)
- [Plugins](#plugins)
- [When to Use What](#when-to-use-what)
- [Where to Define Things](#where-to-define-things)
- [Repository Structure](#repository-structure)
- [Contributing](#contributing)
- [Projects Using This Toolkit](#projects-using-this-toolkit)

---

## What is this?

This repository is the **single source of truth** for Bonitasoft's AI-assisted development methodology. It contains:

| What | Purpose | How many |
|------|---------|----------|
| **Skills** | Expert knowledge with progressive disclosure (BDM, REST API, UIB, Audit, Testing...) | 13 |
| **Agents** | Isolated subagents for delegated tasks (code review, test generation, audit, docs) | 4 |
| **Commands** | Slash commands for common tasks (`/run-tests`, `/generate-tests`) | 17 |
| **Hooks** | Automatic checks that fire without user action (format, style, compile) | 13 |
| **Configs** | Standard rule files (Checkstyle, PMD, EditorConfig) | 3 |
| **Templates** | Ready-to-use settings, CLAUDE.md starter, GitHub Actions | 4 |

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
| `bonita-bdm-expert` | BDM, queries, JPQL, data model | countFor, naming (`PB` prefix), indexes, descriptions |
| `bonita-rest-api-expert` | REST API extensions, controllers | Abstract/Concrete pattern, README, DTOs, OpenAPI |
| `bonita-document-expert` | PDF, HTML, Word/Excel, branding | BrandingConfig, corporate CSS, logo, OpenPDF/Thymeleaf/POI |
| `bonita-groovy-expert` | Groovy scripts in Bonita processes | API accessor, DAO, script extraction from .proc |
| `bonita-process-expert` | Process modeling, .proc files | 3-level tiering, contracts, connectors, subprocess reuse |
| `bonita-uib-expert` | UI Builder, Appsmith pages, widgets | Naming, async/await, JS Objects, bonita-api-plugin |
| `bonita-coding-standards` | Code quality, Java 17, clean code | SRP, method length, Javadoc, Checkstyle, PMD |
| `bonita-audit-expert` | Code audits, quality reports | Backend + UIB audit templates, automated checks |
| `testing-expert` | Unit tests, coverage, mutation testing | JUnit 5 + Mockito + AssertJ + jqwik + PIT |
| `bonita-integration-testing-expert` | Integration tests, controller testing, doHandle | Full lifecycle tests, HTTP status paths, Bonita mocking |
| `skill-creator` | Creating new skills | Anthropic methodology, progressive disclosure |
| `jira-workflow-expert` | Jira issues, sprints, transitions | Issue types, priorities, labels, workflows (MCP skill) |
| `confluence-docs-expert` | Confluence pages, docs, specs | Page templates, structure, labels, writing style (MCP skill) |

> **Multi-file structure:** Every skill uses progressive disclosure — SKILL.md (< 500 lines) contains core rules; `references/`, `scripts/`, and `assets/` directories contain detailed docs, executable scripts, and templates that Claude loads only when needed. This replaces the old `context-ia/` approach where ALL docs were loaded at startup.

#### Enterprise Hooks

| Hook | Event | What it enforces |
|------|-------|-----------------|
| `pre-commit-compile.sh` | PreToolUse (Bash) | **Blocks** `git commit` if `mvn clean compile` fails |
| `check-code-format.sh` | PostToolUse (Edit/Write) | Tabs, trailing whitespace, line length > 120, wildcard imports, blank lines |
| `check-code-style.sh` | PostToolUse (Edit/Write) | System.out.println, empty catch, methods > 30 lines, missing @Override |
| `check-hardcoded-strings.sh` | PostToolUse (Edit) | Magic strings in comparisons and switch cases |
| `check-document-pattern.sh` | PostToolUse (Edit/Write) | Document generation without BrandingConfig, hardcoded colors/fonts, iText usage |
| `check-skill-structure.sh` | PostToolUse (Write/Edit) | SKILL.md structure validation: frontmatter, naming, description, required sections |
| `check-openapi-annotations.sh` | PostToolUse (Edit/Write) | Missing @Tag, @Operation, @ApiResponse on REST API controllers |
| `pre-push-validate.sh` | PreToolUse (Bash) | **Blocks** `git push` if compilation fails or sensitive files staged |

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
| `/generate-integration-tests` | Generate integration tests for a controller | `/generate-integration-tests MyController` |
| `/check-test-coverage-gap` | Find classes missing test pairs and coverage | `/check-test-coverage-gap` or `/check-test-coverage-gap extensions/myModule` |
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
| `test-toolkit/` | Bonita Test Toolkit | Complete .claude/ dir with commands, hooks, skill, and agent for integration tests |
| `CLAUDE.md.template` | Any project | Starter CLAUDE.md with team standards and TODO markers |
| `claude-pr-review.yml` | Any project | GitHub Actions: compile, test, Checkstyle/PMD, coverage gate, optional Claude review |

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

## Agents (Subagents)

Agents are **isolated Claude instances** that receive a delegated task, work independently with their own context, and return results. Unlike skills (which inject knowledge into your conversation), agents run autonomously.

**Key facts:**
- Agents do NOT see your skills automatically — skills must be listed explicitly in the agent's `skills:` frontmatter
- Each agent gets its own context window, isolated from your main conversation
- Agents can have different `tools` and `model` than your main session
- Install in `.claude/agents/` within your project (Project scope)

### Available Agents

| Agent | Skills Loaded | Best For |
|-------|--------------|----------|
| `bonita-code-reviewer` | coding-standards, rest-api-expert, testing-expert | PR reviews, module code reviews |
| `bonita-test-generator` | testing-expert, integration-testing-expert | Batch test creation for modules |
| `bonita-auditor` | audit-expert, coding-standards, bdm-expert, rest-api-expert, testing-expert | Full project audits with scoring |
| `bonita-documentation-generator` | rest-api-expert, document-expert | Batch README and Javadoc generation |

### Usage

```
You: delegate to bonita-code-reviewer: review the changes in this PR
You: delegate to bonita-test-generator: create tests for the payment module
You: delegate to bonita-auditor: run a full audit of this project
You: delegate to bonita-documentation-generator: document all REST controllers
```

> See [agents/README.md](agents/README.md) for details.

---

## MCP Skills

MCP servers provide **tools** (functions Claude can call). Skills teach Claude **how and when** to use those tools following team conventions. Together they form a powerful pattern:

```
MCP Server (provides tools) + Skill (teaches conventions) = Effective AI assistant
```

### Available MCP Skills

| Skill | MCP Server | What it teaches |
|-------|-----------|----------------|
| `jira-workflow-expert` | Jira MCP | Issue types, priority rules, label conventions, workflow transitions |
| `confluence-docs-expert` | Confluence MCP | Page templates, structure standards, label conventions, writing style |

### Why MCP Skills Matter

| Without skill | With skill |
|---------------|-----------|
| Claude creates Jira issues with generic descriptions | Claude follows your issue template (Story, Bug, Task) |
| Claude assigns random priority | Claude uses your priority rules (Blocker → Same day SLA) |
| Claude doesn't add labels | Claude adds required labels per component (`bdm`, `rest-api`, `process`) |
| Claude creates Confluence pages with no structure | Claude applies page templates (Tech Spec, ADR, Runbook) |

> MCP Skills should be deployed at **Enterprise scope** so all team members follow the same conventions.

---

## Plugins

Plugins are **packaged Claude Code extensions** distributed through marketplaces (npm, GitHub). They use **namespaced names** (`plugin-name:skill-name`) and have **Priority 4** (lowest), so they never conflict with higher scopes.

### Plugin Candidates from This Toolkit

| Resource | Why Plugin? |
|----------|-------------|
| `testing-expert` | JUnit 5 + Mockito + AssertJ + jqwik patterns are universal |
| `skill-creator` | Meta-skill useful for any Claude Code user |

### Dual Publishing Strategy

For generic skills, we recommend keeping them in the toolkit (Enterprise, Priority 1) AND publishing as plugins (Priority 4). Since Enterprise > Plugin, there's no conflict. External teams get the community version.

> See [plugins/README.md](plugins/README.md) for publishing instructions.

---

## When to Use What

Not sure which resource type to use? See **[WHEN_TO_USE_WHAT.md](WHEN_TO_USE_WHAT.md)** for:

- Quick decision table
- Detailed comparison of all 7 resource types
- Decision flowchart
- Scope matrix (what goes where)
- Deep dives on Agents, Plugins, and MCP+Skills pattern

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
├── agents/                            # ★☆☆ Project — delegated task agents
│   ├── README.md
│   ├── code-reviewer.md              # Code review with skills
│   ├── test-generator.md             # Batch test creation with skills
│   ├── bonita-auditor.md             # Full project audit with skills
│   └── documentation-generator.md    # Batch documentation with skills
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
│       ├── generate-integration-tests.md
│       ├── check-test-coverage-gap.md
│       └── check-coverage.md
├── hooks/
│   └── scripts/
│       ├── pre-commit-compile.sh      # ★★★ Enterprise — never commit broken code
│       ├── check-code-format.sh       # ★★★ Enterprise — uniform formatting
│       ├── check-code-style.sh        # ★★★ Enterprise — style standards
│       ├── check-hardcoded-strings.sh # ★★★ Enterprise — constants policy
│       ├── check-document-pattern.sh  # ★★★ Enterprise — corporate branding in documents
│       ├── check-skill-structure.sh   # ★★★ Enterprise — SKILL.md methodology validation
│       ├── check-openapi-annotations.sh # ★☆☆ Project — OpenAPI docs on controllers
│       ├── pre-push-validate.sh       # ★★★ Enterprise — never push broken code
│       ├── check-bdm-countfor.sh      # ★☆☆ Project — Bonita BDM only
│       ├── check-controller-readme.sh # ★☆☆ Project — Bonita REST API only
│       ├── check-method-usages.sh     # ★☆☆ Project — multi-module only
│       └── check-test-pair.sh         # ★☆☆ Project — libraries only
├── skills/
│   ├── bonita-bdm-expert/             # ★★★ Enterprise — BDM & data model
│   │   ├── SKILL.md
│   │   ├── references/                # datamodel-rules, query-patterns, access-control
│   │   └── scripts/validate-bdm.sh
│   ├── bonita-rest-api-expert/        # ★★★ Enterprise — REST API patterns
│   │   ├── SKILL.md
│   │   ├── references/                # controller-checklist, dto-patterns, readme-template, openapi
│   │   ├── scripts/check-controller.sh
│   │   └── assets/controller-readme-template.md
│   ├── bonita-document-expert/        # ★★★ Enterprise — corporate document generation
│   │   ├── SKILL.md
│   │   ├── references/                # pdf-generation, office-generation, thymeleaf, maven-deps
│   │   └── assets/                    # BrandingConfig.java, corporate.css, bonitasoft-logo.svg
│   ├── bonita-groovy-expert/          # ★★★ Enterprise — Groovy scripts in Bonita
│   │   ├── SKILL.md
│   │   └── references/               # bonita-api-patterns, proc-script-extraction, common-patterns
│   ├── bonita-process-expert/         # ★★★ Enterprise — process modeling
│   │   ├── SKILL.md
│   │   └── references/               # bpm-standards, process-tiering, contracts, connector-errors
│   ├── bonita-uib-expert/            # ★★★ Enterprise — UI Builder (Appsmith)
│   │   ├── SKILL.md
│   │   ├── references/               # widgets, api-actions, js-patterns, header, charts, naming, xml, troubleshooting
│   │   └── scripts/validate-uib-naming.sh
│   ├── bonita-coding-standards/       # ★★★ Enterprise — Java 17 & clean code
│   │   ├── SKILL.md
│   │   ├── references/               # java17-patterns, delivery-checklist, connectors, deployment
│   │   └── scripts/check-code-quality.sh
│   ├── bonita-audit-expert/           # ★★★ Enterprise — code audits & reports
│   │   ├── SKILL.md
│   │   ├── references/               # backend-audit-template, uib-audit-template, audit-checklist
│   │   └── scripts/                  # generate-audit-report.sh, run-audit-checks.sh
│   ├── testing-expert/                # ★★★ Enterprise — comprehensive testing
│   │   ├── SKILL.md
│   │   ├── references/               # junit5, property-testing, mutation-testing, bonita-mocking
│   │   └── scripts/                  # run-tests.sh, check-coverage.sh
│   ├── bonita-integration-testing-expert/ # ★★★ Enterprise — controller integration tests
│   │   ├── SKILL.md
│   │   ├── references/               # bonita-test-harness, controller-test-patterns, dto-validation
│   │   └── assets/IntegrationTestTemplate.java
│   ├── skill-creator/                 # ★★★ Enterprise — meta-skill for creating skills
│   │   └── SKILL.md
│   ├── jira-workflow-expert/          # ★★★ Enterprise — MCP skill for Jira conventions
│   │   ├── SKILL.md
│   │   └── references/issue-templates.md
│   └── confluence-docs-expert/        # ★★★ Enterprise — MCP skill for Confluence conventions
│       ├── SKILL.md
│       └── references/page-templates.md
├── configs/
│   ├── checkstyle.xml                 # ★★★ Enterprise — code style rules
│   ├── pmd-ruleset.xml                # ★★★ Enterprise — static analysis
│   └── .editorconfig                  # ★★★ Enterprise — editor formatting
├── templates/
│   ├── bonita-project.json            # ★☆☆ Project — Bonita settings template
│   ├── java-library.json              # ★☆☆ Project — Library settings template
│   ├── CLAUDE.md.template             # ★☆☆ Project — Starter instructions
│   ├── test-toolkit/                  # ★☆☆ Project — Bonita Test Toolkit template
│   │   ├── README.md
│   │   └── .claude/                   # Complete .claude/ dir for test projects
│   └── github-actions/
│       └── claude-pr-review.yml       # ★★★ Enterprise — CI/CD quality gates + Claude review
├── plugins/
│   └── README.md                      # Guide for publishing toolkit skills as plugins
├── install.sh                         # Interactive installer (prompts for scope/type)
├── setup-dev-env.sh                   # Non-interactive installer (--personal, --project, --list)
├── WHEN_TO_USE_WHAT.md                # Decision guide: when to use each resource type
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

### PS Toolkit Repos (bonitasoft-ps)

| Repository | Skills | Hooks | Commands |
|-----------|--------|-------|----------|
| [bonita-upgrade-toolkit](https://github.com/bonitasoft-ps/bonita-upgrade-toolkit) | 10 | 2 | 6 |
| [bonita-audit-toolkit](https://github.com/bonitasoft-ps/bonita-audit-toolkit) | 12 | 3 | 7 |
| [bonita-connectors-generator-toolkit](https://github.com/bonitasoft-ps/bonita-connectors-generator-toolkit) | 5 | 4 | 9 |
| [bonita-ps-mcp](https://github.com/bonitasoft-ps/bonita-ps-mcp) | 1 | 1 | 4 |
| [template-test-toolkit](https://github.com/bonitasoft-ps/template-test-toolkit) | 1 | 3 | 0 |

### Presales Projects (bonitasoft-presales)

| Repository | Description |
|-----------|-------------|
| [ps-process-builder](https://github.com/bonitasoft-presales/ps-process-builder) | Bonita BPM Process Builder |
| [process-builder-extension-library](https://github.com/bonitasoft-presales/process-builder-extension-library) | Shared Java library |

### Quick Setup

For PS team members, the fastest way to get everything configured:

```bash
# Clone bonita-ps-mcp and run the all-in-one setup
git clone git@github.com:bonitasoft-ps/bonita-ps-mcp.git
bash bonita-ps-mcp/scripts/setup-ps-tools.sh ~/ps-tools
```

This clones all 6 repos, installs MCP dependencies, configures personal commands, and generates the Claude Desktop config.

Alternatively, use the non-interactive installer directly:

```bash
# Install personal commands only
bash setup-dev-env.sh --personal

# Configure a specific project
bash setup-dev-env.sh --project /path/to/project --project-type bonita

# See what's available
bash setup-dev-env.sh --list
```

---

## License

Internal use — Bonitasoft Professional Services
