---
name: bonita-uibuilder-page-designer
description: "Design Bonita UIBuilder pages and forms with widgets, JS objects, queries, and navigation."
user_invocable: true
trigger_keywords: ["uibuilder page", "appsmith page", "uib page", "uib form", "page design", "widget layout"]
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Bonita UIBuilder Page Designer

You are an expert in Bonita UIBuilder (Appsmith-based) page design.

## UIBuilder Application Structure (Appsmith DSL)

### Application JSON
```json
{
  "artifactJsonType": "APPLICATION",
  "exportedApplication": {
    "name": "AppName",
    "pages": [
      {"id": "Home", "isDefault": true},
      {"id": "Dashboard", "isDefault": false},
      {"id": "Form", "isDefault": false}
    ],
    "navigationSetting": {
      "showNavbar": false,
      "orientation": "side",
      "navStyle": "sidebar"
    }
  },
  "pageList": [...]
}
```

### Page Structure
Each page contains:
- **Widgets** — UI components (Table, Form, Button, Text, Modal, etc.)
- **JS Objects** — Business logic collections (data manipulation, API calls)
- **Queries/APIs** — REST API calls to Bonita backend
- **Variables** — Page-level state management

## Naming Conventions (CRITICAL)

| Element | Convention | Example |
|---------|-----------|---------|
| Widgets | PascalCase, functional names | `HeaderContainer`, `SubmitButton`, `EntityTable` |
| APIs/Queries | verbObject | `getEntities`, `updateEntity`, `deleteEntity` |
| JS Functions | verbActionObject | `openDetailModal`, `validateForm`, `formatDate` |
| Variables | camelCase | `selectedEntity`, `isLoading`, `filterStatus` |

NEVER use generic names like Canvas8, Button3, Table1. Always use functional names.

## Page Types

### List Page Pattern
```
+--[Header: Title + Create Button]--+
|                                    |
|  [Filters: Status, Date, Search]  |
|                                    |
|  [Data Table with pagination]      |
|    - Click row → Detail page       |
|    - Actions column (Edit/Delete)  |
|                                    |
+--[Footer: Total count]------------+
```
- API: GET with p, c, filters → paginated list
- countFor query for total
- Table with server-side pagination

### Detail/Form Page Pattern
```
+--[Header: Entity #{id} + Status]--+
|                                     |
|  [Tab 1: Main Info]                |
|    Form fields bound to entity      |
|                                     |
|  [Tab 2: Related Items]            |
|    Linked entity table              |
|                                     |
|  [Tab 3: History/Comments]         |
|    Timeline or comment thread       |
|                                     |
+--[Actions: Save, Cancel, Delete]---+
```

### Dashboard Page Pattern
```
+--[KPI StatBoxes Row]---------------+
|  [Count1] [Count2] [Count3] [Avg] |
|                                     |
|  [Chart: Timeline/Bar/Pie]         |
|                                     |
|  [Recent Activity Table]           |
+------------------------------------+
```

## Separation of Concerns (MANDATORY)

### Widget Layer (Presentation only)
- Display data from JS Objects
- Capture user interactions
- Trigger JS Object functions on events

### JS Object Layer (Logic)
- All data manipulation
- API call orchestration
- Form validation
- Navigation logic
- Error handling

### API/Query Layer (Data)
- REST API calls to Bonita extensions
- BDM queries via /API/bdm/businessData/
- Process API calls (/API/bpm/process, /API/bpm/humanTask)

## REST API Integration Pattern

### Calling Bonita REST API Extensions
```javascript
// In a Query/API configuration:
// URL: /bonita/API/extension/{apiName}/{path}
// Method: GET
// Params: p={{currentPage}}, c={{pageSize}}, filter={{filterValue}}

// In JS Object:
export default {
  async fetchEntities() {
    const response = await getEntities.run({
      p: this.currentPage,
      c: this.pageSize
    });
    return response;
  }
}
```

### Calling Bonita Process API
```javascript
// Start a process instance
// POST /bonita/API/bpm/process/{processId}/instantiation
// Body: contract inputs as JSON

// Execute a task
// POST /bonita/API/bpm/userTask/{taskId}/execution
// Body: contract inputs as JSON
```

## Performance Best Practices
- DISABLE large data fetches on ON_PAGE_LOAD
- Load heavy data (documents, base64) only on user interaction
- Use server-side pagination (p, c parameters)
- Minimize widget count per page
- Cache reference data in appsmith.store

## Custom Widgets
Custom widgets extend UIBuilder with Angular/TypeScript:
```
web_widgets/customWidgetName/
  customWidgetName.json     # Widget definition + template + controller
  assets/
    css/                    # Widget styles
    js/                     # Widget scripts
```

## Web Fragments (Reusable Components)
```
web_fragments/fragmentName/
  fragmentName.json         # Fragment layout (same format as page rows)
  assets/
    css/
    json/
```
Fragments are embedded in pages via the `pbFragment` widget.

## Form Design for Process Tasks

### Instantiation Form (Process Start)
- Bound to process contract inputs
- Submit → POST /API/bpm/process/{id}/instantiation
- Validate all required contract inputs before submit

### Task Form
- Bound to task contract inputs + business data context
- Pre-populate from BDM via REST API
- Submit → POST /API/bpm/userTask/{id}/execution

### Case Overview (Read-only)
- Display case data from BDM
- Show process timeline
- No submit action

## Navigation Patterns
- URL parameters for entity IDs: `/app/{token}/entity?id={persistenceId}`
- appsmith.URL.queryParams for reading params
- navigateTo() for programmatic navigation
- Breadcrumb via appsmith.store

## MCP Tools
- `generate_uibuilder_page` — Generate UIBuilder page DSL
- `generate_uibuilder_form` — Generate task/instantiation form
- `generate_uibuilder_widget` — Generate custom widget
- `validate_uibuilder_page` — Validate page structure
