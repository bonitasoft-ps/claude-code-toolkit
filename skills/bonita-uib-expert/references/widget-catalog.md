# Widget Catalog — Form and Interactive Widgets

> Bonita Version: 2024.3+

## Common Widget Properties

All widgets share these base properties:

```json
{
  "widgetId": "unique_id",
  "widgetName": "Descriptive_Name",
  "type": "WIDGET_TYPE",
  "parentId": "canvas_parent_id",
  "topRow": 0,
  "bottomRow": 4,
  "leftColumn": 0,
  "rightColumn": 64,
  "isVisible": true,
  "dynamicBindingPathList": [],
  "dynamicPropertyPathList": [],
  "dynamicTriggerPathList": [],
  "version": 1
}
```

## Label Property by Widget Type (CRITICAL)

| Widget | Label property |
|--------|---------------|
| TEXT_WIDGET | `text` |
| INPUT_WIDGET_V2 | `labelText` |
| SELECT_WIDGET | `labelText` |
| CHECKBOX_WIDGET | `label` |
| BUTTON_WIDGET | `text` |
| RADIO_GROUP_WIDGET | `label` |
| DATE_PICKER_WIDGET2 | `labelText` |
| RICH_TEXT_EDITOR_WIDGET | `labelText` |
| SWITCH_WIDGET | `label` |

## INPUT_WIDGET_V2

```json
{
  "type": "INPUT_WIDGET_V2",
  "widgetName": "Invoice_Number_Input",
  "inputType": "TEXT",
  "labelText": "{{JSI18n.t('form.invoiceNumber')}}",
  "placeholderText": "{{JSI18n.t('form.invoiceNumberPlaceholder')}}",
  "defaultText": "{{JSForm.formData.invoiceNumber}}",
  "errorMessage": "{{JSForm.errors.invoiceNumber || ''}}",
  "isRequired": true,
  "isDisabled": false,
  "labelPosition": "Top",
  "labelWidth": 10,
  "onTextChanged": "{{JSForm.updateField('invoiceNumber', Invoice_Number_Input.text)}}",
  "dynamicBindingPathList": [
    { "key": "labelText" },
    { "key": "placeholderText" },
    { "key": "defaultText" },
    { "key": "errorMessage" }
  ],
  "dynamicTriggerPathList": [
    { "key": "onTextChanged" }
  ]
}
```

### Input Types

| inputType | Use for |
|-----------|---------|
| `TEXT` | General text |
| `NUMBER` | Numeric values |
| `PASSWORD` | Passwords |
| `EMAIL` | Email addresses |
| `CURRENCY` | Currency amounts |

## SELECT_WIDGET (CRITICAL)

**MUST include `dynamicPropertyPathList` with `sourceData`** or dropdown won't work:

```json
{
  "type": "SELECT_WIDGET",
  "widgetName": "Status_Select",
  "labelText": "{{JSI18n.t('form.status')}}",
  "sourceData": "{{JSForm.statusOptions}}",
  "optionLabel": "label",
  "optionValue": "value",
  "defaultOptionValue": "{{JSForm.formData.status}}",
  "onOptionChange": "{{JSForm.updateField('status', Status_Select.selectedOptionValue)}}",
  "labelPosition": "Top",
  "dynamicBindingPathList": [
    { "key": "labelText" },
    { "key": "sourceData" },
    { "key": "defaultOptionValue" }
  ],
  "dynamicPropertyPathList": [
    { "key": "sourceData" }
  ],
  "dynamicTriggerPathList": [
    { "key": "onOptionChange" }
  ]
}
```

### SELECT sourceData Format

```javascript
statusOptions: function() {
  return [
    { label: JSI18n.t('status.draft'), value: 'DRAFT' },
    { label: JSI18n.t('status.submitted'), value: 'SUBMITTED' },
    { label: JSI18n.t('status.approved'), value: 'APPROVED' },
    { label: JSI18n.t('status.rejected'), value: 'REJECTED' }
  ];
}
```

**Without `dynamicPropertyPathList: [{ "key": "sourceData" }]`**, the SELECT treats sourceData as a static string.

## BUTTON_WIDGET

```json
{
  "type": "BUTTON_WIDGET",
  "widgetName": "Submit_Button",
  "text": "{{JSI18n.t('actions.submit')}}",
  "buttonStyle": "PRIMARY",
  "buttonColor": "{{appsmith.theme.colors.primaryColor}}",
  "borderRadius": "{{appsmith.theme.borderRadius.appBorderRadius}}",
  "boxShadow": "none",
  "isDisabled": "{{JSForm.isSubmitting || !JSForm.isDirty}}",
  "isLoading": "{{JSForm.isSubmitting}}",
  "onClick": "{{JSForm.submit()}}",
  "dynamicBindingPathList": [
    { "key": "text" },
    { "key": "buttonColor" },
    { "key": "borderRadius" },
    { "key": "isDisabled" },
    { "key": "isLoading" }
  ],
  "dynamicPropertyPathList": [
    { "key": "isDisabled" }
  ],
  "dynamicTriggerPathList": [
    { "key": "onClick" }
  ]
}
```

