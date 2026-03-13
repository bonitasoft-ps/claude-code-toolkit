---
name: bonita-extension-manager
description: |
  Managing Bonita project extensions: adding connectors, actor filters, REST API extensions, custom pages,
  and third-party libraries. Covers dependency management, version updates, pom.xml configuration,
  Bonita Studio import, and process-builder project integration.
  Keywords: extension, connector, actor filter, REST API, custom page, dependency, pom.xml, import, library, version
allowed-tools: Read, Write, Grep, Glob, Bash, Edit
user-invocable: true
---

# Bonita Extension Manager

Expert in managing extensions within Bonita projects. Handles the full lifecycle of adding, updating, and removing connectors, actor filters, REST API extensions, and libraries.

## When activated

1. **Identify extension type**: Connector, Actor Filter, REST API Extension, Custom Page, or Library
2. **Check project type**: Is it a process-builder project (app/pom.xml) or standalone?
3. **Find current dependencies**: Read pom.xml to understand existing extensions
4. **Determine action**: Add new, update version, remove, or troubleshoot

---

## Adding a New Connector to a Process-Builder Project

### What to ask the user

1. Connector artifact coordinates (groupId, artifactId, version)
2. Does the connector produce a fat JAR (-bonita classifier)?
3. Which process(es) will use the connector?

### Steps

1. **Add dependency to app/pom.xml:**
```xml
<dependency>
  <groupId>com.bonitasoft.connectors</groupId>
  <artifactId>bonita-connector-myservice-all</artifactId>
  <version>1.0.0</version>
  <classifier>bonita</classifier>
  <scope>compile</scope>
</dependency>
```

2. **Build the project:**
```bash
mvn clean install -DskipTests
```

3. **Verify the connector is available:**
   - Open Bonita Studio
   - Go to a ServiceTask > Connectors
   - The new connector category should appear

### Key Rules
- Use `classifier=bonita` for fat JARs (shade plugin output)
- Use `scope=compile` (not provided, not test)
- If the connector has NO fat JAR, add it without classifier (all transitive deps must be compatible)
- Check for dependency conflicts with `mvn dependency:tree`

---

## Adding a New Library (Third-Party JAR)

### What to ask the user

1. Library coordinates (groupId, artifactId, version)
2. Purpose: used in connector? REST API extension? Groovy script?
3. Any known conflicts with Bonita runtime?

### Steps

1. **Check for conflicts:**
```bash
mvn dependency:tree | grep -i "library-name"
```

2. **Add to pom.xml:**
```xml
<dependency>
  <groupId>com.example</groupId>
  <artifactId>my-library</artifactId>
  <version>2.0.0</version>
</dependency>
```

3. **Handle conflicts with exclusions if needed:**
```xml
<dependency>
  <groupId>com.example</groupId>
  <artifactId>my-library</artifactId>
  <version>2.0.0</version>
  <exclusions>
    <exclusion>
      <groupId>javax.activation</groupId>
      <artifactId>activation</artifactId>
    </exclusion>
  </exclusions>
</dependency>
```

### Common Conflicts with Bonita Runtime
- `javax.mail` / `jakarta.mail` — Bonita provides its own
- `javax.activation` — provided by runtime
- `org.slf4j:*` — provided by runtime (NEVER include in fat JAR)
- `org.bonitasoft.engine:*` — provided by runtime
- `com.fasterxml.jackson.*` — version must match Bonita's
- `commons-io` / `commons-lang3` — check version compatibility

---

## Updating a Connector Version

### What to check BEFORE updating

1. **Read current pom.xml** — find the existing version
2. **Check changelog** — any breaking changes? API changes?
3. **Check .proc files** — do any processes use this connector?
4. **Check .def changes** — have inputs/outputs changed between versions?

### Steps

1. **Update version in pom.xml**
2. **Build:** `mvn clean install -DskipTests`
3. **If .def changed (new inputs/outputs):**
   - Update .proc files that reference the connector
   - Add new ConnectorParameter entries for new inputs
   - Update output mappings if outputs changed
