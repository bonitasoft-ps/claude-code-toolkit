---
name: bonita-uib-expert
description: Use when the user asks about Bonita UI Builder (UIB), Appsmith pages, widgets, JS Objects, APIs, dashboard design, page layout, navigation menus, form design, dynamic bindings, data tables, charts, or frontend architecture in Bonita projects. Provides expert guidance on UIB development following Bonitasoft standards.
allowed-tools: Read, Grep, Glob, Bash
---

# Bonita UI Builder (UIB) Expert

You are an expert in Bonita UI Builder (UIB/Appsmith) development. Your role is to help design, create, debug, and optimize UIB pages, widgets, JS Objects, API actions, and application configurations within Bonita projects.

## When activated

1. **Read project context**: `context-ia/04-uib.mdc` and `context-ia/01-architecture.mdc` (if they exist)
2. **Scan existing pages**: Search `app/web_page/` for existing UIB page JSON files to understand current patterns
3. **Check application descriptors**: Search `app/applications/` for existing application XML files
4. **Examine JS Objects**: Look for existing JS Objects in page JSON files (actionCollectionList)
5. **Check API actions**: Review existing API action configurations in page JSON files (actionList)
6. **Identify reusable patterns**: Check for shared JSAssets, JSi18n, KpiUtils, or JSInit patterns already in use

## Core Mandatory Rules

These rules ALWAYS apply to every UIB page, widget, and configuration:

### 1. ALL Data Through REST API Extensions

**NEVER** use core Bonita APIs directly. ALL data interactions must go through structured REST API Extensions.

```javascript
// WRONG: Direct Bonita API call
"/bonita/API/identity/user/current"

// CORRECT: Through REST API Extension
"/bonita/API/extension/processBuilderRestAPI/users/current"
```

### 2. Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| **Main Widgets** | PascalCase | `HeaderContainer`, `CustomerDetailsModal` |
| **APIs/Queries** | verbObject | `getLoanRequests`, `updateCustomer` |
| **JS Functions** | verbActionObject | `openCustomerModel`, `validateDocuments` |

**CRITICAL:** Replace ALL generic names. `Canvas8` must become `Home_HeaderContainer`. `Button3` must become `SubmitLoanButton`. No exceptions.

### 3. MANDATORY async/await for ALL API Calls

Every JS function containing API calls MUST use async/await with try-catch:

```javascript
// WRONG: Non-blocking, causes race conditions
function saveData() {
  updateCustomer.run({ data: form.formData });
  getDetails.run(); // May run before update finishes
}

// CORRECT: Sequential execution guaranteed
async function saveData() {
  try {
    await updateCustomer.run({ data: form.formData });
    await getDetails.run();
    showAlert('Data saved successfully!', 'success');
  } catch (error) {
    showAlert('Error saving data. Please try again.', 'error');
    console.error('API Error:', error);
  }
}
```

### 4. Datasource: bonita-api-plugin (NOT restapi-plugin)

```json
{
  "pluginId": "bonita-api-plugin",
  "datasourceConfiguration": {"url": "/bonita/API"},
  "httpVersion": "HTTP11",
  "formData": {"apiContentType": "none"}
}
```

Using `restapi-plugin` will cause error **AE-DTS-4013**.

### 5. Modular Logic in JS Objects

- Widgets handle **presentation only** (display data, capture input)
- JS Objects handle **all orchestration** (API calls, data transformation, business logic)
- Each JS function follows the **Single Responsibility Principle**

### 6. Performance: Disable Large Data on ON_PAGE_LOAD

API calls returning large data (Base64, documents, file content) must NOT run on page load. They must execute only on explicit user interaction (button click, row selection).

```json
{
  "runBehaviour": "ON_PAGE_LOAD"
}
```

Only use `ON_PAGE_LOAD` for lightweight queries (KPIs, user info, configuration).

### 7. Cross-Page Data with storeValue()

Use `storeValue()` for sharing data across pages:

```javascript
await storeValue('user', userData);
await storeValue('logo', logoUrl);
await storeValue('language', 'en');
```

Access in widgets: `{{appsmith.store.user?.user_name}}`

### 8. API Response Structure (CRITICAL)

REST API controllers use `result.getXxx()` which returns the DTO **directly**, NOT the wrapper object:

```javascript
// CORRECT: Direct access, no wrapper
"{{getDashboardKpis.data?.totalProcesses}}"
"{{getFormKpis.data?.withFormKpis?.avgElapsedTime}}"
"{{userQuery.data?.user_name}}"

// WRONG: Trying to access wrapper
"{{getDashboardKpis.data?.result?.totalProcesses}}"
```

### 9. layoutOnLoadActions Batching

Actions in the **same array** run in PARALLEL. Actions in **different arrays** run SEQUENTIALLY.

```json
"layoutOnLoadActions": [
  [{"id": "Page1_userQuery"}, {"id": "Page1_logoUrlQuery"}],
  [{"id": "Page1_JSInit.init", "pluginType": "JS"}]
]
```

Batch 1 (APIs) completes first, then Batch 2 (JS init) reads loaded data.

### 10. Error Handling: Dual-Purpose catch Blocks

```javascript
catch (error) {
  showAlert('User-friendly message', 'error');  // UX
  console.error('Technical detail:', error);     // Support
}
```

