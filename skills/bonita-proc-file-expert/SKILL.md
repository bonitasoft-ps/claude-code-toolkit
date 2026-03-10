---
name: bonita-proc-file-expert
description: |
  Expert in reading, analyzing, modifying, and programmatically generating Bonita .proc files (EMF/XMI XML).
  Covers namespaces, pool-level connectors, output mappings, Groovy scripts in XML,
  expression types, transaction boundaries, notation sections, cloning, and element manipulation.
  Keywords: .proc, XML, EMF, XMI, connector, ON_FINISH, output mapping, Groovy, transaction, pool, notation, clone
allowed-tools: Read, Write, Grep, Glob, Bash
user-invocable: true
---

# Bonita .proc File Expert

Deep expertise on Bonita process definition files (`.proc`), which use EMF/XMI XML format.

## When activated

1. **Read the .proc file** — understand the full XML structure
2. **Identify namespaces** — verify all required EMF/XMI namespaces are present
3. **Map the structure** — pools > lanes > elements > connectors > expressions
4. **Analyze connectors** — identify ON_FINISH, output mappings, scripts, transaction risks

---

## .proc File Anatomy

### Required Namespaces

```xml
<xmi:XMI xmlns:xmi="http://www.omg.org/XMI"
    xmlns:notation="http://www.eclipse.org/gmf/runtime/1.0.3/notation"
    xmlns:process="http://www.bonitasoft.org/ns/bpm/process"
    xmlns:expression="http://www.bonitasoft.org/ns/bpm/expression"
    xmlns:actormapping="http://www.bonitasoft.org/ns/actormapping/6.0"
    xmlns:configuration="http://www.bonitasoft.org/ns/bpm/configuration"
    xmlns:connectorconfiguration="http://www.bonitasoft.org/ns/connector/configuration"
    xmlns:parameter="http://www.bonitasoft.org/ns/bpm/parameter">
```

### Document Structure

```
xmi:XMI
├── notation:Diagram          — visual layout (GMF notation)
├── process:MainProcess       — the root process container
│   ├── elements (Pool)       — each pool is a separate process
│   │   ├── data              — process variables (BDM references, etc.)
│   │   ├── connectors        — pool-level connectors (ON_FINISH, ON_ENTER)
│   │   ├── elements (Lane)
│   │   │   └── elements      — tasks, gateways, events
│   │   │       └── connectors — activity-level connectors
│   │   ├── connections        — sequence flows
│   │   └── actors             — actor definitions
│   └── datatypes              — data type definitions
├── actormapping:ActorMappingsType
├── configuration:Configuration
└── parameter:Parameters (optional)
```

---

## Connector Configuration in .proc

### Connector Element

```xml
<connectors xmi:type="process:Connector"
    xmi:id="_uniqueId"
    name="myConnector"
    definitionId="scripting-groovy-script"
    event="ON_FINISH"
    definitionVersion="1.0.1">
    <configuration>...</configuration>
    <outputs>...</outputs>
</connectors>
```

### Key Attributes

| Attribute | Description |
|-----------|-------------|
| `name` | Human-readable connector name |
| `definitionId` | Connector type (e.g., `scripting-groovy-script`, `email`, `rest-get`) |
| `definitionVersion` | Connector definition version |
| `event` | When it fires: `ON_FINISH`, `ON_ENTER` |

### Event Types

| Event | When | Use case |
|-------|------|----------|
| `ON_FINISH` | After the element completes | Post-processing, cleanup, notifications |
| `ON_ENTER` | When the element starts | Initialization, data loading |

### Configuration Block

```xml
<configuration xmi:type="connectorconfiguration:ConnectorConfiguration"
    definitionId="scripting-groovy-script" version="1.0.1">
    <parameters key="script">
        <value xmi:type="expression:Expression" name="script"
            content="return null"
            interpreter="GROOVY"
            type="TYPE_READ_ONLY_SCRIPT"
            returnType="java.lang.Object"
            returnTypeFixed="true"/>
    </parameters>
</configuration>
```

### Output Mapping Block

```xml
<outputs xmi:type="expression:Operation" operatorType="ASSIGNMENT">
    <leftOperand xmi:type="expression:Expression" name="myVariable"
        content="myVariable"
        type="TYPE_VARIABLE"
        returnType="com.company.model.MyEntity">
        <referencedElements xmi:type="process:BusinessObjectData"
            name="myVariable"
            dataType="..."/>
    </leftOperand>
    <rightOperand xmi:type="expression:Expression" name="outputScript"
        content="// Groovy script here (XML-encoded)&#xA;return myVariable"
        interpreter="GROOVY"
        type="TYPE_READ_ONLY_SCRIPT"
        returnType="com.company.model.MyEntity">
        <referencedElements .../>
    </rightOperand>
</outputs>
```

