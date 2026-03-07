---
name: bonita-cicd-pipeline
description: "Set up CI/CD pipelines for Bonita projects with GitHub Actions, Docker, and automated testing."
user_invocable: true
trigger_keywords: ["cicd", "github actions", "pipeline", "build", "deploy", "docker", "automated deployment"]
---

# Bonita CI/CD Pipeline Designer

You are an expert in Bonita project CI/CD with GitHub Actions and Docker.

## Pipeline Architecture

```
[Push/PR] → [Prerequisites] → [Create Server] → [Build SCA] → [Deploy SCA]
                                     ↓                              ↓
                              [Docker Bonita]                  [Deploy UIB]
                                     ↓                              ↓
                              [Data Generation]            [Integration Tests]
                                                                    ↓
                                                              [Cleanup/Report]
```

## Reusable Workflow Pattern
Each stage is a separate reusable workflow:
```yaml
# .github/workflows/build.yml (orchestrator)
jobs:
  prerequisites:
    uses: ./.github/workflows/reusable_prerequisites.yml
    secrets: inherit

  create_server:
    uses: ./.github/workflows/reusable_create_server.yml
    secrets: inherit

  build:
    needs: [create_server]
    uses: ./.github/workflows/reusable_build_sca.yml
    secrets: inherit

  deploy:
    needs: [build]
    uses: ./.github/workflows/reusable_deploy_sca.yml
    secrets: inherit
    with:
      server_url: ${{ needs.create_server.outputs.url }}
```

## Docker-based Development
```yaml
# docker-compose.yml for local development
services:
  bonita:
    image: bonita:2025.2
    ports:
      - "8080:8080"
    environment:
      - DB_VENDOR=postgres
    volumes:
      - bonita_data:/opt/bonita

  postgres:
    image: postgres:16
    environment:
      - POSTGRES_DB=bonita
```

## Build Steps

### 1. Maven Build (Extensions)
```bash
mvn clean compile test -f extensions/pom.xml
```

### 2. Extension Packaging
Each REST API extension → ZIP with:
- Compiled classes
- page.properties
- Dependencies

### 3. BDM Deployment
- Install bom.xml via Admin API
- Wait for BDM to be accessible

### 4. Organization Import
- Deploy organization.xml
- Map actors to org entities

### 5. Process Deployment
- Deploy .bar files
- Enable processes
- Configure parameters

### 6. UIBuilder Deployment
- Import Appsmith application JSON
- Or deploy UID pages via Bonita Studio

## Secrets Management
```yaml
# Required GitHub secrets
BONITA_URL: https://bonita.example.com
BONITA_USER: install
BONITA_PASSWORD: ${{ secrets.BONITA_PASSWORD }}
AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

## Concurrency Control
```yaml
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
```

## MCP Tools
- `docker_health_check` -- Verify Docker Bonita is running
- `bonita_deploy_process` -- Deploy .bar to runtime
- `bonita_get_kpis` -- Monitor process KPIs
