---
name: confluence-publish-workflow
description: |
  Orchestrates documentation generation and publishing workflow. Core of the Documentation-First
  lifecycle: generate spec → choose destination (Confluence, local, PDF, other) → publish/save →
  validate → proceed with implementation → update with results.
  Templates for: library specs, connector specs, process specs, API specs, audit plans, upgrade plans,
  UI specs, test plans. Manages multiple output destinations and status tracking.
  Trigger: "publish to confluence", "create confluence page", "document first", "publish spec",
  "save document", "generate spec", "document workflow"
allowed-tools: Read, Grep, Glob, Edit, Write, mcp__claude_ai_Atlassian_2__createConfluencePage, mcp__claude_ai_Atlassian_2__updateConfluencePage, mcp__claude_ai_Atlassian_2__searchConfluenceUsingCql, mcp__claude_ai_Atlassian_2__getConfluencePage, mcp__claude_ai_Atlassian_2__getConfluenceSpaces, mcp__claude_ai_Atlassian_2__getPagesInConfluenceSpace, mcp__Bonita-AI-Agent__build_pdf
user_invocable: true
---

# Documentation-First Publish Workflow

This skill orchestrates the documentation phase of ALL lifecycle skills. Every artifact
(library, connector, process, REST API, UI, audit, upgrade) starts with documentation
that must be validated before implementation begins.

## Core Principle

```
SPEC → DOCUMENT → CHOOSE DESTINATION → PUBLISH/SAVE → VALIDATE ✓ → IMPLEMENT → UPDATE DOC
```

## Phase 1: Generate Document

Select template based on artifact type:

| Artifact Type | Template | Page Title Format |
|---------------|----------|-------------------|
| Java Library | library-spec | `[LIB] {Name} — Technical Specification` |
| Project Extension | extension-spec | `[EXT] {Name} — Technical Specification` |
| Connector | connector-spec | `[CON] {Name} — Connector Specification` |
| Actor Filter | filter-spec | `[FLT] {Name} — Actor Filter Specification` |
| Event Handler | handler-spec | `[EVH] {Name} — Event Handler Specification` |
| REST API Extension | api-spec | `[API] {Name} — REST API Specification` |
| BPMN Process | process-spec | `[PROC] {Name} — Process Specification` |
| BDM | bdm-spec | `[BDM] {Name} — Data Model Specification` |
| UI Builder Page | uibuilder-spec | `[UIB] {Name} — UI Builder Specification` |
| Web Application | webapp-spec | `[APP] {Name} — Application Specification` |
| Audit | audit-plan | `[AUDIT] {Client} — Audit Plan` |
| Upgrade | upgrade-plan | `[UPG] {Client} {Source}→{Target} — Upgrade Plan` |
| Test Plan | test-plan | `[TEST] {Name} — Test Plan` |

Generate the document using the appropriate template from `references/confluence-templates.md`.

## Phase 2: Choose Destination

**ALWAYS ask the user where they want the document:**

> "He generado la especificación técnica. ¿Dónde quieres guardarla?"
> 1. **Confluence** — Publicar como página (borrador)
> 2. **Local** — Guardar como Markdown en el proyecto
> 3. **PDF** — Generar PDF corporativo directamente
> 4. **Otro destino** — Indicar dónde (Jira, SharePoint, email, etc.)
> 5. **Solo revisión** — Mostrar aquí para validar verbalmente

### Option 1: Confluence
1. Ask for target space (or search with `getConfluenceSpaces`)
2. Ask for parent page (or search with `searchConfluenceUsingCql`)
3. Create page with `createConfluencePage`
4. Add labels: `{artifact-type}`, `bonita`, `status:draft`, custom labels
5. Share Confluence URL with user

### Option 2: Local
1. Ask for output path (default: `docs/specs/` in current project)
2. Save as Markdown file
3. Also generate HTML version if requested

### Option 3: PDF
1. Use `build_pdf` MCP tool
2. Apply Bonitasoft corporate branding
3. Save to user-specified location

