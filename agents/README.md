# Agents (Subagents)

Custom Claude Code agents for delegating complete tasks to isolated contexts.

## What Are Agents?

Agents are **isolated Claude instances** that receive a task, work independently, and return results. Unlike skills (which inject knowledge into your conversation), agents get their own context window.

**Key fact:** Agents do NOT see your skills automatically — skills must be listed explicitly in the agent's `skills:` frontmatter field.

## Available Agents

| Agent | Skills Loaded | Best For | Scope |
|-------|--------------|----------|-------|
| `bonita-code-reviewer` | coding-standards, rest-api-expert, testing-expert | PR reviews, module reviews | ★☆☆ Project |
| `bonita-test-generator` | testing-expert, integration-testing-expert | Batch test creation | ★☆☆ Project |
| `bonita-auditor` | audit-expert, coding-standards, bdm-expert, rest-api-expert, testing-expert | Full project audits | ★☆☆ Project |
| `bonita-documentation-generator` | rest-api-expert, document-expert | Batch documentation | ★☆☆ Project |

## Installation

Copy agent files to your project:

```bash
cp /path/to/toolkit/agents/*.md your-project/.claude/agents/
```

## Usage

In Claude Code, delegate to an agent:

```
You: delegate to bonita-code-reviewer: review the changes in this PR
You: delegate to bonita-test-generator: create tests for the payment module
You: delegate to bonita-auditor: run a full audit of this project
You: delegate to bonita-documentation-generator: document all REST controllers
```

## Agent vs Skill vs Hook Agent

| Feature | Custom Agent | Skill | Hook Agent (Stop) |
|---------|-------------|-------|-------------------|
| Invocation | User delegates | Auto (context match) | Auto (Claude finishes) |
| Context | Isolated | Shared with conversation | Isolated |
| Skills access | Yes (explicit list) | N/A | No |
| Best for | Complex delegated tasks | Interactive guidance | Post-task validation |
