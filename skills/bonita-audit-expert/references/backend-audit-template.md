# Backend Audit Report Template

This is the full template for Bonita backend (Java/Groovy/BPM/BDM) audit reports. Use this structure exactly when generating the final Markdown report that will be converted to DOCX/PDF.

---

## Document Metadata

Fill in all fields before generating the report:

* **Client Name:** [Client Name]
* **Client Contact:** [Contact Name]
* **Client Email:** [Contact Email]
* **Project Name:** [Project Name]
* **Date:** [Month Year] (e.g., December 2024)
* **Bonitasoft Consultant:** [Consultant Name]
* **Consultant Email:** [Consultant Email]
* **Technical Configuration:**
    * **Bonita BPM Version:** [e.g., 2024.2, 2025.1]

---

## PDF Generation Instructions

The final audit report MUST be delivered in PDF format. Use the `scripts/generate-audit-report.sh` script or follow these manual steps:

### Automatic PDF Generation Workflow

1. **Try to install wkhtmltopdf (recommended):**
   ```bash
   # Windows (using Chocolatey)
   choco install wkhtmltopdf -y
   ```

2. **Generate HTML from Markdown:**
   ```bash
   pandoc report.md -o report.html --standalone --toc \
     --metadata title="Audit Report" \
     --css=https://cdn.jsdelivr.net/npm/github-markdown-css@5/github-markdown.min.css
   ```

3. **Convert HTML to PDF using wkhtmltopdf:**
   ```bash
   wkhtmltopdf --enable-local-file-access \
     --margin-top 25mm --margin-bottom 25mm \
     --margin-left 20mm --margin-right 20mm \
     report.html report.pdf
   ```

4. **Fallback - If wkhtmltopdf cannot be installed:**
   - Generate HTML only (step 2)
   - Open HTML in browser (Chrome/Edge)
   - Print to PDF (Ctrl+P -> Save as PDF)

### Alternative: Using Pandoc with LaTeX
```bash
pandoc report.md -o report.pdf --pdf-engine=xelatex \
  -V geometry:margin=1in --toc --number-sections
```

---

# PROFESSIONAL SERVICES AUDIT REPORT

## Table of Contents

1. Context
   1.1. Objective
   1.2. Methodology
2. Audit Scope
3. Summary of Findings
4. Detailed Description of Findings
   4.1. Global
   4.2. BDM (Business Data Model)
   4.3. Process
   4.4. Pages & Forms
   4.5. Rest API Extensions
5. Questions/Doubts
6. Conclusions
7. Recommendations
8. Out of Scope
9. Customer Satisfaction Survey
10. Our A La Carte Services

---

## 1. Context

### 1.1. Objective

The objective of the consultancy is to carry out an audit of the code developments implemented for the [Project Name] project. The result of the analysis will be described in the following sections, categorized by the relevant Bonita component.

### 1.2. Methodology

The recommended methodology for audits is to involve a Bonita consultant **before and during** the project implementation to ensure best practices are followed. An audit performed only after development may reveal issues that require more extensive rework.

---

## 2. Audit Scope

The audit covers the analysis of the project provided in the code repository: `[Repository Link]`, with the objective of verifying that the implementations respect **best practices** and meet business needs. Additionally, it aims to verify if the processes could affect platform performance, although a complete performance analysis is generally complicated through code review alone.

---

## 3. Summary of Findings

### Severity Legend

| # | Priority Name | Icon | Count | Description |
|---|---|---|---|---|
| **1** | COMMENT | **i** | [Count] | No action required |
| **2** | LOW | | [Count] | Limited impact |
| **3** | MEDIUM | | [Count] | Impact that should be considered |
| **4** | IMPORTANT | | [Count] | Problem that can cause serious disruption |
| **5** | PENDING ANALYSIS | **?** | [Count] | Tests are needed to evaluate the impact |

### Detailed Summary Table

| # | Component | Name | Severity | Link |
|---|---|---|---|---|
| 1 | GLOBAL | Add descriptions to project components and elements for documentation | i | 4.1.1 |
| 2 | GLOBAL | Process Version Management | [Severity] | 4.1.2 |
| 3 | GLOBAL | Use of BDM Datasource | [Severity] | 4.1.3 |
| 4 | BDM | Object and Package Naming Convention | [Severity] | 4.2.1 |
| 5 | BDM | Indexes for default and custom queries | [Severity] | 4.2.2 |
| 6 | BDM | Generation of audit fields | [Severity] | 4.2.3 |
| 7 | BDM | Use of Date types | [Severity] | 4.2.4 |
| ... | ... | *[Continue adding findings here]* | ... | ... |

