---
name: bonita-process-designer
description: |
  REDIRECT: Use bonita-bpmn-expert in bonita-bpmn-generator-toolkit instead.
  Design Bonita BPMN processes with actors, tasks, gateways, events, contracts, connectors.
allowed-tools: Read, Grep, Glob
user-invocable: true
---

# Bonita Process Designer -- REDIRECT

This skill has been consolidated into **bonita-bpmn-generator-toolkit**.

## Canonical location

`C:\PSProjects\bonita-bpmn-generator-toolkit\.claude\skills\bonita-bpmn-expert\SKILL.md`

## Quick reference (task types)

| Type | Has Actor | Has Contract |
|------|-----------|-------------|
| UserTask | Yes | Yes |
| AutomaticTask / ServiceTask | No | No |
| ScriptTask | No | No |
| CallActivity | No | No |
| ReceiveTask / SendTask | No | No |

## Quick reference (connector events)

| Event | When |
|-------|------|
| ON_ENTER | Before task execution |
| ON_FINISH | After task completion |

Fail actions: FAIL, ERROR_EVENT, IGNORE

## Key knowledge files in bonita-bpmn-generator-toolkit/knowledge/

| File | Content |
|------|---------|
| `bonita-process-model-reference.md` | All flow node types, gateways, events |
| `bonita-contract-reference.md` | Contract types, complex inputs, constraints |
| `bonita-design-best-practices.md` | Design rules, connector patterns, operations |
| `bonita-expression-reference.md` | Expression types for operations and conditions |
