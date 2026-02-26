# UIB (UI Builder) Audit Report Template

This is the full template for Bonita front-end (UI Builder / Appsmith-based) audit reports. Use this structure exactly when generating the final Markdown report that will be converted to DOCX/PDF.

---

# PROFESSIONAL SERVICES FRONT-END AUDIT REPORT

## Document Metadata (Header)

| Field | Value to Fill |
| :--- | :--- |
| **Audit Synthesis - Team** | [Team Name/A/B/C] |
| **Focus** | [Page Audited: Home/Risk Team/Mock Customer UI] |
| **Auditors** | [Consultant Name(s)] |
| **Date** | [Month Year] |
| **Project Audited** | [Project Name] |
| **Platform** | Bonitasoft UI Builder (Appsmith-based) |

---

## Best Practices & Practices to Avoid

**Goal:** Identify architectural and coding practices. Add rows as needed.

| Category | Best Practice / To Avoid | Why | Found in project? | Location/Comment |
| :--- | :--- | :--- | :--- | :--- |
| **JS Code Structure** | BEST PRACTICE: Centralize logic in JS Objects (SRP). | Improves maintainability and testing. | [Yes / No] | [Function/File Name] |
| **UI Performance** | TO AVOID: Run heavy queries (Base64/large data) on page load. | Causes high latency and slow load times. | [Yes / No] | [e.g., Home Page OnLoad Actions] |
| **Code Robustness** | TO AVOID: Use hardcoded array indexes for data retrieval. | Highly fragile; breaks if data order changes. | [Yes / No] | [e.g., RequestUtils.getDocumentUrl] |
| **Error Handling** | BEST PRACTICE: Use contextual try/catch blocks with detailed console logs. | Improves UX and speeds up debugging. | [Yes / No] | [e.g., JS Object functions] |
| **Widget Structure** | TO AVOID: Deeply nest simple widgets (Container > Canvas > Container). | Leads to inflexible layout and maintenance issues. | [Yes / No] | [Widget Path] |
| **API Calls** | BEST PRACTICE: Use pagination for all list queries. | Prevents loading excessive data and improves responsiveness. | [Yes / No] | [Query Name] |
| **State Management** | BEST PRACTICE: Use centralized state in JS Objects, not widget-level bindings. | Ensures single source of truth and easier debugging. | [Yes / No] | [Component/Object Name] |
| **Security** | BEST PRACTICE: Validate authorization server-side, not just in UI. | Client-side checks can be bypassed. | [Yes / No] | [Endpoint/Function Name] |
| **Code Duplication** | TO AVOID: Duplicate JS logic across multiple JS Collections. | Increases maintenance burden and risk of inconsistent behavior. | [Yes / No] | [e.g., Home_RequestUtils vs Risk Team_RequestUtils] |
| **Async Patterns** | BEST PRACTICE: Use async/await with proper error handling. | Avoids callback hell and unhandled promise rejections. | [Yes / No] | [Function Name] |

---

## Naming Conventions

**Goal:** Evaluate clarity, consistency, and adherence to naming standards.

| Element | Proposed Convention | Good Example | Bad Example | Applied in project? |
| :--- | :--- | :--- | :--- | :--- |
| **Queries (APIs)** | verbNoun (camelCase) | `getLoanRequests` | `getdata` | [Yes / No] |
| **Javascript (Functions)** | verbActionNoun (camelCase) | `openCustomerModel` | `do_stuff` | [Yes / No] |
| **Widgets** | Noun_Context_Type (PascalCase) | `RequestList_Table` | `Canvas10Copy`, `Button3` | [Yes / No] |
| **JS Objects** | PageName_DomainUtils (PascalCase) | `Home_RequestUtils` | `utils1`, `myFunctions` | [Yes / No] |
| **Pages** | PascalCase descriptive name | `LoanRequestDashboard` | `page1`, `newPage` | [Yes / No] |
| **Variables** | camelCase descriptive name | `selectedCustomerId` | `x`, `temp1`, `val` | [Yes / No] |

---

## Questions / Discussion Points

**Goal:** Points that require internal discussion or clarification with the client's development team.

1. **Index Dependency:** The critical function `getDocumentUrl` relies on a hardcoded index based on document name. What mechanism is in place to guarantee the document order from the backend?
2. **State Management:** Should the logic for container visibility be moved to the centralized JS object for better control, instead of being bound directly to a long expression in the widget property?
3. **Process Status:** Are the intermediate process statuses correctly handled and displayed across all user roles?
4. **Performance Budget:** What is the target page load time? Are there SLAs to meet?
5. **Accessibility:** Has the application been tested for WCAG compliance?
6. **Mobile Responsiveness:** Which screen sizes must be supported?

