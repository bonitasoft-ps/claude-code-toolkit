---
name: bonita-process-lifecycle
description: |
  Complete lifecycle for BPMN processes (.proc files): spec → document → publish/save →
  validate → implement → test with Bonita Test Toolkit → build .bar → deploy → update docs → deliver.
  Covers tasks, gateways, events, variables, connectors, contracts, actors.
  Trigger: "create process", "new process", "bpmn lifecycle", "process lifecycle", "design process flow"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, mcp__claude_ai_Atlassian_2__createConfluencePage, mcp__claude_ai_Atlassian_2__updateConfluencePage, mcp__Bonita-AI-Agent__build_pdf, mcp__Bonita-AI-Agent__generate_bpmn, mcp__Bonita-AI-Agent__validate_bpmn, mcp__Bonita-AI-Agent__generate_subprocess, mcp__Bonita-AI-Agent__generate_event_handler
user_invocable: true
---

# Bonita Process Lifecycle — Documentation-First

## Lifecycle
```
SPEC → DOCUMENT → CHOOSE DESTINATION → VALIDATE ✓ → IMPLEMENT → TEST → BUILD (.bar) → DEPLOY → UPDATE DOC → DELIVER
```

## Phase 1: SPEC
Ask the user:
- Process name, description, business purpose
- Actors and roles (who does what)
- Tasks: for each, name, type (human/service/script), actor, description
- Human tasks: contract inputs, form type
- Service tasks: which connector, inputs/outputs
- Script tasks: Groovy script purpose
- Gateways: type (exclusive/parallel/inclusive), conditions
- Events: start type, end type, intermediate (timer, message, signal), boundary events
- Variables: process-level, business data (BDM), documents
- Connectors needed (which tasks, which external systems)
- Timers: durations, cron expressions

## Phase 2: DOCUMENT
Generate process specification using template.
Include: flow diagram (text), task details, gateway conditions, variable definitions, connector mapping.

## Phase 3: CHOOSE DESTINATION & PUBLISH
**Invoke `confluence-publish-workflow`** — ask user where to save.

## Phase 4: VALIDATE
**GATE — Do NOT proceed without explicit approval**

## Phase 5: IMPLEMENT
Use MCP tools:
1. `generate_bpmn` — generate main process .proc file
2. `generate_subprocess` — for call activities
3. `generate_event_handler` — for event sub-processes
4. `validate_bpmn` — verify generated .proc

### Task Types
| Type | Implementation | Testing |
|------|---------------|---------|
| Human Task | Contract + Form + Actor mapping | BTT: execute task with contract inputs |
| Service Task | Connector configuration | BTT: verify connector output |
| Script Task | Groovy expression | Unit test Groovy logic |
| Call Activity | Reference to subprocess | BTT: verify subprocess execution |

### Gateway Patterns
| Type | Use When | Condition Format |
|------|----------|-----------------|
| Exclusive (XOR) | One path based on condition | Groovy boolean expression |
| Parallel (AND) | All paths execute | No condition |
| Inclusive (OR) | One or more paths | Groovy boolean per path |

### Variable Types
| Type | Scope | Storage |
|------|-------|---------|
| Process Variable | Process instance | In-memory |
| Business Variable | BDM entity | Database (persistent) |
| Document | Attached file | Document store |

## Phase 6: TEST — Bonita Test Toolkit

### Setup
- Bonita Test Toolkit 3.1.x dependency
- AbstractProcessTest base class
- Docker Bonita instance for runtime

### Test Patterns
```java
@Test
void should_complete_happy_path() {
    // Deploy process
    ProcessDefinition process = deployProcess("MyProcess", "1.0");

    // Start case
    long caseId = startCase(process, contractInputs);

    // Execute human tasks
    HumanTask task = waitForUserTask(caseId, "Review");
    executeTask(task, reviewInputs);

    // Assert process completed
    assertProcessCompleted(caseId);
    assertBusinessData("entityName", expectedValues);
}
```

### Coverage
- Happy path (main flow)
- All gateway branches
- Error paths and boundary events
- Timer behavior (use clock manipulation)
- Connector error handling

## Phase 7: BUILD
Package as .bar file:
- Process definition (.proc)
- Connector implementations
- Actor mapping
- Form mapping
- Parameters

## Phase 8: DEPLOY
Deploy to Bonita Runtime:
1. Upload .bar via REST API
2. Get process definition ID
3. Enable process
4. Verify with smoke test (start case, check task list)

## Phase 9: UPDATE DOCUMENT
Add: actual .proc details, test results, deployment info, known issues.

## Phase 10: DELIVER
PDF report if requested, status DELIVERED.
