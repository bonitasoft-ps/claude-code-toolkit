---
name: bonita-audit-lifecycle
description: |
  Complete lifecycle for Bonita code audits: scope → document plan → publish/save →
  validate → execute audit → analyze → document results → deliver PDF report.
  Uses 318 audit rules across 9 categories.
  Trigger: "run audit", "code audit", "audit lifecycle", "quality audit", "bonita audit"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, mcp__claude_ai_Atlassian_2__createConfluencePage, mcp__claude_ai_Atlassian_2__updateConfluencePage, mcp__Bonita-AI-Agent__build_pdf, mcp__Bonita-AI-Agent__run_full_audit, mcp__Bonita-AI-Agent__get_audit_standards, mcp__Bonita-AI-Agent__get_audit_report_template, mcp__Bonita-AI-Agent__search_audit_rules
user_invocable: true
---

# Bonita Audit Lifecycle — Documentation-First

## Lifecycle
```
SCOPE → PLAN DOCUMENT → CHOOSE DESTINATION → VALIDATE ✓ → EXECUTE AUDIT → ANALYZE → DOCUMENT RESULTS → DELIVER
```

## Phase 1: SCOPE
Ask the user:
- Client name (will be anonymized in any shared outputs)
- Audit scope: what to audit (backend, frontend, BDM, processes, connectors, all)
- Bonita version
- Project artifacts: .bos file, source code, or both
- Standards to apply (from 9 categories, 318 rules)
- Specific focus areas or concerns

### Audit Categories
| Category | Rules | Focus |
|----------|-------|-------|
| Backend Java/Groovy | ~80 | Code quality, patterns, security |
| Frontend | ~40 | UI best practices, accessibility |
| BDM | ~35 | Data model design, queries, indexes |
| Process Design | ~45 | BPMN best practices, flow optimization |
| Connectors | ~30 | Lifecycle, error handling, security |
| REST API | ~25 | API design, security, documentation |
| Performance | ~25 | Optimization, caching, scalability |
| Security | ~20 | OWASP, authentication, authorization |
| Architecture | ~18 | Structure, modularity, maintainability |

## Phase 2: PLAN DOCUMENT
Generate audit plan: scope, standards, timeline, deliverables, team.

## Phase 3: CHOOSE DESTINATION & PUBLISH
Use `confluence-publish-workflow` — Confluence, local, PDF, or other.

## Phase 4: VALIDATE
**GATE — Client must approve audit plan before execution**

## Phase 5: EXECUTE AUDIT
1. `get_audit_standards` — load standards for selected categories
2. `run_full_audit` — execute against project artifacts
3. Collect all findings with severity levels

### Severity Levels
| Level | Action Required |
|-------|----------------|
| CRITICAL | Must fix before production |
| MAJOR | Should fix in next sprint |
| MINOR | Nice to fix, low priority |
| INFO | Informational, best practice suggestion |

## Phase 6: ANALYZE
- Severity distribution (pie chart data)
- Top 10 most impactful issues
- Category breakdown
- Comparison with industry standards
- Prioritized recommendations
- Estimated remediation effort

## Phase 7: DOCUMENT RESULTS
Update the audit plan document with:
- Executive summary
- Findings by category and severity
- Top recommendations
- Remediation roadmap
- Update status: IMPLEMENTED

## Phase 8: DELIVER
- Generate corporate PDF: `build_pdf`
- Update status: DELIVERED
- Send to client (email or Confluence share)

## Quick Reference
| Phase | MCP Tool | Output |
|-------|----------|--------|
| Scope | Ask user | Scope definition |
| Standards | get_audit_standards | Rules to apply |
| Execute | run_full_audit | Raw findings |
| Report template | get_audit_report_template | Report structure |
| Search rules | search_audit_rules | Specific rule details |
| PDF | build_pdf | Corporate report |