### Button Styles

| buttonStyle | Use for |
|-------------|---------|
| `PRIMARY` | Main actions (Submit, Save) |
| `SECONDARY` | Secondary actions (Cancel, Back) |
| `DANGER` | Destructive actions (Delete) |

## CHECKBOX_WIDGET

```json
{
  "type": "CHECKBOX_WIDGET",
  "widgetName": "Approve_Checkbox",
  "label": "{{JSI18n.t('form.approve')}}",
  "defaultCheckedState": "{{JSForm.formData.approved}}",
  "isRequired": false,
  "onCheckChange": "{{JSForm.updateField('approved', Approve_Checkbox.isChecked)}}",
  "dynamicBindingPathList": [
    { "key": "label" },
    { "key": "defaultCheckedState" }
  ],
  "dynamicTriggerPathList": [
    { "key": "onCheckChange" }
  ]
}
```

## RADIO_GROUP_WIDGET

```json
{
  "type": "RADIO_GROUP_WIDGET",
  "widgetName": "Priority_Radio",
  "label": "{{JSI18n.t('form.priority')}}",
  "options": "{{JSForm.priorityOptions}}",
  "defaultOptionValue": "{{JSForm.formData.priority}}",
  "onSelectionChange": "{{JSForm.updateField('priority', Priority_Radio.selectedOptionValue)}}",
  "dynamicBindingPathList": [
    { "key": "label" },
    { "key": "options" },
    { "key": "defaultOptionValue" }
  ],
  "dynamicPropertyPathList": [
    { "key": "options" }
  ],
  "dynamicTriggerPathList": [
    { "key": "onSelectionChange" }
  ]
}
```

## DATE_PICKER_WIDGET2

```json
{
  "type": "DATE_PICKER_WIDGET2",
  "widgetName": "Due_Date_Picker",
  "labelText": "{{JSI18n.t('form.dueDate')}}",
  "dateFormat": "YYYY-MM-DD",
  "defaultDate": "{{JSForm.formData.dueDate}}",
  "isRequired": true,
  "labelPosition": "Top",
  "onDateSelected": "{{JSForm.updateField('dueDate', Due_Date_Picker.selectedDate)}}",
  "dynamicBindingPathList": [
    { "key": "labelText" },
    { "key": "defaultDate" }
  ],
  "dynamicTriggerPathList": [
    { "key": "onDateSelected" }
  ]
}
```

## SWITCH_WIDGET

```json
{
  "type": "SWITCH_WIDGET",
  "widgetName": "Active_Switch",
  "label": "{{JSI18n.t('form.active')}}",
  "defaultSwitchState": "{{JSForm.formData.isActive}}",
  "alignWidget": "LEFT",
  "labelPosition": "Left",
  "onChange": "{{JSForm.updateField('isActive', Active_Switch.isSwitchedOn)}}",
  "dynamicBindingPathList": [
    { "key": "label" },
    { "key": "defaultSwitchState" }
  ],
  "dynamicTriggerPathList": [
    { "key": "onChange" }
  ]
}
```

## RICH_TEXT_EDITOR_WIDGET

```json
{
  "type": "RICH_TEXT_EDITOR_WIDGET",
  "widgetName": "Comment_Editor",
  "labelText": "{{JSI18n.t('form.comment')}}",
  "defaultText": "{{JSForm.formData.comment || ''}}",
  "isRequired": false,
  "labelPosition": "Top",
  "onTextChange": "{{JSForm.updateField('comment', Comment_Editor.text)}}",
  "dynamicBindingPathList": [
    { "key": "labelText" },
    { "key": "defaultText" }
  ],
  "dynamicTriggerPathList": [
    { "key": "onTextChange" }
  ]
}
```

## ICON_BUTTON_WIDGET

```json
{
  "type": "ICON_BUTTON_WIDGET",
  "widgetName": "Refresh_Icon_Button",
  "iconName": "refresh",
  "buttonColor": "{{appsmith.theme.colors.primaryColor}}",
  "borderRadius": "{{appsmith.theme.borderRadius.appBorderRadius}}",
  "onClick": "{{JSList.fetchData()}}",
  "dynamicBindingPathList": [
    { "key": "buttonColor" },
    { "key": "borderRadius" }
  ],
  "dynamicTriggerPathList": [
    { "key": "onClick" }
  ]
}
```

## FILE_PICKER_WIDGET_V2

```json
{
  "type": "FILE_PICKER_WIDGET_V2",
  "widgetName": "Document_FilePicker",
  "label": "{{JSI18n.t('form.uploadDocument')}}",
  "maxNumFiles": 1,
  "maxFileSize": 10,
  "allowedFileTypes": ["*"],
  "fileDataType": "Base64",
  "isRequired": false,
  "onFilesSelected": "{{JSForm.handleFileUpload(Document_FilePicker.files)}}",
  "dynamicBindingPathList": [
    { "key": "label" }
  ],
  "dynamicTriggerPathList": [
    { "key": "onFilesSelected" }
  ]
}
```