### Option 4: Other Destination
1. Generate document in Markdown format
2. If Jira: create issue with description using Atlassian MCP
3. If email: prepare content for sending
4. If other: save locally and provide instructions

### Option 5: Review Only
1. Display document content in conversation
2. Ask for feedback/changes
3. After approval, ask again for destination

## Phase 3: Validation Gate

**CRITICAL — Do NOT proceed to implementation without explicit validation**

After publishing/saving the document:
1. Present the document location to the user
2. Ask explicitly: "¿Está validada la especificación? ¿Puedo proceder con la implementación?"
3. If changes requested → update document → update destination → ask again
4. ONLY continue when user explicitly says yes/approved/validated/OK

## Phase 4: Update After Implementation

Once implementation is complete, update the document with actual results:

### Content to Add
- Implementation details (actual classes, packages, files created)
- Test results (test count, coverage %, mutation score)
- Build artifacts (JAR path, .bar location, bundle)
- Deployment info (server, version, date)
- Known issues or limitations
- Next steps

### Update by Destination
- **Confluence**: Use `updateConfluencePage`, change label `status:draft` → `status:implemented`
- **Local**: Edit the Markdown file, add "Implementation Results" section
- **PDF**: Regenerate PDF with updated content
- **Other**: Re-export with updated content

## Document Status Lifecycle

```
DRAFT → UNDER_REVIEW → APPROVED → IMPLEMENTED → DELIVERED
  │         │              │           │            │
  │         │              │           │            └── PDF sent, project closed
  │         │              │           └── Code done, tests passing
  │         │              └── Stakeholder approved, proceed to implement
  │         └── Shared with stakeholders for review
  └── Initial document generated
```

### Status Labels (Confluence)
- `status:draft` — Just created
- `status:under-review` — Shared for review
- `status:approved` — Validated, ready for implementation
- `status:implemented` — Code complete, tests passing
- `status:delivered` — PDF generated, project delivered

## Standard Labels by Artifact Type

| Type | Labels |
|------|--------|
| Library | `library`, `java`, `spec`, `bonita-{version}` |
| Connector | `connector`, `java`, `spec`, `{protocol}` |
| REST API | `rest-api`, `api`, `spec`, `openapi` |
| Process | `process`, `bpmn`, `spec` |
| BDM | `bdm`, `data-model`, `spec` |
| UI | `ui`, `react` or `uibuilder`, `spec` |
| Audit | `audit`, `{client}`, `quality` |
| Upgrade | `upgrade`, `{source-version}`, `{target-version}` |

## Page Naming Conventions

- Always use prefix in brackets: `[LIB]`, `[CON]`, `[API]`, `[PROC]`, etc.
- Include artifact name after prefix
- Add description suffix: "Technical Specification", "Audit Plan", etc.
- For client work: include client name (anonymized if needed)

## Confluence Space Discovery

When user hasn't specified a space:
1. Use `getConfluenceSpaces` to list available spaces
2. Present top 5 most likely spaces
3. Let user choose or specify another

## Integration with Lifecycle Skills

Every lifecycle skill (library, connector, process, etc.) calls this workflow at Phase 2-3:
1. Lifecycle skill gathers requirements (Phase 1: SPEC)
2. Lifecycle skill calls this workflow to generate + publish document
3. This workflow handles destination choice + validation gate
4. Control returns to lifecycle skill for implementation

## Quick Reference

| Action | Tool | When |
|--------|------|------|
| Create Confluence page | `createConfluencePage` | Phase 2, Option 1 |
| Update Confluence page | `updateConfluencePage` | Phase 4 |
| Search existing pages | `searchConfluenceUsingCql` | Before creating (avoid duplicates) |
| Get page content | `getConfluencePage` | When updating |
| List spaces | `getConfluenceSpaces` | Space discovery |
| Generate PDF | `build_pdf` | Option 3 or Phase 4 delivery |
| Save local | Write tool | Option 2 |
