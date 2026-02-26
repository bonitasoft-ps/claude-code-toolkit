# Chart and KPI Patterns

## CHART_WIDGET Types

| Type | Use Case |
|------|----------|
| `PIE_CHART` | Distribution, proportions |
| `BAR_CHART` | Horizontal comparisons |
| `COLUMN_CHART` | Vertical comparisons |
| `LINE_CHART` | Trends over time |
| `AREA_CHART` | Cumulative trends |

## Chart Data Format

All chart types expect data as an **array of `{x, y}` objects**:

```javascript
[
  { x: 'Human Tasks', y: 42 },
  { x: 'Automated Tasks', y: 18 }
]
```

### Generating Chart Data in JS Object

```javascript
export default {
  getTaskDistributionData() {
    const humanTasks = getFormKpis.data?.totalFormSteps || 0;
    const autoTasks = getFormKpis.data?.totalNonFormSteps || 0;
    return [
      { x: 'Human Tasks', y: humanTasks },
      { x: 'Automated Tasks', y: autoTasks }
    ];
  },

  getTimeComparisonData() {
    const data = getFormKpis.data;
    return [
      { x: 'With Form', y: Math.round((data?.withFormKpis?.avgElapsedTime || 0) / 1000) },
      { x: 'Without Form', y: Math.round((data?.withoutFormKpis?.avgElapsedTime || 0) / 1000) }
    ];
  }
}
```

## Pie Chart Example

```json
{
  "type": "CHART_WIDGET",
  "widgetName": "TaskDistributionChart",
  "widgetId": "task_distribution_chart_id",
  "chartType": "PIE_CHART",
  "chartName": "Task Distribution",
  "chartData": {
    "default": {
      "seriesName": "Tasks",
      "data": "{{KpiUtils.getTaskDistributionData()}}"
    }
  },
  "showDataPointLabel": true,
  "borderRadius": "12px",
  "boxShadow": "0 4px 6px -1px rgba(0, 0, 0, 0.1)",
  "topRow": 24.0,
  "bottomRow": 45.0,
  "leftColumn": 32.0,
  "rightColumn": 63.0,
  "isVisible": true,
  "animateLoading": true,
  "dynamicBindingPathList": [
    {"key": "chartData.default.data"}
  ]
}
```

## Column Chart Example

```json
{
  "type": "CHART_WIDGET",
  "widgetName": "TimeComparisonChart",
  "widgetId": "time_comparison_chart_id",
  "chartType": "COLUMN_CHART",
  "chartName": "Time Comparison",
  "chartData": {
    "default": {
      "seriesName": "Avg Time (seconds)",
      "data": "{{KpiUtils.getTimeComparisonData()}}"
    }
  },
  "xAxisName": "Task Type",
  "yAxisName": "Seconds",
  "showDataPointLabel": true,
  "topRow": 46.0,
  "bottomRow": 67.0,
  "leftColumn": 1.0,
  "rightColumn": 32.0,
  "dynamicBindingPathList": [
    {"key": "chartData.default.data"}
  ]
}
```

## Line Chart Example

```json
{
  "type": "CHART_WIDGET",
  "widgetName": "TrendChart",
  "widgetId": "trend_chart_id",
  "chartType": "LINE_CHART",
  "chartName": "Process Trend",
  "chartData": {
    "default": {
      "seriesName": "Instances",
      "data": "{{KpiUtils.getTrendData()}}"
    }
  },
  "xAxisName": "Month",
  "yAxisName": "Count",
  "showDataPointLabel": false,
  "dynamicBindingPathList": [
    {"key": "chartData.default.data"}
  ]
}
```

## Colorful KPI Stat Boxes

Use vibrant background colors with matching accent colors for values:

### Color Palette

```javascript
const kpiColors = {
  blue:   { bg: '#DBEAFE', accent: '#2563EB' },  // Total Processes
  green:  { bg: '#DCFCE7', accent: '#16A34A' },  // Total Cases
  amber:  { bg: '#FEF3C7', accent: '#D97706' },  // Total Tasks
  pink:   { bg: '#FCE7F3', accent: '#DB2777' },  // Avg Case Time
  purple: { bg: '#E9D5FF', accent: '#9333EA' },  // Avg Task Time
  red:    { bg: '#FEE2E2', accent: '#DC2626' },  // Human Tasks
  orange: { bg: '#FFEDD5', accent: '#EA580C' },  // Human Avg Time
  teal:   { bg: '#D1FAE5', accent: '#059669' },  // Auto Tasks
  cyan:   { bg: '#CFFAFE', accent: '#0891B2' }   // Auto Avg Time
};
```

### Suggested KPI-to-Color Mapping

