# BPM Modeling Standards and Conventions

This document defines the complete set of BPM modeling standards for Bonita process design. These standards ensure consistency, readability, and maintainability across all business processes.

## Task Naming

Use **verbs** for task names to make the action immediately clear. The name should tell the user exactly what to do rather than just naming a concept.

### Good Examples
- "Review purchase request"
- "Approve budget allocation"
- "Send notification to manager"
- "Update order status"
- "Calculate shipping cost"

### Bad Examples
- "Request" (no verb, unclear action)
- "Budget" (just a noun)
- "Notification" (what about it?)
- "Step1" (meaningless)

## Lane Naming Convention

Lane names MUST use a **prefix followed by the actor type**:

```
<prefix>_<actorType>
```

### Examples
| Lane Name | Meaning |
|-----------|---------|
| `adm_administrator` | Administrator lane |
| `mgr_manager` | Manager lane |
| `usr_requester` | Requester/end-user lane |
| `sys_system` | System/automated lane |
| `fin_accountant` | Finance accountant lane |
| `hr_recruiter` | HR recruiter lane |

This convention makes it immediately clear which actor type is responsible for tasks in each lane.

## Diagram Organization

### Single Diagram Per Business Process
- One diagram file (`.proc`) should represent ONE business process
- **Exception**: Meta-diagrams can link to multiple sub-processes for overview purposes
- If you find yourself putting unrelated flows in one diagram, split them

### Element Naming Rules

**MANDATORY**: Define names for ALL BPM elements with meaningful, descriptive names.

| Element | Rule | Good Example | Bad Example |
|---------|------|-------------|-------------|
| Start event | Describe what triggers it | "Request received" | "Start1" |
| End event | Describe the outcome | "Request approved" | "End1" |
| Gateway (exclusive) | Describe the decision | "Is amount > 1000?" | "Gate1" |
| Gateway (parallel) | Hide the name | _(hidden)_ | "Gate2" |
| Task | Use verb phrase | "Validate documents" | "Step1" |
| Timer | Describe the duration/trigger | "Wait 24h for response" | "Timer1" |
| Error event | Describe the error | "Payment failed" | "Error1" |

### Use "end" Not "terminal"
For consistency across the project, always use the term **"end"** instead of "terminal" in BPM element names:
- "End - approved" (correct)
- "Terminal - approved" (incorrect)

## Gateway Standards

### Exclusive Gateways (XOR)
1. **Add an explicit name** describing the decision (e.g., "Is request approved?")
2. **Name each transition** with the condition result (e.g., "Yes", "No", "Amount > 1000")
3. **Always add a default transition** -- this prevents process instances from getting stuck

```
Example:
  Gateway: "Is budget sufficient?"
    ├── "Yes" → Proceed to purchase
    ├── "No, under 500" → Request additional funds
    └── "Default" → Escalate to manager
```

### Parallel Gateways (AND)
1. **Hide the gateway name** -- parallel splits and merges are self-explanatory
2. Use parallel gateways only when tasks MUST execute concurrently
3. Ensure all parallel branches converge at a merge gateway

### Merge Gateways
1. **Hide the name** for merge gateways (both exclusive and parallel merges)
2. The merge is a structural element, not a decision point

### NEVER Use Implicit Gateways
Implicit gateways (multiple outgoing transitions from a task without an explicit gateway element) are forbidden. Always use an explicit gateway element for any branching logic.

## Task Type Selection

### Service Task
Use for **API calls and external integrations**:
- Calling external REST APIs
- Sending emails via SMTP
- Integrating with third-party systems
- Database operations through connectors

### Script Task
Use for **internal scripts and logic**:
- Status updates on BDM objects
- Data transformation and mapping
- Calculating values
- Preparing data for subsequent steps

### Decision Rule
**Heavy processing -> Connector** (in a Service Task)
**Simple assignments -> Operations** (on the task itself)

If the logic is complex, computationally expensive, or involves external systems, use a connector. If it is a simple variable assignment or status update, use operations.

## Operations Best Practices

### Avoid Multiple Operations on the Same Object
When you need to update multiple attributes of the same object, do NOT create separate operations for each attribute. Instead:

1. Use **"takes value of"** with a single Groovy expression that sets all attributes
2. This prevents race conditions and ensures atomic updates

### Bad Practice
```
Operation 1: myObject.status = "approved"
Operation 2: myObject.approvalDate = new Date()
Operation 3: myObject.approvedBy = currentUser
```

### Good Practice
```groovy
// Single operation using "takes value of"
def obj = myObject
obj.status = "approved"
obj.approvalDate = new Date()
obj.approvedBy = currentUser
return obj
```

## Process Variables

### Allowed Types
For performance reasons, process variables MUST use ONLY:
- **Primitives**: Boolean, Integer, Long, Double
- **String**
- **List / Array**: Of primitives or String only
- **Map**: For key-value pairs

### Process Variables vs BDM
If the data has **business meaning** and should be **stored persistently**, use a **BDM business variable** -- NOT a process variable.

Use process variables only for:
- Temporary flags and counters
- Loop indices
- Intermediate calculation results
- Simple control flow data

### Naming Convention
- **camelCase** always
- **Descriptive names**: `currentApprovalStatus`, `remainingBudget`, `selectedDocumentIds`
- **Never**: `x`, `tmp`, `var1`, `data`

## Flow Control

### Avoid Infinite Multi-Instances
Multi-instance tasks must always have a bounded collection. Never create a multi-instance that could iterate indefinitely.

### Avoid Infinite Cyclic Flows
Every loop in a process MUST have:
1. A **condition for termination** (the normal exit)
2. A **"manual" option** for termination (escape hatch for exceptional cases)

Without both, a process instance could run forever, consuming resources and cluttering the database.

### Message Events
Care must be taken to define messages that are not captured. Since uncaptured messages will be **listened to infinitely**, they cause the database to grow unboundedly. Always ensure:
- Message correlation is properly configured
- Timeout mechanisms exist for message catches
- Uncorrelated messages are handled gracefully

### Links for Readability
Use **link events** (throw and catch) to improve diagram readability when:
- The flow would require long crossing arrows
- The diagram becomes cluttered with overlapping connections
- You want to connect distant parts of the process visually

## Description Fields

Complete the **description field** inside ALL project components. This is fundamental for:
- Automatic project documentation generation
- Team onboarding and knowledge transfer
- Future maintenance and debugging
