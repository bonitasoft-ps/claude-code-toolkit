---
name: bonita-uibuilder-lifecycle
description: |
  Complete lifecycle for UI Builder (Appsmith-based) applications: spec → document → publish/save →
  validate → implement → test E2E → export → deploy → update docs → deliver.
  Covers pages, forms, widgets, datasources, custom Angular/TS widgets.
  Trigger: "uibuilder lifecycle", "create uibuilder app", "appsmith page", "ui builder lifecycle"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, mcp__claude_ai_Atlassian_2__createConfluencePage, mcp__claude_ai_Atlassian_2__updateConfluencePage, mcp__Bonita-AI-Agent__build_pdf, mcp__Bonita-AI-Agent__generate_uibuilder_page, mcp__Bonita-AI-Agent__generate_uibuilder_form, mcp__Bonita-AI-Agent__validate_uibuilder_page, mcp__Bonita-AI-Agent__generate_uibuilder_widget
user_invocable: true
---

# Bonita UI Builder Lifecycle — Documentation-First

## Lifecycle
```
SPEC → DOCUMENT → CHOOSE DESTINATION → VALIDATE ✓ → IMPLEMENT → TEST (E2E) → EXPORT → DEPLOY → UPDATE DOC → DELIVER
```

## Phase 1: SPEC
Ask the user:
- Application name and purpose
- Page types needed: Form (instantiation/task), Case Overview, Task List, Dashboard
- For each page: widgets, data sources, layout
- Custom widgets needed (Angular/TypeScript)
- Navigation structure
- Bonita version
- Theme/branding requirements

## Phase 2-4: DOCUMENT → PUBLISH → VALIDATE
Generate UI spec with page wireframes (text), widget list, datasources. Publish to chosen destination.

## Phase 5: IMPLEMENT
Use MCP tools:
- `generate_uibuilder_page` — page JSON DSL
- `generate_uibuilder_form` — form with contract bindings
- `generate_uibuilder_widget` — custom Angular widget
- `validate_uibuilder_page` — verify JSON structure

### Page Structure (JSON DSL)
- Root: CANVAS_WIDGET (24-column grid)
- Widgets: INPUT, SELECT, TABLE, BUTTON, CONTAINER, CHART, etc.
- Variable binding: `{{variableName.property}}`
- Datasources: Bonita REST API endpoints

### Custom Widget (Angular/TS)
```typescript
@Component({
  selector: 'custom-widget',
  template: `<div>{{data}}</div>`
})
export class CustomWidget {
  @Input() data: any;
  @Output() action = new EventEmitter();
}
```

## Phase 6: TEST
- Playwright E2E: navigate pages, fill forms, submit, verify
- Visual regression testing
- See `bonita-e2e-testing` skill

## Phase 7: EXPORT
Export pages as JSON from UIBuilder.

## Phase 8: DEPLOY
Import JSON into Bonita UIBuilder instance.

## Phase 9-10: UPDATE DOC → DELIVER
