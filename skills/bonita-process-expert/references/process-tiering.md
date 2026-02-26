# 3-Level Process Architecture Methodology

This document describes the standard methodology for structuring Bonita processes into a tiered architecture. This approach promotes modularity, reusability, and maintainability.

## Overview

Every business process should be decomposed into three levels:

```
Level 1: Main Process (orchestration)
  ├── Level 2: Business Logic Subprocesses (per stage)
  │     ├── Level 3: Technical Section Subprocesses
  │     ├── Level 3: Technical Section Subprocesses
  │     └── ...
  ├── Level 2: Business Logic Subprocesses (per stage)
  │     ├── Level 3: Technical Section Subprocesses
  │     └── ...
  └── ...
```

## Level 1: Main Process (Orchestration)

The main process represents the **high-level business flow**. It should:

- Contain the primary sequence of business stages
- Use **Call Activities** to invoke Level 2 subprocesses
- Be readable as a business flow by non-technical stakeholders
- Have minimal technical implementation details
- Define the overall process contract (start event)
- Manage the primary business variable(s)

### What belongs at Level 1
- Start event with the main contract
- Call Activities to each business stage
- Major decision gateways (e.g., "Is request approved?")
- High-level error handling (boundary events on Call Activities)
- End events representing final outcomes

### What does NOT belong at Level 1
- Groovy scripts
- Connector configurations
- Complex data transformations
- Technical operations (email sending, API calls)

### Example Level 1
```
Start → [Initialize Request] → [Review Stage] → <Approved?>
  → Yes: [Fulfillment Stage] → [Closure Stage] → End (Completed)
  → No: [Rejection Stage] → End (Rejected)
```

Each bracket `[...]` is a Call Activity invoking a Level 2 subprocess.

## Level 2: Business Logic Subprocesses

Level 2 subprocesses implement the **business logic for each stage**. They should:

- Represent a complete business stage (e.g., "Review and Approval", "Document Collection")
- Contain human tasks, business decisions, and stage-specific logic
- Use Call Activities for technical operations (Level 3)
- Have their own contract defining required inputs from Level 1
- Return results to Level 1 through business variables or contract outputs

### What belongs at Level 2
- Human tasks with forms and contracts
- Business decision gateways
- Timer events for SLA and deadlines
- Boundary error events for stage-level error handling
- Call Activities to Level 3 technical subprocesses
- Simple operations (status updates, variable assignments)

### Auditing Exception
If the process requires **auditing**, that operation MUST be carried out at Level 2, even if it is a technical operation. Audit operations need business-level visibility and traceability, so they belong alongside the business logic, not buried in technical subprocesses.

### Example Level 2: Review Stage
```
Start → Assign reviewer → [Review document] → <Decision?>
  → Approve: Update status → [Send approval notification] → End
  → Reject: [Request revision info] → [Send rejection notification] → End
  → Request changes: [Send change request notification] → End (changes requested)
```

## Level 3: Technical Section Subprocesses

Level 3 subprocesses handle **technical operations** that are reusable and self-contained:

- Email and notification sending
- External API integrations
- Document generation
- File operations
- Complex data transformations
- Technical validations

### What belongs at Level 3
- Connectors (REST, SMTP, database)
- Technical scripts and data transformations
- Error handling specific to technical operations
- Retry logic for transient failures

### Key Properties
- **Self-contained**: No dependency on parent process internal state
- **Reusable**: Can be called from any Level 2 subprocess
- **Contract-driven**: All inputs come through the contract, all outputs through variables
- **Error-aware**: Proper error handling and meaningful error propagation

### Example Level 3: Send Notification
```
Start (contract: recipientEmail, subject, templateName, templateData)
  → Prepare email content from template
  → Send via SMTP connector
  → End
  (Error boundary → Log failure → End with error)
```

## When to Create Subprocesses

### Create a Subprocess When:
1. **Logic is reused in 2+ processes** -- e.g., notification sending, approval workflow
2. **A stage is complex enough to warrant isolation** -- more than 5-7 tasks in a sequence
3. **Technical operations need encapsulation** -- API calls, email, document generation
4. **Different teams maintain different parts** -- separation of concerns
5. **Testing in isolation is needed** -- subprocess can be tested independently
6. **The main process diagram becomes unreadable** -- simplify by extracting stages

