# Theme and Styling

> Bonita Version: 2024.3+

## Theme Configuration (theme.json)

**Location:** `theme.json` at project root

```json
{
  "colors": {
    "primaryColor": "#553DE9",
    "backgroundColor": "#F6F6F6"
  },
  "borderRadius": {
    "appBorderRadius": "0.375rem"
  },
  "boxShadow": {
    "appBoxShadow": "0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)"
  },
  "fontFamily": {
    "appFont": "System Default"
  }
}
```

### Theme Variables in Widgets

Always use theme variables for consistent styling:

```json
{
  "buttonColor": "{{appsmith.theme.colors.primaryColor}}",
  "backgroundColor": "{{appsmith.theme.colors.backgroundColor}}",
  "borderRadius": "{{appsmith.theme.borderRadius.appBorderRadius}}",
  "boxShadow": "{{appsmith.theme.boxShadow.appBoxShadow}}",
  "dynamicBindingPathList": [
    { "key": "borderRadius" },
    { "key": "boxShadow" },
    { "key": "buttonColor" }
  ]
}
```

## Color Palette

### Functional Colors

| Purpose | Hex | Usage |
|---------|-----|-------|
| Primary | `#553DE9` | Main actions, links, active states |
| Success | `#36B37E` | Confirmation, approved states |
| Warning | `#FFC107` | Caution, pending states |
| Error | `#CC0000` | Errors, rejected states, destructive actions |
| Info | `#2196F3` | Informational messages |

### Neutral Colors

| Purpose | Hex | Usage |
|---------|-----|-------|
| Text Primary | `#231F20` | Main text, headings |
| Text Secondary | `#6B7280` | Descriptions, labels |
| Text Muted | `#9CA3AF` | Placeholders, disabled text |
| Border | `#E0DEDE` | Container borders, dividers |
| Background Page | `#F6F6F6` or `#F9FAFB` | Page background |
| Background Card | `#FFFFFF` | Container/card background |
| Background Hover | `#F3F4F6` | Hover states |

### Status Colors

```javascript
getStatusColor: function(status) {
  var colors = {
    'DRAFT': '#6B7280',
    'SUBMITTED': '#2196F3',
    'IN_PROGRESS': '#FFC107',
    'APPROVED': '#36B37E',
    'REJECTED': '#CC0000',
    'COMPLETED': '#36B37E',
    'CANCELLED': '#9CA3AF'
  };
  return colors[status] || '#6B7280';
}
```

Usage in TEXT_WIDGET:
```json
{
  "text": "<span style='color: {{JSObject.getStatusColor(currentRow.status)}}; font-weight: 600'>{{JSI18n.translateDynamicValue(currentRow.status, 'status')}}</span>",
  "dynamicBindingPathList": [{ "key": "text" }]
}
```

## Typography

| Element | Size | Weight | Usage |
|---------|------|--------|-------|
| Page Title | `1.5rem` | `BOLD` | Main page heading |
| Section Title | `1.25rem` | `BOLD` | Container/section headings |
| Subtitle | `1rem` | `BOLD` | Sub-section headings |
| Body | `0.875rem` | Normal | Default text, form labels |
| Caption | `0.75rem` | Normal | Help text, metadata |

Available `fontStyle` values: `BOLD`, `ITALIC`, `BOLD_ITALIC`, or empty string.
Available `textAlign` values: `LEFT`, `CENTER`, `RIGHT`.

## Container Styling Variants

### Standard Card

```json
{
  "backgroundColor": "#FFFFFF",
  "borderColor": "#E0DEDE",
  "borderWidth": "1",
  "borderRadius": "{{appsmith.theme.borderRadius.appBorderRadius}}",
  "boxShadow": "{{appsmith.theme.boxShadow.appBoxShadow}}"
}
```

### Flat (No Border/Shadow)

```json
{
  "backgroundColor": "transparent",
  "borderColor": "transparent",
  "borderWidth": "0",
  "borderRadius": "0",
  "boxShadow": "none"
}
```

### Info Banner

```json
{
  "backgroundColor": "#EBF5FF",
  "borderColor": "#2196F3",
  "borderWidth": "1",
  "borderRadius": "{{appsmith.theme.borderRadius.appBorderRadius}}",
  "boxShadow": "none"
}
```

### Error/Warning Banner

```json
{
  "backgroundColor": "#FFF5F5",
  "borderColor": "#CC0000",
  "borderWidth": "1"
}
```

## Inline Styles in TEXT_WIDGET

### Status Badge

```json
{
  "text": "<span style='background-color: {{JSObject.getStatusColor(JSObject.selectedItem.status)}}; color: white; padding: 2px 8px; border-radius: 4px; font-size: 0.75rem; font-weight: 600'>{{JSI18n.translateDynamicValue(JSObject.selectedItem.status, 'status')}}</span>"
}
```

### Key-Value Display

```json
{
  "text": "<span style='color: #6B7280; font-size: 0.75rem'>{{JSI18n.t('form.amount')}}</span><br/><span style='font-size: 1.25rem; font-weight: 700; color: #231F20'>{{JSObject.formatCurrency(JSObject.selectedItem.amount)}}</span>"
}
```

## Button Styling

### Primary

```json
{ "buttonStyle": "PRIMARY", "buttonColor": "{{appsmith.theme.colors.primaryColor}}" }
```

### Secondary/Outline

```json
{ "buttonStyle": "SECONDARY", "buttonColor": "{{appsmith.theme.colors.primaryColor}}" }
```

### Danger

```json
{ "buttonStyle": "DANGER", "buttonColor": "#CC0000" }
```

### Ghost/Text

```json
{ "buttonStyle": "SECONDARY", "buttonColor": "transparent", "borderRadius": "0" }
```

## Spacing Conventions (Grid Rows)

| Spacing | Rows | Use for |
|---------|------|---------|
| Tight | 1-2 | Between related elements (label + input) |
| Normal | 3-4 | Between form fields |
| Loose | 6-8 | Between sections |
| Section gap | 10+ | Between major content blocks |

### Container Padding via Positioning

Containers have no explicit padding. Control whitespace by positioning children:

```
Container: leftColumn 0, rightColumn 64
  Child:   leftColumn 2, rightColumn 62   → ~2 col padding each side
```

## Responsive Layout Guide

| Layout | leftColumn | rightColumn | Notes |
|--------|-----------|-------------|-------|
| Full width | 0 | 64 | Tables, wide content |
| Content width | 4 | 60 | Forms, cards |
| Narrow content | 12 | 52 | Centered forms |
| Side-by-side | 0-30 / 34-64 | | Two-column layout |

## Client Customization Checklist

1. **theme.json**: Update `primaryColor` to client brand
2. **theme.json**: Adjust `borderRadius` (sharp: `0`, subtle: `0.375rem`, rounded: `0.75rem`)
3. **theme.json**: Adjust `boxShadow` (flat: `none`, subtle: default, elevated: larger)
4. **theme.json**: Set `appFont` if client has brand font
5. **Status colors**: Adapt if client has specific conventions
6. **Page background**: `#F6F6F6` (warm gray) or `#F9FAFB` (cool gray)

## Anti-patterns

- Hardcoding colors instead of using theme variables
- Using different border-radius values across containers
- Mixing font-size units (use `rem` consistently)
- Using `boxShadow` on every container (reserve for primary cards)
- Not using status colors consistently across pages
- Deep nesting of HTML in TEXT_WIDGET
- Using pixel values for fonts (use `rem`)