---

## 4. Detailed Description of Findings

### 4.1. Global

#### 4.1.1. Add descriptions to project components and elements for documentation **(Severity: i - Comment)**
* **Problem Found:** Many components and elements lack descriptions, hindering comprehensive understanding.
* **Improvement Proposal:** Fill in descriptions for all components (connectors, tasks, processes, gateways, widgets, BDM objects/attributes, etc.) as the Studio offers full project documentation generation.
* **Impact:** Limited.

#### 4.1.2. Process Version Management **(Severity: [Severity])**
* **Problem Found:** In some cases, the process diagram (`.proc` file) version has been duplicated. This complicates code comparison tools.
* **Improvement Proposal:** Avoid changing the version of the diagram file (`.proc`). The process versioning should be followed for the process itself, but duplicating the diagram file name makes repository comparison difficult.
* **Impact:** [Impact Description].

#### 4.1.3. Use of BDM Datasource **(Severity: [Severity])**
* **Problem Found:** The default engine datasource is used to access the BDM from external REST API Extensions, which adds connections to the pool used by the engine, potentially causing performance issues.
* **Improvement Proposal:** **NEVER** use the engine's default BDM datasource from external REST services (or a REST API Extension). Instead, duplicate the datasource and use the duplicate to avoid overloading the engine's connection pool. Only perform **queries** on the BDM from external services; all inserts, updates, or deletes must be done via process task operations or connector outputs.
* **Impact:** [Impact Description].

---

### 4.2. BDM (Business Data Model)

#### 4.2.1. Object and Package Naming Convention **(Severity: [Severity])**
* **Problem Found:** Most objects and attributes follow a similar naming convention, but some attributes do not, occasionally using `snake_case` instead of the recommended convention.
* **Improvement Proposal:** Use **"camel case"** notation for object names (e.g., `NombreObjeto`) and attributes (e.g., `nombreAtributo`). Also, consider prefixing objects with a trigram/project name (e.g., `PBNombreObjeto`) for easy identification, especially in large projects.
* **Impact:** [Impact Description].

#### 4.2.2. Indexes for default and custom queries **(Severity: [Severity])**
* **Problem Found:** Several custom queries were defined without generating the corresponding indexes. Additionally, some custom queries appear to be redundant duplicates of others.
* **Improvement Proposal:** Create the necessary indexes from the BDM's **Indexes** tab in Studio to optimize query processing time (default and custom). The index should include all fields used in the query conditions. Duplicated or unnecessary custom queries should be eliminated.
* **Impact:** [Impact Description].

#### 4.2.3. Generation of audit fields **(Severity: [Severity])**
* **Problem Found:** Audit fields were created, but not consistently across all business objects, nor were all the necessary fields included.
* **Improvement Proposal:** It is recommended to define the following audit fields in **all** business objects for easier auditing and maintenance:
    * `auFechaCreacion`: DATETIME
    * `auUsuarioCreacion`: STRING (50)
    * `auFechaModificacion`: DATETIME
    * `auUsuarioModificacion`: STRING (50)
    * `auActivo`: BOOLEAN (Optional, for soft delete).
* **Impact:** [Impact Description].

#### 4.2.4. Use of Date types **(Severity: [Severity])**
* **Problem Found:** The `STRING` type is incorrectly used for attributes that represent dates.
* **Improvement Proposal:** Use `DATE ONLY` or `DATE-TIME` types to manage dates and date/times correctly. Avoid using the deprecated `DATE` (`java.util.Date`) type.
* **Impact:** [Impact Description].

#### 4.2.5. Excessive use of STRING fields without adjusting size **(Severity: [Severity])**
* **Problem Found:** The default maximum size of 255 is excessively used for `STRING` type attributes. This is inefficient for fields that clearly require less space.
* **Improvement Proposal:** Define the size of the field according to the **maximum necessary size** for each specific attribute. For numerical identifiers, consider using `INTEGER` or `LONG` types instead of `STRING`.
* **Impact:** [Impact Description].

