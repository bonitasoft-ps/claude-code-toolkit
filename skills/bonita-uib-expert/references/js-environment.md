# JavaScript Environment and State Variables

> Bonita Version: 2024.3+

## JSObject File Structure (CRITICAL)

**Location:** `pages/[PageName]/jsobjects/[JSObjectName]/[JSObjectName].js`

A JSObject file **MUST start with `export default`** — no comments, no blank lines before it:

```javascript
export default {
  myFunction: function() {
    return "hello";
  },
  anotherFunction: function() {
    return this.myFunction();
  }
}
```

**NEVER use arrow functions `() =>` in JSObjects** — they break `this` context:

```javascript
// ✅ CORRECT
myFunction: function() {
  return this.otherFunction();
}

// ❌ WRONG — this will be undefined
myFunction: () => {
  return this.otherFunction();  // TypeError
}
```

## JavaScript Syntax Restrictions (CRITICAL)

Bonita UIB JSObjects run in a **sandboxed environment** with ES5-like constraints. Avoid modern JS features:

| Forbidden | Use Instead |
|-----------|-------------|
| Arrow functions `() =>` | `function() {}` |
| `let` / `const` | `var` |
| Spread operator `{...obj}` | Manual object copy loop |
| Template literals `` `${var}` `` | String concatenation `'text ' + var` |
| Optional chaining `obj?.prop` | `obj && obj.prop` |
| Nullish coalescing `val ?? def` | `val !== null && val !== undefined ? val : def` |
| Destructuring `{a, b} = obj` | `var a = obj.a; var b = obj.b;` |

### Manual Object Copy (Instead of Spread)

```javascript
updateField: function(field, value) {
  var current = this.formData;
  var updated = {};
  var keys = Object.keys(current);
  for (var i = 0; i < keys.length; i++) {
    updated[keys[i]] = current[keys[i]];
  }
  updated[field] = value;
  this.formData.value = updated;
}
```

## Browser Globals NOT Available (CRITICAL)

| NOT Available | Alternative |
|--------------|-------------|
| `window` | Not applicable |
| `document` | Not applicable |
| `Intl` | Manual formatting (see below) |
| `setTimeout` / `setInterval` | Not available |
| `fetch` | Use Bonita queries instead |
| `localStorage` / `sessionStorage` | Use `storeValue()` / `appsmith.store` |
| `require` / `import` | Use `jslibs/` for external libraries |

## State Variables — metadata.json (CRITICAL)

**Location:** `pages/[PageName]/jsobjects/[JSObjectName]/metadata.json`

Every JSObject must have a `metadata.json` declaring state variables:

```json
{
  "body": "export default {}",
  "contextType": "PAGE",
  "variables": [
    { "name": "data", "value": { "data": [] } },
    { "name": "selectedItem", "value": { "data": null } },
    { "name": "isLoading", "value": { "data": false } },
    { "name": "currentPage", "value": { "data": 1 } },
    { "name": "formData", "value": { "data": {} } },
    { "name": "errors", "value": { "data": {} } }
  ]
}
```

### Value Format Rules (CRITICAL)

Values are **always wrapped in `{ "data": ... }`**:

| Type | Format |
|------|--------|
| String | `{ "data": "" }` |
| Number | `{ "data": 0 }` |
| Boolean | `{ "data": false }` |
| Null | `{ "data": null }` |
| Array | `{ "data": [] }` |
| Object | `{ "data": {} }` |

### Reading vs Writing State Variables

```javascript
export default {
  fetchData: function() {
    // READ — no .value
    var page = this.currentPage;

    // WRITE — use .value setter
    this.isLoading.value = true;
    this.data.value = [1, 2, 3];
    this.selectedItem.value = null;
  }
}
```

**READ** with `this.varName`, **WRITE** with `this.varName.value = ...`

## Variable Scoping Pattern

Always use `var self = this` and wrap API calls in try/catch:

```javascript
fetchData: function() {
  var self = this;
  self.isLoading.value = true;
  try {
    var result = getMyData.run();
    self.data.value = result;
  } catch(e) {
    self.data.value = [];
    showAlert('Error: ' + e.message, 'error');
  } finally {
    self.isLoading.value = false;
  }
}
```

## Date Formatting Without Intl

```javascript
formatDate: function(dateStr) {
  if (!dateStr) return '';
  var d = new Date(dateStr);
  var day = d.getDate().toString();
  if (day.length < 2) day = '0' + day;
  var month = (d.getMonth() + 1).toString();
  if (month.length < 2) month = '0' + month;
  var year = d.getFullYear();
  return day + '/' + month + '/' + year;
}
```

## Number / Currency Formatting Without Intl

```javascript
formatCurrency: function(amount) {
  if (amount === null || amount === undefined) return '';
  var num = Number(amount);
  var fixed = num.toFixed(2);
  var parts = fixed.split('.');
  var intPart = parts[0];
  var decPart = parts[1];
  var formatted = '';
  var count = 0;
  for (var i = intPart.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 === 0) formatted = ' ' + formatted;
    formatted = intPart[i] + formatted;
    count++;
  }
  return formatted + ',' + decPart + ' €';
}
```

## Built-in Appsmith Functions

Available globally in JSObjects:

### Navigation

```javascript
navigateTo('PageName', { paramKey: 'value' }, 'SAME_WINDOW');
// Targets: 'SAME_WINDOW', 'NEW_WINDOW'
```

### Alerts

```javascript
showAlert('Success message', 'success');
showAlert('Error message', 'error');
showAlert('Warning message', 'warning');
showAlert('Info message', 'info');
```

### Modal Control

```javascript
showModal('My_Modal');
closeModal('My_Modal');
```

### Data Store (Persistent)

```javascript
storeValue('key', value);           // Store
var val = appsmith.store.key;       // Read
removeValue('key');                 // Remove
```

### URL Parameters

```javascript
var taskId = appsmith.URL.queryParams.id;
```

### Copy to Clipboard

```javascript
copyToClipboard('text to copy');
```

### Run Queries

```javascript
var result = queryName.run();
var result = queryName.run({ param1: 'value1' });

// Sequential
var first = query1.run();
var second = query2.run({ id: first.id });
```

Parameters passed to `.run()` are available in query metadata as `{{this.params.paramName}}`.

## Auto-generated JSObject Method Queries

When a JSObject method calls a query, UIB auto-generates a query folder:

```
queries/
├── JSHomeList-fetchData/
│   └── metadata.json        # Auto-generated
└── getMyTasks/
    └── metadata.json        # Manual API query
```

Do NOT manually create `JS[Object]-[method]` query folders — UIB manages them.

## Anti-patterns

- Starting JSObject file with comments or blank lines before `export default`
- Using arrow functions `() =>` (breaks `this` context)
- Using `let` or `const` instead of `var`
- Using spread, template literals, optional chaining, destructuring
- Using `window`, `document`, `Intl`, `fetch` or other browser globals
- Forgetting `{ "data": ... }` wrapper in metadata.json variable values
- Writing state variables without `.value`: `this.data = x` instead of `this.data.value = x`
- Using `setTimeout`/`setInterval` (not available in sandbox)
- Manually creating `JS[Object]-[method]` query directories
- Calling `this.method()` inside arrow functions
