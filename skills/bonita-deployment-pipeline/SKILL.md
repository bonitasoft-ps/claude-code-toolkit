---
name: bonita-deployment-pipeline
description: "Package and deploy Bonita projects: BAR assembly, actor mapping, form mapping, Docker deploy, and monitoring."
user_invocable: true
trigger_keywords: ["deploy", "package", "bar file", "docker", "deploy process", "packaging", "bar"]
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Bonita Deployment Pipeline

You are an expert in Bonita project packaging and deployment.

## Business Archive (.bar) Structure

A .bar file is a ZIP containing:
```
process-design.xml          — Serialized DesignProcessDefinition
actorMapping.xml            — Actor → organization mapping
form-mapping.xml            — Task → form/page mapping
parameters.properties       — Process parameters
classpath/                  — Connector JARs and dependencies
connector/                  — Connector .impl XML descriptors
forms/                      — Form resources
userFilters/                — Actor filter implementations
documents/                  — Process documents
external/                   — External resources
```

## Assembly Sequence (from BusinessArchiveBuilder)
1. `ProcessDefinitionBuilder.done()` → `DesignProcessDefinition`
2. `BusinessArchiveBuilder.aBusinessArchive()`
3. `.setProcessDefinition(design)`
4. `.setActorMapping(actorMappingXml)`
5. `.setFormMappings(formMappingModel)`
6. `.setParameters(parameterMap)`
7. `.addConnectorImplementation(barResource)` (for each connector)
8. `.addClasspathResource(barResource)` (for each dependency JAR)
9. `.done()` → `BusinessArchive`
10. `BusinessArchiveFactory.writeBusinessArchiveToFile(archive, file)` → .bar

## Deployment via REST API
```
POST /API/bpm/process   — Deploy .bar file
PUT  /API/bpm/process/{id}  — Enable process (activationState: ENABLED)
```

## Pre-Deployment Checklist
- [ ] BDM deployed to runtime (bom.xml installed via Admin portal)
- [ ] Organization imported (organization.xml)
- [ ] All connector JARs included in .bar classpath/
- [ ] Actor mapping references valid org entities
- [ ] Form mapping points to deployed pages
- [ ] Process parameters have values

## MCP Tools
- `generate_actor_mapping` — Generate actorMapping.xml
- `generate_form_mapping` — Generate form-mapping.xml
- `validate_project_consistency` — Cross-validate all artifacts
- `create_delivery_package` — Package deliverables
- `docker_health_check` — Verify Docker Bonita is running
- `bonita_deploy_process` — Deploy .bar to runtime
- `bonita_get_kpis` — Monitor process KPIs
- `get_project_workflow` — Get deployment phase steps
