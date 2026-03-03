# Commands Reference — claude-code-toolkit

19 commands organized by scope and category. Use them by typing `/command-name` in Claude Code.

## Personal Commands ★★☆

Install in `~/.claude/commands/` — available in every project.

### java-maven/ — Build & Test Shortcuts

| Command | File | Usage | Description |
|---------|------|-------|-------------|
| `/compile` | `compile.md` | `/compile` or `/compile extensions` | Compile project with Maven (`mvn clean compile`). Accepts optional module path. |
| `/run-tests` | `run-tests.md` | `/run-tests`, `/run-tests integration`, `/run-tests MyClass` | Run unit, integration, or property tests with Maven. Shows summary of results. |
| `/run-mutation-tests` | `run-mutation-tests.md` | `/run-mutation-tests MyModule` | Run PIT mutation testing to evaluate test quality. Shows mutation score. |

### quality/ — Code Quality Tools

| Command | File | Usage | Description |
|---------|------|-------|-------------|
| `/check-code-quality` | `check-code-quality.md` | `/check-code-quality src/main/java/` | Analyze source files for Javadoc, method length, code smells, and quality issues. |
| `/audit-compliance` | `audit-compliance.md` | `/audit-compliance` | Full project compliance audit with security checks, connector validation, and scoring. |
| `/create-constants` | `create-constants.md` | `/create-constants MyService.java` | Detect hardcoded magic strings and extract them to appropriate constants classes. |
| `/refactor-method-signature` | `refactor-method-signature.md` | `/refactor-method-signature setName add param` | Safely refactor a method signature and update ALL call sites across the project. |
| `/sync-claude-project` | `sync-claude-project.md` | `/sync-claude-project` | Synchronize knowledge files and instructions to the `claude-project/` folder for claude.ai compatibility. |

### testing/ — Testing Tools

| Command | File | Usage | Description |
|---------|------|-------|-------------|
| `/generate-tests` | `generate-tests.md` | `/generate-tests MyController` | Generate comprehensive unit + property tests for a Java/Groovy/Kotlin class. |
| `/check-coverage` | `check-coverage.md` | `/check-coverage` | Run tests with JaCoCo and verify against project coverage thresholds. |
| `/generate-integration-tests` | `generate-integration-tests.md` | `/generate-integration-tests MyController` | Generate integration tests for a Bonita REST API controller testing the full `doHandle()` lifecycle. |
| `/check-test-coverage-gap` | `check-test-coverage-gap.md` | `/check-test-coverage-gap` or `/check-test-coverage-gap extensions/myModule` | Find classes missing test pairs and report a prioritized gap analysis. |

## Project Commands ★☆☆

Install in `.claude/commands/` within the project and commit to git.

### bonita/ — Bonita BPM Commands

| Command | File | Usage | Description |
|---------|------|-------|-------------|
| `/check-bdm-queries` | `check-bdm-queries.md` | `/check-bdm-queries PBProcess` | Search existing BDM queries before creating new ones. Prevents duplicate query creation. |
| `/validate-bdm` | `validate-bdm.md` | `/validate-bdm` | Full BDM compliance audit: countFor queries, descriptions, indexes, naming conventions. |
| `/check-existing-extensions` | `check-existing-extensions.md` | `/check-existing-extensions cancel process` | Search extensions for similar functionality before implementing new code. |
| `/check-existing-processes` | `check-existing-processes.md` | `/check-existing-processes notification` | Search processes and subprocesses for similar logic before creating new processes. |
| `/check-existing` | `check-existing.md` | `/check-existing feature name` | Check for existing connectors, extensions, or processes covering a need. |
| `/generate-readme` | `generate-readme.md` | `/generate-readme CancelController` | Generate a compliant README.md for a REST API controller package. |
| `/generate-document` | `generate-document.md` | `/generate-document PDF InvoiceReport` | Scaffold a corporate document generation service (PDF/HTML/DOCX/XLSX) with Bonitasoft branding. |

## Command Details

