# Skills Catalog — claude-code-toolkit

22 skills covering all Bonita PS development domains.

## Quick Reference

| Skill | Scope | User-Invocable | Auto-invokes when... |
|-------|-------|---------------|---------------------|
| `bonita-audit-expert` | ★★★ Enterprise | Yes | Code audits, quality assessment, audit reports, technical debt analysis |
| `bonita-bdm-expert` | ★★★ Enterprise | Yes | BDM queries, data model, JPQL, business objects, bom.xml, indexes, countFor |
| `bonita-coding-standards` | ★★★ Enterprise | Yes | Coding standards, code quality, Java 17 features, refactoring, Javadoc, PMD |
| `bonita-connector-expert` | ★★★ Enterprise | Yes | `*Connector.java`, `*Filter.java`, `*Handler.java`, `RestAPI*.java` files |
| `bonita-debugging-expert` | ★★★ Enterprise | Yes | Errors, exceptions, bugs, debugging, stuck processes, stack traces |
| `bonita-deployment-expert` | ★★★ Enterprise | Yes | Deploying apps, CI/CD pipelines, .bar files, environment config, DB migration |
| `bonita-document-expert` | ★★★ Enterprise | Yes | PDF, HTML reports, Word, Excel, corporate branding, iText, POI, Thymeleaf |
| `bonita-estimation-expert` | ★★★ Enterprise | Yes | Effort estimation, project sizing, how long, budget, proposal, PS quotes |
| `bonita-groovy-expert` | ★★★ Enterprise | Yes | Groovy scripts in processes, initProcess, connector scripts, .proc files |
| `bonita-integration-testing-expert` | ★★★ Enterprise | Yes | Integration tests, controller tests, `doHandle` testing, full request lifecycle |
| `bonita-migration-expert` | ★★★ Enterprise | Yes | Version migration, Groovy→Java, javax→jakarta, BDM schema migration |
| `bonita-performance-expert` | ★★★ Enterprise | Yes | Performance issues, slow processes, timeouts, memory leaks, high CPU |
| `bonita-process-expert` | ★★★ Enterprise | Yes | Process modeling, `.proc` files, subprocesses, actors, contracts, timers |
| `bonita-rest-api-expert` | ★★★ Enterprise | Yes | REST API extensions, controllers, DTOs, services, OpenAPI documentation |
| `bonita-uib-expert` | ★★★ Enterprise | Yes | UI Builder (UIB), Appsmith pages, widgets, JS Objects, APIs, dashboards |
| `confluence-docs-expert` | ★★★ Enterprise | No | Creating/updating Confluence pages, tech specs, documentation standards |
| `jira-workflow-expert` | ★★★ Enterprise | No | Creating Jira issues, managing sprints, transitions, priorities, labels |
| `multi-repo-manager` | ★★☆ Personal | Yes | Git operations across multiple related repositories |
| `prompt-engineering-log` | ★★☆ Personal | Yes | Generating significant AI content needing audit trail |
| `safe-git-workflow` | ★★★ Enterprise | No (auto-only) | Commit, push, PR — enforces `claude/{type}/{desc}` branch workflow |
| `skill-creator` | ★★★ Enterprise | Yes | Creating new Claude Code skills, SKILL.md design, progressive disclosure |
| `testing-expert` | ★★★ Enterprise | No | Testing strategy, unit tests, JUnit 5, jqwik, PIT, JaCoCo, coverage |

## Detailed Descriptions

### bonita-audit-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Bash, Edit, Write

Conducts comprehensive code reviews of Bonita projects covering backend (Java/Groovy/BPM/BDM) and frontend (UI Builder/Appsmith) components. Generates professional audit reports in DOCX/PDF format with weighted scores, GO/NO-GO verdicts, and phased remediation plans.

**Key capabilities:**
- Backend audit: Java/Groovy code, BDM, REST APIs, processes, connectors
- UIB audit: pages, widgets, JS Objects, API calls, performance
- Full audit: both combined with weighted scoring
- Pre-upgrade compatibility checks (javax→jakarta, Groovy 2→4, Hibernate 5→6)
- Corporate report generation

**References directory:** `references/` — backend-audit-template, uib-audit-template, audit-checklist

---

### bonita-bdm-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Bash

Expert in Bonita Business Data Model (BDM) design, JPQL queries, and data architecture. Enforces strict conventions on naming, documentation, indexing, and query patterns.

