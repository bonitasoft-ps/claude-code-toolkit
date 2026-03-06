# Project Spec Templates

Detailed templates and examples for the project-spec-generator skill.

## 1. Epic Template

```markdown
# Epic: [Epic Name]

**ID**: EPIC-[number]
**Owner**: [Product Owner]
**Priority**: [Must/Should/Nice]
**Target Sprint**: [Sprint X-Y]

## Goal
[What this epic achieves for the user/business]

## Success Criteria
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] [Measurable outcome 3]

## Stories in this Epic
| ID | Title | Priority | Estimate | Status |
|----|-------|----------|----------|--------|
| S-001 | [Title] | Must | M | Draft |
| S-002 | [Title] | Must | S | Draft |
| S-003 | [Title] | Should | L | Draft |

## Dependencies
- **External**: [APIs, services, teams]
- **Internal**: [Other epics, shared components]

## Risks
| Risk | Mitigation |
|------|------------|
| [Risk 1] | [Plan] |

## Notes
[Additional context, links, references]
```

## 2. Detailed User Story Example

```markdown
# Story S-001: User Login with Email and Password

**Epic**: EPIC-01 Authentication
**Priority**: Must Have
**Estimate**: M (3-5 days)
**Status**: Ready for Development

## User Story
As a registered user,
I want to log in with my email and password,
so that I can access my personal dashboard and data.

## Acceptance Criteria

### Happy Path
- [ ] AC-1: Given a registered user with email "user@example.com" and valid password,
       when they submit the login form,
       then they are redirected to the dashboard and see a welcome message.

- [ ] AC-2: Given a successful login,
       when the server responds,
       then a JWT token is stored in httpOnly cookie with 24h expiration.

### Error Cases
- [ ] AC-3: Given an unregistered email,
       when the user submits the login form,
       then they see "Invalid email or password" (no info leak about email existence).

- [ ] AC-4: Given a registered email with wrong password,
       when the user submits the login form,
       then they see "Invalid email or password" and the attempt is logged.

- [ ] AC-5: Given 5 consecutive failed attempts,
       when the user tries again,
       then the account is temporarily locked for 15 minutes and user is notified.

### Edge Cases
- [ ] AC-6: Given a user who is already logged in on another device,
       when they log in from a new device,
       then both sessions remain active (multi-session support).

- [ ] AC-7: Given a user with an expired password (>90 days),
       when they log in successfully,
       then they are redirected to the password change page.

## Technical Notes
- **Endpoint**: POST /api/v1/auth/login
- **Request body**: { email: string, password: string }
- **Response**: { token: string, user: { id, name, role } }
- **Rate limiting**: 10 attempts per IP per minute
- **Password hashing**: bcrypt with cost factor 12
- **Logging**: Log all attempts (success/failure) with IP and timestamp

## UI/UX Notes
- Form fields: Email (with validation), Password (with show/hide toggle)
- "Forgot password?" link below the form
- "Remember me" checkbox (extends token to 30 days)
- Loading spinner on submit button while authenticating

## Dependencies
- Depends on: Database schema (users table), Email service (for lockout notifications)
- Blocks: S-002 (Registration), S-003 (Password Reset)

## Definition of Done
- [ ] All acceptance criteria pass
- [ ] Unit tests cover happy path and error cases
- [ ] Integration test with real database
- [ ] API documented in OpenAPI spec
- [ ] Security review completed
- [ ] No hardcoded secrets
```

## 3. API Specification Template

```markdown
# API Specification: [Service Name]

**Version**: 1.0.0
**Base URL**: /api/v1
**Authentication**: Bearer JWT

## Endpoints

### POST /auth/login
**Description**: Authenticate user with credentials

**Request**:
```json
{
  "email": "string (required, valid email)",
  "password": "string (required, min 8 chars)"
}
```

**Responses**:
| Status | Description | Body |
|--------|-------------|------|
| 200 | Success | `{ "token": "jwt", "user": { "id", "name", "role" } }` |
| 400 | Invalid input | `{ "error": "validation_error", "details": [...] }` |
| 401 | Bad credentials | `{ "error": "invalid_credentials" }` |
| 429 | Rate limited | `{ "error": "rate_limited", "retryAfter": 60 }` |

**Headers**:
- `Content-Type: application/json`
- `X-Request-ID: uuid` (for tracing)

**Notes**:
- Rate limited to 10 req/min per IP
- Failed attempts are logged
- Account locks after 5 failures

---

### GET /users/me
**Description**: Get current user profile
**Auth**: Required

**Response 200**:
```json
{
  "id": "uuid",
  "email": "string",
  "name": "string",
  "role": "admin | user | viewer",
  "createdAt": "ISO-8601",
  "lastLogin": "ISO-8601"
}
```
```

## 4. Data Model Template

