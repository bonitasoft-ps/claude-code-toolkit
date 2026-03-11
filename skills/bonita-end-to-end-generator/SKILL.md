---
name: bonita-end-to-end-generator
description: "Complete end-to-end Bonita project generation: spec -> BDM -> contracts -> process -> forms -> REST API -> CI/CD. Orchestrates all generator toolkits."
user_invocable: true
trigger_keywords: ["generate project", "end to end", "full project", "complete bonita", "e2e generation"]
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Bonita End-to-End Generator

You are an expert in orchestrating the complete Bonita project generation pipeline. You coordinate all generator toolkits to produce a fully deployable Bonita application from a project specification.

## Generation Pipeline Overview

| Phase | Name | Toolkit | MCP Tool |
|-------|------|---------|----------|
| 1 | Project Specification | Manual / AI context | — |
| 2 | BDM Generation | bonita-bdm-generator-toolkit | `generate_bdm` |
| 3 | Contract Generation | bonita-bdm-generator-toolkit | `generate_contract` |
| 4 | Groovy Script Generation | bonita-bdm-generator-toolkit | `generate_groovy_script` |
| 5 | BPMN Process Generation | bonita-bpmn-generator-toolkit | `generate_bpmn` |
| 6 | Form Generation | bonita-uibuilder-generator-toolkit | `generate_page` |
| 7 | REST API Extensions | claude-code-toolkit skill | `bonita-rest-api-expert` |
| 8 | Application Assembly | bonita-uibuilder-generator-toolkit | `generate_application` |
| 9 | CI/CD Pipeline | claude-code-toolkit skill | `bonita-cicd-pipeline` |
| 10 | Validation & Testing | template-test-toolkit | `scaffold_test_class` |

## Phase 1: Project Specification

**Goal:** Understand the business requirements and produce a structured project spec.

**Inputs:** `context-ia/` directory, natural language description, or existing documentation.

