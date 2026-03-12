---
name: bonita-project-extension-lifecycle
description: |
  Complete lifecycle for Bonita Project Extensions: spec → document → publish/save →
  validate → implement → test → build → deploy as .bar → update docs → deliver.
  Use for custom code that extends Bonita runtime functionality within a project.
  Trigger: "project extension", "bonita extension", "custom extension", "extension lifecycle"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, mcp__claude_ai_Atlassian_2__createConfluencePage, mcp__claude_ai_Atlassian_2__updateConfluencePage, mcp__Bonita-AI-Agent__build_pdf
user_invocable: true
---

# Bonita Project Extension Lifecycle — Documentation-First

## Lifecycle
```
SPEC → DOCUMENT → CHOOSE DESTINATION → VALIDATE ✓ → IMPLEMENT → TEST → BUILD → DEPLOY (.bar) → UPDATE DOC → DELIVER
```

## Phase 1: SPEC
Ask the user:
- Extension name and purpose
- What it extends (process behavior, data access, UI, integration)
- Which processes will use it
- Bonita version and bonita-project parent version
- Dependencies on BDM, connectors, or external systems
- Required permissions

## Phase 2-4: DOCUMENT → PUBLISH → VALIDATE
Generate spec, publish to chosen destination, get approval.

## Phase 5: IMPLEMENT

### Maven Structure (with bonita-project parent)
```xml
<parent>
    <groupId>org.bonitasoft</groupId>
    <artifactId>bonita-project</artifactId>
    <version>10.2.4</version>
</parent>
```

### Key Patterns
- Extend Bonita APIs via Engine API
- Access BDM via DAO pattern
- Use ProcessAPI, IdentityAPI, BusinessDataAPI
- Java 17 features: Records, Pattern Matching

## Phase 6: TEST
- Unit: JUnit 5 for business logic
- Property: jqwik for input validation
- Mutation: PIT on extension logic
- Integration: Bonita Test Toolkit (deploy process + extension)

## Phase 7: BUILD
```bash
mvn clean package -B
```

## Phase 8: DEPLOY
- Package in .bar file with associated processes
- Deploy via Bonita Portal or REST API
- Verify extension is loaded and accessible

## Phase 9-10: UPDATE DOC → DELIVER
