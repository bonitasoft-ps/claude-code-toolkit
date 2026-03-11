---
name: bonita-project-structure
description: "Understand and scaffold Bonita project directory structure, multi-module Maven setup, and all artifact types."
user_invocable: true
trigger_keywords: ["project structure", "bonita project", "directory layout", "scaffold", "new project", "project setup"]
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Bonita Project Structure Guide

You are an expert in Bonita project structure and organization.

## Standard Project Layout

```
{project-name}/
  pom.xml                           # Parent POM (multi-module Maven)
  CLAUDE.md                         # AI agent instructions
  AGENTS.md                         # AI context index
  .github/
    workflows/
      build.yml                     # CI/CD pipeline
  app/                              # Bonita Studio project
    pom.xml                         # App module POM
    .project                        # Eclipse project descriptor
    applications/
      {AppName}.xml                 # Application descriptor(s)
    diagrams/
      {ProcessName}-{version}.proc  # BPMN process diagrams
    organizations/
      {OrgName}.xml                 # Organization definition
    environements/                  # Bonita environments (note: Bonita typo is intentional)
      Production.xml
      Qualification.xml
    profiles/
      default_profile.xml           # Security profiles
    web_page/                       # UID pages (legacy UI Designer)
      {PageName}/
        {PageName}.json             # Page definition
        assets/
          css/
          json/
    web_widgets/                    # Custom UID widgets
      custom{WidgetName}/
        custom{WidgetName}.json
        assets/
    web_fragments/                  # Reusable UID fragments
      {FragmentName}/
        {FragmentName}.json
        assets/
    connectors-conf/                # Connector configurations
    src-groovy/                     # Shared Groovy scripts
      com/{company}/
    dependencies/                   # External dependencies
    documentation/                  # Project documentation
      images/
      plantuml/
  bdm/                              # Business Data Model module
    pom.xml
    bom.xml                         # BDM definition (THE key file)
    bdm_access_control.xml          # Data access restrictions
    model/                          # Generated model classes
      pom.xml
    dao-client/                     # Generated DAO interfaces
      pom.xml
  extensions/                       # REST API Extensions
    pom.xml                         # Extensions parent POM
    {apiNameRestAPI}/               # One per API extension
      pom.xml
      src/
        main/java/com/{company}/rest/api/
          controller/               # Controllers
          dto/                      # Data Transfer Objects
          constants/                # Constants, Messages
          utils/                    # Shared utilities
          exception/                # Custom exceptions
        main/resources/
          page.properties           # Extension registration
        test/java/                  # Tests (mirror main structure)
      doc/
        api/                        # OpenAPI specs
  uib/                              # UIBuilder application (Appsmith)
    {AppName}.json                  # Full Appsmith export
  infrastructure/                   # Deployment infrastructure
    sca/                            # Server configuration
      bonita/
        conf/
          template/                 # Config templates
          parsed/                   # Environment-specific configs
      bonita_custom_assets/
        libs/                       # Custom JAR dependencies
      bonita_data/
        log4j2/                     # Logging config
      keycloak/                     # SSO configuration (if used)
        realm-config/
      ui_builder/
        production/                 # UIBuilder deployment configs
  tools/                            # Utility scripts
  context-ia/                       # AI context files
    00-overview.mdc                 # Project scope and goals
    01-architecture.mdc             # Technology stack and rules
    02-datamodel.mdc                # BDM conventions and rules
    03-integrations.mdc             # REST API and backend standards
    04-uib.mdc                      # UIBuilder frontend standards
    99-bonita_coding_standards.mdc  # Delivery checklist
```

## Parent POM Structure
```xml
<modules>
    <module>app</module>
    <module>bdm</module>
    <module>extensions</module>
</modules>
```
- Java 17 mandatory
- Bonita version managed centrally
- Lombok for DTOs (or Java Records)
- JUnit 5 + Mockito + AssertJ for tests

## Key Artifact Relationships

```
[Application XML] ──references──> [Pages/Forms]
       │                               │
       └──profile──> [Organization]    │
                                       │
[Process .proc] ──actor mapping──> [Organization]
       │                               │
       ├──contract──> [BDM entities]   │
       │                               │
       ├──form mapping──> [Pages/Forms]│
       │                               │
       ├──connectors──> [Extensions]   │
       │                               │
       └──operations──> [BDM via DAO]  │
                                       │
[BDM bom.xml] ──generates──> [DAO classes]
       │                         │
       └──queries──> [REST API Extensions]
                         │
                         └──called by──> [UIBuilder Pages]
```

## CI/CD Pipeline Pattern (GitHub Actions)

### Build Pipeline Stages
1. **Prerequisites** — Check versions, licenses, dependencies
2. **Create Server** — Provision cloud infrastructure (AWS/Docker)
3. **Build SCA** — Compile extensions, run tests
4. **Deploy SCA** — Deploy extensions to server
5. **Deploy UIB** — Deploy UIBuilder application
6. **Run Data Generation** — Seed test data
7. **Run Integration Tests** — Execute test suites
8. **Cleanup** — Terminate infrastructure

### Reusable Workflows
Separate reusable workflow files for each stage:
- `reusable_build_sca.yml`
- `reusable_create_server.yml`
- `reusable_deploy_sca.yml`
- `reusable_deploy_uib.yml`
- `reusable_run_it.yml`

## AI Context Files (context-ia/)

Every Bonita project should include AI context files:
1. **00-overview.mdc** — Project purpose, team roles, component map
2. **01-architecture.mdc** — Tech stack, communication flow, structure rules
3. **02-datamodel.mdc** — BDM naming, constraints, query rules, index rules
3. **03-integrations.mdc** — REST API standards, testing requirements, clean code
4. **04-uib.mdc** — UIBuilder naming, performance, architecture patterns
5. **99-coding_standards.mdc** — Delivery checklist

## Environment Management
Bonita environments (environements/*.xml) define per-env configuration:
- Database connections
- Process parameters
- Server URLs
- SMTP settings

## Two Frontend Approaches

### Legacy UI Designer (UID) — app/web_page/
- JSON-based page definitions
- pb* built-in widgets (pbTable, pbInput, pbSelect, pbButton)
- custom* widgets for extended functionality
- Fragments for reusable components
- Stored in Bonita project repository

### Modern UIBuilder (Appsmith) — uib/
- Full Appsmith application export (single JSON)
- Pages with widgets, JS objects, queries
- Deployed separately from Bonita Studio project
- More powerful but separate deployment pipeline

## MCP Tools
- `generate_project_scaffold` — Create complete project structure
- `validate_project_consistency` — Cross-validate all artifacts
- `get_project_workflow` — Get 13-phase development lifecycle
