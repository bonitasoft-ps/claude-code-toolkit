# Confluence Document Templates

## Library Specification Template

```markdown
## Overview
| Field | Value |
|-------|-------|
| Name | {library-name} |
| Version | {version} |
| Java | 17 |
| Bonita Compatibility | {versions} |
| Author | {author} |
| Date | {date} |
| Status | DRAFT |

## Purpose
{Why this library exists, what problem it solves}

## Public API
{Interfaces, classes, methods with signatures}

## Dependencies
| Dependency | Version | Purpose |
|------------|---------|---------|

## Architecture
{Package structure, class diagram}

## Testing Strategy
- Unit: JUnit 5, coverage target {x}%
- Property: jqwik, invariants: {list}
- Mutation: PIT, threshold: 80%
- Integration: {scope}

## Build & Deployment
- Build: `mvn clean package`
- GAV: `{groupId}:{artifactId}:{version}`

## Implementation Results
_To be filled after implementation_
```

## Connector Specification Template

```markdown
## Overview
| Field | Value |
|-------|-------|
| Name | {connector-name} |
| Type | Connector / Actor Filter / Event Handler |
| Protocol | {REST/SOAP/JDBC/LDAP/...} |
| Bonita Version | {version} |
| Author | {author} |
| Date | {date} |
| Status | DRAFT |

## Purpose
{What external system it connects to and why}

## Inputs
| Name | Type | Required | Description |
|------|------|----------|-------------|

## Outputs
| Name | Type | Description |
|------|------|-------------|

## Lifecycle
- VALIDATE: {input validation rules}
- CONNECT: {connection setup}
- EXECUTE: {main logic}
- DISCONNECT: {cleanup}

## Error Handling
{Error types, retry strategy, fallback behavior}

## Testing Strategy
- Unit: Mock external system
- Property: Fuzz inputs
- Mutation: Business logic
- Integration: Test against real/staging system

## Implementation Results
_To be filled after implementation_
```

## Process Specification Template

```markdown
## Overview
| Field | Value |
|-------|-------|
| Process Name | {name} |
| Version | {version} |
| Bonita Version | {version} |
| Author | {author} |
| Date | {date} |
| Status | DRAFT |

## Purpose
{Business process description}

## Actors
| Actor | Role | Description |
|-------|------|-------------|

## Tasks
| # | Name | Type | Actor | Description | Connector |
|---|------|------|-------|-------------|-----------|

## Gateways
| Name | Type | Conditions |
|------|------|------------|

## Variables
| Name | Type | Scope | Description |
|------|------|-------|-------------|

## Events
| Name | Type | Trigger | Description |
|------|------|---------|-------------|

## Contracts
| Task | Input | Type | Required | Constraint |
|------|-------|------|----------|------------|

## Flow Description
{Step-by-step process flow narrative}

## Testing Strategy
- Flow test: Bonita Test Toolkit
- Happy path + all gateway branches
- Timer simulation
- Error paths

## Implementation Results
_To be filled after implementation_
```

## REST API Specification Template

```markdown
## Overview
| Field | Value |
|-------|-------|
| API Name | {name} |
| Base Path | /bonita/API/extension/{path} |
| Version | {version} |
| Author | {author} |
| Date | {date} |
| Status | DRAFT |

## Endpoints
### {METHOD} {path}
- **Description**: {what it does}
- **Permissions**: {required permissions}
- **Parameters**: {query/path params}
- **Request Body**: {JSON schema}
- **Response**: {JSON schema}
- **Error Codes**: {4xx, 5xx}

## DTOs
{Record definitions with fields}

## Security
- Authentication: Bonita session
- Authorization: {profile/permissions}

## Testing Strategy
- Unit: JUnit 5 + Mockito
- Integration: REST Assured
- Property: Input fuzzing

## Implementation Results
_To be filled after implementation_
```

## Audit Plan Template

```markdown
## Overview
| Field | Value |
|-------|-------|
| Client | {client-name} |
| Scope | {what to audit} |
| Standards | {categories: backend, frontend, bdm, ...} |
| Author | {author} |
| Date | {date} |
| Status | DRAFT |

## Scope
{Detailed scope description}

## Standards Applied
| Category | Rule Count | Focus |
|----------|------------|-------|

## Timeline
| Phase | Duration | Description |
|-------|----------|-------------|

## Deliverables
- Audit report (PDF)
- Severity distribution
- Top 10 issues
- Recommendations

## Audit Results
_To be filled after execution_
```

## Upgrade Plan Template

```markdown
## Overview
| Field | Value |
|-------|-------|
| Client | {client-name} |
| Source Version | {current} |
| Target Version | {target} |
| Database | {type + version} |
| App Server | {Tomcat version} |
| Author | {author} |
| Date | {date} |
| Status | DRAFT |

## Version Jump Path
{source} → {intermediate...} → {target}

## Pre-Upgrade Audit
| Category | Issues | Blockers |
|----------|--------|----------|

## Migration Steps
| # | Step | Risk | Rollback |
|---|------|------|----------|

## Custom Code Changes
| Component | Change Required | Effort |
|-----------|----------------|--------|

## Rollback Plan
{Step-by-step rollback procedure}

## Testing Plan
- Smoke tests
- Process execution tests
- Integration verification

## Upgrade Results
_To be filled after execution_
```

## BDM Specification Template

```markdown
## Overview
| Field | Value |
|-------|-------|
| Model Name | {name} |
| Bonita Version | {version} |
| Entity Count | {n} |
| Author | {author} |
| Date | {date} |
| Status | DRAFT |

## Business Domain
{Domain description}

## Entities
### {EntityName}
| Field | Type | Required | Description |
|-------|------|----------|-------------|

### Relationships
| Source | Target | Type | Cardinality | Fetch |
|--------|--------|------|-------------|-------|

### Queries
| Entity | Query | Parameters | Returns | CountFor |
|--------|-------|------------|---------|----------|

### Indexes
| Entity | Fields | Unique |
|--------|--------|--------|

## Implementation Results
_To be filled after implementation_
```

## UI Specification Template

```markdown
## Overview
| Field | Value |
|-------|-------|
| Application Name | {name} |
| Type | React / UIBuilder / Living App |
| Bonita Version | {version} |
| Author | {author} |
| Date | {date} |
| Status | DRAFT |

## Pages
| Page | Type | Description |
|------|------|-------------|

## Components / Widgets
| Name | Type | Data Source |
|------|------|------------|

## Navigation
{Menu structure, routing}

## Data Sources
| Source | Endpoint | Method |
|--------|----------|--------|

## Branding
- Primary: #2c3e7a
- Accent: #e97826
- Theme: {custom or default}

## Implementation Results
_To be filled after implementation_
```
