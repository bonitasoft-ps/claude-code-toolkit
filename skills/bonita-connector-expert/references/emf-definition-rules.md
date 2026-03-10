# EMF ConnectorDefinition Rules (.def files)

These rules are MANDATORY. Violations cause `eResource() null` errors in Bonita Studio,
preventing the connector from being recognized.

## Namespace

```xml
<definition:ConnectorDefinition
    xmlns:definition="http://www.bonitasoft.org/ns/connector/definition/6.1"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
```

Namespace MUST be `definition/6.1`. Do NOT use `6.0`.

## Rule 1: No `<label>` or `<description>` Child Elements

The EMF model does NOT support `<label>` or `<description>` as child elements of any element.
All display text goes in the companion `.properties` file.

```xml
<!-- WRONG — causes eResource() null -->
<category icon="connector.png" id="my-category">
    <label>My Category</label>
</category>

<!-- CORRECT -->
<category icon="connector.png" id="my-category"/>
```

```properties
# In .properties file:
my-category.category=My Category
```

## Rule 2: `<category>` Must Be Self-Closing

```xml
<!-- WRONG -->
<category icon="connector.png" id="my-cat">
</category>

<!-- CORRECT -->
<category icon="connector.png" id="my-cat"/>
```

## Rule 3: `inputName` is a Widget ATTRIBUTE

```xml
<!-- WRONG — causes EMF parse failure -->
<widget xsi:type="definition:Text" id="myWidget">
    <inputName>myParam</inputName>
</widget>

<!-- CORRECT -->
<widget xsi:type="definition:Text" id="myWidget" inputName="myParam"/>
```

## Rule 4: No Labels in Widgets or Pages

```xml
<!-- WRONG -->
<page id="connectionPage">
    <label>Connection Settings</label>
    <widget xsi:type="definition:Text" id="urlWidget" inputName="url">
        <label>URL</label>
        <description>Enter the API URL</description>
    </widget>
</page>

<!-- CORRECT -->
<page id="connectionPage">
    <widget xsi:type="definition:Text" id="urlWidget" inputName="url"/>
</page>
```

```properties
# In .properties file:
connectionPage.pageTitle=Connection Settings
urlWidget.label=URL
urlWidget.description=Enter the API URL
```

## Widget Types

| xsi:type | Use case |
|----------|----------|
| `definition:Text` | Plain text input |
| `definition:Password` | Masked input (credentials, API keys) |
| `definition:TextArea` | Multi-line text (JSON, descriptions) |
| `definition:Checkbox` | Boolean toggle |
| `definition:Array` | List/collection input |
| `definition:Select` | Dropdown selection |

## Java Types for Input/Output

| Type | Use case |
|------|----------|
| `java.lang.String` | Text, JSON, Base64 content |
| `java.lang.Boolean` | Flags, success indicator |
| `java.lang.Integer` | Counts, timeouts, ports |
| `java.lang.Long` | File sizes, timestamps |
| `java.util.Map` | Key-value pairs, metadata |
| `java.util.List` | Collections, search results |

## Properties Key Convention

```properties
# Connector-level (REQUIRED)
connectorDefinitionLabel=Display Name
connectorDefinitionDescription=Description text

# Category (REQUIRED)
{categoryId}.category=Category Display Name

# Pages (one per <page>)
{pageId}.pageTitle=Page Title

# Widgets (one per <widget>)
{widgetId}.label=Widget Label
{widgetId}.description=Widget Help Text
```

## Complete Valid Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<definition:ConnectorDefinition
    xmlns:definition="http://www.bonitasoft.org/ns/connector/definition/6.1"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

    <id>myservice-upload</id>
    <version>1.0.0</version>
    <icon>connector.png</icon>

    <category icon="connector.png" id="my-service"/>

    <input name="apiKey" type="java.lang.String" mandatory="true"/>
    <input name="fileName" type="java.lang.String" mandatory="true"/>
    <input name="fileContent" type="java.lang.String" mandatory="true"/>

    <output name="success" type="java.lang.Boolean"/>
    <output name="errorMessage" type="java.lang.String"/>
    <output name="fileId" type="java.lang.String"/>

    <page id="connectionPage">
        <widget xsi:type="definition:Password" id="apiKeyWidget" inputName="apiKey"/>
    </page>
    <page id="uploadPage">
        <widget xsi:type="definition:Text" id="fileNameWidget" inputName="fileName"/>
        <widget xsi:type="definition:TextArea" id="fileContentWidget" inputName="fileContent"/>
    </page>
</definition:ConnectorDefinition>
```

```properties
connectorDefinitionLabel=My Service - Upload
connectorDefinitionDescription=Upload files to My Service.
my-service.category=My Service
connectionPage.pageTitle=Connection
apiKeyWidget.label=API Key
apiKeyWidget.description=Your API key from the service dashboard.
uploadPage.pageTitle=File Upload
fileNameWidget.label=File Name
fileNameWidget.description=Name for the uploaded file.
fileContentWidget.label=File Content (Base64)
fileContentWidget.description=Base64-encoded file content.
```
