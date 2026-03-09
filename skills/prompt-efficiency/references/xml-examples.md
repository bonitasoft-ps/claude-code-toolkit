# XML Tag Examples — Extended Reference

Additional examples and variations for the XML tag catalog defined in the main skill.

## Variables and Configuration

Use `<variables>` to define reusable parameters that appear in multiple tasks:

```xml
<variables>
  <var name="bonita_version">2024.3</var>
  <var name="target_version">2025.1</var>
  <var name="project_type">upgrade</var>
  <var name="client_env">Oracle Linux + PostgreSQL 15</var>
</variables>

<task id="1" title="Generate migration guide">
  <action>Create migration guide from {bonita_version} to {target_version}</action>
</task>
```

## Combining Tags — Real-World Patterns

### Upgrade assessment (variables + analysis + workflow)

```xml
<variables>
  <var name="source">7.11.4</var>
  <var name="target">2024.3</var>
  <var name="db">PostgreSQL 14</var>
</variables>

<instruction>Assess and plan the upgrade from {source} to {target}</instruction>

<workflow>
  <phase id="1" title="Assessment">
    <analysis>
      <scope>Breaking changes between {source} and {target}</scope>
      <focus>Database schema, API changes, removed features</focus>
      <output>Impact matrix with severity per area</output>
    </analysis>
    <checkpoint>Review impact matrix before proceeding</checkpoint>
  </phase>
  <phase id="2" title="Planning">
    <planning>
      <goal>Migration plan with estimated effort</goal>
      <constraints>
        - Zero downtime requirement
        - Must preserve custom REST API extensions
        - {db} compatibility
      </constraints>
      <output>Phased plan with tasks, dependencies, effort</output>
    </planning>
  </phase>
</workflow>
```

### Connector generation (task_list + context + requirement)

```xml
<instruction>Generate a new Bonita connector from this OpenAPI spec</instruction>

<context>
  Client needs a connector for their internal CRM API.
  OpenAPI 3.0 spec attached. Bonita 2024.3 project.
  Java 17, Maven multi-module.
</context>

<task_list>
  <task id="1" title="Create spec">
    <action>Extract connector spec from OpenAPI: endpoints, auth, data types</action>
  </task>
  <task id="2" title="Scaffold">
    <action>Generate connector code from spec using templates</action>
    <depends_on>task 1</depends_on>
  </task>
  <task id="3" title="Test">
    <action>Generate integration tests with mocked HTTP responses</action>
    <depends_on>task 2</depends_on>
  </task>
</task_list>

<requirement>Use MUST HAVE filter only, no FUTURE features</requirement>
```

### Multi-repo sync (task_list + variables)

```xml
<variables>
  <var name="old_count">318</var>
  <var name="new_count">328</var>
  <var name="reason">Added 10 new BPM rules (BPM-044 to BPM-053)</var>
</variables>

<instruction>Sync rule count from {old_count} to {new_count} across all repos</instruction>

<task_list>
  <task id="1" title="audit-toolkit">
    <repo>bonita-audit-toolkit</repo>
    <files>README.md, CLAUDE.md, claude-project/README.md</files>
    <action>Update rule count references from {old_count} to {new_count}</action>
  </task>
  <task id="2" title="MCP server">
    <repo>bonita-ai-agent-mcp</repo>
    <action>Update get_capabilities and tool descriptions</action>
  </task>
  <task id="3" title="claude-code-toolkit">
    <repo>claude-code-toolkit</repo>
    <files>skills/bonita-audit-expert/SKILL.md</files>
    <action>Update rule count reference</action>
  </task>
</task_list>

<requirement>Create separate branch and PR per repo</requirement>
```

## Nested Review with External Context

```xml
<instruction>Review against the new security standards</instruction>

<external_context>
  <source>OWASP API Security Top 10 — 2024 Edition</source>
  <summary>
    New focus areas: BOLA, broken authentication, unrestricted resource consumption,
    SSRF, unsafe consumption of APIs
  </summary>
</external_context>

<review>
  <target>src/main/java/com/company/api/</target>
  <criteria>
    - BOLA: Are object-level authorization checks in place?
    - Authentication: Token validation on every endpoint?
    - Rate limiting: Any unrestricted resource consumption?
    - Input validation: All parameters sanitized?
  </criteria>
  <output>
    Table: endpoint | vulnerability | severity | fix suggestion
  </output>
</review>
```

## Anti-Patterns (What NOT to Do)

### Too many tags for a simple task

```xml
<!-- BAD: Over-engineered for a simple question -->
<instruction>Tell me the Bonita version</instruction>
<context>I need to know the version</context>
<output>The version number</output>
<requirement>Be accurate</requirement>

<!-- GOOD: Just ask -->
Cual es la version de Bonita en este proyecto?
```

### Missing context for a complex task

```xml
<!-- BAD: Not enough info -->
<task id="1">
  <action>Fix the connector</action>
</task>

<!-- GOOD: Enough context to act -->
<context>
  SAP connector fails with timeout after 30s on EXECUTE phase.
  Bonita 2024.3, Java 17, SAP JCo 3.1.8.
</context>
<task id="1" title="Fix SAP timeout">
  <file>src/main/java/com/company/SapConnector.java</file>
  <action>Increase timeout to 120s and add retry logic on EXECUTE</action>
</task>
```

### Mixing unrelated tasks in one prompt

```xml
<!-- BAD: Two unrelated things -->
<task_list>
  <task id="1"><action>Fix the BDM audit rule</action></task>
  <task id="2"><action>Update the README with new release info</action></task>
</task_list>

<!-- GOOD: Separate prompts for unrelated tasks, or acknowledge they are independent -->
<!-- Prompt 1: Fix BDM rule -->
<!-- Prompt 2: Update README -->
```

## Tag Selection Quick Reference

| Situation | Recommended tags |
|-----------|-----------------|
| Simple question | None — just ask |
| Single code change | `<instruction>` + `<context>` + `<task>` |
| Multiple related changes | `<instruction>` + `<task_list>` |
| Research / analysis | `<instruction>` + `<analysis>` + `<context>` |
| Architecture planning | `<instruction>` + `<planning>` |
| Code review | `<instruction>` + `<review>` |
| Multi-phase project | `<instruction>` + `<workflow>` with `<phase>` |
| Cross-repo operation | `<task_list>` with `<repo>` per task |
| Parameterized tasks | `<variables>` + any of the above |
| External info needed | `<external_context>` + relevant task tags |
