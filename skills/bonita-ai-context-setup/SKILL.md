---
name: bonita-ai-context-setup
description: "Set up AI context files (context-ia/) for Bonita projects to enable AI agent assistance."
user_invocable: true
trigger_keywords: ["context-ia", "ai context", "agents.md", "claude.md", "ai setup", "ai rules"]
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Bonita AI Context Setup

You are an expert in configuring Bonita projects for AI agent assistance.

## Why AI Context Files?
AI agents (Claude, Copilot, Gemini, Cursor) need project-specific context to generate correct code. Without it, they produce generic code that violates project conventions.

## Required Files

### AGENTS.md (Root -- Entry Point)
The master index file that AI agents read first:
1. Points to all context files in order
2. Mandatory compilation check command
3. REST API controller documentation requirements
4. Known issues and workarounds

### CLAUDE.md (Root -- Claude Code specific)
Points to AGENTS.md as the primary context. Keeps Claude Code aligned.

### context-ia/ Directory Structure
```
context-ia/
  00-overview.mdc          # Project scope, team, components
  01-architecture.mdc      # Tech stack, communication flow
  02-datamodel.mdc         # BDM naming, queries, indexes, countFor
  03-integrations.mdc      # REST API standards, testing, clean code
  04-uib.mdc               # UIBuilder/frontend standards
  99-coding_standards.mdc  # Delivery checklist
  reports/                 # Audit report templates
    00-audit_response_template.mdc
    AUDIT.md
    PROMPT-BASIC.md
    PROMPT-FULL.md
```

## File Templates

### 00-overview.mdc
- Project name and purpose
- Team roles and expertise
- Core components (app/, bdm/, extensions/, uib/)
- Quality and convention references
- Official Bonita documentation links

### 02-datamodel.mdc (CRITICAL)
- BDM naming conventions with prefixes
- Description tag obligation
- Data integrity rules (nullable, unique constraints)
- Query and performance rules
- countFor obligation (99% rule)
- Index rules (mandatory for WHERE/ORDER BY fields)
- Security requirements

### 03-integrations.mdc (CRITICAL)
- Java 17 features mandate
- Code coverage requirement (MAXIMUM)
- Documentation requirement (ALL public methods)
- Static analysis (Checkstyle + PMD)
- REST API extension structure
- Controller creation guide with checklist
- Testing requirements (JUnit 5 + Mockito + AssertJ)
- Method naming: should_do_X_when_condition_Y

### 04-uib.mdc
- Widget naming conventions (PascalCase)
- API naming conventions (verbObject)
- Performance rules (disable ON_PAGE_LOAD for heavy data)
- Architecture (Separation of Concerns: Widget -> JS Object -> API)
- Security considerations

## Auto-Load Pattern
AGENTS.md must instruct AI agents to read ALL context files before any task:
```
CRITICAL INSTRUCTION: Before processing ANY request,
read ALL context-ia/ files in order (00 through 99).
```

## MCP Tools
- `generate_project_scaffold` -- Creates project with context-ia/ files
- `validate_project_consistency` -- Checks context files exist