**Key capabilities:**
- BDM naming conventions (`PB` prefix for named queries)
- JPQL query patterns and optimization
- countFor requirement for every collection query
- Indexes and unique constraints
- BDM access control configuration
- REST API compatibility requirements

**References directory:** `references/` — datamodel-rules, query-patterns, access-control

---

### bonita-coding-standards
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Bash

Senior Java Architect and Code Quality Lead enforcing Bonitasoft coding standards across all Bonita BPM projects.

**Key capabilities:**
- Java 17 features: Records, Sealed Classes, Pattern Matching, text blocks
- Groovy scripting standards
- BDM naming and design
- REST API extension patterns
- Method length limits (max 30 lines)
- Javadoc requirements for public methods
- Checkstyle and PMD rule enforcement
- SRP, DRY, SOLID principles

**References directory:** `references/` — java17-patterns, delivery-checklist, connectors, deployment

---

### bonita-connector-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Bash, Edit, Write

Senior Bonita Platform Engineer specializing in all Bonita extension points.

**Key capabilities:**
- Connector lifecycle: VALIDATE → CONNECT → EXECUTE → DISCONNECT
- Actor filters
- Event handlers
- REST API extensions
- Error handling and resource management
- Connector testing patterns
- Version compatibility (7.x vs 2021+ vs 2024+)

---

### bonita-debugging-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Bash

Bonita Platform Debugging Specialist with structured 4-step diagnostic workflow.

**Key capabilities:**
- Problem type identification
- Log analysis and evidence collection
- Exception matching to known causes
- Resolution pattern application
- All layers: engine, BDM, connectors, UIB, REST API

---

### bonita-deployment-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Bash

Expert in deploying Bonita applications to production environments.

**Key capabilities:**
- .bar file packaging
- CI/CD pipelines: GitHub Actions, Jenkins, GitLab CI
- Environment configuration management
- BDM schema migration for database changes
- Bonita server tuning
- Blue/green deployments
- Never hardcode credentials — environment variables or Bonita parameters

**References directory:** `references/` — deployment patterns

---

### bonita-document-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Edit, Write, Bash

Expert in corporate document generation ensuring every document follows Bonitasoft corporate brand identity.

**Key capabilities:**
- PDF generation (OpenPDF, iText, Flying Saucer)
- HTML reports (Thymeleaf)
- Word/Excel (Apache POI)
- Bonitasoft brand guidelines (colors, fonts, logo)
- BrandingConfig pattern enforcement
- Corporate CSS standards

**References directory:** `references/` — pdf-generation, office-generation, thymeleaf, maven-deps | **Assets:** BrandingConfig.java, corporate.css, bonitasoft-logo.svg

---

### bonita-estimation-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob

Bonitasoft Professional Services Estimation Specialist producing structured, defensible effort estimates.

**Key capabilities:**
- PS engagement types: new project, audit, upgrade, connector development, training
- Component counting methodology
- Effort tables per component type
- Risk multipliers (legacy code, missing docs, new team)
- Min/typical/max confidence intervals
- Structured output formats for proposals

---

### bonita-groovy-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Bash

Expert in Groovy scripting within Bonita BPM/BPA processes.

**Key capabilities:**
- initProcess scripts
- Connector scripts
- Operation scripts
- Form mappings
- Script tasks
- API accessor pattern
- DAO integration
- Script extraction from .proc files

---

### bonita-integration-testing-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Bash, Edit, Write

Senior integration testing specialist for Bonita REST API extensions.

**Key capabilities:**
- Full request lifecycle tests through `doHandle()`
- HTTP status code testing
- Mock chain setup for Bonita APIs
- `RestApiResponseBuilder` tests
- Abstract/Concrete controller pattern testing
- JUnit 5 + Mockito 5 + AssertJ
- Test naming: `should_X_when_Y()`

**References directory:** `references/` — bonita-test-harness, controller-test-patterns, dto-validation | **Assets:** IntegrationTestTemplate.java

---

### bonita-migration-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Bash

Expert in migrating Bonita applications between versions.

**Key capabilities:**
- Bonita 7.x → 2021+ transition
- Bonita 2021+ → 2023+ (Jakarta EE) transition
- javax → jakarta namespace migration
- Groovy 2 → 4 migration
- Hibernate 5 → 6 migration
- BDM schema migration
- REST API extension migration
- Breaking changes detection

---

### bonita-performance-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Bash

