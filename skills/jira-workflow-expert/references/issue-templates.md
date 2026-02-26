# Jira Issue Templates — Detailed

## Story: New REST API Endpoint

```
**As a** [frontend developer / external system],
**I want** [endpoint description],
**So that** [business value].

## Acceptance Criteria
- [ ] Endpoint follows Abstract/Concrete controller pattern
- [ ] DTOs defined for request and response
- [ ] OpenAPI annotations present (@Tag, @Operation, @ApiResponse)
- [ ] README.md created for controller
- [ ] Unit tests cover happy path and error cases
- [ ] Integration test validates end-to-end flow
- [ ] No hardcoded strings (constants used)

## Technical Notes
- Module: extensions/[module-name]
- Base path: /api/extension/[path]
- Authentication: Required (Bonita session)

## Test Scenarios
1. Valid request → 200 OK
2. Invalid input → 400 Bad Request
3. Not found → 404
4. Unauthorized → 401
```

## Story: New BDM Entity

```
**As a** [business analyst / developer],
**I want** [entity description],
**So that** [business value].

## Acceptance Criteria
- [ ] Entity follows PB naming prefix
- [ ] All attributes have descriptions
- [ ] countFor query defined
- [ ] Appropriate indexes created
- [ ] Access control configured
- [ ] Unit tests for custom queries

## BDM Definition
- Entity name: PB[EntityName]
- Package: com.company.model.[domain]
- Attributes: [list]
- Queries: [list]
- Indexes: [list]
```

## Bug: Process Error

```
## Steps to Reproduce
1. Deploy process [name] version [X.X]
2. Start case with input: [describe]
3. Execute task [name]
4. Error occurs at [step]

## Expected Behavior
Process should [expected outcome].

## Actual Behavior
Process [actual outcome]. Error: [error message]

## Environment
- Bonita Runtime: [version]
- Database: [PostgreSQL/MySQL/Oracle]
- Test Toolkit: [version]

## Logs
[Paste relevant logs]

## Related
- Process: [process name and version]
- BDM: [affected entities]
- Connectors: [affected connectors]
```

## Task: Refactoring

```
## Objective
[What needs to be refactored and why]

## Scope
- Files: [list affected files]
- Module: [module name]
- Impact: [what might break]

## Approach
1. [Step 1]
2. [Step 2]

## Verification
- [ ] Compilation passes
- [ ] All existing tests pass
- [ ] No new Checkstyle/PMD violations
- [ ] Method call sites updated

## Risk
[Low/Medium/High] — [explanation]
```
