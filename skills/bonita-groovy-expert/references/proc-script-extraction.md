# Working with Scripts in .proc Files

Bonita process definitions are stored as `.proc` files in `app/diagrams/`. These files are XML documents (XMI format) with Groovy scripts embedded as escaped strings within `content` attributes.

## File Structure

Process files follow the XMI (XML Metadata Interchange) format. The namespace prefix `expression:` identifies expression elements that may contain Groovy code.

```
app/diagrams/
  Initialization-1.0.proc
  Process-1.0.proc
  PE_Notifications-1.0.proc
  MasterProcessExecutionOrchestrator-1.0.proc
  ...
```

## How Scripts Are Embedded

Scripts appear as `content` attributes on `expression:Expression` elements with `interpreter="GROOVY"`. The XML uses entity escaping for special characters:

| Escaped | Actual |
|---------|--------|
| `&#xD;&#xA;` | Newline (CRLF) |
| `&#x9;` | Tab |
| `&lt;` | `<` |
| `&gt;` | `>` |
| `&amp;` | `&` |
| `&quot;` | `"` |

### Real example from a .proc file

```xml
<rightOperand
    xmi:type="expression:Expression"
    xmi:id="_7Z7k4tDvEfCEp6ZFgh7glg"
    name="init_genericEntry()"
    content="import java.time.OffsetDateTime&#xD;&#xA;import org.slf4j.Logger&#xD;&#xA;..."
    interpreter="GROOVY"
    type="TYPE_READ_ONLY_SCRIPT"
    returnType="java.util.List">
  <referencedElements xmi:type="expression:Expression"
      name="processInstanceId" content="processInstanceId"
      type="TYPE_ENGINE_CONSTANT" returnType="java.lang.Long"/>
  <referencedElements xmi:type="expression:Expression"
      name="pBEntityTypeDAO" content="pBEntityTypeDAO"
      type="TYPE_BUSINESS_OBJECT_DAO"
      returnType="com.processbuilder.model.PBEntityTypeDAO"/>
  <referencedElements xmi:type="expression:Expression"
      name="apiAccessor" content="apiAccessor"
      type="TYPE_ENGINE_CONSTANT"
      returnType="com.bonitasoft.engine.api.APIAccessor"/>
</rightOperand>
```

### Key attributes on expression elements

| Attribute | Description |
|-----------|-------------|
| `name` | Human-readable script name (e.g., `init_genericEntry()`) |
| `content` | The actual Groovy source code (XML-escaped) |
| `interpreter` | Must be `"GROOVY"` for Groovy scripts |
| `type` | Expression type: `TYPE_READ_ONLY_SCRIPT`, `TYPE_CONSTANT`, `TYPE_VARIABLE`, `TYPE_ENGINE_CONSTANT`, `TYPE_BUSINESS_OBJECT_DAO` |
| `returnType` | Java return type (e.g., `java.util.List`, `java.lang.Boolean`) |

### Referenced elements (script dependencies)

Each script declares its dependencies via `<referencedElements>` child nodes. These tell the Bonita engine what variables/DAOs/constants the script needs at runtime:

| Type | Purpose | Example |
|------|---------|---------|
| `TYPE_ENGINE_CONSTANT` | Engine-provided values | `processInstanceId`, `apiAccessor`, `taskAssigneeId` |
| `TYPE_BUSINESS_OBJECT_DAO` | Typed DAO references | `pBProcessDAO`, `pBConfigurationDAO` |
| `TYPE_VARIABLE` | Process variables | Custom business variables |
| `TYPE_CONSTANT` | Hardcoded constants | String/number constants |

---

## Script Locations in Process Elements

### initProcess scripts (business variable initialization)

Location: Inside `<data>` elements at pool/process level, within `<defaultValue>` or as `<rightOperand>` in operations.

```xml
<elements xmi:type="process:Pool" name="MyProcess">
  <data xmi:type="process:BusinessObjectData" name="myBusinessVar">
    <defaultValue xmi:type="expression:Expression"
        name="initScript()" content="..." interpreter="GROOVY"
        type="TYPE_READ_ONLY_SCRIPT"/>
  </data>
</elements>
```

### Script tasks

Location: Inside `<elements>` of type `process:ScriptTask`.

```xml
<elements xmi:type="process:ScriptTask" name="Calculate Total">
  <dynamicLabel ... content="..." interpreter="GROOVY"/>
</elements>
```

### Connector input/output scripts

Location: Inside `<connectors>` elements, within `<configuration>` parameters.

```xml
<connectors xmi:type="process:Connector" name="sendEmail">
  <configuration>
    <parameters key="to">
      <expression xmi:type="expression:Expression" content="..."
          interpreter="GROOVY" type="TYPE_READ_ONLY_SCRIPT"/>
    </parameters>
  </configuration>
</connectors>
```

### Operations (variable assignments after tasks)

Location: Inside `<operations>` elements as `<rightOperand>`.

```xml
<operations xmi:type="expression:Operation">
  <rightOperand xmi:type="expression:Expression"
      name="updateStatus()" content="..."
      interpreter="GROOVY" type="TYPE_READ_ONLY_SCRIPT"/>
  <leftOperand xmi:type="expression:LeftOperand"
      name="myBusinessVar" type="BUSINESS_DATA"/>
  <operator xmi:type="expression:Operator"
      type="JAVA_METHOD" expression="setStatus"/>
</operations>
```

