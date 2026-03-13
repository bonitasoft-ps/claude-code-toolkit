---
name: bonita-version-upgrade
description: |
  Upgrading versions in Bonita projects: library updates, connector version bumps, Bonita runtime upgrades,
  Java version migration, dependency conflict resolution. Provides systematic upgrade workflows
  with pre-flight checks, impact analysis, and rollback strategies.
  Keywords: upgrade, version, update, migration, dependency, bump, library, runtime, Java
allowed-tools: Read, Write, Grep, Glob, Bash, Edit
user-invocable: true
---

# Bonita Version Upgrade Expert

Systematic approach to version upgrades in Bonita projects. Covers library updates, connector version bumps, runtime upgrades, and dependency conflict resolution.

## When activated

1. **Identify upgrade scope**: Single library? Connector? Bonita runtime? Java version?
2. **Pre-flight analysis**: Check current versions, dependency tree, .proc references
3. **Impact assessment**: What breaks? What needs updating?
4. **Execute upgrade**: Step by step with validation at each stage
5. **Post-upgrade verification**: Build, test, verify Studio import

---

## Pre-Flight Checklist (ALL upgrades)

Before any upgrade:

1. **Document current state:**
```bash
mvn dependency:tree > dependency-tree-before.txt
mvn versions:display-dependency-updates  # shows available updates
```

2. **Check for uncommitted changes:**
```bash
git status
git stash  # if needed
```

3. **Identify affected files:**
```bash
# Find all pom.xml files
find . -name "pom.xml" -not -path "*/target/*"

# Find .proc files that may reference connectors
find . -name "*.proc"
```

4. **Backup:**
```bash
git checkout -b upgrade/library-name-version
```

---

## Upgrade Type 1: Library Version Update

### Scope: Updating a third-party library (e.g., Google API, Apache Commons)

#### Steps

1. **Find current usage:**
```bash
grep -r "library-artifact-id" --include="pom.xml" .
```

2. **Check if library is inside a connector fat JAR:**
   - If YES: update the CONNECTOR's pom.xml, not the consumer project
   - If NO: update directly

3. **Update version in pom.xml:**
```xml
<!-- Before -->
<dependency>
  <groupId>com.google.apis</groupId>
  <artifactId>google-api-services-drive</artifactId>
  <version>v3-rev20240509-2.0.0</version>
</dependency>

<!-- After -->
<dependency>
  <groupId>com.google.apis</groupId>
  <artifactId>google-api-services-drive</artifactId>
  <version>v3-rev20250101-2.0.0</version>
</dependency>
```

4. **Check for transitive conflicts:**
```bash
mvn dependency:tree -Dverbose 2>&1 | grep "omitted for conflict"
```

5. **Build and test:**
```bash
mvn clean install -DskipTests  # compile first
mvn test                        # then test
```

6. **If in a multi-module project, rebuild the aggregator:**
```bash
mvn clean install -DskipTests -pl bonita-connector-myservice-all -am
```

7. **Verify fat JAR contents:**
```bash
jar tf target/*-bonita.jar | grep "library-name"
```

---

## Upgrade Type 2: Connector Version Update

### Scope: Updating a connector used in processes

#### Impact Analysis

```bash
# Find all .proc files using this connector
grep -rl "definitionId=\"connector-id\"" app/diagrams/

# Check current version references
grep -r "definitionVersion=\"" app/diagrams/ | grep "connector-id"
```

#### Case A: Same .def version (non-breaking)

Only the implementation changed, inputs/outputs are the same.

1. Update version in pom.xml
2. Build: `mvn clean install -DskipTests`
3. Update processDependencies JAR names in .proc files (if manually managed)
4. Done — no .proc connector configuration changes needed

#### Case B: New .def version (BREAKING)

Inputs or outputs have changed.

1. **Read the new .def file** — identify added/removed/changed inputs and outputs
2. **Update pom.xml** with new version
3. **For EACH .proc file that uses this connector:**

   a. Update connector element:
   ```xml
   <connectors definitionVersion="NEW_VERSION" ...>
   ```

   b. Update configuration block:
   ```xml
   <configuration definitionId="connector-id" version="NEW_VERSION">
   ```

   c. Add new input parameters:
   ```xml
   <parameters key="newInput">
     <value xmi:type="expression:Expression" name="newInput"
       content="" type="TYPE_CONSTANT"
       returnType="java.lang.String" returnTypeFixed="true"/>
   </parameters>
   ```

   d. Remove deleted input parameters (remove entire `<parameters>` block)

   e. Update output mappings if output names/types changed:
   ```xml
   <rightOperand content="newOutputName" type="CONNECTOR_OUTPUT_TYPE"
     returnType="java.lang.String"/>
   ```

   f. Update configuration section:
   ```xml
   <definitionMappings definitionVersion="NEW_VERSION" implementationVersion="NEW_VERSION"/>
   <processDependencies definitionVersion="NEW_VERSION">
     <!-- Update JAR fragment list -->
   </processDependencies>
   ```

