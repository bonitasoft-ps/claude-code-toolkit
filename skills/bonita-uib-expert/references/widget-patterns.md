# Widget Patterns and Grid System

## Common Widget Types

| Type | Widget | Use Case |
|------|--------|----------|
| `TEXT_WIDGET` | Text display | Titles, labels, dynamic text |
| `TABLE_WIDGET_V2` | Data table | Lists, rankings, paginated data |
| `BUTTON_WIDGET` | Button | Actions, form submissions |
| `INPUT_WIDGET_V2` | Text input | Forms, search fields |
| `SELECT_WIDGET` | Dropdown | Selection from options |
| `CHART_WIDGET` | Charts | Visualizations (pie, bar, line) |
| `CONTAINER_WIDGET` | Container | Layout grouping, sections |
| `STATBOX_WIDGET` | Stat box with icon | KPI metrics display |
| `MENU_BUTTON_WIDGET` | Menu button | Navigation, dropdown actions |
| `IMAGE_WIDGET` | Image display | Logos, icons, photos |
| `CANVAS_WIDGET` | Canvas (internal) | Required child of CONTAINER_WIDGET |

## 64-Column Grid System

UIB uses a **64-column** grid. Widgets are positioned using four properties:

| Property | Description |
|----------|-------------|
| `topRow` | Starting row (0-based, top of page) |
| `bottomRow` | Ending row (determines height) |
| `leftColumn` | Starting column (0-63) |
| `rightColumn` | Ending column (determines width) |

**Row Height:** Each row is approximately **10 pixels**. A widget with `topRow=5, bottomRow=12` is 7 rows tall (~70px).

### Positioning JSON Example

```json
{
  "topRow": 5.0,
  "bottomRow": 12.0,
  "leftColumn": 1.0,
  "rightColumn": 13.0,
  "mobileTopRow": 5.0,
  "mobileBottomRow": 12.0,
  "mobileLeftColumn": 1.0,
  "mobileRightColumn": 13.0
}
```

### Mobile Variants

Every widget should include mobile positioning properties:
- `mobileTopRow`, `mobileBottomRow`, `mobileLeftColumn`, `mobileRightColumn`
- These control the layout on mobile/small screens
- Typically mirror the desktop values unless responsive adjustments are needed

## Grid Layout Examples

### 4 Equal Columns (full width)

```
Column 1: leftColumn=1,  rightColumn=16   (width: 15)
Column 2: leftColumn=16, rightColumn=32   (width: 16)
Column 3: leftColumn=32, rightColumn=48   (width: 16)
Column 4: leftColumn=48, rightColumn=63   (width: 15)
```

### 5 Equal Columns (full width)

```
Column 1: leftColumn=1,  rightColumn=13   (width: 12)
Column 2: leftColumn=13, rightColumn=26   (width: 13)
Column 3: leftColumn=26, rightColumn=39   (width: 13)
Column 4: leftColumn=39, rightColumn=52   (width: 13)
Column 5: leftColumn=52, rightColumn=63   (width: 11)
```

### 2 Equal Columns (half-half)

```
Left half:  leftColumn=1,  rightColumn=32  (width: 31)
Right half: leftColumn=32, rightColumn=63  (width: 31)
```

### Header (full width)

```
Full width: leftColumn=0, rightColumn=64, topRow=0, bottomRow=10
```

### Header with Logo and Welcome (Process-Builder pattern)

```
Logo area:    leftColumn=0,  rightColumn=19  (width: 19)
Welcome area: leftColumn=19, rightColumn=64  (width: 45)
```

## Dynamic Bindings

### dynamicBindingPathList

Properties that reference **reactive data** (queries, store, other widgets). UIB watches these for changes and re-renders.

```json
"dynamicBindingPathList": [
  {"key": "tableData"},
  {"key": "value"},
  {"key": "borderRadius"},
  {"key": "boxShadow"},
  {"key": "text"}
]
```

**Every property using `{{}}` mustache syntax MUST be listed here**, or it will be treated as a static string.

### dynamicTriggerPathList

Properties that **execute actions** (onClick, onRowClick, onChange, onSubmit):

```json
"dynamicTriggerPathList": [
  {"key": "onClick"},
  {"key": "onRowSelected"},
  {"key": "onChange"}
]
```

### dynamicPropertyPathList

Properties whose **type depends on other widget values** for computed display:

```json
"dynamicPropertyPathList": [
  {"key": "isVisible"}
]
```

### Mustache Syntax `{{}}`

All dynamic values in widget properties use mustache syntax:

```javascript
// Query data with null safety
"{{myQuery.data?.fieldName || defaultValue}}"

// Store access
"{{appsmith.store.logo}}"

// Theme variables
"{{appsmith.theme.borderRadius.appBorderRadius}}"

// JS Object function call
"{{KpiUtils.formatTime(currentRow.avgElapsedTime)}}"

// Conditional rendering
"{{myQuery.data?.count > 0}}"
```

## Complete Widget Examples

### TEXT_WIDGET (Title)

