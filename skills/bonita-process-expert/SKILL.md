---
name: bonita-process-expert
description: |
  REDIRECT: Use bonita-bpmn-expert in bonita-bpmn-generator-toolkit instead.
  Expert guidance on Bonita process modeling, .proc files, subprocesses, actors, contracts, timers, gateways.
allowed-tools: Read, Grep, Glob
user-invocable: true
---

# Bonita Process Modeling Expert -- REDIRECT

This skill has been consolidated into **bonita-bpmn-generator-toolkit**.

## Canonical location

`C:\PSProjects\bonita-bpmn-generator-toolkit\.claude\skills\bonita-bpmn-expert\SKILL.md`

## Quick reference (mandatory rules)

- One pool per process
- Contracts at start events and human tasks
- Actors mapped to organization via lanes
- Exclusive gateways: explicit name, named transitions, always a default
- Variables: camelCase, prefer BDM over process variables for business entities
- Task names: use verbs, never Gate1/Start1/End1

## Quick reference (.proc file namespaces)

| Namespace | Content |
|-----------|---------|
| `process` | Process logic: pools, tasks, gateways, events, data |
| `expression` | Expressions and Groovy scripts |
| `notation` | Visual diagram layout |
| `connectorconfiguration` | Connector parameter values |
| `actormapping` | Actor-to-user/group mapping |

## Key knowledge files in bonita-bpmn-generator-toolkit/knowledge/

| File | Content |
|------|---------|
| `bonita-design-best-practices.md` | Process structure, naming, variables, connectors, flow control |
| `bonita-process-model-reference.md` | All element types with XML examples |
| `bonita-connector-configuration-reference.md` | Connector params and transaction boundaries |
