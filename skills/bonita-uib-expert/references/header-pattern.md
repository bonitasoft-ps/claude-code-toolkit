# Header and Navigation Pattern (Process-Builder Style)

## Structure Overview

The Process-Builder header consists of **TWO containers side by side**:

```
+-------------------+----------------------------------------+
| ContainerLogo     | Welcome Container                      |
| (leftColumn: 0-19)| (leftColumn: 19-64)                   |
| Blue background   | White background                       |
| Contains: Logo    | Contains: Title, Welcome Text, Menu   |
+-------------------+----------------------------------------+
```

## layoutOnLoadActions Batching for Header

The header requires specific API loading order to avoid race conditions:

```json
"layoutOnLoadActions": [
  [
    {"id": "Page1_userQuery"},
    {"id": "Page1_logoUrlQuery"}
  ],
  [
    {
      "id": "Page1_JSInit.init",
      "name": "JSInit.init",
      "collectionId": "Page1_JSInit",
      "confirmBeforeExecute": false,
      "pluginType": "JS",
      "jsonPathKeys": [],
      "timeoutInMillisecond": 10000
    }
  ]
]
```

**Batch 1:** `userQuery` and `logoUrlQuery` run in **parallel** (both are API calls).
**Batch 2:** `JSInit.init()` runs **after** batch 1 completes. It reads from already-loaded data.

## JSInit Pattern (Batch 2: Read API Data, NO .run() Calls)

**IMPORTANT:** JSInit runs in batch 2, so APIs are already loaded. Do NOT call `.run()` again.

```javascript
export default {
  user: null,

  async init() {
    // APIs already loaded in batch 1 - just read their data

    // Set logo from already-loaded logoUrlQuery
    if (logoUrlQuery.data && logoUrlQuery.data.length > 0 && logoUrlQuery.data[0].configValue) {
      await storeValue('logo', logoUrlQuery.data[0].configValue);
    } else {
      await storeValue('logo', JSAssets.logo);
    }

    // Set user from already-loaded userQuery
    if (userQuery.data && userQuery.data.user_name) {
      this.user = userQuery.data;
      await storeValue('user', this.user);
    } else {
      // Fallback menu
      await storeValue('user', {
        user_name: 'User',
        menu: [
          { id: 'home', label: 'Home page', icon: 'home', page: 'Home' },
          { id: 'logout', label: 'Log out', icon: 'log-out', page: 'Logout' }
        ]
      });
    }
  }
}
```

### Anti-Pattern: Calling .run() in JSInit

```javascript
// WRONG: Redundant .run() when API is in layoutOnLoadActions batch 1
async init() {
  await userQuery.run();  // Already loaded! Don't call again
  this.user = userQuery.data;
}
```

## Logo Container Structure

```json
{
  "type": "CONTAINER_WIDGET",
  "widgetName": "ContainerLogo",
  "widgetId": "container_logo_id",
  "topRow": 0.0,
  "bottomRow": 10.0,
  "leftColumn": 0.0,
  "rightColumn": 19.0,
  "backgroundColor": "#2b4570",
  "containerStyle": "card",
  "borderWidth": "0",
  "borderColor": "#E0DEDE",
  "isCanvas": true,
  "shouldScrollContents": false,
  "dynamicHeight": "FIXED",
  "minHeight": 100.0,
  "isVisible": true,
  "children": [{
    "type": "CANVAS_WIDGET",
    "widgetName": "ContainerLogoCanvas",
    "children": [{
      "type": "IMAGE_WIDGET",
      "widgetName": "Logo",
      "widgetId": "logo_image_id",
      "image": "{{appsmith.store.logo}}",
      "objectFit": "contain",
      "imageShape": "RECTANGLE",
      "enableDownload": false,
      "enableRotation": false,
      "topRow": 0.0,
      "bottomRow": 8.0,
      "leftColumn": 6.0,
      "rightColumn": 60.0,
      "dynamicBindingPathList": [
        {"key": "image"}
      ]
    }]
  }],
  "dynamicBindingPathList": [
    {"key": "borderRadius"},
    {"key": "boxShadow"}
  ]
}
```

### Logo Container Positioning

- Full height of header: `topRow: 0`, `bottomRow: 10`
- Left section: `leftColumn: 0`, `rightColumn: 19`
- Blue background: `#2b4570`
- Logo image centered within: `leftColumn: 6`, `rightColumn: 60` (inside container grid)

## Welcome Container Structure