### `/compile`
```bash
# Compile entire project
/compile

# Compile a specific module
/compile extensions
```
Runs `mvn clean compile` at project root (or specified path). Uses Java 17.

---

### `/run-tests`
```bash
# All tests
/run-tests

# Integration tests only (Failsafe)
/run-tests integration

# Specific class
/run-tests MyControllerTest
```
Runs `mvn test` or `mvn verify` depending on test type. Shows pass/fail summary.

---

### `/run-mutation-tests`
```bash
/run-mutation-tests extensions/myModule
```
Runs PIT mutation testing. Reports mutation score (% killed). Thresholds: typically 70%+ for new code.

---

### `/generate-tests`
```bash
/generate-tests MyController
```
Generates:
1. Unit tests (`*Test.java`) with JUnit 5 + Mockito 5 + AssertJ
2. Property tests (`*PropertyTest.java`) with jqwik
3. Naming: `should_X_when_Y()`

---

### `/check-coverage`
```bash
/check-coverage
```
Runs `mvn verify` with JaCoCo. Reports per-class and aggregate coverage. Fails if below thresholds (typically 80% line coverage).

---

### `/generate-integration-tests`
```bash
/generate-integration-tests CancelController
```
Generates `CancelControllerIT.java` testing full `doHandle()` lifecycle:
- Happy path (200 OK)
- Validation errors (400)
- Authorization errors (403)
- Server errors (500)
- Edge cases (null parameters, empty collections)

---

### `/check-code-quality`
```bash
/check-code-quality src/main/java/
```
Checks:
- Javadoc on all public methods
- Method length (> 30 lines flagged)
- Class length (> 300 lines flagged)
- Magic numbers and strings
- Empty catch blocks
- System.out.println usage

---

### `/audit-compliance`
```bash
/audit-compliance
```
Full audit with:
- Code style (Checkstyle)
- Static analysis (PMD)
- Security checks (OWASP patterns)
- Connector validation
- Test coverage check
- Score (0-100)

---

### `/check-bdm-queries`
```bash
/check-bdm-queries PBProcess
```
Reads `bdm/bom.xml` and lists all existing queries for the given business object. Use before implementing new JPQL queries.

---

### `/validate-bdm`
```bash
/validate-bdm
```
Full BDM compliance check:
- Named query naming (must start with `PB`)
- Every collection query has a `countFor` companion
- All business objects have descriptions
- Indexes present for frequently queried fields

---

### `/generate-readme`
```bash
/generate-readme CancelController
```
Generates `README.md` in the controller's Java package directory with:
- Endpoint URL and HTTP method
- Request/response format (JSON examples)
- Error codes table
- Usage examples

---

### `/generate-document`
```bash
/generate-document PDF InvoiceReport
/generate-document HTML StatusReport
/generate-document XLSX DataExport
```
Scaffolds a document generation service with:
- `DocumentService.java` (iText/OpenPDF, Thymeleaf, or Apache POI)
- `BrandingConfig.java` (corporate colors, fonts, logo)
- HTML template (if applicable)
- Maven dependencies in `pom.xml`

---

### `/sync-claude-project`
```bash
/sync-claude-project
```
Updates the `claude-project/` folder with current knowledge files and regenerates `INSTRUCTIONS.md` with the latest counts and descriptions. Use after adding or updating skills, hooks, or commands.

---

## Installation

### Personal commands (all projects)
```bash
# Install all personal commands
mkdir -p ~/.claude/commands
cp commands/java-maven/* ~/.claude/commands/
cp commands/quality/* ~/.claude/commands/
cp commands/testing/* ~/.claude/commands/
```

### Project commands (Bonita BPM)
```bash
# Install Bonita-specific commands
mkdir -p .claude/commands
cp /path/to/toolkit/commands/bonita/* .claude/commands/
git add .claude/commands/
git commit -m "chore: install Bonita commands from claude-code-toolkit"
```

### Automated installer
```bash
bash install.sh
# Follow prompts to choose scope and project type
```