```markdown
# Data Model: [Project Name]

## Entity Relationship Overview

```
User 1──* Session
User 1──* Project
Project 1──* Task
Task *──* Tag
```

## Entities

### User
| Field | Type | Constraints | Index | Description |
|-------|------|-------------|-------|-------------|
| id | UUID | PK | Yes | Auto-generated |
| email | VARCHAR(255) | UNIQUE, NOT NULL | Yes | Login identifier |
| password_hash | VARCHAR(72) | NOT NULL | No | bcrypt hash |
| name | VARCHAR(100) | NOT NULL | No | Display name |
| role | ENUM | DEFAULT 'user' | Yes | admin, user, viewer |
| created_at | TIMESTAMP | DEFAULT NOW() | No | Registration date |
| last_login | TIMESTAMP | NULLABLE | No | Last successful login |
| failed_attempts | INT | DEFAULT 0 | No | Consecutive failures |
| locked_until | TIMESTAMP | NULLABLE | No | Account lock expiry |

### Session
| Field | Type | Constraints | Index | Description |
|-------|------|-------------|-------|-------------|
| id | UUID | PK | Yes | Session identifier |
| user_id | UUID | FK → User.id | Yes | Owner |
| token | VARCHAR(500) | NOT NULL | Yes | JWT token |
| ip_address | VARCHAR(45) | NOT NULL | No | Client IP |
| user_agent | TEXT | NULLABLE | No | Browser info |
| expires_at | TIMESTAMP | NOT NULL | Yes | Token expiry |
| created_at | TIMESTAMP | DEFAULT NOW() | No | Session start |
```

## 5. Architecture Decision Record (ADR) Template

```markdown
# ADR-[number]: [Decision Title]

**Date**: YYYY-MM-DD
**Status**: Proposed | Accepted | Deprecated | Superseded by ADR-XXX
**Deciders**: [Names/roles involved]

## Context
[What is the issue? Why do we need to make this decision?]

## Decision
[What did we decide? Be specific.]

## Considered Alternatives

### Option A: [Name]
- **Pros**: [Benefits]
- **Cons**: [Drawbacks]
- **Cost**: [Estimated effort/cost]

### Option B: [Name]
- **Pros**: [Benefits]
- **Cons**: [Drawbacks]
- **Cost**: [Estimated effort/cost]

## Consequences

### Positive
- [Benefit 1]
- [Benefit 2]

### Negative
- [Trade-off 1]
- [Mitigation plan]

### Risks
- [Risk and its mitigation]

## References
- [Links to relevant docs, articles, RFCs]
```

## 6. Sprint Planning Template

```markdown
# Sprint [X]: [Sprint Goal]

**Dates**: YYYY-MM-DD → YYYY-MM-DD
**Capacity**: [X story points / Y dev-days]
**Goal**: [One sentence describing what we deliver]

## Stories Committed

| ID | Title | Estimate | Owner | Status |
|----|-------|----------|-------|--------|
| S-001 | User Login | M (5pt) | Dev A | To Do |
| S-002 | Registration | M (5pt) | Dev B | To Do |
| S-003 | Password Reset | S (3pt) | Dev A | To Do |

**Total**: 13 points (within capacity)

## Dependencies
- [ ] [External dependency and who handles it]

## Risks
- [ ] [Risk and mitigation]

## Definition of Done (Sprint Level)
- [ ] All committed stories meet their acceptance criteria
- [ ] Code reviewed and merged to main
- [ ] Tests passing (unit + integration)
- [ ] API docs updated
- [ ] Demo prepared for stakeholders
```

## 7. Generating Stories from PRD

### Workflow

1. Read `docs/PRD.md` — extract functional requirements
2. Group requirements into epics (by domain/feature area)
3. For each requirement, create a user story:
   - Convert requirement to "As a..., I want..., so that..." format
   - Add 3-5 acceptance criteria (happy path + error + edge case)
   - Add technical notes from architecture doc
   - Estimate size (S/M/L/XL)
   - Identify dependencies between stories
4. Create epic files with story index
5. Order stories by dependency and priority

### Estimation Guide

| Size | Story Points | Days | Characteristics |
|------|:---:|:---:|---|
| **S** (Small) | 1-2 | <1 | Single component, clear solution, no unknowns |
| **M** (Medium) | 3-5 | 1-3 | 2-3 components, known patterns, minor unknowns |
| **L** (Large) | 8 | 3-5 | Multiple components, some complexity, needs design |
| **XL** (Extra Large) | 13+ | 5+ | **Split this!** Too large for one story |

### Splitting Strategies

If a story is XL, split by:

1. **Workflow steps**: Login → Registration → Password Reset
2. **Data variations**: CRUD (Create, Read, Update, Delete as separate stories)
3. **User types**: Admin view vs User view
4. **Happy path vs errors**: Basic flow first, error handling second
5. **Interface layers**: API endpoint → UI form → Integration test
