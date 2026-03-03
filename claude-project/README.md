# Bonita PS Claude Code Toolkit — claude.ai Project Knowledge

## Project Name (copy this)

```
Bonita PS Claude Code Methodology
```

## Project Description (copy this)

```
AI assistant that helps Bonitasoft Professional Services teams apply development
methodology best practices. Provides 22 expert skills covering Bonita BDM, REST APIs,
UI Builder, connectors, testing, audits, deployment, performance, debugging, and
estimation. Includes 15 automatic quality hooks, 19 developer commands, and 5 agent
definitions for code review, test generation, audits, and documentation. Use this
assistant to get expert guidance on Bonita project development, quality enforcement,
and PS engagement delivery.
```

## What is this?

This folder contains everything you need to create a **Claude AI Project** on [claude.ai](https://claude.ai) that acts as a **Bonita PS Methodology Expert**.

Once set up, you can ask the assistant for expert guidance on any Bonita development topic, and it will follow Bonitasoft PS conventions for code quality, testing, deployment, and delivery.

## What's inside (6 files)

| File | Purpose |
|------|---------|
| `INSTRUCTIONS.md` | System prompt — paste into Custom Instructions |
| `CHANGELOG.md` | Version history |
| `knowledge/skills-catalog.md` | 22 skills with descriptions and invocation contexts |
| `knowledge/hooks-reference.md` | 15 hooks with triggers and actions |
| `knowledge/commands-reference.md` | 19 commands with usage examples |

## How to create the Claude Project

1. Go to **https://claude.ai**
2. Click **Projects** in the left sidebar
3. Click **Create Project**
4. **Name:** `Bonita PS Claude Code Methodology`
5. **Custom Instructions:** Open `INSTRUCTIONS.md`, copy ALL its content, and paste it into the Custom Instructions field
6. **Knowledge:** Click "Add knowledge" and upload the 3 files from the `knowledge/` folder:
   - `skills-catalog.md`
   - `hooks-reference.md`
   - `commands-reference.md`
7. Click **Create** — you're ready to go

## How to use it

Start a conversation and try one of these:

**Get expert guidance on a topic:**
```
"How should I design the BDM for a loan application process?"
"What's the best pattern for a Bonita REST API extension?"
"Review this Groovy script for quality issues"
```

**Ask about methodology:**
```
"Which skill should I use for testing REST API controllers?"
"What hooks should I install for a new Bonita project?"
"How do I estimate a connector development engagement?"
```

**Ask about commands:**
```
"How do I check for existing BDM queries before creating new ones?"
"What command generates integration tests for a controller?"
```

## Version Tracking

Current version: **v1.0.0** (2026-03-03)

When updating an existing Claude.ai project:
1. Check the version in your Claude.ai Custom Instructions (visible at the top: `v1.0.0`)
2. Compare with the version in this folder's `INSTRUCTIONS.md`
3. If different, check `CHANGELOG.md` for what changed
4. Upload only the changed files + update Custom Instructions text

## Keeping it updated

These files are a snapshot from the `claude-code-toolkit` Git repository. When skills, hooks, or commands are added or updated in the repo, re-upload the changed `.md` files to keep this project current.

---

*Bonitasoft Professional Services*
