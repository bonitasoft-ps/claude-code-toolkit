# JS Object Patterns and i18n

## JS Object Structure (actionCollectionList)

Every JS Object in UIB follows this JSON structure:

```json
{
  "unpublishedCollection": {
    "name": "MyUtils",
    "pageId": "Page1",
    "pluginId": "js-plugin",
    "pluginType": "JS",
    "actions": [],
    "body": "export default {\n  myFunction() {\n    return 'hello';\n  }\n}",
    "variables": [],
    "userPermissions": []
  },
  "publishedCollection": {
    "name": "MyUtils",
    "pageId": "Page1",
    "pluginId": "js-plugin",
    "pluginType": "JS",
    "actions": [],
    "body": "export default {\n  myFunction() {\n    return 'hello';\n  }\n}",
    "variables": [],
    "userPermissions": []
  },
  "gitSyncId": "unique_js_id",
  "id": "Page1_MyUtils",
  "deleted": false
}
```

### Key Properties

| Property | Value | Notes |
|----------|-------|-------|
| `name` | JS Object name | e.g., `MyUtils`, `JSInit`, `KpiUtils` |
| `pageId` | Page identifier | e.g., `Page1` |
| `pluginId` | `"js-plugin"` | Always this value for JS Objects |
| `pluginType` | `"JS"` | Always this value for JS Objects |
| `gitSyncId` | Unique ID | Must be unique per object across the application |
| `id` | `PageId_ObjectName` | Format: `Page1_MyUtils` |

### Both Collections Required

Both `unpublishedCollection` and `publishedCollection` must be present with identical structure. The `unpublishedCollection` is the working copy; `publishedCollection` is the deployed copy.

## async/await Patterns

### Correct Pattern

```javascript
export default {
  async saveCustomerData() {
    try {
      await updateCustomer.run({ data: CustomerForm.formData });
      await getLoanDetails.run();
      showAlert('Customer data updated successfully!', 'success');
    } catch (error) {
      showAlert('An error occurred. Please try again.', 'error');
      console.error('API Error saving customer:', error);
    }
  }
}
```

### Anti-Pattern: Missing async/await

```javascript
// WRONG: Does not wait for API response before continuing
export default {
  saveCustomerData() {
    updateCustomer.run({ data: CustomerForm.formData }); // Non-blocking!
    getLoanDetails.run(); // May run before update finishes!
  }
}
```

> **JSInit pattern:** See `header-pattern.md` for the full JSInit implementation (read already-loaded data, never call `.run()` on APIs already in `layoutOnLoadActions`).

### Parallel API Calls

When multiple independent APIs need to run, use `Promise.all`:

```javascript
export default {
  async refreshAllData() {
    try {
      await Promise.all([
        getDashboardKpis.run(),
        getUserRanking.run(),
        getFormKpis.run()
      ]);
      showAlert('Data refreshed!', 'success');
    } catch (error) {
      showAlert('Error refreshing data.', 'error');
      console.error('Refresh error:', error);
    }
  }
}
```

## Store Values (appsmith.store)

### Common Store Keys

| Store Key | Description | Set By |
|-----------|-------------|--------|
| `appsmith.store.user` | Current user with menu | JSInit via userQuery |
| `appsmith.store.logo` | Logo URL or base64 | JSInit via logoUrlQuery |
| `appsmith.store.theme` | Theme colors | JSTheme |
| `appsmith.store.language` | i18n language setting | JSi18n |

### Writing to Store

```javascript
await storeValue('user', userData);
await storeValue('logo', logoUrl);
await storeValue('language', 'en');
await storeValue('selectedItem', row);
```

### Reading from Store in Widgets

```javascript
"{{appsmith.store.user?.user_name}}"
"{{appsmith.store.logo}}"
"{{appsmith.store.language}}"
```

### Reading from Store in JS Objects

```javascript
const user = appsmith.store.user;
const lang = appsmith.store.language;
```

## Internationalization

> See `i18n-patterns.md` for the complete JSI18n implementation (translations, locale detection, widget usage, key conventions).

## KpiUtils Formatting Utilities

### Full Implementation

```javascript
export default {
  // Format milliseconds to human-readable format
  formatTime(ms) {
    if (ms === null || ms === undefined) return '-';
    if (ms === 0) return '0 ms';

    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return days + 'd ' + (hours % 24) + 'h';
    if (hours > 0) return hours + 'h ' + (minutes % 60) + 'm';
    if (minutes > 0) return minutes + 'm ' + (seconds % 60) + 's';
    if (seconds > 0) return seconds + 's';
    return ms + ' ms';
  },

  // Format percentage with one decimal
  formatPercent(value) {
    if (value === null || value === undefined) return '-';
    return value.toFixed(1) + '%';
  },

  // Format large numbers with locale separators
  formatNumber(num) {
    if (num === null || num === undefined) return '-';
    return num.toLocaleString();
  }
}
```

### Usage Examples

```javascript
"{{KpiUtils.formatTime(api.data?.elapsedTime)}}"       // "2h 15m"
"{{KpiUtils.formatPercent(api.data?.completionRate)}}"  // "95.5%"
"{{KpiUtils.formatNumber(api.data?.totalCount)}}"       // "1,234,567"
```

### In Table Computed Values

```json
{
  "primaryColumns": {
    "avgElapsedTime": {
      "id": "avgElapsedTime",
      "label": "Avg Time",
      "computedValue": "{{KpiUtils.formatTime(currentRow.avgElapsedTime)}}"
    }
  }
}
```

## JSAssets -- Default Application Assets

Store static assets (logos, icons) as base64 in a JS Object:

```javascript
export default {
  // Default logo as base64 SVG
  logo: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD...',

  // Default favicon
  icon: 'data:image/png;base64,iVBORw0KGgo...'
}
```

### Usage in Widgets

```javascript
// Use store value with fallback to JSAssets
"{{appsmith.store.logo || JSAssets.logo}}"
```

### In JSInit

```javascript
async init() {
  if (logoUrlQuery.data?.[0]?.configValue) {
    await storeValue('logo', logoUrlQuery.data[0].configValue);
  } else {
    await storeValue('logo', JSAssets.logo);
  }
}
```

## General JS Best Practices

1. **Use Lodash** for complex array/object manipulation -- improves performance and readability
2. **Named functions** as top-level properties in JS Objects (not arrow functions)
3. **Arrow functions** are fine inside a regular named function
4. **Single Responsibility Principle**: Each function does one thing
5. **No hardcoded indexes** (`[0]`, `[1]`) -- use unique identifiers
6. **Dual-purpose catch blocks**: `showAlert()` for UX + `console.error()` for support
