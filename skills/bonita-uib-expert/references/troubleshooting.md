# Troubleshooting Common UIB Issues

## Stat Boxes Show Empty

### Symptoms
- STATBOX_WIDGET renders but shows no value
- Value appears as blank or undefined

### Checklist

1. **Check API response structure** -- The data may not be wrapped as expected.
   - REST API controllers use `result.getXxx()` which returns the DTO **directly**
   - Use `api.data?.fieldName` not `api.data?.wrapper?.fieldName`
   - Test the API endpoint directly to see the actual response shape

2. **Verify `dynamicBindingPathList`** includes the value binding:
   ```json
   "dynamicBindingPathList": [
     {"key": "value"}
   ]
   ```
   If `"value"` is not listed here, the `{{}}` expression will be treated as a literal string.

3. **Confirm API is in `layoutOnLoadActions`**:
   ```json
   "layoutOnLoadActions": [
     [{"id": "Page1_getDashboardKpis"}]
   ]
   ```
   If the API is not listed, it will not run on page load, and the widget will have no data.

4. **Check for null data** -- Use null-safe access:
   ```javascript
   "{{getDashboardKpis.data?.totalProcesses || 0}}"
   ```

### Fallback: Container-Based Stat Box

If STATBOX_WIDGET consistently fails to render, use CONTAINER_WIDGET + TEXT_WIDGET. See `references/widget-patterns.md` for the Custom Stat Boxes pattern.

## Tables Show No Data

### Symptoms
- TABLE_WIDGET_V2 renders but shows "No data" or empty rows

### Checklist

1. **Check `tableData` binding path**:
   ```json
   "tableData": "{{getUserRanking.data?.users || []}}"
   ```
   Verify the property chain matches the actual API response structure.

2. **Verify array access** -- The data may be nested:
   ```javascript
   // If API returns { users: [...] }
   "{{getUserRanking.data?.users || []}}"

   // If API returns { items: [...] }
   "{{getItems.data?.items || []}}"

   // If API returns array directly
   "{{getItems.data || []}}"
   ```

3. **Confirm column IDs match data field names**:
   ```json
   "primaryColumns": {
     "displayName": {
       "id": "displayName",  // Must match the field name in data objects
       "label": "User"
     }
   }
   ```
   If `id` does not match the JSON field name, the column will be empty.

4. **Verify `tableData` is in `dynamicBindingPathList`**:
   ```json
   "dynamicBindingPathList": [
     {"key": "tableData"}
   ]
   ```

5. **Check API is loading** -- Verify the API is in `layoutOnLoadActions` or is triggered by user action.

## Header Not Displaying

### Symptoms
- Header area is blank or missing
- Logo or welcome text not visible

### Checklist

1. **Ensure `topRow: 0`** and proper dimensions:
   ```json
   {
     "topRow": 0.0,
     "bottomRow": 10.0,
     "leftColumn": 0.0,
     "rightColumn": 64.0
   }
   ```

2. **Check `backgroundColor` is set**:
   ```json
   "backgroundColor": "#2b4570"
   ```
   Without an explicit background color, the container may be transparent.

3. **Verify child CANVAS_WIDGET structure** -- Every CONTAINER_WIDGET must have a CANVAS_WIDGET child:
   ```json
   {
     "type": "CONTAINER_WIDGET",
     "children": [{
       "type": "CANVAS_WIDGET",
       "children": [
         // Actual content widgets go here
       ]
     }]
   }
   ```
   Missing the CANVAS_WIDGET layer will prevent children from rendering.

4. **Check `dynamicHeight: "FIXED"`** -- Without this, the container may collapse:
   ```json
   "dynamicHeight": "FIXED",
   "minHeight": 100.0
   ```

5. **Verify logo `image` binding**:
   ```json
   "image": "{{appsmith.store.logo}}",
   "dynamicBindingPathList": [{"key": "image"}]
   ```

## APIs Return Error AE-DTS-4013

### Symptoms
- API calls fail with error code AE-DTS-4013
- Network tab shows failed requests

### Checklist

1. **Use `bonita-api-plugin`** (NOT `restapi-plugin`):
   ```json
   "pluginId": "bonita-api-plugin"
   ```
   This must be set in BOTH the datasource AND the action.

