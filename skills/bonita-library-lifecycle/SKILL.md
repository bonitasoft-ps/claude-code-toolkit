---
name: bonita-library-lifecycle
description: |
  Complete lifecycle for Java libraries in Bonita ecosystem: spec → document → publish/save →
  validate → implement → test (unit/property/mutation/integration) → build → deploy → update docs → deliver.
  Use when creating, updating, or deploying a standalone Java library (JAR) used by Bonita projects.
  Trigger: "create library", "java library", "shared library", "utility jar", "library lifecycle"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, mcp__claude_ai_Atlassian_2__createConfluencePage, mcp__claude_ai_Atlassian_2__updateConfluencePage, mcp__Bonita-AI-Agent__build_pdf
user_invocable: true
---

# Bonita Library Lifecycle — Documentation-First

## Lifecycle Overview

```
SPEC → DOCUMENT → CHOOSE DESTINATION → VALIDATE ✓ → IMPLEMENT → TEST → BUILD → DEPLOY → UPDATE DOC → DELIVER
```

## Phase 1: SPEC — Gather Requirements
Ask the user:
- Library name and purpose
- Target Bonita version compatibility
- Public API contract (interfaces, methods)
- Dependencies (external libraries, Bonita APIs)
- Consumers (which projects/processes will use it)
- Java version (default: 17)

## Phase 2: DOCUMENT — Generate Technical Specification
Generate spec using template from `confluence-publish-workflow` skill.
Include: overview, API definition, dependencies, architecture, testing strategy, build plan.

## Phase 3: CHOOSE DESTINATION & PUBLISH
**Invoke `confluence-publish-workflow` skill** to:
1. Ask user where to save (Confluence, local, PDF, other)
2. Publish/save the document
3. Share with stakeholders

## Phase 4: VALIDATE
**GATE — Do NOT proceed without explicit approval**
- Ask: "¿Está validada la especificación? ¿Puedo proceder con la implementación?"
- If changes → update document → ask again
- Only continue when user explicitly approves

## Phase 5: IMPLEMENT — Generate Code
Maven project structure:
```
library-name/
├── pom.xml                  # Java 17, JUnit 5, jqwik, PIT, JaCoCo
├── src/main/java/           # Implementation
├── src/test/java/           # Unit + property tests
└── src/test/resources/      # Test fixtures
```

Implementation rules:
- Java 17: Records for DTOs, Sealed Classes, Pattern Matching
- JavaDoc on all public methods
- No hardcoded strings — use constants
- OWASP Top 10 compliance
- Use pom.xml template from `references/maven-library-template.md`

## Phase 6: TEST — Testing Pyramid

### 6a. Unit Tests (JUnit 5)
- Naming: `should_{expected}_when_{condition}()`
- AAA pattern: Arrange, Act, Assert
- Coverage target: 80%+ line coverage
- Run: `mvn test`

### 6b. Property Tests (jqwik)
- Test invariants with random inputs
- @ForAll with Arbitraries for input generation
- Focus: input validation, edge cases, mathematical properties
- See `bonita-property-testing` skill for patterns

### 6c. Mutation Tests (PIT)
- Run: `mvn org.pitest:pitest-maven:mutationCoverage`
- Target: 80%+ mutation score
- Exclude: DTOs, constants, generated code
- See `bonita-mutation-testing` skill for config

### 6d. Integration Tests
- Naming: `*IT.java` (Maven Failsafe)
- Test with real dependencies where possible
- Run: `mvn verify`

## Phase 7: BUILD
```bash
mvn clean package -B
```
Verify: all tests pass, coverage met, no warnings, JAR in target/

## Phase 8: DEPLOY
- Local: `mvn install`
- Nexus: `mvn deploy` (if configured)
- Include in Bonita project: add dependency in consumer pom.xml

## Phase 9: UPDATE DOCUMENT
Update the spec document (wherever it was saved) with:
- Actual classes and packages created
- Test results: coverage %, mutation score, test count
- Build artifact: GAV coordinates
- Deployment location
- Update status: IMPLEMENTED

## Phase 10: DELIVER
- Generate corporate PDF if requested (`build_pdf`)
- Update status: DELIVERED
- Notify stakeholders

## Quick Reference

| Phase | Action | Output |
|-------|--------|--------|
| Spec | Ask user | Requirements |
| Document | Generate spec | Markdown document |
| Destination | Ask user | Confluence/local/PDF/other |
| Validate | User approval | Go/No-go |
| Implement | Write code | Java source |
| Test | mvn test/verify | Test reports |
| Build | mvn package | JAR |
| Deploy | mvn install/deploy | Published artifact |
| Update Doc | Edit document | Updated spec |
| Deliver | build_pdf | Corporate PDF |
