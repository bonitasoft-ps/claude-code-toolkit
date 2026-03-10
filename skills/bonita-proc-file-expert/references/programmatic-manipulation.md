# .proc File Programmatic Manipulation

Advanced patterns for creating, cloning, and modifying `.proc` files programmatically.

## Critical Rule: Never Use XML Serializers

**NEVER** use `xml.etree.ElementTree.write()`, `lxml.tostring()`, or any XML serializer to save .proc files. They destroy EMF/XMI namespace prefixes which makes the file unreadable by Bonita Studio.

**ALWAYS** use raw string manipulation:

```python
# CORRECT
with open(proc_file, 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('old_text', 'new_text')
with open(proc_file, 'w', encoding='utf-8') as f:
    f.write(content)

# WRONG — destroys namespaces
tree = ET.parse(proc_file)
tree.write(proc_file)  # NEVER DO THIS
```

`ET.parse()` is safe for **read-only validation** only.

## Generating Unique IDs

```python
import uuid
new_id = f"_{uuid.uuid4().hex[:22]}"  # Format: _<22 hex chars>
```

## Adding Elements

### ServiceTask with Connector

```xml
<elements xsi:type="process:ServiceTask" xmi:id="_TASK_ID" name="Task Name">
    <dynamicLabel xmi:id="_DL_ID" xsi:type="expression:Expression"
        name="" content="" returnType="java.lang.String"
        returnTypeFixed="true" type="TYPE_CONSTANT"/>
    <connectors xmi:id="_CONN_ID" definitionId="connector-def-id"
        definitionVersion="1.0.0" event="ON_ENTER" name="Connector Name">
        <configuration xmi:id="_CFG_ID"
            xsi:type="connectorconfiguration:ConnectorConfiguration"
            definitionId="connector-def-id" version="1.0.0">
            <parameters xmi:id="_PARAM_ID" key="inputParamName">
                <expression xmi:id="_EXPR_ID" xsi:type="expression:Expression"
                    name="value" content="value"
                    returnType="java.lang.String" type="TYPE_CONSTANT"/>
            </parameters>
        </configuration>
    </connectors>
</elements>
```

### Sequence Flow

Connections go **outside the Lane** but **inside the Pool**:

```xml
<connections xmi:id="_CONN_ID" xsi:type="process:SequenceFlow"
    name="" source="_sourceElementId" target="_targetElementId">
    <decisionTable xmi:id="_DT_ID" xsi:type="decision:DecisionTable"/>
    <condition xmi:id="_COND_ID" xsi:type="expression:Expression"
        name="" content="" returnType="java.lang.Boolean"
        returnTypeFixed="true" type="TYPE_CONSTANT"/>
</connections>
```

### Business Variable (BDM)

```xml
<data xmi:id="_DATA_ID" xsi:type="process:BusinessObjectData"
    name="variableName" dataType="_datatypeRef"
    className="com.processbuilder.model.ClassName"
    businessDataRepositoryId="default">
    <defaultValue xmi:id="_DEF_ID" xsi:type="expression:Expression"
        name="" content="" returnType="com.processbuilder.model.ClassName"
        returnTypeFixed="true" type="TYPE_CONSTANT"/>
</data>
```

## Removing Elements

```python
import re

def remove_element_block(content, pattern):
    """Remove XML element block matching regex pattern."""
    match = re.search(pattern, content)
    if not match:
        return content
    start = match.start()
    tag_match = re.match(r'<(\w+)', match.group())
    tag = tag_match.group(1)
    depth, i = 0, start
    while i < len(content):
        if content[i:].startswith(f'<{tag} ') or content[i:].startswith(f'<{tag}>'):
            depth += 1
        elif content[i:].startswith(f'</{tag}>'):
            depth -= 1
            if depth == 0:
                end = i + len(f'</{tag}>')
                return content[:start] + content[end:]
        i += 1
    return content
```

## Notation Section (Visual Layout)

### Shape Type Reference

| Type | BPMN Element |
|------|-------------|
| 2007 | Pool |
| 3007 | Lane |
| 3005 | Activity (Task/ServiceTask/CallActivity) |
| 3002 | Start Event |
| 3003 | End Event |
| 3008 | XOR Gateway |
| 3009 | AND Gateway |
| 7001 | Pool Decoration (label area) |
| 7002 | Pool Body (contains lanes) |
| 7003 | Lane Decoration (label area) |
| 7004 | Lane Body (contains shapes) |
| 4001 | Sequence Flow Edge |

### Best Practice: Replace Entire Notation Section

When making significant changes, **replace the entire `<notation:Diagram>` block** rather than surgically editing individual shapes.

```python
content = re.sub(
    r'<notation:Diagram[^>]*>.*?</notation:Diagram>',
    new_notation, content, flags=re.DOTALL
)
```

## Cloning a .proc File

```python
import re, uuid

def clone_proc(source_path, target_path, renames):
    with open(source_path, 'r', encoding='utf-8') as f:
        content = f.read()
    # 1. Replace ALL xmi:id values
    old_ids = set(re.findall(r'xmi:id="([^"]+)"', content))
    id_map = {old: f"_{uuid.uuid4().hex[:22]}" for old in old_ids}
    for old_id, new_id in id_map.items():
        content = content.replace(f'"{old_id}"', f'"{new_id}"')
    # 2. Apply name renames
    for old_name, new_name in renames.items():
        content = content.replace(f'name="{old_name}"', f'name="{new_name}"')
    # 3. Write and validate
    with open(target_path, 'w', encoding='utf-8') as f:
        f.write(content)
    import xml.etree.ElementTree as ET
    ET.parse(target_path)  # Read-only validation
```

## Configuration Section: Connector Mappings

When adding a new connector, register in ALL environment configurations:

```xml
<definitionMappings xmi:id="_MAP_ID" type="CONNECTOR"
    definitionId="connector-def-id" definitionVersion="1.0.0"
    implementationId="connector-impl-id" implementationVersion="1.0.0"/>
```

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Namespace prefixes lost | Use raw string manipulation only |
| New element not visible in Studio | Add notation shape with matching `element=` ref |
| Connector not found at runtime | Add `<definitionMappings>` in ALL config blocks |
| Clone has duplicate IDs | Use regex to find ALL IDs, replace systematically |
| Connection breaks after removal | Remove associated connections when removing elements |
