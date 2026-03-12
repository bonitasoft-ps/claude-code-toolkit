---
name: bonita-pdf-corporate
description: |
  Generate corporate-branded PDF documents from technical specifications, audit reports,
  upgrade plans, and test results. Uses Bonitasoft branding (colors, fonts, logo).
  Supports HTML-to-PDF pipeline with Flying Saucer/OpenPDF.
  Trigger: "generate pdf", "corporate pdf", "pdf report", "print document", "export pdf"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, mcp__Bonita-AI-Agent__build_pdf
user_invocable: true
---

# Corporate PDF Generation

## Bonitasoft Branding

### Colors
| Name | Hex | Usage |
|------|-----|-------|
| Primary | `#2c3e7a` | Headers, titles, primary buttons |
| Accent | `#e97826` | Highlights, call-to-action, links |
| Success | `#27ae60` | Positive indicators, passed tests |
| Error | `#e74c3c` | Critical issues, failed tests |
| Warning | `#f39c12` | Warnings, attention needed |
| Text | `#2c3e50` | Body text |
| Light BG | `#f8f9fa` | Table alternating rows, code blocks |

### Typography
- **Headings**: Inter or Roboto, bold
- **Body**: Inter or Roboto, regular, 11pt
- **Code**: JetBrains Mono or Fira Code, 10pt
- **Formal documents**: Consider serif font for body

### Logo
- Place in top-left of header
- Minimum size: 120px width
- White version on dark backgrounds

## Document Types

### 1. Technical Specification
- Cover page: title, version, date, author, status
- Table of contents
- Sections: Overview, Architecture, API, Dependencies, Testing
- Footer: page numbers, document reference

### 2. Audit Report
- Cover page: client, scope, date, auditor
- Executive summary
- Findings table (severity, category, description, recommendation)
- Charts: severity distribution, category breakdown
- Remediation roadmap
- Appendix: detailed findings

### 3. Upgrade Report
- Cover page: source → target version, client, date
- Version jump path
- Pre-upgrade audit summary
- Migration steps executed
- Issues encountered
- Test results
- Rollback status

### 4. Test Report
- Cover page: project, date, test scope
- Summary: total/passed/failed/skipped
- Coverage: line%, branch%, mutation%
- Detailed results by category
- Failed test details

## Using build_pdf MCP Tool

The `build_pdf` tool accepts:
- **content**: Markdown or HTML content
- **template**: Document type (spec, audit, upgrade, test)
- **metadata**: title, author, date, version, client

Example workflow:
1. Generate content in Markdown
2. Call `build_pdf` with content + template type
3. PDF is generated with corporate branding
4. Save to user-specified location

## HTML Template Structure

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        :root {
            --primary: #2c3e7a;
            --accent: #e97826;
            --text: #2c3e50;
        }
        body { font-family: 'Inter', sans-serif; color: var(--text); }
        h1, h2, h3 { color: var(--primary); }
        a { color: var(--accent); }
        .header { background: var(--primary); color: white; padding: 20px; }
        .footer { border-top: 2px solid var(--primary); padding: 10px; font-size: 9pt; }
        table { width: 100%; border-collapse: collapse; }
        th { background: var(--primary); color: white; padding: 8px; }
        td { padding: 8px; border-bottom: 1px solid #ddd; }
        tr:nth-child(even) { background: #f8f9fa; }
        .severity-critical { color: #e74c3c; font-weight: bold; }
        .severity-major { color: #e97826; }
        .severity-minor { color: #f39c12; }
        .severity-info { color: #27ae60; }
        code { background: #f8f9fa; padding: 2px 6px; border-radius: 3px; font-size: 10pt; }
    </style>
</head>
<body>
    <div class="header">
        <img src="logo.svg" alt="Bonitasoft" width="120">
        <h1>{{title}}</h1>
        <p>{{subtitle}} | {{date}}</p>
    </div>
    <div class="content">
        {{content}}
    </div>
    <div class="footer">
        <p>Bonitasoft Professional Services | Confidential | Page {{page}}</p>
    </div>
</body>
</html>
```

## Workflow
1. User requests PDF (or lifecycle skill reaches DELIVER phase)
2. Gather content from spec/results document
3. Select appropriate template
4. Call `build_pdf` or generate HTML + convert
5. Save PDF to user's chosen location
6. Optionally attach to Confluence page or email
