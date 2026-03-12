---
name: bonita-connector-lifecycle
description: |
  Complete lifecycle for Bonita Connectors, Actor Filters, and Event Handlers:
  spec → document → publish/save → validate → implement → test → build → deploy → update docs → deliver.
  Covers the full VALIDATE → CONNECT → EXECUTE → DISCONNECT pattern.
  Trigger: "create connector", "new connector", "actor filter", "event handler", "connector lifecycle"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, mcp__claude_ai_Atlassian_2__createConfluencePage, mcp__claude_ai_Atlassian_2__updateConfluencePage, mcp__Bonita-AI-Agent__build_pdf, mcp__Bonita-AI-Agent__create_connector_spec, mcp__Bonita-AI-Agent__get_connector_template, mcp__Bonita-AI-Agent__match_existing_connector
user_invocable: true
---

# Bonita Connector Lifecycle — Documentation-First

## Lifecycle Overview
```
SPEC → DOCUMENT → CHOOSE DESTINATION → VALIDATE ✓ → IMPLEMENT → TEST → BUILD → DEPLOY → UPDATE DOC → DELIVER
```

## Supported Artifact Types
| Type | Interface | Lifecycle |
|------|-----------|-----------|
| Connector | AbstractConnector | VALIDATE → CONNECT → EXECUTE → DISCONNECT |
| Actor Filter | UserFilter | shouldAutoAssign → check → filter |
| Event Handler | SHandler | execute (event-driven) |

## Phase 1: SPEC
Ask the user:
- Type: Connector, Actor Filter, or Event Handler
- Name and description
- Target Bonita version
- For Connector: external system, protocol (REST/SOAP/JDBC/LDAP/custom)
- For Connector: inputs (name, type, required) and outputs (name, type)
- For Actor Filter: selection criteria, auto-assign behavior
- For Event Handler: event types to listen for
- Error handling strategy (retry, fallback, circuit breaker)

Check existing connectors: `match_existing_connector` to avoid duplication.
Generate spec: `create_connector_spec` MCP tool.

## Phase 2: DOCUMENT
Generate technical specification using connector template.
Include: overview, I/O definition, lifecycle implementation plan, error handling, testing strategy.

## Phase 3: CHOOSE DESTINATION & PUBLISH
**Invoke `confluence-publish-workflow`** to ask user where to save and publish.

## Phase 4: VALIDATE
**GATE — Do NOT proceed without explicit approval**

## Phase 5: IMPLEMENT

### Connector Implementation
```java
public class MyConnector extends AbstractConnector {
    @Override
    protected void validateInputParameters() throws ConnectorValidationException {
        // Validate all required inputs
    }

    @Override
    protected void connect() throws ConnectorException {
        // Establish connection to external system
    }

    @Override
    protected void executeBusinessLogic() throws ConnectorException {
        // Main business logic
        setOutputParameter("result", value);
    }

    @Override
    protected void disconnect() throws ConnectorException {
        // Close connections, cleanup resources
    }
}
```

### Actor Filter Implementation
```java
public class MyFilter extends AbstractUserFilterImpl {
    @Override
    public void validateInputParameters() throws ConnectorValidationException { }

    @Override
    public boolean shouldAutoAssignTaskIfSingleResult() { return true; }

    @Override
    public List<Long> filter(String actorName) throws UserFilterException {
        // Return list of user IDs
    }
}
```

### Event Handler Implementation
```java
public class MyHandler extends SHandler {
    @Override
    public void execute(SEvent event) throws SHandlerExecutionException {
        // Handle event
    }
}
```

Use templates: `get_connector_template` MCP tool.

## Phase 6: TEST

### Unit Tests (JUnit 5)
- `should_validate_when_all_inputs_present()`
- `should_throw_when_required_input_missing()`
- `should_connect_when_valid_credentials()`
- `should_execute_when_connected()`
- `should_disconnect_after_execution()`
- `should_handle_error_gracefully()`

### Property Tests (jqwik)
- Fuzz all input parameters with valid/invalid values
- Verify validation catches all invalid inputs
- Test output consistency across random valid inputs

### Mutation Tests (PIT)
- Target: connector logic classes (not DTOs, not definitions)
- Threshold: 80% mutation score

### Integration Tests
- Test against real or staging external system
- Verify full lifecycle: validate → connect → execute → disconnect
- Test error scenarios: timeout, connection refused, invalid response

## Phase 7: BUILD
```bash
mvn clean package -B
```

## Phase 8: DEPLOY
- Include in .bar file for process deployment
- Or deploy as standalone extension via Bonita Portal
- Test in running Bonita instance

## Phase 9: UPDATE DOCUMENT
Add: actual classes, test results, deployment info, known limitations.

## Phase 10: DELIVER
Generate PDF if requested, update status to DELIVERED.
