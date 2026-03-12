---
name: bonita-groovy-scripting
description: |
  REDIRECT: Use bonita-bpmn-expert in bonita-bpmn-generator-toolkit instead.
  Groovy patterns for Bonita: BDM initialization, contract-to-BDM mapping, DAO queries, operations.
allowed-tools: Read, Grep, Glob
user-invocable: true
---

# Bonita Groovy Scripting Patterns -- REDIRECT

This skill has been consolidated into **bonita-bpmn-generator-toolkit**.

## Canonical location

`C:\PSProjects\bonita-bpmn-generator-toolkit\.claude\skills\bonita-bpmn-expert\SKILL.md`

## Quick reference (engine constants)

```groovy
apiAccessor          // All Bonita APIs
processInstanceId    // Current process instance (Long)
activityInstanceId   // Current task ID (Long)
taskAssigneeId       // Assigned user (Long)
loggedUserId         // Logged-in user (Long)
```

## Quick reference (critical patterns)

- OffsetDateTime: always `.truncatedTo(ChronoUnit.MICROS)`
- DAO typed access: `apiAccessor.getDAO(MyDAO.class)`
- BDM init: create entity, set fields from contract, return entity
- Error handling: SLF4J logger + try-catch + throw IllegalStateException

## Key knowledge files in bonita-bpmn-generator-toolkit/knowledge/

| File | Content |
|------|---------|
| `bonita-groovy-patterns.md` | Complete Groovy patterns, DAO, relations, error handling |
| `bonita-contract-reference.md` | Contract types, BDM mapping, constraints |
| `bonita-expression-reference.md` | Expression and operation types in .proc XML |
