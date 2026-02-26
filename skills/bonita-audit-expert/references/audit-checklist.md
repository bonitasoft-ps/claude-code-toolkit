# Comprehensive Bonita Audit Checklist

This checklist combines all verification checks for backend (Java/Groovy/BPM/BDM) and frontend (UIB/Appsmith) audits. Work through each section systematically and record pass/fail status.

---

## 1. Pre-Flight Checks

### 1.1. Compilation
- [ ] Java 17 is the active JDK (`java -version`)
- [ ] Project compiles successfully: `mvn clean compile`
- [ ] No compilation warnings related to deprecated APIs
- [ ] All dependencies resolve without errors

### 1.2. Environment
- [ ] Bonita Studio version is documented
- [ ] Maven version is compatible (3.8+)
- [ ] Git repository is clean (no uncommitted changes affecting the audit)
- [ ] EditorConfig file (`.editorconfig`) is present and consistent

### 1.3. Project Structure
- [ ] Standard Bonita project structure is followed
- [ ] `bdm/bom.xml` exists and is well-formed
- [ ] Process diagrams (`.proc`) are in `app/diagrams/`
- [ ] REST API Extensions are in `extensions/`
- [ ] UIB pages are in `/uib/` directory (if applicable)

---

## 2. BDM (Business Data Model) Checks

### 2.1. Naming Conventions
- [ ] Business objects use PascalCase with project prefix (e.g., `PBProcessName`)
- [ ] Attributes use camelCase (e.g., `firstName`, `creationDate`)
- [ ] No snake_case in attribute names
- [ ] Package names follow Java conventions (lowercase, dot-separated)
- [ ] Query names use camelCase starting with `find`, `countFor`, or aggregate prefix

### 2.2. Descriptions
- [ ] ALL business objects have non-empty `<description>` tags
- [ ] ALL fields/attributes have non-empty `<description>` tags
- [ ] ALL custom queries have non-empty `<description>` tags
- [ ] ALL indexes have non-empty `<description>` tags
- [ ] ALL unique constraints have non-empty `<description>` tags

### 2.3. Indexes
- [ ] Every attribute used in a WHERE clause has a corresponding index
- [ ] Every attribute used in an ORDER BY clause has a corresponding index
- [ ] Every attribute used in a JOIN condition has a corresponding index
- [ ] Composite indexes exist for multi-column query conditions
- [ ] No redundant/duplicate indexes exist

### 2.4. CountFor Queries
- [ ] Every query returning `java.util.List` has a corresponding `countFor` query
- [ ] Queries returning Long, single objects, or aggregates do NOT have unnecessary countFor
- [ ] OrderBy variants document which base countFor query to reuse

### 2.5. Field Types and Sizing
- [ ] No STRING type used for date/time attributes (use DATE ONLY or DATE-TIME)
- [ ] No deprecated `DATE` (`java.util.Date`) type used (use DATE ONLY or DATE-TIME)
- [ ] STRING field sizes are appropriate (not all defaulting to 255)
- [ ] Numerical identifiers use INTEGER or LONG, not STRING
- [ ] BOOLEAN used where appropriate instead of STRING "true"/"false"

### 2.6. Audit Fields
- [ ] All business objects have `auFechaCreacion` (DATETIME)
- [ ] All business objects have `auUsuarioCreacion` (STRING 50)
- [ ] All business objects have `auFechaModificacion` (DATETIME)
- [ ] All business objects have `auUsuarioModificacion` (STRING 50)
- [ ] Optional: `auActivo` (BOOLEAN) for soft delete support

### 2.7. Relationships
- [ ] Aggregation/Composition relationships used correctly (not manual ID fields)
- [ ] No redundant fields storing values available through relationships
- [ ] Similar catalog tables consolidated where possible (generic table pattern)

### 2.8. Access Control
- [ ] BDM access control rules are defined and appropriate
- [ ] No overly permissive access (e.g., all profiles can read/write everything)

### 2.9. Custom Queries
- [ ] No custom queries duplicating Bonita's default generated queries
- [ ] No redundant/duplicate custom queries
- [ ] All custom queries are actually used in the codebase

---

## 3. BPM Process Checks

### 3.1. Naming Conventions
- [ ] Processes: `ProcNombreProceso` pattern
- [ ] Subprocesses: `SubProcNombreProceso` pattern
- [ ] Tasks: descriptive names (not `Paso1`, `Compuerta1`, `Inicio1`)
- [ ] Connectors: `NombreConectorCon` pattern
- [ ] Scripts: `nombreScriptScript()` pattern
- [ ] Gateways: named when they have multiple outgoing flows

### 3.2. Gateways
- [ ] No implicit gateways (all gateways are explicit BPMN elements)
- [ ] All gateways with multiple outputs have descriptive names
- [ ] Gateway conditions are clear and documented