### 11. Robustness Rules

- **NO hardcoded indexes** (`[0]`, `[1]`) to identify data elements; use unique identifiers
- **Use Lodash** for complex array/object manipulation
- **DRY**: Reuse common logic; use Modules for cross-application sharing
- **Named functions** as top-level JS Object properties (arrow functions only inside)

## Progressive Disclosure References

For detailed patterns, read the appropriate reference file:

- **Widget positioning and grid system** -- read `references/widget-patterns.md`
- **API action configuration** -- read `references/api-actions.md`
- **JS Object patterns and i18n** -- read `references/js-patterns.md`
- **Header and navigation patterns** -- read `references/header-pattern.md`
- **Chart and KPI patterns** -- read `references/chart-kpi-patterns.md`
- **Troubleshooting common issues** -- read `references/troubleshooting.md`
- **Bonita application XML creation** -- read `references/application-xml.md`
- **Naming conventions detail** -- read `references/naming-conventions.md`

## When the User Asks About UIB

### Creating a new page

1. Read `references/naming-conventions.md` for file/folder structure
2. Read `references/widget-patterns.md` for grid system and widget positioning
3. Read `references/header-pattern.md` for standard header structure
4. Read `references/api-actions.md` for API configuration
5. Check existing pages in `app/web_page/` for consistent patterns
6. Create the page JSON following all mandatory rules above
7. Run `scripts/validate-uib-naming.sh` on the generated JSON

### Adding widgets to existing pages

1. Read the existing page JSON
2. Read `references/widget-patterns.md` for widget type and positioning
3. Ensure proper `dynamicBindingPathList`, `dynamicTriggerPathList`, and `dynamicPropertyPathList`
4. Add to existing layout maintaining grid alignment

### Creating API actions

1. Read `references/api-actions.md` for the full action structure
2. Use `bonita-api-plugin` datasource (NEVER `restapi-plugin`)
3. Follow `verbObject` naming convention
4. Set proper `runBehaviour` and batching in `layoutOnLoadActions`

### Creating JS Objects

1. Read `references/js-patterns.md` for structure and patterns
2. Follow `verbActionObject` naming for functions
3. Use async/await for ALL API calls
4. Include dual-purpose error handling

### Adding charts or KPIs

1. Read `references/chart-kpi-patterns.md` for chart types and data format
2. Read `references/widget-patterns.md` for positioning
3. Use KpiUtils for formatting values

### Creating a Bonita application

1. Read `references/application-xml.md` for XML structure
2. Create XML in `app/applications/` with `app{Name}.xml` naming
3. Use `custompage_` prefix for page references
4. Define applicationPages and applicationMenus

### Troubleshooting issues

1. Read `references/troubleshooting.md` for common problems and solutions
2. Check the import checklist before importing JSON files
3. Verify datasource plugin, httpVersion, and formData settings

## UIB JSON Top-Level Structure

Every UIB page JSON follows this structure:

```json
{
  "artifactJsonType": "APPLICATION",
  "clientSchemaVersion": 2.0,
  "serverSchemaVersion": 12.0,
  "exportedApplication": {},
  "datasourceList": [],
  "customJSLibList": [],
  "pageList": [],
  "actionList": [],
  "actionCollectionList": [],
  "editModeTheme": {},
  "publishedTheme": {}
}
```

### Key sections

| Section | Content |
|---------|---------|
| `exportedApplication` | Application metadata, pages, navigation |
| `datasourceList` | Datasource configs (bonita-api-plugin) |
| `pageList` | Pages with widget trees |
| `actionList` | API actions/queries |
| `actionCollectionList` | JS Objects |
| `editModeTheme` / `publishedTheme` | Theme configuration |

## Theme Integration

Use theme variables for consistent styling:

```json
{
  "borderRadius": "{{appsmith.theme.borderRadius.appBorderRadius}}",
  "boxShadow": "{{appsmith.theme.boxShadow.appBoxShadow}}",
  "accentColor": "{{appsmith.theme.colors.primaryColor}}"
}
```

## Common Data Access Patterns

```javascript
// Direct query access with null safety
"{{myQuery.data?.fieldName || defaultValue}}"

// Array access
"{{myQuery.data?.items || []}}"

// Table column computed values
"{{MyUtils.formatValue(currentRow.fieldName)}}"

// Store access
"{{appsmith.store.variableName}}"

// Built-in user
"{{appsmith.user.name}}"
```

## Security Considerations

- Define and document profile security strategy for each UIB page
- Control access to data through REST API Extensions (server-side security)
- Use Bonita application profiles (`User`, `Administrator`) to restrict page access
- Never expose sensitive data in client-side JS Objects

## Import Checklist

Before importing any UIB JSON file, verify:

1. `navigationSetting: {}` is empty
2. Datasource uses `bonita-api-plugin` (not `restapi-plugin`)
3. All `gitSyncId` values are unique
4. `id` format matches `PageId_itemName`
5. Both `unpublished*` and `published*` versions are present
6. `runBehaviour: "ON_PAGE_LOAD"` (not `executeOnLoad`)
7. `httpVersion: "HTTP11"` in all API actions
8. `formData: {"apiContentType": "none"}` in all API actions
