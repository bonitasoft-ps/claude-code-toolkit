# Bonita Project Delivery and Best Practices Checklist

This is the **complete** delivery checklist for Bonita projects. Every item must be verified
before a project is considered ready for delivery or code review approval.

---

## I. General Development Standards

- [ ] **Description fields completed** in all project components (processes, connectors, REST APIs, BDM objects) to allow project documentation generation.
- [ ] **camelCase naming** for attributes, scripts, methods, and variables.
- [ ] **PascalCase naming** for classes and BDM objects (e.g., `PBLoanRequest`).
- [ ] **No credentials in source code** (no passwords, API keys, tokens in code, parameters, or committed configuration).
- [ ] **Clean Code principles applied**: readability, maintainability, clear structuring.
- [ ] **Descriptive names** for classes, methods, variables, and all code elements. No short or ambiguous names.
- [ ] **No code duplication** (DRY). Functions/methods and classes used to encapsulate and reuse logic.
- [ ] **Consistent code structure**. Related functions and variables grouped into logical classes and packages.
- [ ] **Errors handled elegantly** with meaningful error messages.
- [ ] **Java 17 features used** (Records, Pattern Matching, Text Blocks, Sealed Classes, Streams, Optional).
- [ ] **Method length under 25-30 lines**. Long methods refactored into smaller, well-named utility methods.
- [ ] **Javadoc/Groovydoc present** on all public classes, methods, and complex logic blocks.
- [ ] **Constants used** for all magic strings and magic numbers.
- [ ] **SLF4J logging** used exclusively. No `System.out.println` or `System.err.println`.
- [ ] **Checkstyle and PMD** pass without violations.

---

## II. Business Data Model (BDM) Standards

### Data Structure and Organization

- [ ] Packages used to organize BDM objects.
- [ ] Project prefix used for object names to avoid multi-project conflicts (e.g., `PBUser`).
- [ ] **camelCase** for attribute naming.
- [ ] `processInstanceId` and `userId` fields present on tables linked to process instances.
- [ ] Flat (one-level) objects used for user search/sort tables for performance.
- [ ] Mandatory attributes defined at BDM level (not just in processes).
- [ ] No reserved keywords used as attribute names (e.g., avoid `type`).
- [ ] Audit fields included: `creationDate`, `creationUser`, `modificationDate`, `modificationUser`.
- [ ] BDM objects structured into logical packages.

### Relationships, Constraints, and Queries

- [ ] **LAZY loading** used instead of EAGER for all relationships (mandatory for multi-result queries).
- [ ] Unicity constraints defined for each unicity criteria.
- [ ] Indexes specified for all queries (predefined and custom queries do NOT create indexes automatically).
- [ ] Custom queries created for business needs.
- [ ] **Count queries** (`countFor*`) created for every multi-result query (required for pagination).
- [ ] Cross-table queries handled via REST API Extensions (not JPQL joins across BDM objects).
- [ ] Single-object retrieval queries constrained by `processInstanceId` for efficiency.

### Access Control

- [ ] BDM Access Control activated for all objects containing personal information.
- [ ] Access rules defined correctly per profile.
- [ ] Security applied by default to every business object.

---

## III. Business Process Model (BPM) Standards

### Modeling and Structure

- [ ] **Verbs used for task names** (e.g., "Review application" not "Application review").
- [ ] Lane names use prefix + actor type (e.g., `adm_administrator`).
- [ ] One diagram = one business process (except meta-diagrams linking to sub-processes).
- [ ] "End" used instead of "terminal" for naming convention consistency.
- [ ] All BPM elements have **meaningful names** (no `Gate1`, `Start1`, `End1`, `Step1`).

### Execution Flow and Logic

- [ ] No implicit gateways.
- [ ] Names hidden for parallel and merge gateways.
- [ ] Explicit names on exclusive gateways, with names on each transition.
- [ ] **Default transition** present on every exclusive gateway.
- [ ] Heavy logic delegated to connectors; operations reserved for simple assignments.
- [ ] Single operation per object update (use "takes value of" for multi-attribute updates).
- [ ] Service tasks used for API/external integrations.
- [ ] Script tasks used for internal scripts (e.g., status updates).
- [ ] No infinite multi-instances.
- [ ] No infinite cyclic flows (termination condition + manual termination option always present).
- [ ] Uncaptured messages addressed (they listen infinitely and grow the database).
- [ ] Links used to improve diagram readability.
- [ ] Process variables limited to: primitives, String, List/Array (of primitives or String), Map.
- [ ] Business data stored in BDM, not process variables.

### Process Structure (3-Level Methodology)

- [ ] **Level 1**: Main process logic (orchestration).
- [ ] **Level 2**: Business logic sub-processes for each stage. Auditing operations at this level.
- [ ] **Level 3**: Technical section sub-processes.

### Contracts

- [ ] Complex root object used to group input data.
- [ ] "Input" suffix added to contract names for readability.
- [ ] Only mandatory elements defined in contracts.
- [ ] Constraints defined to validate inputs.
- [ ] Contracts defined for all sub-processes called via calling activities.

---

## IV. Groovy Script Standards

