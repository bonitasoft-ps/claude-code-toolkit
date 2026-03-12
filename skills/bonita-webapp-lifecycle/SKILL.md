---
name: bonita-webapp-lifecycle
description: |
  Complete lifecycle for React/Angular web applications: spec → document → publish/save →
  validate → implement → test (unit/mutation/E2E) → build → deploy → update docs → deliver.
  For standalone web apps or Bonita Living Applications with React/Tailwind.
  Trigger: "create web app", "react app", "angular app", "living app react", "webapp lifecycle"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, mcp__claude_ai_Atlassian_2__createConfluencePage, mcp__claude_ai_Atlassian_2__updateConfluencePage, mcp__Bonita-AI-Agent__build_pdf, mcp__Bonita-AI-Agent__generate_ui_form, mcp__Bonita-AI-Agent__generate_dashboard, mcp__Bonita-AI-Agent__generate_living_app
user_invocable: true
---

# Bonita Web Application Lifecycle — Documentation-First

## Lifecycle
```
SPEC → DOCUMENT → CHOOSE DESTINATION → VALIDATE ✓ → IMPLEMENT → TEST → BUILD → DEPLOY → UPDATE DOC → DELIVER
```

## Phase 1: SPEC
Ask the user:
- App name and purpose
- Framework: React (default) or Angular
- Pages/routes and their purpose
- Components per page
- Bonita API integration: which endpoints
- State management approach
- Authentication: Bonita session
- Theme: Bonita branding (primary #2c3e7a, accent #e97826)

## Phase 2-4: DOCUMENT → PUBLISH → VALIDATE

## Phase 5: IMPLEMENT
Use MCP tools:
- `generate_ui_form` — React form for Bonita tasks
- `generate_dashboard` — dashboard with KPIs
- `generate_living_app` — Living Application descriptor

### React + Tailwind Stack
```
webapp/
├── package.json
├── src/
│   ├── App.tsx
│   ├── components/     # Reusable components
│   ├── pages/          # Route pages
│   ├── hooks/          # Custom hooks (useBonita, useTask, etc.)
│   ├── services/       # Bonita API client
│   └── styles/         # Tailwind config + Bonita theme
├── public/
└── tests/
```

### Bonita API Integration
```typescript
// CSRF token handling (required for POST/PUT/DELETE)
const csrfToken = await fetch('/bonita/API/session/unusedId', {
  method: 'GET', credentials: 'include'
}).then(r => r.headers.get('X-Bonita-API-Token'));
```

## Phase 6: TEST
- **Unit**: Jest/Vitest for components and hooks
- **Mutation**: Stryker for business logic
- **E2E**: Playwright against running Bonita

## Phase 7: BUILD
```bash
npm run build
```
For Living App: package as ZIP with page.properties + dist/

## Phase 8: DEPLOY
- Living App: upload via Bonita Portal
- Standalone: deploy to CDN/web server

## Phase 9-10: UPDATE DOC → DELIVER