[Add or remove questions based on the actual audit findings.]

---

## For Client Audits

**Goal:** Executive summary of findings, focusing on business impact and required remediation.

### Key questions to ask:

1. **Performance Priority:** How critical is the initial page load time? Should heavy data fetching (e.g., document Base64) be deferred until user interaction?
2. **Security Authorization:** Can we verify that the Bonita backend's API layer strictly enforces authorization checks for data retrieval endpoints, ensuring users can only access documents related to their assigned tasks/requests?
3. **Future Scalability:** Given the current widget naming and component documentation state, how will the client handle maintenance and onboarding for new developers?

### Points to watch for:

* **Rigid UI Layout:** Deep nesting of components may cause responsiveness issues on different devices.
* **UX Error Handling:** Error messages are too generic (e.g., "There was an error") and must provide meaningful feedback to users and support staff.
* **Single Responsibility Principle (SRP) Violation:** Functions performing multiple unrelated actions complicate testing and maintenance.
* **Fragile Data Dependencies:** Hardcoded indexes, literal strings, or assumptions about data ordering that will break if the backend changes.

### Red flags to identify:

* **CRITICAL: Data Instability (Document Indexing):** Hardcoded array index logic for document retrieval is highly likely to fail if the backend document list order changes. Must be immediately refactored.
* **HIGH: Security Risk in API:** Data retrieval endpoints (especially Base64 document endpoints) are high-risk areas. Authorization must be validated against Bonita security best practices.
* **HIGH: Code Duplication Across Pages:** Identical JS logic duplicated in multiple JS Collections creates a maintenance nightmare and inconsistency risk.
* **MEDIUM: Performance on Page Load:** Heavy queries running on page initialization without lazy loading or pagination.

---

## Detailed Findings

### Finding Template

For each finding, use this structure:

#### [Finding Number]. [Finding Title] **(Severity: [COMMENT/LOW/MEDIUM/IMPORTANT/PENDING ANALYSIS])**

* **Component:** [Page/Widget/JS Object/Query name]
* **Location:** [File path or component path within UIB]
* **Problem Found:** [Clear description of what was found]
* **Improvement Proposal:** [Specific, actionable recommendation]
* **Code Example (Before):**
  ```javascript
  // Fragile: depends on array order
  const index = fileName === "Credit history" ? 0 : 1;
  ```
* **Code Example (After):**
  ```javascript
  // Robust: finds by property
  const doc = documents.find(d => d.name === fileName);
  ```
* **Impact:** [Business and technical impact description]

---

## Attachments

* **Code Snippet: Fragile Indexing** (e.g., `const index = fileName === "Credit history" ? 0 : 1;`)
* **Screenshot:** Example of poorly named widget (e.g., `Canvas10Copy`).
* **Performance Profile:** Page load waterfall showing heavy queries.
* **Duplication Report:** Side-by-side comparison of duplicated JS Objects.

[Add relevant screenshots, code snippets, and data to support findings.]

---

## Export and Delivery Instructions

The final audit report MUST be delivered in PDF format.

### 1. Generating the Final Markdown File

Save the completed report as: **`YYYY_MM_audit_uib_report.md`**

### 2. Converting to Word (Intermediate Step)

Use Pandoc to convert the Markdown to a DOCX file:
```bash
pandoc audit_report.md -o YYYY_MM_Audit_UIB_Report.docx
```

### 3. Converting to PDF (Final Deliverable)

Option A - Using wkhtmltopdf:
```bash
pandoc audit_report.md -o audit_report.html --standalone --toc
wkhtmltopdf --enable-local-file-access \
  --margin-top 25mm --margin-bottom 25mm \
  --margin-left 20mm --margin-right 20mm \
  audit_report.html YYYY_MM_Audit_UIB_Report.pdf
```

Option B - Using LaTeX:
```bash
pandoc audit_report.md -o YYYY_MM_Audit_UIB_Report.pdf --pdf-engine=xelatex \
  -V geometry:margin=1in --toc --number-sections
```

Option C - Manual fallback:
- Generate HTML via Pandoc
- Open in Chrome/Edge
- Print to PDF (Ctrl+P -> Save as PDF)

### 4. Output Location

Deliver the final files to: `reports/audit-out/`