**Actions:**
1. Read all context files (context-ia/*.md, requirements, mockups)
2. Identify **entities** (nouns → BDM objects) with their fields and relationships
3. Identify **processes** (verbs → BPMN workflows) with steps and decisions
4. Identify **actors** (roles → organization groups/roles)
5. Identify **integrations** (external systems → connectors or REST API extensions)
6. Identify **pages** (screens → forms, dashboards, overviews)

**Output:** Structured spec with entities, processes, actors, integrations, and UI requirements.

## Phase 2: BDM Generation

**Toolkit:** `bonita-bdm-generator-toolkit`

**Actions:**
1. Define entities with fields, types, and constraints
2. Define relations: COMPOSITION (parent owns child lifecycle) vs AGGREGATION (reference by persistenceId)
3. Add unique constraints and custom queries (JPQL)
4. Generate `bom.xml`
5. Validate: no circular compositions, valid Java identifiers, no SQL reserved words

**Field types:** STRING, TEXT, INTEGER, DOUBLE, LONG, FLOAT, DATE, BOOLEAN, LOCALDATE, LOCALDATETIME, OFFSETDATETIME

**Relation rules:**
- COMPOSITION: child is created/deleted with parent, embedded in parent's contract
- AGGREGATION: child exists independently, referenced by persistenceId in contract

**MCP Tools:** `generate_bdm`, `generate_bdm_entity`, `validate_bdm`

## Phase 3: Contract Generation

**Toolkit:** `bonita-bdm-generator-toolkit`

**Actions:**
1. For each process: generate **instantiation contract** from the BDM fields needed at start
2. For each user task: generate **task contract** with the fields that task modifies
3. Map BDM field types to contract input types:

| BDM Type | Contract Type |
|----------|---------------|
| STRING / TEXT | TEXT |
| INTEGER | INTEGER |
| LONG | LONG |
| DOUBLE / FLOAT | DECIMAL |
| BOOLEAN | BOOLEAN |
| DATE | DATE |
| LOCALDATE | LOCALDATE |
| LOCALDATETIME | LOCALDATETIME |
| OFFSETDATETIME | OFFSETDATETIME |
| byte[] | BYTE_ARRAY |
| Document | FILE |

4. Generate **complex inputs** for nested entities (COMPOSITION creates child structure, AGGREGATION uses persistenceId reference)
5. Name convention: `{entityName}Input` for the complex type, `{fieldName}Input` for simple fields

**MCP Tools:** `generate_contract`, `validate_contract`

## Phase 4: Groovy Script Generation

**Toolkit:** `bonita-bdm-generator-toolkit`

**Actions:**
1. For each contract, generate Groovy scripts for BDM operations

**Create mode** (process instantiation — new entity from contract):
```groovy
import com.company.model.MyEntity

def entity = new MyEntity()
entity.name = myEntityInput.name
entity.description = myEntityInput.description
entity.createdDate = java.time.OffsetDateTime.now().truncatedTo(java.time.temporal.ChronoUnit.MICROS)
return entity
```

**Update mode** (task — modify existing entity from contract):
```groovy
import com.company.model.MyEntity

def entity = myEntityDAO.findByPersistenceId(persistenceId)
entity.name = myEntityInput.name
entity.status = myEntityInput.status
entity.updatedDate = java.time.OffsetDateTime.now().truncatedTo(java.time.temporal.ChronoUnit.MICROS)
return entity
```

**Relation handling:**
- AGGREGATION: load child by persistenceId → `childDAO.findByPersistenceId(input.persistenceId_string.toLong())`
- COMPOSITION: create child inline → `def child = new ChildEntity(); child.field = input.field`

**Critical:** Always truncate OffsetDateTime to `ChronoUnit.MICROS` — Bonita database precision is microseconds, not nanoseconds.

**MCP Tools:** `generate_groovy_script`, `validate_groovy`

## Phase 5: BPMN Process Generation

**Toolkit:** `bonita-bpmn-generator-toolkit`

**Actions:**
1. Create pool with process name and version
2. Define lanes per actor
3. Add start event with process instantiation contract
4. Add user tasks with:
   - Actor assignment (lane)
   - Task contract
   - Operations (Groovy scripts from Phase 4)
   - Business data variables
5. Add automatic/service tasks for system operations
6. Add gateways: EXCLUSIVE (decisions), PARALLEL (fork/join), INCLUSIVE (optional paths)
7. Add connectors on tasks (ON_ENTER or ON_FINISH)
8. Add boundary events: timer (deadlines), error (exception handling), message (notifications)
9. Add end events (plain, error, terminate)
10. Connect all flow nodes with sequence flows and conditions

**MCP Tools:** `generate_bpmn`, `generate_subprocess`, `generate_event_handler`, `validate_bpmn`

## Phase 6: Form Generation

**Toolkit:** `bonita-uibuilder-generator-toolkit`

**Actions:**
1. Generate **process start form** from process instantiation contract
2. Generate **task forms** per user task:
   - Create form: all fields editable, submit creates entity
   - Edit form: pre-populated fields, submit updates entity
   - Approval form: read-only data + approve/reject buttons
3. Generate **overview page** showing case data and history
4. Generate **dashboard pages** with KPI widgets (optional)

**Widget selection from contract types:**
| Contract Type | Widget |
|---------------|--------|
| TEXT | Input (text) |
| INTEGER / LONG / DECIMAL | Input (number) |
| BOOLEAN | Checkbox or Switch |
| DATE / LOCALDATE | Date Picker |
| LOCALDATETIME / OFFSETDATETIME | DateTime Picker |
| FILE | File Upload |
| BYTE_ARRAY | File Upload |
| Complex (nested) | Container with child widgets |
| List | Table or Repeatable Container |

**MCP Tools:** `generate_uibuilder_page`, `generate_uibuilder_form`, `validate_uibuilder_page`

## Phase 7: REST API Extensions (Optional)

**When needed:** Custom BDM queries, aggregated data endpoints, integration proxies.

**Structure:**
```
restAPIExtension/
├── page.properties
├── src/main/
│   ├── groovy/
│   │   └── com/company/rest/
│   │       ├── Index.groovy        — Controller (routing)
│   │       └── dto/
│   │           └── EntityDTO.groovy — Data transfer objects
│   └── resources/
│       └── page.properties
└── pom.xml
```

**Controller pattern:**
```groovy
class Index implements RestApiController {
    RestApiResponse doHandle(HttpServletRequest request, RestApiResponseBuilder responseBuilder, ...) {
        def result = context.apiClient.getDAO(MyEntityDAO.class).find(0, 100)
        return buildResponse(responseBuilder, HttpServletResponse.SC_OK, new JsonBuilder(result).toString())
    }
}
```

## Phase 8: Application Assembly

**Toolkit:** `bonita-uibuilder-generator-toolkit`

**Actions:**
1. Create application descriptor XML:
```xml
<application xmlns="http://www.bonitasoft.org/ns/application/6.0"
    token="myapp" version="1.0"
    displayName="My Application"
    profile="User">
    <layout>custompage_layoutBonita</layout>
    <theme>custompage_bonitaTheme</theme>
    <pages>
        <page token="submit" page="custompage_submitForm"/>
        <page token="dashboard" page="custompage_dashboard"/>
    </pages>
    <navigation>
        <menuItem token="submit" label="Submit Request" page="submit"/>
        <menuItem token="dashboard" label="Dashboard" page="dashboard"/>
    </navigation>
</application>
```
2. Generate actor mapping (actorMapping.xml)
3. Generate form mapping (form-mapping.xml)
4. Map organization roles to process actors

**MCP Tools:** `generate_application`, `generate_actor_mapping`, `generate_form_mapping`

## Phase 9: CI/CD Pipeline

**Actions:**
1. Generate GitHub Actions workflow:
   - Build and validate BDM
   - Build connectors (Maven)
   - Package forms
   - Assemble BAR
   - Deploy to Docker test environment
   - Run integration tests
2. Generate Docker Compose infrastructure:
   - Bonita server (with BDM and organization pre-loaded)
   - PostgreSQL database
   - Test runner service
3. Generate deployment scripts (shell/PowerShell)

## Phase 10: Validation & Testing

**Actions:**
1. Validate process: all tasks have contracts, all actors mapped, all connectors have implementations
2. Validate BDM: valid field types, no circular compositions, unique constraints valid
3. Validate forms: all contract inputs have corresponding form widgets
4. Validate consistency: actors in process match organization, forms match tasks
5. Scaffold integration tests:
   - Process lifecycle test (start → complete tasks → end)
   - Connector tests
   - BDM query tests
6. Generate test data

**MCP Tools:** `validate_project_consistency`, `scaffold_test_class`, `get_test_template`

## Execution Order and Dependencies

```
Phase 1: Spec ─────────────────────────────────────────────────┐
Phase 2: BDM ─────────┐                                       │
Phase 3: Contracts ────┤ (depends on BDM)                      │
Phase 4: Groovy ───────┘ (depends on Contracts)                │
Phase 5: BPMN ────────── (depends on Contracts + Groovy)       │
Phase 6: Forms ────────── (depends on Contracts + BPMN)        │
Phase 7: REST API ─────── (depends on BDM, optional)           │
Phase 8: Application ──── (depends on Forms + BPMN)            │
Phase 9: CI/CD ────────── (depends on all artifacts)           │
Phase 10: Validation ──── (depends on all artifacts)           │
```

**Parallelizable:** Phases 5-7 can run in parallel once Phase 4 is complete.

## Cross-Phase Consistency Rules

1. **BDM ↔ Contracts:** Every BDM field used in a contract must have matching types
2. **Contracts ↔ Groovy:** Every contract input must be consumed by a Groovy script
3. **Contracts ↔ Forms:** Every contract input must have a form widget
4. **BPMN ↔ Actors:** Every actor in the process must have an actor mapping entry
5. **BPMN ↔ Connectors:** Every connector reference must have a .impl descriptor and JARs
6. **Forms ↔ Application:** Every form referenced in form-mapping must be in the application
7. **BAR ↔ Runtime:** BDM and organization must be deployed before BAR deployment

## Quick Start

To generate a complete project:
1. Provide a business description or point to `context-ia/` files
2. Run through phases 1-10 sequentially (the pipeline handles dependencies)
3. Use `validate_project_consistency` at the end for a final cross-check
4. Deploy with `bonita_deploy_process` or package with `create_delivery_package`
