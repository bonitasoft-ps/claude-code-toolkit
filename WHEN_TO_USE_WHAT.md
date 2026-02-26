# When to Use What — Claude Code Resource Guide

> A practical reference to decide **which Claude Code resource** to use for each situation. Based on the [Introduction to Agent Skills](https://skilljar.anthropic.com) course and Bonitasoft team experience.

---

## The 7 Resource Types

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│   CLAUDE.md        → "What you ARE and what you must NOT do" (always)  │
│   Skills           → "How to do X when asked" (on demand)             │
│   Commands         → "Shortcuts I invoke with /" (explicit)           │
│   Hooks            → "What happens automatically on events" (event)   │
│   Agents           → "Delegate this entire task" (isolated context)   │
│   Plugins          → "Shareable extensions for the community"         │
│   MCP Servers      → "External tool connections (Jira, Confluence)"   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Quick Decision Table

| I want to... | Use | Why |
|--------------|-----|-----|
| Set rules Claude ALWAYS follows | `CLAUDE.md` | Loaded into every conversation |
| Teach Claude HOW to do a task | **Skill** | Loaded on demand when relevant |
| Create a shortcut I type `/` to run | **Command** | Explicit user invocation |
| Auto-check every time Claude edits a file | **Hook** | Event-driven, no user action needed |
| Delegate a complete task to an isolated agent | **Agent** | Separate context, returns results |
| Share functionality with other teams/community | **Plugin** | Namespaced, installable |
| Connect an external tool (Jira, SonarQube) | **MCP Server** | Provides tools to Claude |
| Teach Claude HOW to use an MCP tool well | **Skill + MCP** | Best practice patterns |

---

## Detailed Comparison

### CLAUDE.md vs Skills

| Aspect | CLAUDE.md | Skills |
|--------|-----------|--------|
| **Loading** | Every conversation (always on) | On demand (when matched) |
| **Token cost** | Constant (always in context) | Only when activated |
| **Best for** | Project-wide standards, constraints | Task-specific expertise |
| **Example** | "Use Java 17", "Never modify DB schema" | "How to create BDM queries" |
| **Format** | Free-form Markdown | `SKILL.md` with YAML frontmatter |

**Rule of thumb:** If it applies to >80% of conversations → `CLAUDE.md`. If it applies to <30% → Skill.

### Skills vs Commands

| Aspect | Skill | Command |
|--------|-------|---------|
| **Invocation** | Automatic (Claude detects context) | Explicit (user types `/command`) |
| **Format** | `SKILL.md` with frontmatter | `.md` file |
| **Tool restrictions** | Yes (`allowed-tools`) | No |
| **Progressive disclosure** | Yes (`references/`, `scripts/`, `assets/`) | No |
| **Best for** | Expert knowledge, complex procedures | Quick shortcuts, specific actions |
| **Example** | `bonita-bdm-expert` (activates when discussing BDM) | `/run-tests` (user explicitly runs) |

**Rule of thumb:** If the user should think about invoking it → Command. If Claude should figure it out → Skill.

### Skills vs Hooks

| Aspect | Skill | Hook |
|--------|-------|------|
| **Trigger** | Request-driven (matches user's question) | Event-driven (file save, commit, tool use) |
| **Purpose** | Add knowledge/guidance | Enforce rules/run checks |
| **Interaction** | Claude follows instructions in conversation | Script runs automatically, returns pass/fail |
| **Best for** | "How to design a REST API" | "Block commit if compilation fails" |

**Rule of thumb:** If it **guides** Claude's thinking → Skill. If it **enforces** a rule automatically → Hook.

### Skills vs Agents (Subagents)

| Aspect | Skill | Agent (Subagent) |
|--------|-------|-----------------|
| **Context** | Injected into current conversation | Separate, isolated context |
| **Interaction** | Enhances ongoing conversation | Delegated task, returns results |
| **Skills access** | N/A (is a skill) | Must explicitly list skills in frontmatter |
| **Best for** | "Help me design this BDM" (interactive) | "Review the entire PR" (autonomous) |
| **Token cost** | Shares main conversation context | Own context window |

**Rule of thumb:** If you want a **conversation** → Skill. If you want to **delegate** → Agent.

### Agents vs Hook Agents

| Aspect | Custom Agent (.claude/agents/) | Hook Agent (settings.json Stop event) |
|--------|-------------------------------|--------------------------------------|
| **Invocation** | User delegates explicitly | Automatic when Claude finishes |
| **Skills** | Can load skills | No skills access |
| **Tools** | Configurable in frontmatter | Full tool access |
| **Best for** | Complex delegated tasks | Post-task validation (auto-test) |

### Plugins vs Skills

| Aspect | Plugin | Skill |
|--------|--------|-------|
| **Scope** | Priority 4 (lowest) | Priority 1-3 depending on scope |
| **Distribution** | npm, GitHub marketplace | Git repo, manual copy |
| **Namespace** | `plugin-name:skill-name` | Flat name |
| **Best for** | Community-shareable, generic tools | Team-specific, domain expertise |

**Rule of thumb:** If it's useful **outside your company** → consider Plugin. If it's company-specific → Skill.

### MCP Servers + Skills

| Component | What it provides |
|-----------|-----------------|
| **MCP Server** | Tools (functions Claude can call) |
| **Skill for MCP** | Knowledge (when and how to use those tools well) |

**Example:**
- MCP: `jira-server` → gives Claude tools like `create_issue`, `search_issues`, `transition_issue`
- Skill: `jira-workflow-expert` → teaches Claude your team's issue conventions, priorities, labels

**Without the skill:** Claude can create Jira issues, but might use wrong priorities or miss required fields.
**With the skill:** Claude creates issues following your team's exact conventions.

---

## The 4 Scopes

```
┌──────────────────────────────────────────────────────────────┐
│  PRIORITY 1 ★★★  Enterprise                                 │
│  Cannot be overridden. For ALL developers on ALL projects.   │
│  Path: managed-settings.json (system-wide)                   │
├──────────────────────────────────────────────────────────────┤
│  PRIORITY 2 ★★☆  Personal                                   │
│  Your home directory. Available in ALL your projects.        │
│  Path: ~/.claude/                                            │
├──────────────────────────────────────────────────────────────┤
│  PRIORITY 3 ★☆☆  Project                                    │
│  Inside the repo .claude/. Shared with team via git.         │
│  Path: .claude/ in repository root                           │
├──────────────────────────────────────────────────────────────┤
│  PRIORITY 4 ☆☆☆  Plugin                                     │
│  Namespaced. Lowest priority. Community-distributed.         │
│  Path: Installed via marketplace                             │
└──────────────────────────────────────────────────────────────┘
```

### What Goes Where

| Resource | Enterprise ★★★ | Personal ★★☆ | Project ★☆☆ |
|----------|---------------|--------------|-------------|
| Domain expertise (BDM, REST API) | ✅ | — | copy from toolkit |
| Coding standards | ✅ | — | copy from toolkit |
| Format/style hooks | ✅ | — | — |
| Pre-commit compilation | ✅ | — | — |
| Productivity commands (/compile, /test) | — | ✅ | — |
| Personal preferences | — | ✅ | — |
| Project-specific commands (Bonita) | — | — | ✅ |
| Project-specific hooks (BDM checks) | — | — | ✅ |
| Custom agents (code-reviewer) | — | — | ✅ |
| MCP skill (jira-workflow) | ✅ | — | copy from toolkit |
| Settings templates | — | — | ✅ |

---

## Decision Flowchart

```
                       START
                         │
                         ▼
              ┌─────────────────────┐
              │ Does it need to run │───── YES ──→ HOOK
              │ WITHOUT user action │              (PreToolUse/PostToolUse/Stop)
              │ (on events)?        │
              └─────────────────────┘
                         │ NO
                         ▼
              ┌─────────────────────┐
              │ Is it a full task   │───── YES ──→ AGENT
              │ that should run     │              (.claude/agents/name.md)
              │ in isolation?       │
              └─────────────────────┘
                         │ NO
                         ▼
              ┌─────────────────────┐
              │ Should Claude       │───── YES ──→ SKILL
              │ figure out WHEN     │              (.claude/skills/name/SKILL.md)
              │ to use it?          │
              └─────────────────────┘
                         │ NO
                         ▼
              ┌─────────────────────┐
              │ Is it a shortcut    │───── YES ──→ COMMAND
              │ the user types /?   │              (.claude/commands/name.md)
              └─────────────────────┘
                         │ NO
                         ▼
              ┌─────────────────────┐
              │ Does it apply to    │───── YES ──→ CLAUDE.md
              │ ALL conversations?  │
              └─────────────────────┘
                         │ NO
                         ▼
              ┌─────────────────────┐
              │ Is it an external   │───── YES ──→ MCP SERVER
              │ tool connection?    │              + SKILL for conventions
              └─────────────────────┘
```

---

## Agents Deep Dive

### What Are Agents (Subagents)?

Agents are **isolated Claude instances** that receive a task, work independently, and return results. They are defined as Markdown files in `.claude/agents/`.

### Key Facts About Agents

1. **Subagents do NOT see your skills automatically** — you must list them explicitly in the `skills:` field
2. **Built-in agents** (Explorer, Plan, Verify) **cannot access skills at all**
3. Skills listed in an agent's frontmatter are loaded at startup (not on demand)
4. Each agent gets its own context window — isolated from your main conversation
5. Agents can have different `tools` and `model` than your main session

### Agent Frontmatter

```yaml
---
name: my-agent-name
description: "When to delegate to this agent"
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
color: blue
skills: skill-one, skill-two
---

## Instructions
What this agent should do when invoked.
```

### Agent vs Hook Agent vs Auto-Test Agent

| Type | Defined in | Trigger | Has skills? | Interactive? |
|------|-----------|---------|-------------|-------------|
| Custom Agent | `.claude/agents/` | User delegates | Yes (explicit list) | Returns results |
| Hook Agent | `settings.json` (Stop) | Claude finishes | No | Runs automatically |
| Hook Command | `settings.json` (Pre/Post) | Tool events | No | Pass/fail only |

### When to Create an Agent

- **Code Review Agent**: Load `coding-standards` + `rest-api-expert` skills. Delegate "review this PR" for autonomous, thorough review.
- **Test Generator Agent**: Load `testing-expert` + `integration-testing-expert`. Delegate "generate tests for module X" for batch test creation.
- **Audit Agent**: Load `audit-expert` + `coding-standards`. Delegate "audit the project" for comprehensive report.
- **Documentation Agent**: Load `rest-api-expert` + `document-expert`. Delegate "document all controllers" for batch documentation.

---

## Plugins Deep Dive

### What Are Plugins?

Plugins are **packaged Claude Code extensions** distributed through marketplaces (npm, GitHub). They can contain skills, commands, and configurations.

### When to Use Plugins

| Consideration | Skill in toolkit | Plugin |
|--------------|-----------------|--------|
| Team-specific knowledge (Bonita BDM) | ✅ Better | ❌ Not appropriate |
| Generic Java testing patterns | ✅ OK | ✅ Better (wider audience) |
| Cross-company utility (prompt log) | ✅ OK | ✅ Better (community benefit) |
| Meta-skills (skill-creator) | ✅ OK | ✅ Better (useful everywhere) |

### Plugin Priority

Plugins have **Priority 4** (lowest). This means:
- Enterprise skills override plugins with the same name
- Personal skills override plugins
- Project skills override plugins
- Plugins never conflict with higher scopes

### Plugin Naming

Plugins use namespaced names: `plugin-name:skill-name`. This prevents any naming conflicts.

---

## MCP + Skills Pattern

### The Pattern

```
MCP Server (provides tools) + Skill (teaches conventions) = Effective AI assistant
```

### Example: Jira

| Without skill | With skill |
|---------------|-----------|
| Claude creates issues with generic descriptions | Claude follows your issue template |
| Claude assigns random priority | Claude uses your priority rules |
| Claude doesn't add labels | Claude adds required labels per component |

### How to Implement

1. **Set up MCP server** (e.g., Jira MCP server in Claude Code settings)
2. **Create a skill** that teaches conventions for using that tool
3. **In the skill's `allowed-tools`**, include the MCP tool patterns (e.g., `mcp__jira__*`)
4. **Install at Enterprise scope** so all team members follow the same conventions

---

## References

- [Introduction to Agent Skills — Anthropic Skilljar Course](https://skilljar.anthropic.com)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Agent Skills Open Standard — agentskills.io](https://agentskills.io)
- [Claude Code Toolkit — Bonitasoft](https://github.com/bonitasoft-ps/claude-code-toolkit)
