---
name: prompt-engineering-log
description: |
  Activate when generating significant AI content (Confluence pages, specifications,
  catalogs, reports, documentation). Ask the user if they want to save a prompt
  engineering log for audit trail and reproducibility.
allowed-tools: Read, Write, Edit, Glob, Grep
user-invocable: true
---

# Prompt Engineering Log

Create audit trail documentation for AI-generated content.

## Scope

**Personal** (recommended for any developer using AI-assisted content generation).

## When to Activate

Offer (not auto-create) a prompt engineering log after completing:

1. **Page creation** — Documentation published to Confluence, GitHub wiki, or similar
2. **Specification generation** — Technical specs, design docs, API documentation
3. **Catalog or knowledge base updates** — Significant additions to knowledge bases
4. **Report generation** — Audit reports, analysis documents, PDFs

## Trigger Behavior

After completing a significant generation task, ask:

> "Would you like me to create a **Prompt Engineering Log** to document how this was produced?"
>
> 1. **Yes, save locally** — Markdown file alongside the content
> 2. **Yes, publish** — As child page or sibling of generated content
> 3. **No, skip**

## Log Template

```markdown
# Prompt Engineering Log — [Content Title]

**Version:** 1.0
**Date:** YYYY-MM-DD
**Author:** [User] + Claude (AI-assisted)
**Project:** [Project name]

---

## Session Overview

What was produced and why.

## Prompts (Actual User Messages)

### Prompt 1: [Phase Name] (date/context)

> [Exact user message — if in another language, provide English translation]

### Prompt 2: ...

## Execution Strategy

- Agents launched (parallel research, etc.)
- Files/repos analysed
- Tools used (MCP, skills, commands, APIs)

## Key Findings

| Finding | Impact |
|---------|--------|

## Design Decisions

| Decision | Rationale |
|----------|-----------|

## Quality Assessment

- Coverage: what was included vs missed
- Consistency with existing docs
- Known limitations

## Sources Analysed

- List all repos, files, pages consulted

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
```

## Local Storage

- **Path:** Same directory as generated content
- **Filename:** `PROMPT-LOG-[content-name].md`

## Important Rules

- **Never auto-create** — always ask first
- **Include actual prompts** — user's exact words
- **Be honest** about what Claude did vs what the user did
- **Include gaps** — document what wasn't covered
- **Reference sibling sessions** if content relates to other generation sessions
