# Check Existing Bonita Components

Before building something new, check if an existing Bonita connector, extension, or process already covers the need.

## Arguments
- `$ARGUMENTS`: Description of what you need (e.g., "send email with attachments", "connect to SAP", "upload to S3")

## Instructions

### 1. Check Existing Connectors
Search for existing Bonita connectors that match the requirement:
- Look at the Bonita Marketplace connectors
- Check the project's existing connector implementations
- Consider both exact matches and partial matches that could be configured

### 2. Check Existing REST API Extensions
Search `extensions/` directory for controllers that provide similar functionality.
Use `/check-existing-extensions` for a thorough search.

### 3. Check Existing Processes
Search for `.proc` files or process definitions that may already implement the workflow.
Use `/check-existing-processes` for a thorough search.

### 4. Report

```
## Existing Component Check: "{requirement}"

### Exact Matches
- {component} — covers this need completely. Configuration: {details}

### Partial Matches
- {component} — covers {percentage}. Missing: {gaps}

### No Match
No existing component found. Recommendation: build new {type}.
```

### 5. Decision Matrix

| Option | Effort | Risk | Recommendation |
|--------|--------|------|----------------|
| Use existing {X} | Low | Low | Recommended if {condition} |
| Extend existing {Y} | Medium | Low | Good if {condition} |
| Build new | High | Medium | Only if no alternative |

**Scope:** ★☆☆ Project — Bonita-specific, useful for any Bonita project to avoid duplicate work.
