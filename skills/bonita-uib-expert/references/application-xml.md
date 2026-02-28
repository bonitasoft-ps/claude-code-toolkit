# Bonita Application XML Creation

## Overview

Each Bonita application is defined in a **separate XML file** in `app/applications/` with the naming convention `app{ApplicationName}.xml`.

**IMPORTANT:** Use full `application` definition. Do NOT use `applicationLink`.

## Basic Structure

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<applications xmlns="http://documentation.bonitasoft.com/application-xml-schema/1.1">
    <application homePage="dashboard" layout="custompage_layoutBonita" theme="custompage_themeBonita"
                 token="my-app-token" version="1.0" profile="User" state="ACTIVATED">
        <displayName>Application Display Name</displayName>
        <description>Application description here</description>
        <applicationPages>
            <applicationPage customPage="custompage_PageName" token="page-token"/>
        </applicationPages>
        <applicationMenus>
            <applicationMenu applicationPage="page-token">
                <displayName>Menu Item Label</displayName>
            </applicationMenu>
        </applicationMenus>
    </application>
</applications>
```

## Key Attributes

| Attribute | Description | Example |
|-----------|-------------|---------|
| `homePage` | Token of the default page | `dashboard` |
| `layout` | Layout page to use | `custompage_layoutBonita` |
| `theme` | Theme to use | `custompage_themeBonita` |
| `token` | Unique URL identifier for the app | `kpi-dashboard` |
| `version` | Application version | `1.0` |
| `profile` | User profile required for access | `User` or `Administrator` |
| `state` | Application state | `ACTIVATED` or `DEACTIVATED` |

## Page References

### customPage attribute

Must use the prefix `custompage_` followed by the page folder name:

```xml
<applicationPage customPage="custompage_KpiDashboard" token="dashboard"/>
```

The `custompage_` prefix is **mandatory**. The page name after the prefix must match the folder name in `app/web_page/`.

### token attribute

URL-friendly identifier for the page within the application:

```xml
<applicationPage customPage="custompage_KpiDashboard" token="dashboard"/>
<applicationPage customPage="custompage_KpiUserRanking" token="user-ranking"/>
```

The `homePage` attribute in the `<application>` element must match one of these tokens.

## applicationMenus

Define navigation menu items that appear in the application layout:

```xml
<applicationMenus>
    <applicationMenu applicationPage="dashboard">
        <displayName>Dashboard</displayName>
    </applicationMenu>
    <applicationMenu applicationPage="process-analysis">
        <displayName>Process Analysis</displayName>
    </applicationMenu>
    <applicationMenu applicationPage="user-ranking">
        <displayName>User Ranking</displayName>
    </applicationMenu>
</applicationMenus>
```

The `applicationPage` attribute must reference a valid page token defined in `<applicationPages>`.

## Complete Example

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<applications xmlns="http://documentation.bonitasoft.com/application-xml-schema/1.1">
    <application homePage="dashboard" layout="custompage_layoutBonita" theme="custompage_themeBonita"
                 token="kpi-dashboard" version="1.0" profile="User" state="ACTIVATED">
        <displayName>KPI Dashboard</displayName>
        <description>Performance metrics and analytics dashboard</description>
        <applicationPages>
            <applicationPage customPage="custompage_KpiDashboard" token="dashboard"/>
            <applicationPage customPage="custompage_KpiProcessAnalysis" token="process-analysis"/>
            <applicationPage customPage="custompage_KpiUserRanking" token="user-ranking"/>
        </applicationPages>
        <applicationMenus>
            <applicationMenu applicationPage="dashboard">
                <displayName>Dashboard</displayName>
            </applicationMenu>
            <applicationMenu applicationPage="process-analysis">
                <displayName>Process Analysis</displayName>
            </applicationMenu>
            <applicationMenu applicationPage="user-ranking">
                <displayName>User Ranking</displayName>
            </applicationMenu>
        </applicationMenus>
    </application>
</applications>
```

## File Structure Convention

```
app/
  applications/
    appKpiDashboard.xml          # Application descriptor
  web_page/
    KpiDashboard/
      KpiDashboard.json          # Page definition (name must match folder)
      assets/
        css/style.css            # Page styles
        json/localization.json   # Localization data
    KpiUserRanking/
      KpiUserRanking.json
    KpiProcessAnalysis/
      KpiProcessAnalysis.json
```

> See `naming-conventions.md` for complete naming rules (application XML, page folders, page JSON, customPage references).

## Multiple Applications

Each application gets its own XML file. Do NOT put multiple applications in the same file:

```
app/applications/
  appProcessBuilder.xml       # Main application
  appKpiDashboard.xml         # Dashboard application
  appAdminPanel.xml           # Admin panel application
```

## Profile-Based Access Control

Use the `profile` attribute to control who can access the application:

```xml
<!-- Accessible by regular users -->
<application ... profile="User" state="ACTIVATED">

<!-- Accessible only by administrators -->
<application ... profile="Administrator" state="ACTIVATED">
```

## Application States

| State | Description |
|-------|-------------|
| `ACTIVATED` | Application is live and accessible |
| `DEACTIVATED` | Application exists but is not accessible |

Use `DEACTIVATED` during development or maintenance periods.
