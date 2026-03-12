---
name: bonita-groovy-expert
description: |
  REDIRECT: Use bonita-bpmn-expert in bonita-bpmn-generator-toolkit instead.
  Groovy scripting in Bonita: initProcess, connectors, operations, conditions, DAO queries.
allowed-tools: Read, Grep, Glob
user-invocable: true
---

# Bonita Groovy Script Expert -- REDIRECT

This skill has been consolidated into **bonita-bpmn-generator-toolkit**.

## Canonical location

`C:\PSProjects\bonita-bpmn-generator-toolkit\.claude\skills\bonita-bpmn-expert\SKILL.md`

## Quick reference (where scripts run)

- **initProcess**: Initialize BDM at process start
- **Script tasks**: Inline Groovy logic in flow
- **Connector scripts**: Input/output mappings
- **Operations**: Variable assignments after tasks
- **Conditions**: Gateway transition guards
- **Shared scripts**: Reusable `.groovy` in `app/src-groovy/`

## Quick reference (code standards)

- Use SLF4J logger, never `System.out.println`
- `try-catch` for ALL external calls
- Max 30 lines per script
- Truncate `OffsetDateTime` to MICROS
- Null-safe: `entity?.field?.subField`

## Key knowledge files in bonita-bpmn-generator-toolkit/knowledge/

| File | Content |
|------|---------|
| `bonita-groovy-patterns.md` | BDM init, DAO queries, relations, error handling, code standards |
| `bonita-expression-reference.md` | All expression types in .proc XML |
| `bonita-contract-reference.md` | Contract-to-BDM mapping patterns |