### 3.3. Variables
- [ ] Process variable count is reasonable (flag if >40 per process)
- [ ] No unused process variables exist
- [ ] BDM objects used instead of multiple primitive variables where possible
- [ ] No process variables storing data that should be in BDM

### 3.4. Tiered Architecture
- [ ] Level 1: Main process logic/stages
- [ ] Level 2: Subprocesses for business logic
- [ ] Level 3: Subprocesses for technical functionalities
- [ ] Reusable logic is extracted to shared subprocesses

### 3.5. Connectors and Operations
- [ ] One connector per task rule is followed
- [ ] No connectors on Call Activities or Human Tasks
- [ ] Bulk processing uses Service Tasks with Groovy Connectors (not operations)
- [ ] Object updates use single-object assignment (not per-attribute operations)

### 3.6. Error Handling
- [ ] Error events are defined for critical connectors
- [ ] Timer events exist for retry logic where appropriate
- [ ] Human tasks exist for manual review/restart scenarios
- [ ] Connector failures return meaningful error information

### 3.7. Call Activities
- [ ] Version is NOT hardcoded in Call Activities (use latest deployed)
- [ ] Exception: version is specified only when strictly necessary

### 3.8. Inter-Process Communication
- [ ] NO REST Connectors calling Bonita's own REST API Extensions from within processes
- [ ] Bonita Java API used inside processes (Script Connectors / Custom Connectors)
- [ ] Bonita REST API used from Pages/Forms only

### 3.9. Document Management
- [ ] Documents NOT stored directly in Bonita database
- [ ] External storage (Azure, S3) used for document content
- [ ] Document URLs stored in BDM objects
- [ ] Maximum upload size is configured/limited

### 3.10. Engine Tables
- [ ] Periodic purge procedure exists for archived tables
- [ ] `queriable_log` table management is defined
- [ ] Archive configuration reviewed in `bonita-tenant-sp-custom.properties`

### 3.11. Version Management
- [ ] Process diagram (`.proc`) file versions are not duplicated
- [ ] Process versioning follows a clear convention

---

## 4. REST API Extension Checks

### 4.1. Controller Pattern
- [ ] Controllers follow the standard Bonita REST API Extension pattern
- [ ] Code is modular (validation, business logic, response building separated)
- [ ] No large monolithic `doHandle` methods with duplicated logic
- [ ] `switch` statements or dedicated handler methods used for different actions

### 4.2. README Documentation
- [ ] Every controller package has a `README.md` file
- [ ] README includes: Overview, Endpoint, Query Parameters, Request Body, Response Structure
- [ ] README includes: Examples, Error Handling, Files in Package

### 4.3. Code Quality
- [ ] Methods are short with single responsibility
- [ ] No magic strings (use constants)
- [ ] Descriptive variable and method names
- [ ] No mixing of high-level flow control with low-level details
- [ ] Shared utility methods extracted to common library

### 4.4. Error Handling
- [ ] All exceptions return appropriate HTTP error status codes (not 200 "OK")
- [ ] Error responses include meaningful messages
- [ ] Error logging is present (not swallowed exceptions)
- [ ] try/catch blocks used for all external calls

### 4.5. Datasource Usage
- [ ] NEVER uses engine's default BDM datasource
- [ ] Duplicate read-only datasource used for BDM queries
- [ ] No direct SQL manipulation of Bonita engine tables (STRICTLY FORBIDDEN)
- [ ] All BDM CRUD operations happen within BPM processes only
- [ ] REST API Extensions limited to READ operations on BDM

### 4.6. Testing
- [ ] Unit tests exist for REST API Extension logic
- [ ] Edge cases are tested (null values, empty inputs, invalid parameters)
- [ ] Test coverage meets minimum threshold (>80%)

---

## 5. Groovy Script Checks

### 5.1. Script Naming
- [ ] Scripts follow `nombreScriptScript()` naming convention
- [ ] Script names are descriptive and indicate purpose

### 5.2. Code Quality
- [ ] Scripts are SHORT (max 30 lines)
- [ ] Complex logic extracted to shared scripts (`app/src-groovy/`) or extension library
- [ ] `def` used for local variables, explicit types for method parameters
- [ ] No `System.out.println` (use SLF4J logger)
- [ ] Constants used from extension library enums (no hardcoded strings)

### 5.3. Error Handling
- [ ] try/catch blocks used for ALL external calls (DAO, API, connectors)
- [ ] Null checks present for optional variables
- [ ] Meaningful error messages in catch blocks

### 5.4. Bonita API Usage
- [ ] DAO access uses `apiAccessor.getBusinessObjectDAO()` or typed DAO
- [ ] Process variables accessed via `execution.getProcessVariableValue()`
- [ ] Identity API accessed via `apiAccessor.getIdentityAPI()`
- [ ] No direct JDBC/SQL queries when Bonita API provides the functionality

---

## 6. UIB (UI Builder) Checks