```json
{
  "type": "CONTAINER_WIDGET",
  "widgetName": "Welcome",
  "widgetId": "welcome_container_id",
  "topRow": 0.0,
  "bottomRow": 10.0,
  "leftColumn": 19.0,
  "rightColumn": 64.0,
  "backgroundColor": "#FFFFFF",
  "containerStyle": "card",
  "borderWidth": "0",
  "isCanvas": true,
  "shouldScrollContents": false,
  "dynamicHeight": "FIXED",
  "children": [{
    "type": "CANVAS_WIDGET",
    "widgetName": "WelcomeCanvas",
    "children": [
      {
        "type": "TEXT_WIDGET",
        "widgetName": "TitleHeader",
        "widgetId": "title_header_id",
        "text": "Page Title",
        "fontSize": "1.25rem",
        "fontStyle": "BOLD",
        "textColor": "#2B4570",
        "textAlign": "LEFT",
        "topRow": 1.0,
        "bottomRow": 4.0,
        "leftColumn": 1.0,
        "rightColumn": 40.0
      },
      {
        "type": "TEXT_WIDGET",
        "widgetName": "WelcomeText",
        "widgetId": "welcome_text_id",
        "text": "Welcome {{appsmith.user.name || appsmith.user.email || 'User'}}",
        "fontSize": "0.875rem",
        "textColor": "#6B7280",
        "textAlign": "LEFT",
        "topRow": 4.0,
        "bottomRow": 7.0,
        "leftColumn": 1.0,
        "rightColumn": 40.0,
        "dynamicBindingPathList": [
          {"key": "text"}
        ]
      },
      {
        "type": "MENU_BUTTON_WIDGET",
        "widgetName": "MenuButton1",
        "widgetId": "menu_button_id",
        "topRow": 2.0,
        "bottomRow": 6.0,
        "leftColumn": 55.0,
        "rightColumn": 63.0,
        "sourceData": "{{appsmith.store.user?.menu || []}}",
        "menuItemsSource": "DYNAMIC",
        "iconName": "menu",
        "menuVariant": "TERTIARY",
        "configureMenuItems": {
          "config": {
            "onClick": "{{navigateTo(currentItem.page, {}, 'SAME_WINDOW')}}",
            "label": "{{MenuButton1.sourceData.map(item => item.label)}}",
            "iconName": "{{MenuButton1.sourceData.map(item => item.icon)}}"
          }
        },
        "dynamicBindingPathList": [
          {"key": "sourceData"},
          {"key": "configureMenuItems.config.label"},
          {"key": "configureMenuItems.config.iconName"},
          {"key": "menuColor"}
        ],
        "dynamicTriggerPathList": [
          {"key": "configureMenuItems.config.onClick"}
        ]
      }
    ]
  }]
}
```

## Welcome Text Pattern

**IMPORTANT:** Use `appsmith.user` (built-in, always available) for the welcome message, NOT `appsmith.store.user` which requires JSInit to run first.

```javascript
// CORRECT: Uses built-in appsmith.user object (always available)
"Welcome {{appsmith.user.name || appsmith.user.email || 'User'}}"

// With i18n
"{{JSi18n.t('welcome', {name: appsmith.user.name || appsmith.user.email})}}"
```

`appsmith.user` is populated automatically by Appsmith/UIB. `appsmith.store.user` requires JSInit to execute successfully and is populated from the custom `userQuery` API.

### When to Use Each

| Source | Availability | Contains |
|--------|-------------|----------|
| `appsmith.user` | Always (built-in) | `name`, `email`, basic auth info |
| `appsmith.store.user` | After JSInit | `user_name`, `isPBUser`, `isPBAdministrator`, `menu` |

Use `appsmith.user` for the welcome text. Use `appsmith.store.user` for menu data and Bonita-specific user properties.

## User API Response Format

The `userQuery` API returns:

```json
{
  "user_id": "123",
  "user_name": "john.doe",
  "isPBUser": true,
  "isPBAdministrator": false,
  "menu": [
    {"id": "home", "label": "Home page", "icon": "home", "page": "../process-builder/home"},
    {"id": "dashboard", "label": "Dashboard", "icon": "dashboard", "page": "../kpi-dashboard/dashboard"},
    {"id": "logout", "label": "Log out", "icon": "log-out", "page": "/bonita/logoutservice"}
  ]
}
```

## Dynamic Navigation with MENU_BUTTON_WIDGET

### Full Configuration

```json
{
  "type": "MENU_BUTTON_WIDGET",
  "widgetName": "MenuButton1",
  "sourceData": "{{appsmith.store.user?.menu || []}}",
  "menuItemsSource": "DYNAMIC",
  "iconName": "menu",
  "menuVariant": "TERTIARY",
  "configureMenuItems": {
    "config": {
      "onClick": "{{navigateTo(currentItem.page, {}, 'SAME_WINDOW')}}",
      "label": "{{MenuButton1.sourceData.map(item => item.label)}}",
      "iconName": "{{MenuButton1.sourceData.map(item => item.icon)}}"
    }
  },
  "dynamicBindingPathList": [
    {"key": "sourceData"},
    {"key": "configureMenuItems.config.label"},
    {"key": "configureMenuItems.config.iconName"},
    {"key": "menuColor"}
  ],
  "dynamicTriggerPathList": [
    {"key": "configureMenuItems.config.onClick"}
  ]
}
```

### Menu Item Data Structure

```json
{
  "id": "home",
  "label": "Home page",
  "icon": "home",
  "page": "../process-builder/home"
}
```

### Common Menu Icons

| Icon Name | Use Case |
|-----------|----------|
| `home` | Home page |
| `dashboard` | Dashboard |
| `log-out` | Logout |
| `settings` | Settings |
| `user` | User profile |
| `chart-pie` | Analytics |

### Navigation Patterns

```javascript
// Same window navigation
"{{navigateTo(currentItem.page, {}, 'SAME_WINDOW')}}"

// New window navigation
"{{navigateTo(currentItem.page, {}, 'NEW_WINDOW')}}"

// With query parameters
"{{navigateTo(currentItem.page, {processId: appsmith.store.selectedId}, 'SAME_WINDOW')}}"
```
