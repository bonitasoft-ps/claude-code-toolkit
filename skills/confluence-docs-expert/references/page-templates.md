# Confluence Page Templates — Detailed

## Runbook Template

```markdown
# Runbook: [Procedure Name]

**Environment:** Production | Staging | Test
**Last tested:** [date]
**Author:** [name]

## Prerequisites
- [ ] Access to [system]
- [ ] VPN connected
- [ ] Credentials for [service]

## Steps

### 1. [Step Name]
```bash
# Command to execute
```
**Expected output:** [what you should see]
**If it fails:** [troubleshooting steps]

### 2. [Step Name]
...

## Rollback Procedure
If something goes wrong:
1. [Step 1]
2. [Step 2]

## Verification
How to confirm the procedure succeeded:
- [ ] Check 1
- [ ] Check 2

## History
| Date | Who | What | Result |
|------|-----|------|--------|
```

## Release Notes Template

```markdown
# Release Notes — [Project] v[X.Y.Z]

**Release date:** [date]
**Environment:** [Production/Staging]
**Deployed by:** [name]

## What's New

### Features
- **[PROJ-XXX]** [Feature description]

### Bug Fixes
- **[PROJ-XXX]** [Fix description]

### Improvements
- **[PROJ-XXX]** [Improvement description]

## Breaking Changes
- [Description of breaking change and migration guide]

## Known Issues
- [PROJ-XXX] [Description and workaround]

## Deployment Notes
- [Any special deployment steps]
- [Database migrations if any]
- [Configuration changes]

## Dependencies Updated
| Dependency | Previous | New |
|-----------|----------|-----|
```

## Onboarding Guide Template

```markdown
# Developer Onboarding — [Project]

## Day 1: Environment Setup

### Prerequisites
- [ ] Java 17 installed
- [ ] Maven 3.8+ installed
- [ ] Git configured
- [ ] IDE installed (IntelliJ recommended)
- [ ] Claude Code installed

### Steps
1. Clone repository: `git clone [url]`
2. Install Claude Code toolkit: `bash install.sh`
3. Open in IDE
4. Build: `mvn clean compile`
5. Run tests: `mvn verify`

## Day 2: Architecture Overview
- Read CLAUDE.md
- Read context-ai/ files
- Review [Architecture page link]

## Day 3: First Task
- Pick a "good first issue" from Jira
- Follow development workflow in AGENTS.md
- Submit PR following team conventions

## Key Contacts
| Role | Name | Slack |
|------|------|-------|
```
