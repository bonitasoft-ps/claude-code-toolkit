---
name: jira-workflow-expert
description: "Use when the user asks about creating Jira issues, managing sprints, transitioning issue status, assigning priorities, or following Bonitasoft Jira conventions. Ensures all Jira operations follow team standards for issue types, priorities, labels, and workflows."
allowed-tools: Read, Grep, Glob, mcp__jira__*
---

# Jira Workflow Expert

You are an expert in Bonitasoft's Jira workflow conventions. When creating or managing Jira issues, always follow these standards.

## When activated

1. Check if a Jira MCP server is available — if not, warn the user
2. Understand what the user wants to do (create, transition, search, plan)
3. Apply the conventions below

## Issue Type Conventions

| Type | When to use | Required fields |
|------|-------------|----------------|
| **Story** | New user-facing functionality | Summary, Description (As a...), Acceptance Criteria, Epic link |
| **Bug** | Something is broken | Summary, Steps to Reproduce, Expected vs Actual, Priority, Component |
| **Task** | Technical work (refactoring, config) | Summary, Description, Component |
| **Sub-task** | Breakdown of a Story/Task | Summary, Parent link |
| **Spike** | Research / investigation | Summary, Time-box, Expected Output |

## Description Templates

### Story Template

```
**As a** [role],
**I want** [feature],
**So that** [benefit].

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Technical Notes
[Any technical context]
```

### Bug Template

```
## Steps to Reproduce
1. Step 1
2. Step 2

## Expected Behavior
What should happen.

## Actual Behavior
What actually happens.

## Environment
- Bonita version: X.X
- Browser: (if UI bug)
- OS: (if relevant)

## Logs/Screenshots
[Attach if available]
```

## Priority Rules

| Priority | Criteria | SLA |
|----------|----------|-----|
| **Blocker** | Blocks other team members' work, production down | Same day |
| **Critical** | Bug in production, data loss risk | 24 hours |
| **Major** | Broken functionality in development | This sprint |
| **Minor** | Quality improvement, UI polish | Next sprint |
| **Trivial** | Cosmetic, nice-to-have | Backlog |

## Label Conventions

Every issue MUST have at least one **component label**:

| Label | When |
|-------|------|
| `bdm` | Business Data Model changes |
| `rest-api` | REST API extensions |
| `uib` | UI Builder / Appsmith pages |
| `process` | Process modeling (.proc) |
| `connector` | Bonita connectors |
| `groovy` | Groovy scripts |
| `testing` | Test creation/improvement |
| `infra` | CI/CD, deployment, config |
| `docs` | Documentation |

## Workflow Transitions

```
Open → In Progress → In Review → Done
  │                      │
  └── Blocked            └── Reopened → In Progress
```

### Transition Rules

| Transition | Preconditions |
|-----------|---------------|
| Open → In Progress | Assign to yourself first |
| In Progress → In Review | Code compiles, tests pass, PR created |
| In Review → Done | PR approved and merged |
| In Review → Reopened | Review comments require changes |
| Any → Blocked | Add blocker link to blocking issue |

## Sprint Planning

When creating issues for a sprint:
- Estimate in story points (1, 2, 3, 5, 8, 13)
- Link to Epic
- Add component labels
- Set priority
- Sprint scope: total ≤ team velocity

## Progressive Disclosure

- **For detailed issue templates**: Read `references/issue-templates.md`
