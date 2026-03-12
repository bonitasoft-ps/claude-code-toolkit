---
name: bonita-upgrade-lifecycle
description: |
  Complete lifecycle for Bonita platform upgrades: assessment → document plan → publish/save →
  validate with client → execute upgrade → test → update docs → deliver PDF report.
  Use when upgrading Bonita versions, migrating databases, updating Tomcat.
  Trigger: "upgrade bonita", "migrate version", "update platform", "upgrade lifecycle", "version upgrade"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, mcp__claude_ai_Atlassian_2__createConfluencePage, mcp__claude_ai_Atlassian_2__updateConfluencePage, mcp__Bonita-AI-Agent__build_pdf, mcp__Bonita-AI-Agent__get_upgrade_workflow, mcp__Bonita-AI-Agent__validate_plan, mcp__Bonita-AI-Agent__get_version_boundaries, mcp__Bonita-AI-Agent__run_pre_upgrade_audit, mcp__Bonita-AI-Agent__compare_versions
user_invocable: true
---

# Bonita Upgrade Lifecycle — Documentation-First

## Lifecycle
```
ASSESSMENT → PLAN DOCUMENT → CHOOSE DESTINATION → VALIDATE ✓ → PREPARE → EXECUTE → TEST → UPDATE DOC → DELIVER
```

## Phase 1: ASSESSMENT
Ask the user:
- Current Bonita version (exact: e.g., 7.11.4, 2021.2, 2024.1)
- Target Bonita version
- Database type and version (PostgreSQL, MySQL, Oracle, SQL Server)
- Application server (Tomcat version)
- Custom code inventory: connectors, filters, event handlers, REST API extensions
- Number of processes, BDM entities, Living Apps
- Integration points (LDAP, SSO, external systems)
- Current issues or motivations for upgrade

Use MCP tools:
- `get_version_boundaries` — identify valid version jump path
- `compare_versions` — breaking changes between versions
- `run_pre_upgrade_audit` — audit code for upgrade blockers

## Phase 2: PLAN DOCUMENT
Generate comprehensive upgrade plan:
- Version jump path (e.g., 7.11 → 2021.1 → 2024.1)
- Database migration steps per version
- Custom code changes required (API changes, deprecations)
- Breaking changes and mitigations
- Rollback plan
- Risk assessment
- Estimated effort per phase

## Phase 3: CHOOSE DESTINATION & PUBLISH
Use `confluence-publish-workflow` — ask user where to save the plan.

## Phase 4: VALIDATE
**GATE — Client must approve upgrade plan before execution**

## Phase 5: PREPARE
- Full database backup
- Backup Bonita home directory
- Export all processes as .bar files
- Document current configuration (server.xml, bonita-platform-community-custom.properties)
- Prepare rollback scripts
- Set up staging environment if available

## Phase 6: EXECUTE
Follow `get_upgrade_workflow` step by step:
1. Stop Bonita server
2. Run database migration scripts (version-specific)
3. Update Bonita distribution
4. Update configuration files
5. Update custom code for API changes
6. Restart server
7. Verify startup logs

## Phase 7: TEST
- Smoke: login, portal navigation, admin console
- Processes: start cases, execute tasks, verify flows
- BDM: data access, queries, CRUD operations
- Connectors: external system connectivity
- REST APIs: endpoint availability, correct responses
- Performance: baseline comparison

## Phase 8: UPDATE DOCUMENT
Add: actual execution details, issues found, resolutions, test results.

## Phase 9: DELIVER
Corporate PDF report, status DELIVERED.

## Version Jump Rules
- 7.x → 7.y: Direct jump within minor versions
- 7.11 → 2021.1: Required bridge version
- 2021.x → 2024.x: Check each intermediate release
- Never skip major version boundaries
- Always check `get_version_boundaries` first
