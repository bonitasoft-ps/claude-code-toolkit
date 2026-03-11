---
name: bonita-process-designer
description: "Design Bonita BPMN processes with actors, tasks, gateways, events, contracts, connectors, and business data."
user_invocable: true
trigger_keywords: ["bpmn", "process design", "workflow design", "process model", "flow diagram"]
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Bonita Process Designer

You are an expert in Bonita BPMN process design. You help create well-structured processes.

## Flow Node Types (from Bonita engine)

### Tasks
| Type | Use Case | Has Actor | Has Contract |
|------|----------|-----------|-------------|
| UserTask | Human interaction | Yes | Yes |
| AutomaticTask | System operation (no human) | No | No |
| ManualTask | External manual work (rare) | Yes | No |
| CallActivity | Invoke sub-process | No | No |
| ReceiveTask | Wait for message | No | No |
| SendTask | Send message | No | No |

### Gateways (GatewayType enum)
| Type | Use | Pattern |
|------|-----|---------|
| EXCLUSIVE | Decision (only one path) | If-else, switch |
| PARALLEL | Fork (all paths) / Join (wait all) | Concurrent execution |
| INCLUSIVE | Optional paths (one or more) | Conditional parallel |

### Events
**Start:** Plain, Timer (CYCLE/DATE/DURATION), Message, Signal
**End:** Plain, Error, Terminate
**Intermediate Catch:** Timer, Message, Signal
**Intermediate Throw:** Message, Signal, Error
**Boundary:** Timer, Message, Error, Signal (interrupting or non-interrupting)

## Contract System (from engine Type enum)
Contract types: TEXT, BOOLEAN, DATE, INTEGER, DECIMAL, BYTE_ARRAY, FILE, LONG, LOCALDATE, LOCALDATETIME, OFFSETDATETIME

**Process contract:** Inputs needed to start a case
**Task contract:** Inputs needed to complete a human task

## Expression Types (ExpressionType enum)
| Type | Use | Example |
|------|-----|---------|
| TYPE_CONSTANT | Literal values | `"Hello"`, `42` |
| TYPE_READ_ONLY_SCRIPT | Groovy scripts | `contractInput.toUpperCase()` |
| TYPE_VARIABLE | Process variables | `myVariable` |
| TYPE_BUSINESS_DATA | BDM instance | `myBusinessData` |
| TYPE_CONTRACT_INPUT | Contract input value | `nameInput` |
| TYPE_PARAMETER | Process parameter | `emailServer` |
| TYPE_ENGINE_CONSTANT | API accessor, process ID | `apiAccessor` |
| TYPE_QUERY_BUSINESS_DATA | JPQL query result | `Employee.findByName` |

## Connector Events
| Event | When | Use Case |
|-------|------|----------|
| ON_ENTER | Before task execution | Pre-populate data, send notification |
| ON_FINISH | After task completion | Post-processing, external update |

Fail actions: FAIL (stop process), ERROR_EVENT (trigger boundary event), IGNORE

## Operation Pattern: Contract → BDM
```groovy
// Create new entity from contract inputs
def employee = new com.company.model.Employee()
employee.firstName = firstNameInput
employee.lastName = lastNameInput
employee.email = emailInput
return employee
```

## Design Best Practices
1. Every user task needs a contract
2. Every process needs at least one actor
3. Use EXCLUSIVE gateway for decisions (add conditions on transitions)
4. Use PARALLEL gateway for concurrent work
5. Always add a default transition on EXCLUSIVE/INCLUSIVE gateways
6. Place connectors ON_FINISH for better error handling
7. Use boundary timer events for deadlines/escalations
8. Use sub-processes for reusable workflows

## MCP Tools
- `generate_bpmn` — Generate complete process with actors, tasks, flows
- `generate_subprocess` — Generate callable subprocess
- `generate_event_handler` — Generate boundary/timer/message events
- `validate_bpmn` — Validate process XML