- [ ] **Clear names** for all scripts (never `newScript()`).
- [ ] **Error handling** with try-catch and logging in all scripts. Log import included at minimum.
- [ ] External libraries analyzed and justified. Library injection into app server only as last resort.
- [ ] Functions/methods kept short and focused on a single responsibility.
- [ ] Process statuses defined as enums.
- [ ] Note: Groovy scripts are deprecated; prefer Java in REST API extensions for new logic.

---

## V. Connector Standards

- [ ] **Error handling** in every connector (try-catch with logging).
- [ ] Connections closed properly. Only Java objects returned (not connected objects).
- [ ] No complex library-dependent objects returned (no JSON objects, no BDM objects). Use Map or other standard Java objects.
- [ ] Dependencies minimized. Logic encapsulated within the connector.
- [ ] **Unit tests** included for connectors developed outside Studio.
- [ ] Errors caught with sufficient detail for diagnosis (try-catch, logs).
- [ ] Input parameters defined via the expression editor.

---

## VI. REST API Extension Standards

- [ ] Services consolidated into one (or limited number of) REST API extensions for code reuse.
- [ ] Methods used to improve readability. No single 500-line class/method.
- [ ] **Constants** used for magic strings.
- [ ] **Unit tests** implemented for each extension.
- [ ] **OpenAPI/Swagger documentation** provided (especially for multi-API projects).
- [ ] **Javadoc headers** on all methods.
- [ ] Classes separated by usage into different packages.
- [ ] No complex or unpaginated queries.
- [ ] API returns only the data needed (no full objects if unused fields exist).
- [ ] Permissions managed on requested records where necessary.
- [ ] Expensive queries executed server-side (REST API Extension), not from browser.
- [ ] BDM read access only from extensions; write operations from processes.
- [ ] External database connections properly closed.
- [ ] External REST API/WS access limited to read/query operations.
- [ ] Permission management and organization properly defined.
- [ ] One class per REST API endpoint.
- [ ] Utility functions grouped in a `tools/Utils` class.
- [ ] Template with common function tools defined and reused.
- [ ] Code comments explain business logic, design decisions, and the "why" behind complex implementations.

---

## VII. UI Standards

### UIBuilder

- [ ] UI code (UIB) versioned and managed for team collaboration.
- [ ] Validation applied on both frontend and contract.
- [ ] Forms not used in task execution (use UI APIs instead).

### UIDesigner (Deprecated)

- [ ] REST API Extension call count minimized. Same service not called multiple times.
- [ ] Custom widgets used for code reuse.
- [ ] Constraints included via Widget, JS, and/or contract.
- [ ] One or more controller classes (ctrl) defined for all business logic.
- [ ] JS functions used for data processing, modals, etc. (library pattern).
- [ ] Widgets used; Angular JS services avoided.
- [ ] Widgets do not make REST calls directly (externalize calls to pages/forms).
- [ ] Widgets kept "dumb"; fragments or pages implement the logic.
- [ ] Fragments used to improve maintainability and reusability.

---

## VIII. Testing and Quality Standards

- [ ] **Bonita APIs mocked** where possible.
- [ ] **Minimum 85% code coverage** achieved.
- [ ] **Process simulations run** before committing BPMN changes.
- [ ] **JMeter/Gatling** used for API load and performance tests.
- [ ] **Bonita Test Toolkit** used for process-level tests.
- [ ] **Unit tests defined** for connectors, REST API extensions, event handlers, and actor filters.
- [ ] **Code review checklist** verified:
  - [ ] Naming consistency
  - [ ] Proper documentation
  - [ ] No hardcoded secrets
  - [ ] Error handling in place
  - [ ] Unit testing approach defined
- [ ] **JUnit 5** as testing framework (`@Test`, `@BeforeEach`, `@DisplayName`).
- [ ] **Mockito 5** for mocking (`@Mock`, `@InjectMocks`, `when()`, `verify()`).
- [ ] **AssertJ** for assertions. NEVER native JUnit assertions.
- [ ] Test classes annotated with `@ExtendWith(MockitoExtension.class)` and `@MockitoSettings(strictness = Strictness.LENIENT)`.
- [ ] Test method naming: `should_do_X_when_condition_Y`.
- [ ] Constants used for all mock content and magic strings in tests.
- [ ] Each test method tests a single path (Single Assertion Principle).

---

## IX. Deployment Standards

- [ ] **BCD (Bonita Continuous Delivery)** used for automatic deployment.
- [ ] **One bar file per environment** with environment-specific parameters, actors, etc.
- [ ] **All configurations filled** (actors and parameters) for every target environment.
- [ ] **Dynamic and static permissions reviewed** per profile.
- [ ] All permissions associated with profiles documented.
- [ ] Application profiles listed with which profiles apply to each application.

---

## Delivery Sign-Off

| Area | Reviewer | Status | Notes |
|------|----------|--------|-------|
| General Standards | | | |
| BDM | | | |
| BPM | | | |
| Groovy Scripts | | | |
| Connectors | | | |
| REST API Extensions | | | |
| UI | | | |
| Testing & Quality | | | |
| Deployment | | | |

**Delivery approved**: [ ] Yes / [ ] No
**Date**: ___________
**Approved by**: ___________