| KPI | Background | Accent |
|-----|-----------|--------|
| Total Processes | `#DBEAFE` | `#2563EB` |
| Total Cases | `#DCFCE7` | `#16A34A` |
| Total Tasks | `#FEF3C7` | `#D97706` |
| Avg Case Time | `#FCE7F3` | `#DB2777` |
| Avg Task Time | `#E9D5FF` | `#9333EA` |
| Human Tasks | `#FEE2E2` | `#DC2626` |
| Human Avg Time | `#FFEDD5` | `#EA580C` |
| Auto Tasks | `#D1FAE5` | `#059669` |
| Auto Avg Time | `#CFFAFE` | `#0891B2` |

## Stat Box Container Styling

```json
{
  "type": "CONTAINER_WIDGET",
  "widgetName": "StatTotalProcesses",
  "backgroundColor": "#DBEAFE",
  "borderWidth": "0",
  "borderRadius": "16px",
  "boxShadow": "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)",
  "containerStyle": "card",
  "topRow": 12.0,
  "bottomRow": 19.0,
  "leftColumn": 1.0,
  "rightColumn": 13.0,
  "children": [{
    "type": "CANVAS_WIDGET",
    "children": [
      {
        "type": "TEXT_WIDGET",
        "widgetName": "StatTotalProcessesValue",
        "text": "{{KpiUtils.formatNumber(getDashboardKpis.data?.totalProcesses) || '0'}}",
        "fontSize": "2.5rem",
        "fontStyle": "BOLD",
        "textColor": "#2563EB",
        "textAlign": "CENTER",
        "topRow": 1.0,
        "bottomRow": 5.0,
        "leftColumn": 0.0,
        "rightColumn": 64.0,
        "dynamicBindingPathList": [{"key": "text"}]
      },
      {
        "type": "TEXT_WIDGET",
        "widgetName": "StatTotalProcessesLabel",
        "text": "Total Processes",
        "fontSize": "0.875rem",
        "fontStyle": "BOLD",
        "textColor": "#374151",
        "textAlign": "CENTER",
        "topRow": 5.0,
        "bottomRow": 7.0,
        "leftColumn": 0.0,
        "rightColumn": 64.0
      }
    ]
  }]
}
```

## Value Text Styling

Large, bold value displayed prominently:

```json
{
  "type": "TEXT_WIDGET",
  "fontSize": "2.5rem",
  "fontStyle": "BOLD",
  "textColor": "#2563EB",
  "textAlign": "CENTER"
}
```

## Label Text Styling

Smaller, descriptive label below the value:

```json
{
  "type": "TEXT_WIDGET",
  "fontSize": "0.875rem",
  "fontStyle": "BOLD",
  "textColor": "#374151",
  "textAlign": "CENTER"
}
```

## KPI Layout Pattern (5 Columns)

For a row of 5 KPI stat boxes:

```
Column 1: leftColumn=1,  rightColumn=13   (width: 12)
Column 2: leftColumn=13, rightColumn=26   (width: 13)
Column 3: leftColumn=26, rightColumn=39   (width: 13)
Column 4: leftColumn=39, rightColumn=52   (width: 13)
Column 5: leftColumn=52, rightColumn=63   (width: 11)
```

## KPI Layout Pattern (4 Columns)

For a row of 4 KPI stat boxes:

```
Column 1: leftColumn=1,  rightColumn=16   (width: 15)
Column 2: leftColumn=16, rightColumn=32   (width: 16)
Column 3: leftColumn=32, rightColumn=48   (width: 16)
Column 4: leftColumn=48, rightColumn=63   (width: 15)
```

## Multi-Series Chart

For charts with multiple data series:

```json
{
  "chartData": {
    "series1": {
      "seriesName": "Completed",
      "data": "{{KpiUtils.getCompletedData()}}"
    },
    "series2": {
      "seriesName": "Pending",
      "data": "{{KpiUtils.getPendingData()}}"
    }
  },
  "dynamicBindingPathList": [
    {"key": "chartData.series1.data"},
    {"key": "chartData.series2.data"}
  ]
}
```

## Chart Inside Container

For charts with a title and border:

```json
{
  "type": "CONTAINER_WIDGET",
  "widgetName": "ChartContainer",
  "backgroundColor": "#FFFFFF",
  "borderRadius": "12px",
  "boxShadow": "0 4px 6px -1px rgba(0, 0, 0, 0.1)",
  "children": [{
    "type": "CANVAS_WIDGET",
    "children": [
      {
        "type": "TEXT_WIDGET",
        "widgetName": "ChartTitle",
        "text": "Task Distribution",
        "fontSize": "1.125rem",
        "fontStyle": "BOLD",
        "textColor": "#2B4570",
        "topRow": 0, "bottomRow": 2,
        "leftColumn": 1, "rightColumn": 63
      },
      {
        "type": "CHART_WIDGET",
        "widgetName": "TaskDistributionChart",
        "chartType": "PIE_CHART",
        "topRow": 2, "bottomRow": 20,
        "leftColumn": 0, "rightColumn": 64
      }
    ]
  }]
}
```