---

## Expression Types

| Type | Usage |
|------|-------|
| `TYPE_READ_ONLY_SCRIPT` | Groovy script (content = script code, XML-encoded) |
| `TYPE_CONSTANT` | Static value (content = the value) |
| `TYPE_VARIABLE` | Reference to a process variable |
| `TYPE_PATTERN` | String pattern with ${} placeholders |
| `TYPE_PARAMETER` | Reference to a process parameter |

### Groovy in XML Encoding

Groovy scripts in `.proc` files are XML-encoded:

| Character | XML Encoding |
|-----------|-------------|
| `<` | `&lt;` |
| `>` | `&gt;` |
| `&` | `&amp;` |
| `"` | `&quot;` |
| newline | `&#xA;` |

---

## Pool-Level Connector Execution

### Mandatory Rule: Sequential Execution in XML Order

Pool-level connectors execute **sequentially in the order they appear in the XML document**. This is critical for understanding execution flow.

```xml
<elements xmi:type="process:Pool" name="MyProcess">
    <!-- Connector 1 executes FIRST -->
    <connectors name="calculateData" event="ON_FINISH">...</connectors>
    <!-- Connector 2 executes SECOND -->
    <connectors name="sendNotification" event="ON_FINISH">...</connectors>
</elements>
```

### Transaction Boundaries

**Each pool-level ON_FINISH connector executes in its own database transaction.**

- Connector 1 output mapping → TX1 commits
- Connector 2 output mapping → TX2 commits
- If TX2 fails, TX1 changes are already committed and safe

This is the foundation for the **two-connector pattern**.

---

## Pattern: Two-Connector Fix for Self-Destructive Operations

### Problem

When a connector cancels its own root process instance, the cascade cancellation destroys the connector_instance row before the output mapping transaction can commit. This causes:
- `SConnectorInstanceNotFoundException` — connector instance deleted mid-transaction
- `Deadlock on CONNECTOR_INSTANCE` — race between cascade and output mapping

### Solution

Split into two sequential connectors:

```xml
<!-- Connector 1: Persist BDM data (TX1 — safe, commits before connector 2) -->
<connectors name="persistData" event="ON_FINISH" definitionId="scripting-groovy-script">
    <configuration>
        <!-- Minimal script that returns null -->
    </configuration>
    <outputs>
        <!-- Output mapping calculates and persists BDM changes -->
        <!-- TX1 commits successfully -->
    </outputs>
</connectors>

<!-- Connector 2: Destructive action (TX2 — may fail, but data is safe) -->
<connectors name="cancelProcess" event="ON_FINISH" definitionId="scripting-groovy-script">
    <configuration>
        <!-- Script that calls cancelProcessInstance() -->
    </configuration>
    <!-- NO output mapping — TX2 may be destroyed by cascade -->
</connectors>
```

### Why This Works

1. Connector 1 runs in TX1 → output mapping persists BDM → TX1 commits
2. Connector 2 runs in TX2 → calls cancelProcessInstance()
3. Cascade cancellation destroys connector 2's instance → TX2 fails
4. BDM data from TX1 is safe (already committed)

---

## Common Modifications

### Adding a New Pool-Level Connector

1. Create a `<connectors>` element inside the pool `<elements>`
2. Generate a unique `xmi:id` (format: `_randomAlphanumericId`)
3. Set `definitionId`, `definitionVersion`, `event`, `name`
4. Add `<configuration>` with required parameters
5. Add `<outputs>` if BDM writes are needed
6. **Position matters**: place before/after existing connectors based on execution order

### Removing an Output Mapping

Remove the entire `<outputs>` element from the connector. The connector will still execute its script but won't write results back.

### Modifying a Groovy Script

Edit the `content` attribute of the `<value>` or `<rightOperand>` expression. Remember to XML-encode the Groovy code.

---

## Validation Checklist

- [ ] All `xmi:id` values are unique within the document
- [ ] Namespace declarations are complete
- [ ] Connector `definitionId` matches an available connector definition
- [ ] Expression `type` matches the expected usage (script vs constant vs variable)
- [ ] Groovy scripts are properly XML-encoded (no raw `<`, `>`, `&`)
- [ ] `referencedElements` point to valid data declarations
- [ ] Pool-level connector order matches intended execution sequence
- [ ] No output mappings on connectors that trigger self-destructive cascade
