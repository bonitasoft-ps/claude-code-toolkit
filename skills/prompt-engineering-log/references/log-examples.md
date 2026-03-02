# Prompt Engineering Log Examples

## Example 1: Confluence Page Generation

```yaml
date: 2026-02-15
type: confluence-page
target: BPA space > PS Toolkits > Connector Generator
model: claude-sonnet-4-6
iterations: 3

prompts:
  - version: 1
    prompt: "Create a Confluence page documenting the connector generator toolkit"
    result: "Too generic, missing architecture diagram"
    feedback: "Add Mermaid diagram, include lifecycle phases"

  - version: 2
    prompt: "Create a Confluence page for connector generator with Mermaid architecture diagram showing VALIDATE->CONNECT->EXECUTE->DISCONNECT lifecycle"
    result: "Good structure but missing setup instructions"
    feedback: "Add Prerequisites section with Java 17, Maven, Bonita SDK"

  - version: 3
    prompt: "Final version with prerequisites, architecture diagram, and example connector spec"
    result: "Approved and published"

lessons:
  - Always specify diagram type (Mermaid) explicitly
  - Include setup/prerequisites for technical pages
  - Reference existing specs as examples
```

## Example 2: Audit Report Generation

```yaml
date: 2026-02-20
type: audit-report
target: Customer project ACME-v2
model: claude-opus-4-6
iterations: 2

prompts:
  - version: 1
    prompt: "/bonita-audit-expert run full audit on app/ directory"
    result: "142 findings across 9 categories"
    feedback: "Group by severity, add fix examples for critical findings"

  - version: 2
    prompt: "Regenerate report grouped by severity (CRITICAL > HIGH > MEDIUM > LOW), include code fix examples for all CRITICAL findings"
    result: "Approved — 8 critical, 23 high, 67 medium, 44 low"

lessons:
  - Always request severity grouping upfront
  - Critical findings need concrete fix examples, not just descriptions
```
