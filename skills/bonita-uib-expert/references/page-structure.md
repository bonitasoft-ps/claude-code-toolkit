# Page Structure and Layout

> Bonita Version: 2024.3+

## Page Registration (CRITICAL)

**Every page MUST be in `application.json`** or UIB will delete it on sync:

```json
{
  "pages": [
    { "id": "PageName", "isDefault": true },
    { "id": "AnotherPage", "isDefault": false }
  ]
}
```

## Page Types

| Type | Purpose | Context |
|------|---------|---------|
| Process Form | Task execution, instantiation | Has task/case context |
| Application Page | General UI in Living Apps | No process context |
| Overview Page | Case summary | Case context |

## Page JSON Structure (CRITICAL)

**Location:** `pages/[PageName]/[PageName].json`

```json
{
  "gitSyncId": "[app_id]_[unique_page_id]",
  "unpublishedPage": {
    "customSlug": "",
    "isHidden": false,
    "layouts": [{
      "dsl": {
        "backgroundColor": "#F9FAFB",
        "bottomRow": 1200,
        "canExtend": true,
        "containerStyle": "none",
        "detachFromLayout": true,
        "dynamicBindingPathList": [],
        "dynamicTriggerPathList": [],
        "leftColumn": 0,
        "minHeight": 800,
        "parentColumnSpace": 1,
        "parentRowSpace": 1,
        "rightColumn": 1224,
        "snapColumns": 64,
        "snapRows": 120,
        "topRow": 0,
        "type": "CANVAS_WIDGET",
        "version": 94,
        "widgetId": "0",
        "widgetName": "MainContainer"
      }
    }],
    "name": "[PageName]",
    "slug": "[pagename-lowercase]"
  }
}
```

## Widget Directory Structure (CRITICAL)

**Widgets MUST be in subdirectories matching container names**:

```
pages/[PageName]/widgets/
├── Header_Container/
│   ├── Header_Container.json
│   └── Page_Title.json
├── Content_Container/
│   ├── Content_Container.json
│   └── Form_Input.json
└── My_Modal/
    ├── My_Modal.json
    └── Modal_Title.json
```

**NEVER put widgets flat in `widgets/`** — UIB will delete them on sync.

## Layout Grid

Standard grid: **64 columns**

| Layout | leftColumn | rightColumn |
|--------|-----------|-------------|
| Full width | 0 | 64 |
| Half (left) | 0 | 32 |
| Half (right) | 32 | 64 |
| Third | 0 | 21 |
| Quarter | 0 | 16 |
| Centered content | 8 | 56 |
| Narrow content | 12 | 52 |

## Container Widget Structure (CRITICAL)

Containers **MUST** have `children` array with a CANVAS_WIDGET inside:

```json
{
  "type": "CONTAINER_WIDGET",
  "widgetId": "container_id_001",
  "widgetName": "My_Container",
  "parentId": "0",
  "topRow": 0,
  "bottomRow": 40,
  "leftColumn": 8,
  "rightColumn": 56,
  "backgroundColor": "#FFFFFF",
  "borderColor": "#E0DEDE",
  "borderRadius": "{{appsmith.theme.borderRadius.appBorderRadius}}",
  "borderWidth": "1",
  "boxShadow": "{{appsmith.theme.boxShadow.appBoxShadow}}",
  "children": [{
    "type": "CANVAS_WIDGET",
    "widgetId": "canvas_id_001",
    "widgetName": "My_Canvas",
    "parentId": "container_id_001",
    "bottomRow": 400,
    "canExtend": false,
    "containerStyle": "none",
    "detachFromLayout": true,
    "dynamicBindingPathList": [],
    "dynamicTriggerPathList": [],
    "flexLayers": []
  }],
  "dynamicBindingPathList": [
    { "key": "borderRadius" },
    { "key": "boxShadow" }
  ],
  "dynamicTriggerPathList": [],
  "isCanvas": true
}
```

## Child Widget parentId (CRITICAL)

Child widgets point to the **canvas ID**, NOT the container ID:

```json
{
  "type": "TEXT_WIDGET",
  "widgetName": "My_Text",
  "parentId": "canvas_id_001"
}
```

**Wrong:** `"parentId": "container_id_001"` → widget won't render.

## Modal Widget Structure (CRITICAL)

Same as container, plus `width` and `size` properties:

