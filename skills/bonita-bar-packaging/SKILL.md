---
name: bonita-bar-packaging
description: "Package Bonita Business Archives (.bar): process-design.xml, actorMapping, formMapping, parameters, connectors, and deployment."
user_invocable: true
trigger_keywords: ["bar", "package", "business archive", "deploy bar", "bar file"]
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Bonita BAR Packaging

You are an expert in Bonita Business Archive (.bar) packaging and deployment.

## BAR File Structure

A .bar file is a ZIP archive with the naming convention `{process-name}--{version}.bar`. Internal structure:

```
{process-name}--{version}.bar (ZIP)
├── process-design.xml          — Serialized DesignProcessDefinition
├── actorMapping.xml            — Actor → organization mapping
├── form-mapping.xml            — Task/process → form/page mapping
├── parameters.properties       — Process parameter key=value pairs
├── classpath/                  — Connector JARs and dependency libraries
├── connector/                  — Connector .impl XML descriptors
├── forms/                      — Custom page/form resources
├── userFilters/                — Actor filter .impl XML descriptors
├── documents/                  — Initial document values
└── external/                   — External resources
```

## Two Packaging Paths

### Path A: Studio Path (Recommended for standard projects)
1. Generate `.proc` XML (BPMN model in Bonita Studio format)
2. Import `.proc` in Bonita Studio
3. Configure connectors, actors, forms in Studio
4. Studio builds the `.bar` automatically via Build > Deploy

### Path B: Headless Path (CI/CD, automated generation)
1. Use `ProcessDefinitionBuilder` to define the process programmatically
2. Call `.done()` to get a `DesignProcessDefinition`
3. Use `BusinessArchiveBuilder` to assemble the BAR:

```java
ProcessDefinitionBuilder pdb = new ProcessDefinitionBuilder()
    .createNewInstance("MyProcess", "1.0");
// ... add tasks, actors, transitions, connectors ...
DesignProcessDefinition design = pdb.done();

BusinessArchive archive = new BusinessArchiveBuilder()
    .createNewBusinessArchive()
    .setProcessDefinition(design)
    .setActorMapping(actorMappingXml)
    .setFormMappings(formMappingModel)
    .setParameters(parameterMap)
    .addConnectorImplementation(connectorBarResource)
    .addClasspathResource(jarBarResource)
    .addUserFilters(filterBarResource)
    .addDocumentResource(docBarResource)
    .addExternalResource(externalBarResource)
    .done();

BusinessArchiveFactory.writeBusinessArchiveToFile(archive, new File("MyProcess--1.0.bar"));
```

## Actor Mapping XML Format

Namespace: `http://www.bonitasoft.org/ns/actormapping/6.0`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<actorMappings xmlns="http://www.bonitasoft.org/ns/actormapping/6.0">
    <actorMapping name="Employee">
        <groups>
            <group>/company</group>
        </groups>
        <roles>
            <role>employee</role>
        </roles>
        <users>
            <user>john.doe</user>
        </users>
        <memberships>
            <membership>
                <role>manager</role>
                <group>/company/hr</group>
            </membership>
        </memberships>
    </actorMapping>
    <actorMapping name="Manager">
        <roles>
            <role>manager</role>
        </roles>
    </actorMapping>
</actorMappings>
```

**Rules:**
- Every actor defined in the process MUST have an `<actorMapping>` entry
- At least one mapping type (groups, roles, users, memberships) must be non-empty
- The actor initiator must also be mapped

## Form Mapping XML Format

Form mapping types (FormMappingType): `PROCESS_START`, `PROCESS_OVERVIEW`, `TASK`
Form mapping targets (FormMappingTarget): `INTERNAL`, `URL`, `NONE`, `LEGACY`, `UNDEFINED`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form-mapping>
    <form-mappings>
        <!-- Process instantiation form -->
        <form-mapping type="PROCESS_START" target="INTERNAL">
            <form>custompage_submitRequestForm</form>
        </form-mapping>

        <!-- Process overview (case detail) page -->
        <form-mapping type="PROCESS_OVERVIEW" target="INTERNAL">
            <form>custompage_requestOverview</form>
        </form-mapping>

        <!-- User task forms -->
        <form-mapping type="TASK" target="INTERNAL" task="Review Request">
            <form>custompage_reviewRequestForm</form>
        </form-mapping>

        <!-- Task with no form (auto-submit) -->
        <form-mapping type="TASK" target="NONE" task="Auto Notification"/>

        <!-- Task with external URL form -->
        <form-mapping type="TASK" target="URL" task="External Approval">
            <url>https://forms.example.com/approve</url>
        </form-mapping>
    </form-mappings>
</form-mapping>
```

