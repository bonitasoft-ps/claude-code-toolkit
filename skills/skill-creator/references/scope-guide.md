# Skill Scope Guide — Detailed Examples and Decision Matrix

## Scope Decision Matrix

| Scenario | Scope | Why |
|----------|-------|-----|
| BDM naming conventions for all Bonita projects | ★★★ Enterprise | Company-wide standard |
| REST API controller patterns | ★★★ Enterprise | Shared architecture knowledge |
| Document branding (Bonitasoft logo, colors) | ★★★ Enterprise | Corporate identity |
| Code quality standards (Java 17, clean code) | ★★★ Enterprise | Team-wide enforcement |
| Testing patterns (JUnit 5, jqwik, Mockito) | ★★★ Enterprise | Consistent test quality |
| BPMN process modeling rules | ★★★ Enterprise | Platform best practices |
| Your preferred commit message format | ★★☆ Personal | Individual preference |
| Your custom code review checklist | ★★☆ Personal | Personal workflow |
| Your IDE shortcuts and snippets | ★★☆ Personal | Personal productivity |
| A specific project's custom BDM prefix rules | ★☆☆ Project | Only this project |
| Project-specific API endpoint documentation | ★☆☆ Project | Only this project |
| A project's custom deployment pipeline | ★☆☆ Project | Only this project |

## Enterprise Skill Examples (★★★)

Enterprise skills encode **company-wide domain knowledge** that every project should follow.

### Characteristics
- Created and maintained by team leads / architects
- Stored in the shared toolkit repository
- Copied to every new project's `.claude/skills/`
- Cannot be overridden by Personal or Project skills
- Typically have the most detailed progressive disclosure structure

### Current Enterprise Skills
| Skill | Domain | Files |
|-------|--------|-------|
| `bonita-bdm-expert` | Business Data Model | SKILL.md + 3 references + 1 script |
| `bonita-rest-api-expert` | REST API Extensions | SKILL.md + 4 references + 1 script + 1 asset |
| `bonita-groovy-expert` | Groovy Scripts | SKILL.md + 3 references |
| `bonita-process-expert` | BPM Processes | SKILL.md + 4 references |
| `bonita-uib-expert` | UI Builder | SKILL.md + 8 references + 1 script |
| `bonita-document-expert` | Document Generation | SKILL.md + 4 references + 3 assets |
| `bonita-coding-standards` | Code Quality | SKILL.md + 4 references + 1 script |
| `bonita-audit-expert` | Code Audits | SKILL.md + 3 references + 2 scripts |
| `testing-expert` | Testing Patterns | SKILL.md + 4 references + 2 scripts |
| `skill-creator` | Meta-skill | SKILL.md + 1 reference + 1 script |

### Example: Creating a New Enterprise Skill

**Scenario**: The team needs a skill for Bonita connector development.

```
Step 1: Name → bonita-connector-expert
Step 2: Structure →
  skills/bonita-connector-expert/
  ├── SKILL.md                          # Core rules (~200 lines)
  ├── references/
  │   ├── connector-archetype.md        # Maven archetype setup
  │   ├── error-handling-patterns.md    # Try-catch, retry, logging
  │   └── testing-connectors.md         # Unit test patterns
  ├── scripts/
  │   └── scaffold-connector.sh         # Create connector from template
  └── assets/
      └── ConnectorTemplate.java        # Ready-to-copy Java template

Step 3: Install →
  a) Create in toolkit: C:\JavaProjects\claude-code-toolkit\skills\bonita-connector-expert\
  b) Copy to each project: .claude\skills\bonita-connector-expert\
  c) Update toolkit README.md
  d) Commit and push to toolkit repo
```

## Personal Skill Examples (★★☆)

Personal skills encode **your individual preferences and workflow**.

### Characteristics
- Only YOU see them (not committed to any repo)
- Available in ALL your projects automatically
- Stored in `~/.claude/skills/`
- Can be overridden by Enterprise skills with the same name
- Usually simpler (no references needed, just a SKILL.md)

### Example: Personal Code Review Style

```yaml
---
name: my-review-preferences
description: Use when reviewing code or creating pull requests. Enforces my personal coding style preferences beyond team standards.
---

# My Code Review Preferences

## When reviewing code

- I prefer early returns over deeply nested if-else
- I want all DTOs to be Java Records unless Lombok is required
- I prefer `var` for obvious local variables
- I want test methods to start with `should_` not `test_`
- I prefer `assertThat(x).isEqualTo(y)` over `assertThat(y).isEqualTo(x)`
```

### Example: Personal Git Workflow

```yaml
---
name: my-git-workflow
description: Use when committing, branching, or creating pull requests. Follows my preferred git workflow conventions.
---

# My Git Workflow

## Commit messages
- Format: `type(scope): description`
- Types: feat, fix, refactor, test, docs, chore
- Max 72 chars for first line

## Branching
- Feature: `feature/TICKET-123-brief-description`
- Bugfix: `fix/TICKET-456-brief-description`
- Always rebase before merge
```

## Project Skill Examples (★☆☆)

Project skills encode **project-specific knowledge** that only applies to one project.

### Characteristics
- Committed to the project repository
- Available to everyone working on this project
- Stored in `.claude/skills/` at the project root
- Overridden by both Enterprise and Personal skills
- May reference project-specific files, APIs, or conventions

### Example: Project-Specific API Documentation

```yaml
---
name: loan-request-api
description: Use when working with the Loan Request module in this project. Provides API endpoints, BDM structure, and business rules specific to loan processing.
---

# Loan Request API Expert

## When activated

1. Read `extensions/src/main/java/com/company/api/loanrequest/` for existing controllers
2. Read `bdm/bom.xml` and search for `LoanRequest` objects

## API Endpoints

| Endpoint | Method | Controller |
|----------|--------|-----------|
| `/loan/requests` | GET | LoanRequestsAccessible |
| `/loan/request/create` | POST | CreateLoanRequest |
| `/loan/request/{id}/approve` | POST | ApproveLoanRequest |

## Business Rules

- Loan amounts > 50,000 require manager approval
- Documents must be uploaded before submission
- Status flow: DRAFT → SUBMITTED → UNDER_REVIEW → APPROVED/REJECTED
```

## When a Skill Should NOT Be Created

Not everything needs to be a skill. **Do NOT create a skill** when:

1. **The information is one-time** — If it's a single task or question, just answer it directly
2. **It duplicates AGENTS.md** — Project structure and build commands belong in AGENTS.md, not skills
3. **It's too narrow** — A skill for "how to add a button to page X" is too specific
4. **It's too broad** — A skill for "everything about Java" is too broad and will always load
5. **It conflicts with an existing skill** — Enhance the existing skill instead

### Good rule of thumb
If you'll use this knowledge in **3+ future conversations**, it's worth creating a skill.
If it's a **one-off** task, just do the work and move on.
