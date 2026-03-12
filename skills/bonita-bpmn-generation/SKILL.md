---
name: bonita-bpmn-generation
description: |
  REDIRECT: Use bonita-bpmn-expert in bonita-bpmn-generator-toolkit instead.
  Generate Bonita .proc files (BPMN 2.0 + Bonita extensions) from process descriptions.
allowed-tools: Read, Grep, Glob
user-invocable: true
---

# BPMN Generation for Bonita -- REDIRECT

This skill has been consolidated into **bonita-bpmn-generator-toolkit**.

## Canonical location

`C:\PSProjects\bonita-bpmn-generator-toolkit\.claude\skills\bonita-bpmn-expert\SKILL.md`

## Quick reference (generation inputs)

1. **Process name** -- PascalCase, no spaces
2. **Version** -- e.g. `1.0`
3. **Actors** -- exhaustive list of human actors
4. **Steps** -- id, name, type, actor (if human task)
5. **Flows** -- all sequence flows, including conditions for XOR gateways

## Key knowledge files in bonita-bpmn-generator-toolkit/knowledge/

| File | Content |
|------|---------|
| `bonita-process-model-reference.md` | Tasks, gateways, events, transitions |
| `bonita-bpmn-extensions.md` | Namespaces, variables, contracts |
| `bonita-proc-generation-guide.md` | Programmatic generation pipeline |
| `bonita-design-best-practices.md` | Naming, structure, validation rules |

## To use

Read the bonita-bpmn-expert skill and its knowledge directory for complete generation rules, validation checklists, and XML templates.
