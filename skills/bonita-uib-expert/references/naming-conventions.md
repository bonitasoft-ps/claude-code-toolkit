# Naming Conventions

## Widget Naming

| Element | Convention | Example | Best Practice |
|---------|-----------|---------|---------------|
| **Main Widgets** | PascalCase | `HeaderContainer`, `CustomerDetailsModal` | **CRITICAL:** Replace generic names |
| **APIs/Queries** | verbObject | `getLoanRequests`, `updateCustomer` | Clear action-object names |
| **JS Functions** | verbActionObject | `openCustomerModel`, `validateDocuments` | Single Responsibility Principle |

## CRITICAL: Replace Generic Names

Generic auto-generated names are **never acceptable** in production code:

| Generic (WRONG) | Descriptive (CORRECT) |
|-----------------|----------------------|
| `Canvas8` | `Home_HeaderContainer` |
| `Button3` | `SubmitLoanButton` |
| `Text1` | `WelcomeText` |
| `Container2` | `KpiStatsContainer` |
| `Table1` | `UserRankingTable` |
| `Input1` | `SearchInput` |
| `Select1` | `ProcessFilterSelect` |
| `Image1` | `Logo` |
| `Chart1` | `TaskDistributionChart` |

### Naming Pattern

Widget names should communicate:
1. **What** the widget displays or does
2. **Where** it appears (optional prefix for context)

Examples:
- `StatTotalProcesses` -- A stat box showing total processes
- `UserRankingTable` -- A table showing user rankings
- `TaskDistributionChart` -- A chart showing task distribution
- `Home_HeaderContainer` -- The header container on the Home page
- `SubmitLoanButton` -- A button that submits a loan

## Pages and Files

### Page Names
- PascalCase: `KpiDashboard`, `ProcessAnalysis`, `UserRanking`
- Descriptive and concise
- Match the folder name exactly

### File Structure

```
app/
  applications/
    app{ApplicationName}.xml       # Application descriptor
  web_page/
    {PageName}/
      {PageName}.json              # Page definition (name MUST match folder)
      assets/
        css/style.css              # Page-specific styles
        json/localization.json     # Localization strings
```

### Naming Rules

| Item | Convention | Example |
|------|-----------|---------|
| Application XML | `app{Name}.xml` | `appKpiDashboard.xml` |
| Page folder | PascalCase | `KpiDashboard/` |
| Page JSON | Matches folder | `KpiDashboard.json` |
| customPage reference | `custompage_` + folder | `custompage_KpiDashboard` |
| Application token | kebab-case | `kpi-dashboard` |
| Page token | kebab-case | `user-ranking` |

## API / Query Names

Follow `verbObject` pattern:

| Pattern | Example | Description |
|---------|---------|-------------|
| `get{Object}` | `getDashboardKpis` | Fetch data |
| `get{Object}` | `getUserRanking` | Fetch list data |
| `update{Object}` | `updateCustomer` | Modify existing data |
| `create{Object}` | `createLoanRequest` | Create new record |
| `delete{Object}` | `deleteDocument` | Remove record |
| `{verb}{Object}Query` | `userQuery` | Query-style name (also acceptable) |
| `{object}UrlQuery` | `logoUrlQuery` | URL-specific query |

### API Action ID Format

```
PageId_actionName
```

Examples:
- `Page1_getDashboardKpis`
- `Page1_userQuery`
- `Page1_updateCustomer`

## JS Object Names

| Pattern | Example | Purpose |
|---------|---------|---------|
| `JSInit` | `JSInit` | Page initialization logic |
| `JSAssets` | `JSAssets` | Static assets (logos, icons) |
| `JSi18n` | `JSi18n` | Internationalization |
| `KpiUtils` | `KpiUtils` | KPI formatting utilities |
| `{Feature}Utils` | `CustomerUtils` | Feature-specific utilities |
| `{Feature}Handler` | `FormHandler` | Event handling logic |

### JS Function Names

Follow `verbActionObject` pattern:

| Pattern | Example | Description |
|---------|---------|-------------|
| `init` | `init()` | Initialize page/component |
| `open{Object}` | `openCustomerModel()` | Open a modal/dialog |
| `validate{Object}` | `validateDocuments()` | Validate data |
| `format{Type}` | `formatTime()` | Format display values |
| `get{Data}Data` | `getTaskDistributionData()` | Prepare chart data |
| `handle{Event}` | `handleRowClick()` | Handle user interaction |
| `refresh{Data}` | `refreshAllData()` | Reload data from APIs |
| `set{Value}` | `setLang()` | Set a configuration value |

### JS Object ID Format

```
PageId_ObjectName
```

Examples:
- `Page1_JSInit`
- `Page1_KpiUtils`
- `Page1_JSi18n`

### JS Function ID in layoutOnLoadActions

```
PageId_ObjectName.functionName
```

Examples:
- `Page1_JSInit.init`
- `Page1_JSi18n.init`

## Store Key Names

| Key | Convention | Example |
|-----|-----------|---------|
| User data | `user` | `appsmith.store.user` |
| Logo | `logo` | `appsmith.store.logo` |
| Theme | `theme` | `appsmith.store.theme` |
| Language | `language` | `appsmith.store.language` |
| Selected item | `selectedItem` | `appsmith.store.selectedItem` |
| Feature-specific | camelCase | `appsmith.store.selectedProcessId` |

## gitSyncId Values

Every entity in the UIB JSON must have a unique `gitSyncId`. Use descriptive, unique identifiers:

```json
"gitSyncId": "datasource_bonita_api_kpidashboard"
"gitSyncId": "action_getDashboardKpis_page1"
"gitSyncId": "js_JSInit_page1"
"gitSyncId": "js_KpiUtils_page1"
```

Never reuse `gitSyncId` values across entities. Duplicate IDs cause import conflicts.