### File Data Types

| fileDataType | Use for |
|-------------|---------|
| `Base64` | Upload to Bonita API (most common) |
| `Binary` | Raw binary processing |
| `Text` | Text file content |

### File Object Properties

```javascript
handleFileUpload: function(files) {
  if (files && files.length > 0) {
    var file = files[0];
    // file.name — original filename
    // file.type — MIME type
    // file.size — size in bytes
    // file.data — content (format depends on fileDataType)
    this.uploadedFile.value = {
      name: file.name,
      type: file.type,
      data: file.data
    };
  }
}
```

## TABS_WIDGET

```json
{
  "type": "TABS_WIDGET",
  "widgetId": "tabs_001",
  "widgetName": "Main_Tabs",
  "tabsObj": {
    "tab1": {
      "id": "tab1",
      "widgetId": "tab1",
      "label": "{{JSI18n.t('tabs.overview')}}",
      "index": 0,
      "isVisible": true
    },
    "tab2": {
      "id": "tab2",
      "widgetId": "tab2",
      "label": "{{JSI18n.t('tabs.details')}}",
      "index": 1,
      "isVisible": true
    },
    "tab3": {
      "id": "tab3",
      "widgetId": "tab3",
      "label": "{{JSI18n.t('tabs.history')}}",
      "index": 2,
      "isVisible": "{{JSObject.selectedItem !== null}}"
    }
  },
  "defaultTab": "tab1",
  "shouldShowTabs": true,
  "onTabSelected": "{{JSObject.onTabChange(Main_Tabs.selectedTab)}}",
  "dynamicBindingPathList": [
    { "key": "tabsObj.tab1.label" },
    { "key": "tabsObj.tab2.label" },
    { "key": "tabsObj.tab3.label" },
    { "key": "tabsObj.tab3.isVisible" }
  ],
  "dynamicPropertyPathList": [
    { "key": "tabsObj.tab3.isVisible" }
  ],
  "dynamicTriggerPathList": [
    { "key": "onTabSelected" }
  ]
}
```

Each tab contains a CANVAS_WIDGET with children. Tab children use the tab's canvas `widgetId` as `parentId`.

## LIST_WIDGET_V2

```json
{
  "type": "LIST_WIDGET_V2",
  "widgetName": "Items_List",
  "listData": "{{JSList.data}}",
  "serverSidePaginationEnabled": true,
  "onPageChange": "{{JSList.onPageChange(Items_List.pageNo)}}",
  "currentItemsViewHeight": 400,
  "itemSpacing": 8,
  "backgroundColor": "#FFFFFF",
  "dynamicBindingPathList": [
    { "key": "listData" }
  ],
  "dynamicTriggerPathList": [
    { "key": "onPageChange" }
  ]
}
```

### List Item Template

Child widgets use `currentItem` and `currentIndex`:

```json
{
  "type": "TEXT_WIDGET",
  "widgetName": "Item_Title",
  "parentId": "list_canvas_id",
  "text": "{{currentItem.name}}",
  "dynamicBindingPathList": [{ "key": "text" }]
}
```

### List vs Table

| Use LIST_WIDGET when | Use TABLE_WIDGET when |
|---------------------|----------------------|
| Card-style layout | Tabular data display |
| Complex item templates | Simple column-based data |
| Custom item designs | Built-in sorting/filtering |
| Variable item heights | Uniform row heights |

## IMAGE_WIDGET

```json
{
  "type": "IMAGE_WIDGET",
  "widgetName": "User_Avatar",
  "image": "{{JSUser.avatarUrl || '/static/default-avatar.png'}}",
  "defaultImage": "/static/default-avatar.png",
  "objectFit": "contain",
  "maxZoomLevel": 1,
  "dynamicBindingPathList": [
    { "key": "image" }
  ],
  "dynamicTriggerPathList": []
}
```

### objectFit Values

| Value | Behavior |
|-------|----------|
| `contain` | Fit within bounds, maintain aspect ratio |
| `cover` | Fill bounds, crop if needed |
| `auto` | Natural size |

## DIVIDER_WIDGET

```json
{
  "type": "DIVIDER_WIDGET",
  "widgetName": "Section_Divider",
  "orientation": "horizontal",
  "capType": "nc",
  "dividerColor": "#E0DEDE",
  "strokeStyle": "solid",
  "thickness": 1
}
```

## Anti-patterns

- Missing `dynamicPropertyPathList: [{ "key": "sourceData" }]` on SELECT_WIDGET
- Wrong `parentId` (container ID instead of canvas ID)
- Missing `dynamicTriggerPathList: []` (even when empty)
- Using `label` where widget expects `labelText` (or vice-versa)
- Not declaring dynamic bindings in PathLists
- Forgetting column `dynamicBindingPathList` for translated labels in tables
- Using hardcoded colors instead of theme bindings
