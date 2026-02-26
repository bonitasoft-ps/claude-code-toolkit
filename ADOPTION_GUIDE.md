# Adoption Guide: Claude Code Toolkit

This guide explains how to adopt the Bonitasoft development methodology in your project.

---

## Quick Start (5 minutes)

### Option A: Automated Installer (Recommended)

```bash
# Clone the toolkit
git clone https://github.com/bonitasoft-ps/claude-code-toolkit.git

# Run the installer
cd claude-code-toolkit
bash install.sh
```

The installer asks:
1. **Scope** — Enterprise (org-wide), Personal (your tools), or Project (team via git)
2. **Project type** — Bonita BPM, Java Library, or Generic Java
3. **Path** — Where to install

### Option B: Manual Setup

```bash
# Clone the toolkit
git clone https://github.com/bonitasoft-ps/claude-code-toolkit.git

# Go to your project
cd your-project
mkdir -p .claude/commands .claude/hooks .claude/skills .claude/agents

# Copy settings template (choose one)
cp /path/to/toolkit/templates/bonita-project.json .claude/settings.json  # For Bonita
cp /path/to/toolkit/templates/java-library.json .claude/settings.json    # For libraries

# Copy commands
cp /path/to/toolkit/commands/bonita/* .claude/commands/     # Bonita-specific commands
cp /path/to/toolkit/commands/java-maven/* .claude/commands/ # Build commands (optional)
cp /path/to/toolkit/commands/quality/* .claude/commands/    # Quality commands (optional)
cp /path/to/toolkit/commands/testing/* .claude/commands/    # Testing commands (optional)

# Copy hook scripts + make executable
cp /path/to/toolkit/hooks/scripts/* .claude/hooks/
chmod +x .claude/hooks/*.sh

# Copy skills
cp -r /path/to/toolkit/skills/* .claude/skills/

# Copy agents
cp /path/to/toolkit/agents/*.md .claude/agents/

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

### Step 3: Restart Claude Code

Close and reopen Claude Code (or your IDE with Claude extension) to load the new hooks.

---

## Understanding the Scopes

Resources are organized by **scope** — who they affect and where they're installed:

```
★★★ Enterprise   Cannot be overridden. For ALL developers on ALL projects.
★★☆ Personal     Your ~/.claude/ directory. Available in all YOUR projects.
★☆☆ Project      Inside the repo .claude/. Shared with team via git.
```

**Priority:** Enterprise > Personal > Project. If two resources have the same name, the higher scope wins.

### What goes where?

| Resource type | Recommended scope | Why |
|---------------|------------------|-----|
| Formatting hooks (check-code-format.sh) | ★★★ Enterprise | Everyone formats the same |
| Style hooks (check-code-style.sh) | ★★★ Enterprise | Consistent style standards |
| Pre-commit compilation | ★★★ Enterprise | Never commit broken code |
| Config files (Checkstyle, PMD) | ★★★ Enterprise | Same rules for everyone |
| Skills (BDM expert, REST API expert) | ★★★ Enterprise | Company domain knowledge |
| Productivity commands (/compile, /run-tests) | ★★☆ Personal | Developer convenience |
| Bonita-specific commands (/check-bdm-queries) | ★☆☆ Project | Only for Bonita projects |
| BDM hooks (check-bdm-countfor.sh) | ★☆☆ Project | Only for BDM projects |
| Agents (code-reviewer, auditor) | ★☆☆ Project | Delegated tasks use project skills |
| MCP skills (jira, confluence) | ★★★ Enterprise | Same conventions for all teams |
| Settings templates | ★☆☆ Project | Tailored per project type |

---

## What You Get

### Automatic Hooks (fire without user action)

| When | What happens | Scope |
|------|-------------|-------|
| You edit Java/Groovy | Checks formatting (tabs, whitespace, line length) | ★★★ |
| You edit Java | Checks style (System.out, empty catch, method length) | ★★★ |
| You edit Java/Groovy | Detects hardcoded magic strings | ★★★ |
| You commit code | Blocks if `mvn clean compile` fails | ★★★ |
| You edit bom.xml | Checks for missing countFor queries | ★☆☆ |
| You edit Java/Groovy | Lists files using modified method signatures | ★☆☆ |
| You create a controller | Warns if README.md is missing | ★☆☆ |
| Claude finishes | Auto-creates/updates tests for modified files | ★☆☆ |

### Slash Commands (type `/command` in Claude Code)

| Command | What it does | Scope |
|---------|-------------|-------|
| `/compile` | Compile project | ★★☆ |
| `/run-tests` | Run unit/integration/property tests | ★★☆ |
| `/run-mutation-tests` | Run PIT mutation testing | ★★☆ |
| `/generate-tests ClassName` | Generate unit + property tests | ★★☆ |
| `/check-code-quality` | Check Javadoc, method length, smells | ★★☆ |
| `/audit-compliance` | Full project compliance audit | ★★☆ |
| `/refactor-method-signature` | Refactor method + update call sites | ★★☆ |
| `/create-constants` | Extract hardcoded strings to constants | ★★☆ |
| `/check-coverage` | Run JaCoCo and check thresholds | ★★☆ |
| `/check-bdm-queries PBObject` | Search existing BDM queries | ★☆☆ |
| `/validate-bdm` | Validate BDM countFor, descriptions, indexes | ★☆☆ |
| `/check-existing-extensions` | Search for existing functionality | ★☆☆ |
| `/check-existing-processes` | Search for existing process logic | ★☆☆ |
| `/generate-readme` | Generate README.md for a controller | ★☆☆ |

### Expert Skills (auto-invoked by Claude)

| Skill | When Claude activates it | Scope |
|-------|------------------------|-------|
| `bonita-bdm-expert` | User asks about BDM, queries, JPQL, data model | ★★★ |
| `bonita-rest-api-expert` | User asks about REST API extensions, controllers | ★★★ |
| `jira-workflow-expert` | User manages Jira issues, priorities, labels (requires Jira MCP) | ★★★ |
| `confluence-docs-expert` | User creates/updates Confluence pages (requires Confluence MCP) | ★★★ |

### Agents (delegate complete tasks)

Agents are **isolated Claude instances** that work autonomously and return results. Install them in `.claude/agents/`:

```bash
cp /path/to/toolkit/agents/*.md your-project/.claude/agents/
```

| Agent | What it does | How to invoke |
|-------|-------------|---------------|
| `bonita-code-reviewer` | Reviews code against team standards | `delegate to bonita-code-reviewer: review this PR` |
| `bonita-test-generator` | Creates unit + property + integration tests in batch | `delegate to bonita-test-generator: create tests for payment module` |
| `bonita-auditor` | Full project audit with scoring | `delegate to bonita-auditor: audit this project` |
| `bonita-documentation-generator` | Generates READMEs and documentation | `delegate to bonita-documentation-generator: document all controllers` |

> **Agent vs Skill:** Skills enhance your current conversation (interactive). Agents run in isolation and return results (autonomous). Use agents for large delegated tasks like "review the entire PR" or "audit the project".

### MCP + Skills (external tool integration)

If your team uses Jira or Confluence MCPs, install the companion skills so Claude follows your conventions:

```
MCP Server (provides tools) + Skill (teaches conventions) = Effective AI assistant
```

| MCP Server | Companion Skill | What it adds |
|-----------|----------------|-------------|
| Jira MCP | `jira-workflow-expert` | Issue templates, priority rules, label conventions, workflow transitions |
| Confluence MCP | `confluence-docs-expert` | Page templates (Tech Spec, ADR, Runbook), structure standards, writing style |

Without the skill, Claude can create Jira issues but might use wrong priorities or skip required labels. With the skill, Claude follows your exact team conventions.

---

## For Different Project Types

### Bonita BPM Projects

Use `bonita-project.json` as the settings template. This includes all enterprise hooks plus:
- BDM countFor validation
- Controller README.md check
- Method usage tracking
- Auto-test agent on Stop

### Java Library Projects

Use `java-library.json` as the settings template. Differences from Bonita:
- Test pair validation (*Test.java + *PropertyTest.java)
- Auto-test agent includes property test generation

### Generic Java Projects

Use `bash install.sh` and choose "Generic Java". Gets enterprise hooks only (formatting, style, pre-commit).

---

## Customizing

### Add project-specific commands
Create `.claude/commands/my-command.md` in your project:

```markdown
# My Custom Command
## Arguments
- `$ARGUMENTS`: what the user passes after the command
## Instructions
1. Step one
2. Step two
```

### Disable a hook temporarily
Edit `.claude/settings.json` and remove the hook entry, or use:
```json
{ "disableAllHooks": true }
```

### Personal commands (not shared)
Put them in `~/.claude/commands/` — available in all your projects, invisible to teammates.

### Personal overrides (not shared)
Use `.claude/settings.local.json` for permissions or hook overrides that only apply to you.

---

## Setup per Role

### Developer
1. Run `bash install.sh` → choose Personal for commands, Project for your project
2. Add personal shortcuts to `~/.claude/commands/`
3. Customize `CLAUDE.local.md` for your preferences

### Tech Lead
1. Set up the toolkit in each project repo (Project scope)
2. Coordinate Enterprise scope deployment with IT/DevOps
3. Customize hooks per project needs
4. Review and update the shared toolkit periodically

### New Team Member
1. `git clone` the project — commands, hooks, and skills are already there
2. Optionally run `bash install.sh` → Personal to get productivity commands
3. Nothing else to install or configure

### IT/DevOps (Enterprise Deployment)
1. Run `bash install.sh` → Enterprise
2. Deploy `managed-settings.json` to the system path
3. Upload skills via Claude Skills API for organization-wide availability