```json
{
  "type": "MODAL_WIDGET",
  "widgetId": "modal_id_001",
  "widgetName": "My_Modal",
  "width": 1518,
  "leftColumn": 4,
  "rightColumn": 28,
  "borderRadius": "{{appsmith.theme.borderRadius.appBorderRadius}}",
  "canOutsideClickClose": true,
  "shouldScrollContents": true,
  "size": "MODAL_LARGE",
  "children": [{
    "type": "CANVAS_WIDGET",
    "widgetId": "modal_canvas_001",
    "widgetName": "Modal_Canvas",
    "parentId": "modal_id_001",
    "dynamicBindingPathList": [],
    "dynamicTriggerPathList": []
  }],
  "dynamicBindingPathList": [
    { "key": "borderRadius" }
  ],
  "dynamicTriggerPathList": []
}
```

### Modal Control from JSObjects

```javascript
showModal('My_Modal');
closeModal('My_Modal');
```

## Container Positioning — Avoid Overlap (CRITICAL)

Root-level containers use `topRow`/`bottomRow` for vertical positioning.
**Containers must NOT overlap** — stack them vertically:

```
Header_Container:   topRow: 0,   bottomRow: 10
Filters_Container:  topRow: 10,  bottomRow: 20
Content_Container:  topRow: 20,  bottomRow: 80
Footer_Container:   topRow: 80,  bottomRow: 90
```

## Auto-Height for Dynamic Content (CRITICAL)

Use `dynamicHeight: "AUTO_HEIGHT"` for widgets with variable content:

```json
{
  "type": "CONTAINER_WIDGET",
  "dynamicHeight": "AUTO_HEIGHT",
  "minHeight": 400
}
```

Use on:
- Containers with dynamic child widgets
- Text widgets with variable-length text
- Lists or widgets bound to arrays

**Without AUTO_HEIGHT**, content may overflow or be cut off when data changes.

## Dynamic Binding Declarations

Every dynamic value must be declared in the appropriate PathList:

```json
{
  "dynamicBindingPathList": [{ "key": "text" }],
  "dynamicPropertyPathList": [{ "key": "isVisible" }],
  "dynamicTriggerPathList": [{ "key": "onClick" }]
}
```

| PathList | Purpose | Example properties |
|----------|---------|-------------------|
| `dynamicBindingPathList` | Computed values `{{ }}` | text, defaultText, label, tableData |
| `dynamicPropertyPathList` | JS expression properties | isVisible, isDisabled, sourceData |
| `dynamicTriggerPathList` | Event handlers | onClick, onPageChange, onSort |

**Forgetting `dynamicTriggerPathList: []`** (even empty) causes Git checkout failure.

## Wizard Pattern (Multi-step)

Multiple containers at the same position with dynamic visibility:

```json
{
  "widgetName": "Step1_Container",
  "topRow": 20, "bottomRow": 60,
  "isVisible": "{{JSWizard.currentStep === 1}}",
  "dynamicBindingPathList": [{ "key": "isVisible" }],
  "dynamicPropertyPathList": [{ "key": "isVisible" }]
}
```

```json
{
  "widgetName": "Step2_Container",
  "topRow": 20, "bottomRow": 60,
  "isVisible": "{{JSWizard.currentStep === 2}}",
  "dynamicBindingPathList": [{ "key": "isVisible" }],
  "dynamicPropertyPathList": [{ "key": "isVisible" }]
}
```

## In-Page Detail Pattern (List / Detail Toggle)

Show/hide containers based on selection state:

```json
{
  "widgetName": "List_Container",
  "isVisible": "{{JSObject.selectedItem === null}}",
  "dynamicBindingPathList": [{ "key": "isVisible" }],
  "dynamicPropertyPathList": [{ "key": "isVisible" }]
}
```

```json
{
  "widgetName": "Detail_Container",
  "isVisible": "{{JSObject.selectedItem !== null}}",
  "dynamicBindingPathList": [{ "key": "isVisible" }],
  "dynamicPropertyPathList": [{ "key": "isVisible" }]
}
```

## Anti-patterns

- Forgetting `dynamicTriggerPathList: []` on containers (causes Git checkout failure)
- Overlapping root containers (unpredictable layout behavior)
- Using float values (e.g., `1200.0` instead of `1200`)
- Not declaring dynamic bindings in PathLists
- Putting widgets flat in `widgets/` directory (not in container subdirectories)
- Pointing child `parentId` to container instead of its canvas
- Forgetting `CANVAS_WIDGET` inside container `children` array
- Not using `AUTO_HEIGHT` on containers with variable content
- Not registering pages in `application.json`