4. **If definitionVersion changed:**
   - Update `definitionVersion` in .proc connector references
   - Update `definitionMappings` in configuration section
   - Update `processDependencies` in configuration section
5. **Test:** Run integration tests

### When .def Version Changes (BREAKING)

If the connector's .def version changes (e.g., 1.0.0 → 2.0.0):

In EVERY .proc file that uses this connector:
```xml
<!-- Update connector reference -->
<connectors definitionId="my-connector" definitionVersion="2.0.0" ...>

<!-- Update configuration -->
<configuration definitionId="my-connector" version="2.0.0">

<!-- Update definitionMappings -->
<definitionMappings definitionId="my-connector" definitionVersion="2.0.0"
  implementationId="my-connector-impl" implementationVersion="2.0.0"/>

<!-- Update processDependencies -->
<processDependencies definitionId="my-connector" definitionVersion="2.0.0">
```

---

## Updating a Library Version

### What to check

1. **Dependency tree impact:** `mvn dependency:tree`
2. **Transitive dependency changes:** new transitives may conflict
3. **API compatibility:** check if methods/classes used still exist
4. **Connector fat JARs:** if the library is inside a connector's fat JAR, update the connector instead

### Steps

1. Update version in pom.xml
2. `mvn clean install -DskipTests`
3. Check for compilation errors
4. Run tests: `mvn test`
5. If the library is used in Groovy scripts inside .proc files, verify the scripts still work

---

## Adding an Actor Filter

### What to ask
1. Filter artifact coordinates
2. Which actor(s) will use it?
3. Filter configuration parameters

### Steps
1. Add dependency to pom.xml (same pattern as connector)
2. In .proc file, add filter to the actor definition:
```xml
<actors name="Employee actor">
  <filteredBy xmi:type="process:ActorFilter"
    definitionId="my-filter" definitionVersion="1.0.0"
    name="My Filter">
    <configuration ...>
      <parameters key="filterParam">
        <value xmi:type="expression:Expression" .../>
      </parameters>
    </configuration>
  </filteredBy>
</actors>
```

---

## Adding a REST API Extension

### What to ask
1. Extension artifact coordinates
2. What REST endpoints does it expose?
3. Permission requirements?

### Steps
1. Add dependency to pom.xml:
```xml
<dependency>
  <groupId>com.company</groupId>
  <artifactId>my-rest-extension</artifactId>
  <version>1.0.0</version>
  <type>zip</type>
</dependency>
```
2. Note: REST API extensions use `type=zip` not `classifier=bonita`
3. Build and deploy

---

## Removing an Extension

### Checklist before removal
1. Search all .proc files for references: `grep -r "definitionId=\"my-connector\"" app/diagrams/`
2. Remove from ALL .proc files:
   - Remove `<connectors>` elements
   - Remove `<definitionMappings>` entries
   - Remove `<processDependencies>` entries
3. Remove from pom.xml
4. Build to verify: `mvn clean install -DskipTests`

---

## Troubleshooting

### "Connector not found" after import
- Check classifier=bonita in pom.xml
- Verify .def and .impl are at JAR root: `jar tf *.jar | grep -E '\.(def|impl)$'`
- Check category ID matches what you're searching for

### "Class not found" at runtime
- Check shade plugin excludes — the class may be in an excluded group
- Verify the fat JAR contains the class: `jar tf *.jar | grep MyClass`
- Check for duplicate JARs with conflicting versions

### Dependency conflicts
```bash
mvn dependency:tree -Dverbose | grep "conflict"
mvn enforcer:enforce  # if enforcer plugin is configured
```

### .proc file corrupted after manual edit
- Validate XML: all tags properly closed, all xmi:id unique
- Check namespace declarations at root
- Verify all href paths are valid (@elements indexes)
- Re-import in Bonita Studio to regenerate notation if needed