#### 4.2.6. Correct use of aggregation or composition in BDM objects **(Severity: [Severity])**
* **Problem Found:** Incorrect use or non-use of Aggregation/Composition relationships. The code sometimes defines fields for an object's ID as a `LONG` instead of defining the attribute as an object relationship.
* **Improvement Proposal:**
    * **Define relationships correctly** using the **Aggregation** (is referenced by) and **Composition** (is part of) settings between objects, instead of manually defining ID fields.
    * **Eliminate redundant fields** if the value can be retrieved via the related object.
    * **Consolidate similar catalog tables** into generic tables to simplify the BDM structure and maintenance.
* **Impact:** [Impact Description].

#### 4.2.7. Unnecessary generation of custom queries **(Severity: [Severity])**
* **Problem Found:** Multiple custom queries and count methods were implemented that duplicate the functionality already provided by Bonita's default generated queries.
* **Improvement Proposal:** Analyze the required searches and **rely on Bonita's default queries** to avoid unnecessary duplication of code, slowing down implementation, and complicating maintenance.
* **Impact:** [Impact Description].

---

### 4.3. Process

#### 4.3.1. Process Naming Convention **(Severity: [Severity])**
* **Problem Found:** Lack of a clear and consistent naming convention for BPM elements, making processes harder to understand in scripts and diagrams.
* **Improvement Proposal:** Follow a clear naming convention for all elements. Examples:
    * **Process:** `ProcNombreProceso`
    * **Subprocess:** `SubProcNombreProceso`
    * **Task/Step:** "NombreTarea" (`displayName` "Nombre Tarea")
    * **Connectors:** `NombreConectorCon`
    * **Scripts:** `nombreScriptScript()`
* **Impact:** [Impact Description].

#### 4.3.2. Avoid bulk processing in operations **(Severity: [Severity])**
* **Problem Found:** Bulk processing logic is sometimes implemented within task **operations**.
* **Improvement Proposal:** Use **Groovy Connectors** (Service Tasks) for heavy or bulk processing, reserving task operations for simpler functions.
* **Impact:** [Impact Description].

#### 4.3.3. Avoid defining excessive process variables **(Severity: [Severity])**
* **Problem Found:** Processes contain a high number of process variables. Each modification archives a new record in `ArchDataInstance`, leading to a large volume of database records.
* **Improvement Proposal:** Minimize the number of process variables. **Use Business Data Model (BDM) objects** to store information, or consolidate multiple variables into a single BDM object variable.
* **Impact:** [Impact Description].

#### 4.3.4. Use of implicit gateways **(Severity: [Severity])**
* **Problem Found:** The use of implicit gateways makes process diagrams confusing and violates BPMN standards.
* **Improvement Proposal:** **Always use explicit gateways** to join or split two transitions. Gateways should also be explicitly named when they have multiple outgoing flows to explain the logic.
* **Impact:** [Impact Description].

#### 4.3.5. Tiered implementation (subprocesses) **(Severity: [Severity])**
* **Problem Found:** Reusable logic is not adequately structured into subprocesses.
* **Improvement Proposal:** Implement processes in a **three-tiered logic**:
    * **Level 1:** Main process logic/stages.
    * **Level 2:** Subprocesses for business logic within each stage.
    * **Level 3:** Subprocesses for technical functionalities (REST calls, error handling).
* **Impact:** [Impact Description].

#### 4.3.6. Code/Connector Reutilization - Subprocesses **(Severity: [Severity])**
* **Problem Found:** Multiple tasks contain numerous operations and multiple connectors, making logic hard to see and violating BPMN best practices.
* **Improvement Proposal:** Restructure so that a task contains **only one connector or operation**, and create dedicated reusable **Subprocesses** for common logic (REST calls, notification management).
* **Impact:** [Impact Description].

#### 4.3.7. Error Management **(Severity: [Severity])**
* **Problem Found:** Errors from connectors are not adequately managed, potentially leading to incorrect data or stuck processes.
* **Improvement Proposal:** Implement a **robust error management system** (error events, timers for retries, human tasks for manual review) to make processes more robust.
* **Impact:** [Impact Description].

#### 4.3.8. Library Management **(Severity: [Severity])**
* **Problem Found:** External library usage is not optimally managed.
* **Improvement Proposal:** Consolidate usage through **Subprocesses** so the dependency only needs to be added once, or inject the library into the application server's `../lib` folder.
* **Impact:** [Impact Description].

#### 4.3.9. Unnecessary Variables **(Severity: [Severity])**
* **Problem Found:** Several process variables were identified as unused in the process.
* **Improvement Proposal:** **Remove all unused process variables** as they unnecessarily consume space in the active and archived variable tables.
* **Impact:** [Impact Description].