```json
{
  "type": "TEXT_WIDGET",
  "widgetName": "SectionTitle",
  "widgetId": "section_title_id",
  "text": "User Productivity Ranking",
  "fontSize": "1.25rem",
  "fontStyle": "BOLD",
  "textAlign": "LEFT",
  "textColor": "#2B4570",
  "overflow": "NONE",
  "shouldTruncate": false,
  "topRow": 22.0,
  "bottomRow": 24.0,
  "leftColumn": 1.0,
  "rightColumn": 32.0,
  "isVisible": true,
  "animateLoading": true,
  "version": 1.0,
  "renderMode": "CANVAS",
  "dynamicBindingPathList": [],
  "dynamicTriggerPathList": [],
  "dynamicPropertyPathList": []
}
```

### TABLE_WIDGET_V2 (Data Table)

```json
{
  "type": "TABLE_WIDGET_V2",
  "widgetName": "UserRankingTable",
  "widgetId": "user_ranking_table_id",
  "topRow": 24.0,
  "bottomRow": 45.0,
  "leftColumn": 1.0,
  "rightColumn": 32.0,
  "tableData": "{{getUserRanking.data?.users || []}}",
  "primaryColumns": {
    "displayName": {
      "id": "displayName",
      "label": "User",
      "columnType": "text",
      "isVisible": true,
      "index": 0,
      "width": 150.0,
      "horizontalAlignment": "LEFT",
      "textSize": "0.875rem"
    },
    "totalTasks": {
      "id": "totalTasks",
      "label": "Total",
      "columnType": "number",
      "isVisible": true,
      "index": 1,
      "width": 80.0,
      "horizontalAlignment": "RIGHT"
    },
    "avgElapsedTime": {
      "id": "avgElapsedTime",
      "label": "Avg Time",
      "columnType": "number",
      "isVisible": true,
      "index": 3,
      "computedValue": "{{KpiUtils.formatTime(currentRow.avgElapsedTime)}}"
    }
  },
  "columnOrder": ["displayName", "totalTasks", "avgElapsedTime"],
  "defaultPageSize": 10.0,
  "isVisibleSearch": true,
  "isVisibleFilters": true,
  "isVisibleDownload": true,
  "isVisiblePagination": true,
  "serverSidePaginationEnabled": false,
  "dynamicBindingPathList": [
    {"key": "tableData"},
    {"key": "primaryColumns.avgElapsedTime.computedValue"}
  ]
}
```

### STATBOX_WIDGET (KPI Metric)

```json
{
  "type": "STATBOX_WIDGET",
  "widgetName": "StatTotalProcesses",
  "widgetId": "stat_processes_id",
  "key": "stat_processes_key",
  "parentId": "0",
  "topRow": 5.0,
  "bottomRow": 12.0,
  "leftColumn": 1.0,
  "rightColumn": 13.0,
  "value": "{{getDashboardKpis.data?.totalProcesses || 0}}",
  "label": "Total Processes",
  "iconName": "timeline-bar-chart",
  "iconAlign": "left",
  "valueColor": "#2B4570",
  "labelColor": "#6B7280",
  "animateLoading": true,
  "isVisible": true,
  "version": 1.0,
  "isLoading": false,
  "renderMode": "CANVAS",
  "responsiveBehavior": "fill",
  "flexVerticalAlignment": "start",
  "borderRadius": "{{appsmith.theme.borderRadius.appBorderRadius}}",
  "boxShadow": "{{appsmith.theme.boxShadow.appBoxShadow}}",
  "dynamicBindingPathList": [
    {"key": "borderRadius"},
    {"key": "boxShadow"},
    {"key": "value"}
  ],
  "dynamicPropertyPathList": [],
  "dynamicTriggerPathList": [],
  "mobileTopRow": 5.0,
  "mobileBottomRow": 12.0,
  "mobileLeftColumn": 1.0,
  "mobileRightColumn": 13.0,
  "parentRowSpace": 10.0,
  "parentColumnSpace": 19.125
}
```

## Custom Stat Boxes (Container-Based)

When `STATBOX_WIDGET` does not render correctly, use a `CONTAINER_WIDGET` + `TEXT_WIDGET` combination as a fallback:

```json
{
  "type": "CONTAINER_WIDGET",
  "widgetName": "StatTotalProcesses",
  "topRow": 12, "bottomRow": 19,
  "leftColumn": 1, "rightColumn": 13,
  "backgroundColor": "#FFFFFF",
  "borderWidth": "1",
  "borderColor": "#E0DEDE",
  "containerStyle": "card",
  "children": [{
    "type": "CANVAS_WIDGET",
    "children": [
      {
        "type": "TEXT_WIDGET",
        "widgetName": "StatTotalProcessesLabel",
        "text": "Total Processes",
        "fontSize": "0.75rem",
        "textColor": "#6B7280",
        "topRow": 1, "bottomRow": 3
      },
      {
        "type": "TEXT_WIDGET",
        "widgetName": "StatTotalProcessesValue",
        "text": "{{KpiUtils.formatNumber(getDashboardKpis.data?.totalProcesses) || '0'}}",
        "fontSize": "1.5rem",
        "fontStyle": "BOLD",
        "textColor": "#2B4570",
        "topRow": 3, "bottomRow": 6,
        "dynamicBindingPathList": [{"key": "text"}]
      }
    ]
  }]
}
```

This pattern provides:
- A label text (small, gray) at the top
- A value text (large, bold, colored) below
- Full control over layout and styling
- Card-style container with border and shadow