2. **Verify `httpVersion: "HTTP11"`**:
   ```json
   "httpVersion": "HTTP11"
   ```

3. **Check `formData`**:
   ```json
   "formData": {"apiContentType": "none"}
   ```

4. **Verify datasource URL**:
   ```json
   "datasourceConfiguration": {"url": "/bonita/API"}
   ```

5. **Check the action path** starts with `/extension/`:
   ```json
   "path": "/extension/processBuilderRestAPI/dashboard/kpis"
   ```

## Race Conditions: Data Not Available

### Symptoms
- "Welcome User" instead of actual user name
- Menu items empty
- Logo not showing

### Root Cause
JSInit runs in parallel with APIs instead of sequentially.

### Fix
Ensure proper batching in `layoutOnLoadActions`:

```json
"layoutOnLoadActions": [
  [
    {"id": "Page1_userQuery"},
    {"id": "Page1_logoUrlQuery"}
  ],
  [
    {"id": "Page1_JSInit.init", "pluginType": "JS", "collectionId": "Page1_JSInit"}
  ]
]
```

APIs in batch 1 (first array), JSInit in batch 2 (second array).

### Verify JSInit Does NOT Call .run()

```javascript
// WRONG: Redundant .run() call
async init() {
  await userQuery.run();  // Already loaded in batch 1!
}

// CORRECT: Just read the data
async init() {
  if (userQuery.data?.user_name) {
    await storeValue('user', userQuery.data);
  }
}
```

## Widget Not Visible

### Symptoms
- Widget exists in JSON but does not appear on page

### Checklist

1. **Check `isVisible: true`**
2. **Verify positioning** -- Widget may be outside visible area
3. **Check parent container** -- Widget must be inside the correct CANVAS_WIDGET
4. **Verify `parentId`** -- Must reference the correct parent widget ID

## Dynamic Binding Not Working

### Symptoms
- `{{}}` expression shows as literal text instead of evaluated value

### Checklist

1. **Add property to `dynamicBindingPathList`**:
   ```json
   "dynamicBindingPathList": [
     {"key": "text"},
     {"key": "value"},
     {"key": "tableData"}
   ]
   ```

2. **Check mustache syntax** -- Must use double curly braces:
   ```javascript
   // Correct
   "{{myQuery.data?.field}}"

   // Wrong
   "{myQuery.data?.field}"
   ```

3. **For trigger bindings** (onClick, onChange), use `dynamicTriggerPathList` instead:
   ```json
   "dynamicTriggerPathList": [
     {"key": "onClick"}
   ]
   ```

## Import Checklist

Before importing a UIB JSON file, verify ALL of the following:

| Check | Expected Value | Common Mistake |
|-------|---------------|----------------|
| `navigationSetting` | `{}` (empty object) | Populated settings cause import issues |
| Datasource `pluginId` | `"bonita-api-plugin"` | Using `"restapi-plugin"` |
| `gitSyncId` values | All unique | Duplicate IDs cause conflicts |
| Action `id` format | `PageId_actionName` | Missing page prefix |
| Unpublished + Published | Both present | Missing `publishedAction` or `publishedCollection` |
| `runBehaviour` | `"ON_PAGE_LOAD"` | Using `executeOnLoad: true` |
| `httpVersion` | `"HTTP11"` | Missing or wrong version |
| `formData` | `{"apiContentType": "none"}` | Missing formData |

## Debugging Tips

### Check API Response in Browser

1. Open browser developer tools (F12)
2. Go to Network tab
3. Trigger the page load
4. Find the API request
5. Check the Response tab for actual data structure

### Console Logging in JS Objects

```javascript
export default {
  async debugInit() {
    console.log('userQuery.data:', JSON.stringify(userQuery.data));
    console.log('logoUrlQuery.data:', JSON.stringify(logoUrlQuery.data));
    console.log('appsmith.store:', JSON.stringify(appsmith.store));
  }
}
```

### Verify Widget Bindings

In the UIB editor, click on a widget and check:
- The property panel shows the binding expression
- The evaluated value shows the actual data
- No red error indicators on binding fields