#### 4.3.10. Define process version in call activities **(Severity: [Severity])**
* **Problem Found:** Explicit versions are sometimes defined in Call Activities, tying the process to a specific version.
* **Improvement Proposal:** **Avoid specifying the version** in the Call Activity. If omitted, the process will automatically call the **latest deployed version**.
* **Impact:** [Impact Description].

#### 4.3.11. One task, one connector for BPMN compatibility **(Severity: [Severity])**
* **Problem Found:** Tasks are overloaded with multiple actions, making diagrams illegible.
* **Improvement Proposal:** Limit a Service or Script task to **one connector**, and avoid adding connectors to Call Activities or Human Tasks.
* **Impact:** [Impact Description].

#### 4.3.12. Engine table management **(Severity: [Severity])**
* **Problem Found:** Document and query log tables show very large size and high growth rate, indicating potential performance issues.
* **Improvement Proposal:**
    * **Implement periodic purges** of archived tables using Bonita's purge tool.
    * Consider executing a **`TRUNCATE` on `queriable_log`** if that information is not being used.
    * Configure archived elements via `bonita-tenant-sp-custom.properties`.
* **Impact:** [Impact Description].

#### 4.3.13. Document Management **(Severity: [Severity])**
* **Problem Found:** Documents are stored directly in the Bonita database, causing significant database growth.
* **Improvement Proposal:** **Do not store documents in the Bonita database** for later viewing.
    * **Option 1:** Upload to external storage (e.g., Azure) immediately after submission, then **delete content from the Bonita instance**.
    * **Option 2:** Store the document URL in a BDM object or document field and remove content from the database.
    * Limit maximum upload size for documents/images.
* **Impact:** [Impact Description].

#### 4.3.14. Facilitate maintenance of operations on the same object **(Severity: [Severity])**
* **Problem Found:** Updating multiple attributes is done via separate operations for each attribute, resulting in a long list.
* **Improvement Proposal:** Update the business or process variable as a **single object** (`Take value of`) instead of updating individual attributes one by one.
* **Impact:** [Impact Description].

#### 4.3.15. Manage CRUD of business objects in a BPM process **(Severity: [Severity])**
* **Problem Found:** Separate process diagrams exist solely for managing CRUD operations on business objects.
* **Improvement Proposal:** Consolidate into **one or two generic management processes** using an `action` variable (NEW, EDIT, DELETE) and `persistenceId`.
* **Impact:** [Impact Description].

#### 4.3.16. Incorrect use of REST API connector with REST API Extension **(Severity: [Severity])**
* **Problem Found:** Processes excessively use **REST Connectors to call Bonita's own REST API Extensions**, consuming HTTP connections and causing unnecessary re-authentication.
* **Improvement Proposal:** **Do not call Bonita REST API Extensions from within a Bonita process**. Instead:
    * **Inside the Process:** Use the **Bonita Java API** via **Script Connectors** or **Custom Connectors**.
    * **From Pages/Forms:** Use the **Bonita REST API**.
* **Impact:** [Impact Description].

---

### 4.4. Pages & Forms

#### 4.4.1. Use of the "data" variable **(Severity: [Severity])**
* **Problem Found:** Multiple JavaScript variables are defined, becoming complicated to manage.
* **Improvement Proposal:** Define a single **`data` (JavaScript) variable** containing all necessary variables within a single JSON structure.
* **Impact:** [Impact Description].

#### 4.4.2. Use of the "ctrl" variable **(Severity: [Severity])**
* **Problem Found:** Multiple separate JavaScript variables are used for logic implementation.
* **Improvement Proposal:** Use a single **`ctrl` (controller/manager - JavaScript) variable** to consolidate all JavaScript code/functions.
* **Impact:** [Impact Description].

#### 4.4.3. Use of development variables **(Severity: [Severity])**
* **Problem Found:** Lack of dedicated variables to aid development and debugging.
* **Improvement Proposal:** Incorporate standard development variables:
    * **`log` (JavaScript):** For `console.log` messages.
    * **`debug` (URL):** URL parameter to enable hidden debug elements.
    * **`temp` (JavaScript):** For temporary or intermediate data.
    * **`functions` (JavaScript):** To hold functions for page logic.
* **Impact:** [Impact Description].

