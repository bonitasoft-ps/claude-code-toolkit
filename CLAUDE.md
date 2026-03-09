# claude-code-toolkit

Shared Claude Code methodology toolkit for the Bonitasoft PS ecosystem. Provides skills, hooks, commands, configs, and agents reusable across all PS projects.

## Before Making Changes

- Read `README.md` for full documentation
- Read `CONTRIBUTING.md` for quality standards
- When adding/removing resources, update README.md counts

## Structure

- `skills/` — 22 reusable skills (Bonita experts, coding standards, etc.)
- `hooks/scripts/` — 16 hooks (code quality, docs consistency, RAG reminder, etc.)
- `commands/` — 19 commands (java-maven, quality, testing, bonita)
- `agents/` — 5 agent definitions
- `configs/` — Shared configs (checkstyle, PMD, editorconfig)
- `templates/` — Project templates (CLAUDE.md, settings.json)

## Key Rules

- All skills must have YAML frontmatter (name, description, instructions)
- All skills should have a `references/` directory for progressive disclosure
- Hooks must be POSIX-compatible (no grep -P, use PYTHON_CMD fallback pattern)
- Update README counts when adding or removing any resource

## Ecosystem

This toolkit is used by 7 PS repos:
- bonita-upgrade-toolkit, bonita-audit-toolkit, bonita-connectors-generator-toolkit
- template-test-toolkit, bonita-docs-toolkit, bonita-ps-mcp, claude-code-toolkit

All exposed via bonita-ps-mcp (64 MCP tools).