### Gateway conditions

Location: Inside `<connections>` of type `process:SequenceFlow`, as `<condition>`.

```xml
<connections xmi:type="process:SequenceFlow" name="approvedPath">
  <condition xmi:type="expression:Expression"
      name="isApproved" content="return status == &quot;APPROVED&quot;"
      interpreter="GROOVY" type="TYPE_READ_ONLY_SCRIPT"
      returnType="java.lang.Boolean"/>
</connections>
```

---

## Extracting Scripts Programmatically

### Python extraction script

```python
import xml.etree.ElementTree as ET
import html
import re
import sys


def extract_scripts(proc_file):
    """Extract all Groovy scripts from a .proc file."""
    tree = ET.parse(proc_file)
    root = tree.getroot()
    scripts = []

    for elem in root.iter():
        interpreter = elem.get('interpreter', '')
        content = elem.get('content', '')

        if interpreter == 'GROOVY' and content.strip():
            # Decode XML entities
            decoded = html.unescape(content)

            # Get parent element for context
            script_info = {
                'name': elem.get('name', 'unnamed'),
                'tag': elem.tag,
                'type': elem.get('type', ''),
                'return_type': elem.get('returnType', ''),
                'content': decoded,
                'line_count': len(decoded.strip().split('\n')),
            }

            # Collect referenced elements (dependencies)
            refs = []
            for ref in elem:
                ref_name = ref.get('name', '')
                ref_type = ref.get('type', '')
                if ref_name:
                    refs.append(f"{ref_name} ({ref_type})")
            script_info['references'] = refs

            scripts.append(script_info)

    return scripts


def print_scripts(scripts):
    """Print extracted scripts in a readable format."""
    for i, script in enumerate(scripts, 1):
        print(f"\n{'='*60}")
        print(f"Script #{i}: {script['name']}")
        print(f"Type: {script['type']}")
        print(f"Return: {script['return_type']}")
        print(f"Lines: {script['line_count']}")
        if script['references']:
            print(f"Dependencies: {', '.join(script['references'])}")
        print(f"{'='*60}")
        print(script['content'])


if __name__ == '__main__':
    proc_file = sys.argv[1] if len(sys.argv) > 1 else 'Process-1.0.proc'
    scripts = extract_scripts(proc_file)
    print(f"Found {len(scripts)} Groovy scripts in {proc_file}")
    print_scripts(scripts)
```

### Using grep to quickly find scripts (from terminal)

```bash
# Find all elements with interpreter="GROOVY" and non-empty content
grep -oP 'name="[^"]*".*?interpreter="GROOVY"' app/diagrams/Process-1.0.proc

# Count Groovy scripts per .proc file
for f in app/diagrams/*.proc; do
    count=$(grep -c 'interpreter="GROOVY"' "$f" 2>/dev/null || echo 0)
    echo "$f: $count scripts"
done
```

### Using the Grep tool within Claude Code

```
# Find all Groovy script expressions in a specific process
Grep pattern: interpreter="GROOVY"
path: app/diagrams/Process-1.0.proc

# Find scripts that use a specific DAO
Grep pattern: content=".*pBProcessDAO.*"
path: app/diagrams/

# Find scripts that import extension library classes
Grep pattern: import com.bonitasoft.processbuilder
path: app/diagrams/
```

---

## Comparing Scripts Between Process Versions

When a process has multiple versions (e.g., `Process-1.0.proc` and `Process-1.1.proc`), compare scripts by:

1. **Extract scripts from both versions** using the Python script above
2. **Match by name**: Scripts with the same `name` attribute are the same logical script
3. **Diff the content**: Compare decoded content line by line

```bash
# Quick diff of all Groovy content between versions
python extract_scripts.py app/diagrams/Process-1.0.proc > v1_scripts.txt
python extract_scripts.py app/diagrams/Process-1.1.proc > v2_scripts.txt
diff v1_scripts.txt v2_scripts.txt
```

---

## Identifying Which Script Belongs to Which Task

Scripts do not directly carry their parent task name in their attributes. To determine ownership:

1. **Check the `name` attribute**: Convention is to name scripts after their purpose (e.g., `init_genericEntry()`, `updateStatus()`)
2. **Check the parent XML element**: The script is nested inside its owning element (pool, task, connector, sequence flow)
3. **Check referenced elements**: The `referencedElements` children reveal which DAOs and variables the script depends on, helping identify its context

### XML hierarchy for script ownership

```
Pool (process:Pool name="MyProcess")
  +-- data (business variable initialization)
  |     +-- defaultValue (expression:Expression -- INIT SCRIPT)
  +-- elements (process:Task name="Review Request")
  |     +-- operations (post-task operations)
  |     |     +-- rightOperand (expression:Expression -- OPERATION SCRIPT)
  |     +-- connectors (attached connectors)
  |           +-- configuration > parameters > expression -- CONNECTOR SCRIPT
  +-- connections (process:SequenceFlow)
        +-- condition (expression:Expression -- CONDITION SCRIPT)
```