### Do NOT Create a Subprocess When:
1. The logic is trivial (1-2 tasks)
2. The logic is unique to this process and will never be reused
3. Creating a subprocess adds unnecessary complexity without benefit
4. The data passing overhead outweighs the modularity benefit

## Call Activity vs Embedded Subprocess

### Call Activity (Recommended for Levels 2 and 3)
A Call Activity invokes an **independent process** defined in its own `.proc` file.

**Advantages:**
- Fully independent and reusable across multiple processes
- Has its own versioning (can be updated independently)
- Has its own contract (clear interface)
- Can be tested and deployed independently
- Appears in the Bonita Portal as a separate process instance
- Supports different actor mappings per deployment

**Use When:**
- The subprocess is reused across multiple parent processes
- You need independent versioning
- You want clear separation of concerns
- The subprocess has its own lifecycle

**Data Passing:**
```
Parent Process                    Called Process
  ├── Contract inputs ──────────→ Start contract
  │                               (process executes)
  └── Business variables ←──────── Return via shared BDM
```

### Embedded Subprocess
An Embedded Subprocess is defined **within** the parent process pool.

**Advantages:**
- Shares the parent process context (variables, data)
- No contract overhead for data passing
- Simpler for small, localized logic groups
- Useful for error boundary grouping

**Use When:**
- The logic is specific to this process only
- You need access to parent process variables directly
- The grouping is primarily for visual organization
- You want to attach a single error boundary to a group of tasks

**Limitations:**
- Cannot be reused across different processes
- No independent versioning
- Increases the complexity of the parent `.proc` file

## Example: 3-Level Decomposition

### Business Scenario: Employee Onboarding

#### Level 1: Main Onboarding Process
```
Start (contract: newEmployeeInput)
  → [Initialize Employee Record]          ← Call Activity (L2)
  → [Document Collection]                 ← Call Activity (L2)
  → [IT Setup]                            ← Call Activity (L2)
  →<All parallel>
      ├── [Workspace Preparation]         ← Call Activity (L2)
      └── [Training Assignment]           ← Call Activity (L2)
  → [Onboarding Complete]                 ← Call Activity (L2)
  → End
```

#### Level 2: Document Collection Stage
```
Start (contract: employeeId, requiredDocuments)
  → Send document request to employee      (Human task)
  → <Timer: 5 days>
      → Send reminder                      ← Call Activity (L3: Send Notification)
  → Upload documents                       (Human task)
  → [Validate documents]                   ← Call Activity (L3: Document Validation)
  → <All valid?>
      → Yes: Update status → End (documents collected)
      → No: Request corrections → (loop back to Upload)
  → [Audit: Log document collection]       ← Level 2 (auditing stays here)
  → End
```

#### Level 3: Send Notification
```
Start (contract: recipientEmail, subject, templateName, variables)
  → Build email body from template
  → Send via SMTP connector
  → End
  (Error boundary → Log error → End with error code)
```

#### Level 3: Document Validation
```
Start (contract: documentIds, validationRules)
  → Retrieve documents via REST API
  → Apply validation rules
  → Return validation results
  → End
  (Error boundary → Log error → End with error code)
```

## Subprocess Design Principles

### Self-Contained
Every subprocess must be fully self-contained:
- All required data comes through the **contract**
- No assumptions about parent process state
- No direct access to parent process variables
- Results returned through business variables or shared BDM

### Clear Contract Interface
```
Inputs (via contract):
  - employeeIdInput (Long) -- mandatory
  - documentTypeInput (String) -- mandatory
  - notifyOnCompletionInput (Boolean) -- optional, default false

Outputs (via BDM):
  - Updated business objects accessible through queries
```

### Error Propagation
- Level 3 errors should be caught at Level 2 via boundary events
- Level 2 errors should be caught at Level 1 via boundary events
- Each level decides: retry, compensate, or escalate

### Versioning Strategy
- Level 1 versions align with business process versions
- Level 2 and 3 can be versioned independently
- Use consistent naming: `ProcessName-X.Y.proc`
- Document version compatibility between levels