#### 4.4.4. Use of custom widgets **(Severity: [Severity])**
* **Problem Found:** Excessive number of custom widgets, many duplicating functionality. Custom widgets are not natively supported by Bonita.
* **Improvement Proposal:**
    * **Minimize custom widget usage** to only when strictly necessary.
    * Utilize widget properties for reusability.
    * Avoid Bonita REST API calls from within custom widgets.
    * Implement shared functionality in a **JavaScript library** as an asset.
* **Impact:** [Impact Description].

#### 4.4.5. Use of exposed variables in a fragment **(Severity: [Severity])**
* **Problem Found:** Fragments expose a large number of individual "exposed" variables.
* **Improvement Proposal:** Use a single **`data` (JavaScript) variable** containing a JSON object to pass all required values.
* **Impact:** [Impact Description].

---

### 4.5. REST API Extensions

#### 4.5.1. Manage validation correctly **(Severity: [Severity])**
* **Problem Found:** `doHandle` method duplicates code for validation and response handling. Exceptions sometimes return misleading "OK" responses.
* **Improvement Proposal:** **Refactor and modularize the code** to simplify validation (dedicated handler methods, `switch` statements, generic response builders). Implement clear constants and ensure **error logs** are present. Return appropriate HTTP error status codes.
* **Impact:** [Impact Description].

#### 4.5.2. Code optimization **(Severity: [Severity])**
* **Problem Found:** Groovy code in REST API Extensions is long, repetitive, and lacks proper legibility and reuse.
* **Improvement Proposal:** Apply **Clean Code** principles:
    * **Functions/Methods:** Keep them short, with a single responsibility.
    * **Reusability:** Create shared utility methods and a common library.
    * **Readability:** Use descriptive names, eliminate magic strings/constants.
* **Impact:** [Impact Description].

#### 4.5.3. Unnecessary REST API Extension **(Severity: [Severity])**
* **Problem Found:** REST API Extensions implement generic functionality that could be simplified. Some execute **direct SQL updates to Bonita's engine tables** (STRICTLY FORBIDDEN).
* **Improvement Proposal:**
    * **NEVER perform direct manipulation (Insert, Update, Delete) of Bonita engine tables**.
    * **All BDM modifications (CRUD) must happen within the BPM process**.
    * Limit REST API Extensions to **reading** information from the BDM using a duplicated read-only datasource.
* **Impact:** [Impact Description].

---

## 5. Questions/Doubts

[This section should contain any questions that arose during the review that require clarification from the client or development team.]

---

## 6. Conclusions

* **Document Management:** [Assessment of document handling practices]
* **Database Optimization:** [Assessment of BDM indexes, purge procedures, query optimization]
* **Process Architecture:** [Assessment of subprocess tiering, connector usage, BPMN compliance]
* **Inter-Process Communication:** [Assessment of REST connector usage patterns]
* **Code Quality:** [Assessment of Clean Code adherence in REST API Extensions and scripts]
* **BDM Structure:** [Assessment of data model design, catalog consolidation]
* **Variable Usage:** [Assessment of process variable minimization]
* **BPMN Compliance:** [Assessment of gateway usage and diagram legibility]
* **Cleanup:** [Assessment of unused components and dead code]

---

## 7. Recommendations

* **Front-End Performance:** Limit external API calls per page/fragment; ensure pagination for all list queries.
* **API Usage:** Prioritize **Bonita Java API in processes/connectors** and **Bonita REST API in forms/pages**.
* **UI Best Practices:** Use explicit input validation, reduce exposed variables in fragments, develop responsive applications.
* **Continuous Improvement:** Implement robust **Error Management** strategy.
* **Security:** Define proper **profile** to restrict access to authorized users.
* **Documentation:** Consistently use descriptions in Studio for **automatic technical documentation generation**.

---

## 8. Out of Scope

* Any code not within the provided Git repository.
* Any development required to correct the points mentioned in this document.

---

## 9. Customer Satisfaction Survey

Please follow the link here to send your feedback: [Link to Survey]

---

## 10. Our A La Carte Services

* **SIP (Strategic Implementation Partner):** Expert support to carry out your project successfully following Bonitasoft best practices.
* **Audit:** Validation of your Bonita platform configuration (sizing, security, performance) and code review to ensure best practices.
* **Bonita Update:** Technical assistance to upgrade your Bonita version to benefit from new functionalities.
* **Urgent Project Delivery:** Fast-track your project to production using Bonita's full expertise.
* **Customer Support:** Expert assistance for your Bonita project delivery.