### 6.1. Naming Conventions
- [ ] Queries/APIs: verbNoun camelCase (e.g., `getLoanRequests`)
- [ ] JS Functions: verbActionNoun camelCase (e.g., `openCustomerModel`)
- [ ] Widgets: Noun_Context_Type PascalCase (e.g., `RequestList_Table`)
- [ ] JS Objects: PageName_DomainUtils PascalCase (e.g., `Home_RequestUtils`)
- [ ] Pages: PascalCase descriptive names (not `page1`, `newPage`)
- [ ] Variables: camelCase descriptive names (not `x`, `temp1`)
- [ ] No generic names (`Canvas10Copy`, `Button3`, `Container1`)

### 6.2. JS Objects and Code Quality
- [ ] Logic centralized in JS Objects (not scattered in widget properties)
- [ ] Functions follow Single Responsibility Principle (SRP)
- [ ] No functions performing multiple unrelated actions
- [ ] async/await used with proper error handling
- [ ] try/catch blocks in all API call functions
- [ ] No callback hell patterns

### 6.3. Code Duplication
- [ ] No duplicated JS logic across multiple JS Collections
- [ ] Shared utilities extracted to common JS Objects
- [ ] Cross-page shared logic in reusable modules

### 6.4. Performance
- [ ] No heavy queries (Base64, large datasets) running on page load
- [ ] Pagination used for all list queries
- [ ] Lazy loading implemented for non-critical data
- [ ] Images and documents loaded on demand (not eagerly)

### 6.5. Widget Structure
- [ ] No deep nesting (Container > Canvas > Container patterns)
- [ ] Responsive layout tested on multiple screen sizes
- [ ] Widget hierarchy is flat and maintainable

### 6.6. Fragile Logic
- [ ] No hardcoded array indexes for data retrieval (`? 0 : 1` pattern)
- [ ] No literal strings for status/state matching (use constants)
- [ ] Data accessed by property/name, not by position
- [ ] No assumptions about backend data ordering

### 6.7. Error Handling
- [ ] Error messages are specific and actionable (not generic "There was an error")
- [ ] Loading states shown during API calls
- [ ] Empty states handled gracefully
- [ ] Network error fallbacks exist

### 6.8. Security
- [ ] Authorization validated server-side (not just UI-level checks)
- [ ] API endpoints enforce role-based access
- [ ] Sensitive data not exposed in client-side code
- [ ] Profile-based access control configured

### 6.9. Accessibility
- [ ] WCAG compliance checked (labels, contrast, keyboard navigation)
- [ ] Screen reader compatibility verified
- [ ] Focus management implemented for modals/dialogs

### 6.10. State Management
- [ ] Centralized state in JS Objects (single source of truth)
- [ ] No widget-level bindings for shared state
- [ ] Container visibility logic in JS Objects (not widget property expressions)

---

## 7. Testing Checks

### 7.1. Coverage
- [ ] Unit test coverage >80% (verified via JaCoCo)
- [ ] Critical paths have test coverage
- [ ] Edge cases are tested

### 7.2. Test Quality
- [ ] Test names are descriptive (describe what is being tested)
- [ ] Assertions are specific (not just `assertNotNull`)
- [ ] Tests are independent (no shared mutable state)
- [ ] Mocks used appropriately for external dependencies

### 7.3. Test Organization
- [ ] Tests follow the same package structure as source code
- [ ] Test utility classes are shared and not duplicated
- [ ] Integration tests exist for REST API Extensions
- [ ] Property-based testing used where applicable

---

## 8. Quality Tools Configuration

### 8.1. Checkstyle
- [ ] Checkstyle configuration exists in project
- [ ] `mvn checkstyle:check` passes (or violations are documented)
- [ ] Naming conventions enforced
- [ ] Import ordering enforced

### 8.2. PMD
- [ ] PMD configuration exists in project
- [ ] `mvn pmd:check` passes (or violations are documented)
- [ ] No unused variables/imports
- [ ] No empty catch blocks
- [ ] No overly complex methods

### 8.3. EditorConfig
- [ ] `.editorconfig` file present at project root
- [ ] Consistent indentation (spaces vs tabs)
- [ ] Consistent line endings
- [ ] Trailing whitespace trimmed

### 8.4. JaCoCo
- [ ] JaCoCo configured in pom.xml
- [ ] `mvn jacoco:report` generates coverage report
- [ ] Minimum coverage threshold enforced (>80%)

---

## Audit Summary Template

After completing the checklist, summarize results:

| Section | Total Checks | Passed | Failed | N/A | Notes |
|---------|-------------|--------|--------|-----|-------|
| 1. Pre-Flight | | | | | |
| 2. BDM | | | | | |
| 3. BPM Process | | | | | |
| 4. REST API Extensions | | | | | |
| 5. Groovy Scripts | | | | | |
| 6. UIB | | | | | |
| 7. Testing | | | | | |
| 8. Quality Tools | | | | | |
| **TOTAL** | | | | | |