4. **Build and verify:**
```bash
mvn clean install -DskipTests
```

---

## Upgrade Type 3: Bonita Runtime Version Update

### Scope: Upgrading bonita.version in pom.xml (e.g., 10.1.0 → 10.2.0)

#### Pre-flight

1. Read Bonita release notes for the target version
2. Check API changes: deprecated methods, new APIs
3. Check Java version requirements

#### Steps

1. **Update parent POM:**
```xml
<properties>
  <bonita.version>10.2.0</bonita.version>
</properties>
```

2. **Check for deprecated APIs:**
```bash
mvn clean compile -Xlint:deprecation 2>&1 | grep "deprecated"
```

3. **Update Bonita Maven plugin if needed:**
```xml
<plugin>
  <groupId>org.bonitasoft.maven</groupId>
  <artifactId>bonita-project-maven-plugin</artifactId>
  <version>NEW_VERSION</version>
</plugin>
```

4. **Update configuration version in .proc files:**
```xml
<configuration:Configuration version="10.2.0">
```

5. **Build and test**

---

## Upgrade Type 4: Java Version Migration

### Scope: e.g., Java 11 → Java 17

#### Key changes

1. **Update pom.xml compiler settings:**
```xml
<properties>
  <maven.compiler.source>17</maven.compiler.source>
  <maven.compiler.target>17</maven.compiler.target>
</properties>
```

2. **Check for javax → jakarta namespace changes** (if upgrading to Jakarta EE):
```bash
grep -r "javax.mail" --include="*.java" .
grep -r "javax.activation" --include="*.java" .
```

3. **Leverage Java 17 features** (optional):
   - Records for configuration/DTO classes
   - Sealed classes for exception hierarchies
   - Pattern matching for instanceof
   - Text blocks for SQL/JSON templates

---

## Dependency Conflict Resolution

### Diagnosing conflicts

```bash
# Full dependency tree with conflict details
mvn dependency:tree -Dverbose

# Check specific artifact
mvn dependency:tree -Dincludes=com.fasterxml.jackson.core
```

### Resolution strategies

1. **Exclusion** (most common):
```xml
<dependency>
  <groupId>com.example</groupId>
  <artifactId>my-lib</artifactId>
  <exclusions>
    <exclusion>
      <groupId>conflicting-group</groupId>
      <artifactId>conflicting-artifact</artifactId>
    </exclusion>
  </exclusions>
</dependency>
```

2. **Version pinning** in parent POM:
```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>com.fasterxml.jackson.core</groupId>
      <artifactId>jackson-databind</artifactId>
      <version>2.15.0</version>
    </dependency>
  </dependencies>
</dependencyManagement>
```

3. **Shade plugin relocation** (last resort):
```xml
<relocations>
  <relocation>
    <pattern>com.google.common</pattern>
    <shadedPattern>shaded.com.google.common</shadedPattern>
  </relocation>
</relocations>
```

---

## Post-Upgrade Verification

### Build verification
```bash
mvn clean install -DskipTests  # compile
mvn test                        # test
```

### Fat JAR verification
```bash
# Check JAR contains all expected files
jar tf target/*-bonita.jar | grep -E '\.(def|impl|properties|png)$'

# Check .impl has resolved dependencies (not placeholders)
jar xf target/*-bonita.jar my-connector-impl.impl
cat my-connector-impl.impl | grep jarDependency
# Should show actual JAR names, NOT ${connector-dependencies}
```

### Bonita Studio verification
1. Import updated extension: Extensions > Import extension
2. Open a process that uses the connector
3. Configure a task with the connector — verify all inputs appear
4. Run the process in Studio — verify connector executes

### Rollback
```bash
git diff  # review all changes
git stash  # if something went wrong
# or
git checkout main -- pom.xml  # revert specific file
```

---

## Quick Reference: What Changes Where

| What changed | pom.xml | .proc connectors | .proc config | .proc variables | Tests |
|-------------|---------|-------------------|--------------|-----------------|-------|
| Library version (in fat JAR) | Connector POM | No | processDependencies JARs | No | Yes |
| Library version (direct) | Project POM | No | No | No | Yes |
| Connector version (same .def) | Yes | No | processDependencies | No | Yes |
| Connector version (new .def) | Yes | Yes (all refs) | Yes (mappings + deps) | Maybe (new outputs) | Yes |
| Bonita runtime | Yes | No | version attr | No | Yes |
| Java version | Yes | No | No | No | Yes |
