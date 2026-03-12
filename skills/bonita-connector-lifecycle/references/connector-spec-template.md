# Connector Specification Template

## JSON Spec Structure (for create_connector_spec MCP tool)

```json
{
  "name": "connector-name",
  "type": "connector|actorFilter|eventHandler",
  "description": "What it does",
  "bonitaVersion": "2024.1",
  "protocol": "REST|SOAP|JDBC|LDAP|custom",
  "inputs": [
    {"name": "url", "type": "STRING", "required": true, "description": "Endpoint URL"},
    {"name": "timeout", "type": "INTEGER", "required": false, "description": "Timeout in ms", "defaultValue": "30000"}
  ],
  "outputs": [
    {"name": "response", "type": "STRING", "description": "API response body"},
    {"name": "statusCode", "type": "INTEGER", "description": "HTTP status code"}
  ],
  "errorHandling": {
    "retry": true,
    "maxRetries": 3,
    "fallback": "Return error message"
  }
}
```

## Connector Definition XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<definition:ConnectorDefinition xmlns:definition="http://www.bonitasoft.org/ns/connector/definition/6.1"
    id="${connector-id}" version="1.0.0" icon="connector.png">
    <input name="url" type="java.lang.String" mandatory="true"/>
    <input name="timeout" type="java.lang.Integer" mandatory="false" defaultValue="30000"/>
    <output name="response" type="java.lang.String"/>
    <output name="statusCode" type="java.lang.Integer"/>
    <page id="connectionPage">
        <widget id="urlWidget" inputName="url" xsi:type="definition:Text"/>
        <widget id="timeoutWidget" inputName="timeout" xsi:type="definition:Text"/>
    </page>
</definition:ConnectorDefinition>
```
