---
name: bonita-proc-file-expert
description: |
  Expert in Bonita .proc files. For comprehensive .proc knowledge, use the bonita-bpmn-generator-toolkit
  which contains complete references for process models, expressions, connector configuration, notation,
  and programmatic generation.
  Keywords: .proc, XML, EMF, XMI, connector, notation, expression, BPMN
allowed-tools: Read, Grep, Glob
user-invocable: true
---

# Bonita .proc File Expert

For comprehensive .proc file knowledge, use the **bonita-bpmn-generator-toolkit** which contains:

## Knowledge Base
- **bonita-process-model-reference.md** — Pool, Lane, Task, Gateway, Event structures
- **bonita-expression-reference.md** — All expression types (TYPE_VARIABLE, TYPE_READ_ONLY_SCRIPT, CONNECTOR_OUTPUT_TYPE, etc.)
- **bonita-connector-configuration-reference.md** — Connector params, output mappings, configuration section
- **bonita-notation-reference.md** — GMF notation (shapes, dimensions, anchors, bendpoints, colors)
- **bonita-proc-generation-guide.md** — Programmatic generation approach
- **bonita-groovy-patterns.md** — Groovy scripts in XML encoding
- **bonita-bpmn-extensions.md** — Bonita-specific BPMN extensions

## Skill
- **bonita-bpmn-expert** — Complete skill for reading, modifying, and generating .proc files

## Quick Reference: .proc Anatomy

```
xmi:XMI
├── notation:Diagram          — visual layout (GMF notation)
├── process:MainProcess       — root process container
│   ├── elements (Pool)       — each pool = separate process
│   │   ├── data              — process variables
│   │   ├── connectors        — pool-level connectors
│   │   ├── elements (Lane)
│   │   │   └── elements      — tasks, gateways, events
│   │   ├── connections        — sequence flows
│   │   └── actors             — actor definitions
│   └── datatypes              — data type definitions
├── actormapping:ActorMappingsType
└── configuration:Configuration
```

## Pool-Level Connector Execution

Pool-level connectors execute **sequentially in XML document order**, each in its own database transaction.

### Two-Connector Pattern (Self-Destructive Operations)

When a connector cancels its own process:
1. **Connector 1** (TX1): Persist BDM data → COMMIT (safe)
2. **Connector 2** (TX2): Call cancelProcessInstance → cascade kills TX2 → ROLLBACK (acceptable)

Move all BDM writes to Connector 1. Remove output mappings from Connector 2.