Bonita Performance Architect specializing in diagnosing and resolving performance bottlenecks.

**Key capabilities:**
- BDM query optimization
- Bonita engine tuning
- UIB frontend performance
- REST API response time optimization
- Database-specific tips
- Memory leak diagnosis
- Data-driven approach: measure first, then optimize

---

### bonita-process-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Bash

Expert in Bonita BPM/BPA process design and implementation.

**Key capabilities:**
- Process modeling in .proc files
- 3-level process architecture (orchestration / coordination / execution)
- Subprocesses and call activities
- Actor and contract design
- Connectors and event handling
- Timers and gateways
- Subprocess reuse

**References directory:** `references/` — bpm-standards, process-tiering, contracts, connector-error-patterns

---

### bonita-rest-api-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Bash, Edit, Write

Expert in Bonita REST API extension development (Java 17, Lombok, JUnit 5, AssertJ).

**Key capabilities:**
- Abstract/Concrete controller pattern
- DTOs and services
- OpenAPI documentation
- README per controller package
- Error handling and response building
- Security: OWASP Top 10 compliance

**References directory:** `references/` — controller-checklist, dto-patterns, readme-template, openapi

---

### bonita-uib-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Bash

Expert in Bonita UI Builder (UIB/Appsmith) development.

**Key capabilities:**
- Page and widget architecture
- JS Objects patterns
- API actions configuration
- Dashboard design
- Form design with dynamic bindings
- Data tables and charts
- Naming conventions
- bonita-api-plugin integration

**References directory:** `references/` — widgets, api-actions, js-patterns, header, charts, naming, xml, troubleshooting

---

### confluence-docs-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Write, Confluence MCP tools

Expert in Bonitasoft's Confluence documentation conventions.

**Key capabilities:**
- Tech Spec page template
- ADR (Architecture Decision Record) template
- Runbook template
- Page structure and labels
- Confluence MCP integration (creates pages directly when available)

**References directory:** `references/page-templates.md`

---

### jira-workflow-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Jira MCP tools

Expert in Bonitasoft's Jira workflow conventions.

**Key capabilities:**
- Issue type conventions: Story, Bug, Task, Sub-task
- Priority rules (Blocker → same day SLA)
- Required labels per component
- Sprint planning
- Status transitions
- Jira MCP integration (creates/transitions issues directly when available)

**References directory:** `references/issue-templates.md`

---

### multi-repo-manager
**Scope:** Personal ★★☆ | **Allowed tools:** Bash (git only) | **User-invocable:** Yes

Performs git operations across multiple related repositories in a single command.

**Usage:**
```
/multi-repo-manager status    — git status on all repos
/multi-repo-manager pull      — git pull on all repos
/multi-repo-manager push      — git push on all repos
```

---

### prompt-engineering-log
**Scope:** Personal ★★☆ | **Allowed tools:** Read, Write, Edit, Glob, Grep | **User-invocable:** Yes

Creates audit trail documentation for AI-generated content.

**Activates when:** Generating Confluence pages, specifications, catalogs, reports, documentation

**Usage:**
```
/prompt-engineering-log    — save a log of this generation session
```

---

### safe-git-workflow
**Scope:** Enterprise ★★★ | **Auto-only** (not user-invocable)

Enforces branch-based workflow. All changes go through `claude/{type}/{description}` branches with PRs via `gh` CLI. Blocks direct commits to main/master/develop.

**References directory:** `references/branch-examples.md`

---

### skill-creator
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Edit, Write, Bash | **User-invocable:** Yes

Meta-skill for generating Claude Code skills following Anthropic agent skills standard and Bonitasoft methodology.

**Key capabilities:**
- Scope determination: Enterprise / Personal / Project
- SKILL.md structure and frontmatter
- Progressive disclosure design
- `references/` directory structure
- Install.sh integration
- Conflict checking

---

### testing-expert
**Scope:** Enterprise ★★★ | **Allowed tools:** Read, Grep, Glob, Bash, Edit, Write

Expert in Java testing strategy and implementation.

**Key capabilities:**
- JUnit 5 test structure
- Mockito 5 mocking patterns
- AssertJ fluent assertions
- jqwik property-based testing
- PIT mutation testing
- JaCoCo coverage thresholds
- Test naming: `should_X_when_Y()`
- `*IT.java` for integration tests (Maven Failsafe)

**References directory:** `references/` — junit5, property-testing, mutation-testing, bonita-mocking