**Rules:**
- Every user task MUST have a form mapping entry
- PROCESS_START and PROCESS_OVERVIEW are optional but recommended
- INTERNAL target references a deployed custom page (custompage_ prefix)
- NONE means the task auto-submits (no UI)
- URL opens an external form in an iframe

## Connector Implementation Descriptor

Each connector needs a `.impl` XML file in the `connector/` directory:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<implementation:connectorImplementation
    xmlns:implementation="http://www.bonitasoft.org/ns/connector/implementation/6.0">
    <implementationId>email-connector-impl</implementationId>
    <implementationVersion>1.0.0</implementationVersion>
    <definitionId>email-connector</definitionId>
    <definitionVersion>1.0.0</definitionVersion>
    <implementationClassname>com.company.connector.EmailConnector</implementationClassname>
    <jarDependencies>
        <jarDependency>email-connector-1.0.0.jar</jarDependency>
        <jarDependency>javax.mail-1.6.2.jar</jarDependency>
    </jarDependencies>
</implementation:connectorImplementation>
```

**Rules:**
- `definitionId` + `definitionVersion` must match the connector definition in the process
- All JARs listed in `<jarDependencies>` must exist in `classpath/`
- `implementationClassname` must be a valid class in one of the JARs

## Actor Filter Implementation Descriptor

Actor filters (user filters) use a similar `.impl` format in `userFilters/`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<implementation:connectorImplementation
    xmlns:implementation="http://www.bonitasoft.org/ns/connector/implementation/6.0">
    <implementationId>manager-filter-impl</implementationId>
    <implementationVersion>1.0.0</implementationVersion>
    <definitionId>manager-filter</definitionId>
    <definitionVersion>1.0.0</definitionVersion>
    <implementationClassname>com.company.filter.ManagerFilter</implementationClassname>
    <jarDependencies>
        <jarDependency>manager-filter-1.0.0.jar</jarDependency>
    </jarDependencies>
</implementation:connectorImplementation>
```

## BAR Naming Convention

Format: `{process-name}--{version}.bar`

Examples:
- `Leave-Request--1.0.bar`
- `Invoice-Approval--2.3.bar`
- `Employee-Onboarding--1.0.0.bar`

**Important:** The double dash `--` separates the process name from the version. Process names should use hyphens, not spaces.

## REST API Deployment Endpoints

### Deploy a .bar file
```
POST /API/bpm/process
Content-Type: multipart/form-data
Body: file=@MyProcess--1.0.bar

Response: { "id": "7654321", "name": "MyProcess", "version": "1.0", ... }
```

### Enable the deployed process
```
PUT /API/bpm/process/{processId}
Content-Type: application/json
Body: { "activationState": "ENABLED" }
```

### Start a new case
```
POST /API/bpm/case
Content-Type: application/json
Body: { "processDefinitionId": "{processId}", "variables": [...] }
```

### Check process status
```
GET /API/bpm/process?s={processName}&f=version={version}
```

## Pre-Deployment Checklist

Before deploying a .bar file, verify:

- [ ] **BDM deployed** — bom.xml installed via Admin Portal or REST API (`POST /API/tenant/bdm`)
- [ ] **Organization imported** — organization.xml loaded with all actors' groups/roles/users
- [ ] **Connector JARs included** — All connector dependencies in `classpath/`, descriptors in `connector/`
- [ ] **Actor filters included** — All filter JARs in `classpath/`, descriptors in `userFilters/`
- [ ] **Actors mapped** — actorMapping.xml references valid organization entities
- [ ] **Forms deployed** — Custom pages deployed to Portal before enabling process
- [ ] **Parameters set** — All process parameters have values in parameters.properties
- [ ] **REST API extensions deployed** — Any custom REST APIs the forms depend on
- [ ] **Application descriptor deployed** — Application XML linking pages and navigation

## MCP Tools

- `generate_actor_mapping` — Generate actorMapping.xml from process actors and organization
- `generate_form_mapping` — Generate form-mapping.xml from user tasks and pages
- `validate_project_consistency` — Cross-validate BAR contents (actors, forms, connectors)
- `create_delivery_package` — Assemble all artifacts into deliverable
- `bonita_deploy_process` — Deploy .bar to Bonita runtime via REST API
- `docker_health_check` — Verify Docker Bonita is running before deployment
