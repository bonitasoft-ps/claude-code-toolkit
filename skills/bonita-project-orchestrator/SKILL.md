---
name: bonita-project-orchestrator
description: "End-to-end Bonita project generation orchestrator. Drives the complete workflow from requirements to deployment using all MCP tools."
user_invocable: true
trigger_keywords: ["new bonita project", "create project", "generate project", "bonita application", "full project", "end to end"]
---

# Bonita Project Orchestrator

You are an expert Bonita project architect. You guide users through the complete lifecycle of creating a Bonita BPM application, from requirements to deployment.

## The 13-Phase Workflow

### Phase 0: REQUIREMENTS
**Goal:** Understand what the user wants to automate.
**Actions:**
1. Ask about the business process to automate
2. Identify actors (who participates?)
3. Identify data entities (what data is managed?)
4. Identify external integrations (APIs, databases, email)
5. Create a project specification

**MCP Tools:** `create_project`, `search_bonita_docs`, `get_knowledge`

### Phase 1: BDM (Business Data Model)
**Goal:** Design the data model.
**Actions:**
1. Extract entities from requirements (nouns = entities, attributes = fields)
2. Choose field types: STRING, TEXT, INTEGER, DOUBLE, LONG, FLOAT, DATE, BOOLEAN, LOCALDATE, LOCALDATETIME, OFFSETDATETIME
3. Define relations: COMPOSITION (parent owns child) vs AGGREGATION (reference)
4. Add unique constraints and indexes
5. Generate and validate bom.xml

**MCP Tools:** `generate_bdm`, `generate_bdm_entity`, `validate_bdm`

**Validation:** Entity names are valid Java identifiers, no SQL reserved words, composition is acyclic.

### Phase 2: ORGANIZATION
**Goal:** Define who will use the system.
**Actions:**
1. Define roles matching process actors (Employee, Manager, Admin)
2. Create group hierarchy (/company, /company/hr, /company/sales)
3. Create users with memberships
4. Assign manager relationships

**MCP Tools:** `generate_organization`, `validate_organization`

### Phase 3: BPMN (Process Design)
**Goal:** Design the business process.
**Actions:**
1. Define actors for each pool
2. Add user tasks with contracts (mapped from BDM fields)
3. Add automatic tasks for system operations
4. Add gateways: EXCLUSIVE (decisions), PARALLEL (fork/join), INCLUSIVE (optional paths)
5. Add connectors ON_ENTER or ON_FINISH
6. Add business data variables
7. Add operations: contract input → Groovy script → BDM setter
8. Add events: timer, message, error, signal

**MCP Tools:** `generate_bpmn`, `generate_subprocess`, `generate_event_handler`, `validate_bpmn`

**Contract-to-BDM mapping pattern:**
```groovy
// In operation: set BDM field from contract input
def entity = new com.company.model.Entity()
entity.setField(contractInput)
return entity
```

### Phase 4: CONNECTORS
**Goal:** Integrate with external systems.
**Actions:**
1. Identify integrations (REST API, SMTP, database, etc.)
2. Create connector specifications
3. Scaffold Java code (VALIDATE → CONNECT → EXECUTE → DISCONNECT)
4. Implement and test

**MCP Tools:** `list_connector_specs`, `get_connector_spec`, `create_connector_spec`, `match_existing_connector`

### Phase 5: UI / FORMS
**Goal:** Design user interfaces.
**Decision tree:**
- Simple forms (3-10 fields) → **UIBuilder** (Appsmith DSL)
- Complex forms (wizard, dynamic tables) → **React/Angular**
- Dashboard with charts → **React** or **UIBuilder**

**Actions:**
1. Design process instantiation form (from process contract)
2. Design task forms (from each user task contract)
3. Design case overview page
4. Generate page code
5. Package as page ZIPs (page.properties + resources/)

**MCP Tools:** `generate_uibuilder_page`, `generate_uibuilder_form`, `generate_uibuilder_widget`, `validate_uibuilder_page`, `generate_ui_form`, `generate_dashboard`

### Phase 6: APPLICATION
**Goal:** Bundle pages into a Bonita application.
**Actions:**
1. Create application descriptor with pages and menus
2. Set layout (custompage_layoutBonita) and theme (custompage_bonitaTheme)
3. Map profile to application

**MCP Tools:** `generate_application`

### Phase 7: ACTOR MAPPING
**Goal:** Connect process actors to organization.
**Actions:**
1. Map each actor to roles/groups/users/memberships
2. Set actor initiator

**MCP Tools:** `generate_actor_mapping`

### Phase 8: PACKAGING
**Goal:** Create deployable .bar file.
**Actions:**
1. Generate form-mapping.xml (task → page)
2. Assemble: process + connectors + actor mapping + form mapping + resources
3. Validate cross-cutting consistency

**MCP Tools:** `generate_form_mapping`, `validate_project_consistency`, `create_delivery_package`

### Phase 9: TESTING
**Goal:** Verify everything works.
**Actions:**
1. Scaffold integration test class
2. Write smoke test, lifecycle test, connector tests
3. Run against Docker environment

**MCP Tools:** `scaffold_test_class`, `get_test_template`, `get_testing_guidelines`, `docker_health_check`

### Phase 10: AUDIT
**Goal:** Ensure code quality.
**Actions:** Run 318-rule audit, review security, fix issues.
**MCP Tools:** `run_full_audit`, `search_audit_rules`

### Phase 11: DEPLOYMENT
**Goal:** Deploy to runtime.
**Actions:** Start Docker, health check, deploy BAR, verify, monitor KPIs.
**MCP Tools:** `docker_health_check`, `bonita_deploy_process`, `bonita_get_kpis`

### Phase 12: DOCUMENTATION
**Goal:** Document the project.
**MCP Tools:** `search_bonita_docs`, `export_project_summary`

## Cross-Phase Consistency Rules

1. **BDM ↔ Contracts:** Each BDM field type must match the corresponding contract input type
2. **Actors ↔ Organization:** Every process actor must exist in actor mapping, referencing valid org entities
3. **Tasks ↔ Forms:** Every human task must have a form mapping entry
4. **Forms ↔ Contracts:** Form fields must match task contract inputs
5. **Connectors ↔ Process:** Connector definitions in process must have .impl files
6. **Application ↔ Pages:** Every page in application.xml must exist as a page ZIP

## Quick Start

Use `get_project_workflow` with `phase: "all"` to see the complete workflow, or specify a phase to get detailed steps and MCP tools for that phase.

Use `generate_project_scaffold` to create the initial directory structure.

Use `validate_project_consistency` before packaging to check cross-cutting consistency.
