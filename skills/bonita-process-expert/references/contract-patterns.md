# Contract Design Patterns

This document defines the patterns and standards for designing contracts in Bonita processes. Contracts define the API interface for starting processes and completing human tasks.

## General Contract Principles

1. **Contracts are the API**: They define what data flows in and out of process boundaries
2. **Validate at the boundary**: Use contract constraints to reject invalid data early
3. **Minimal surface area**: Only include what is needed at that specific point
4. **Document everything**: Every input should have a clear description

## Start Contracts

Start contracts define ALL input parameters needed to **start a process instance**. They are the entry point for the business process.

### Rules for Start Contracts

1. **Define ALL input parameters** needed to initialize the process
2. **Use complex types** for structured data (group related fields)
3. **Validate with contract constraints** (mandatory fields, format, ranges)
4. **Document each input** with a clear description
5. **Add "Input" suffix** to input names (e.g., `requestInput`, `employeeInput`)
6. **Use a complex root object** to group all input data
7. **Define ONLY mandatory elements** -- optional data should have defaults in the process logic

### Start Contract Structure

```
Contract: Start Event
└── <processName>Input (COMPLEX)
    ├── field1 (TEXT) -- description: "..."
    ├── field2 (INTEGER) -- description: "..."
    ├── nestedObject (COMPLEX)
    │   ├── subField1 (TEXT)
    │   └── subField2 (DATE)
    └── items (COMPLEX, MULTIPLE)
        ├── itemName (TEXT)
        └── quantity (INTEGER)
```

### Example: Purchase Request Start Contract

```
Contract: Start Event - "Submit purchase request"
└── purchaseRequestInput (COMPLEX)
    ├── title (TEXT)
    │   Description: "Title of the purchase request"
    │   Constraint: mandatory, maxLength(200)
    ├── description (TEXT)
    │   Description: "Detailed description of what is being requested"
    ├── department (TEXT)
    │   Description: "Department code requesting the purchase"
    │   Constraint: mandatory
    ├── totalAmount (DECIMAL)
    │   Description: "Total estimated amount in base currency"
    │   Constraint: mandatory, greaterThan(0)
    ├── currency (TEXT)
    │   Description: "ISO 4217 currency code (e.g., EUR, USD)"
    │   Constraint: mandatory, pattern("[A-Z]{3}")
    ├── urgency (TEXT)
    │   Description: "Priority level: LOW, MEDIUM, HIGH, CRITICAL"
    │   Constraint: mandatory
    └── lineItems (COMPLEX, MULTIPLE)
        ├── itemDescription (TEXT)
        │   Constraint: mandatory
        ├── quantity (INTEGER)
        │   Constraint: mandatory, greaterThan(0)
        ├── unitPrice (DECIMAL)
        │   Constraint: mandatory, greaterThan(0)
        └── supplierCode (TEXT)
            Description: "Preferred supplier code, if known"
```

### Start Contract Constraints

Constraints validate input data before the process starts. Define constraints for:

| Constraint Type | Example | Use Case |
|----------------|---------|----------|
| Mandatory | `field != null` | Required fields |
| Pattern | `matches("[A-Z]{3}")` | Format validation |
| Range | `value > 0 && value < 10000` | Numeric bounds |
| Length | `length <= 200` | String length limits |
| Custom | Groovy expression | Business rules |

### What to Initialize from Start Contract

The start contract data should be used in the process instantiation to:
1. Create the initial BDM business object(s)
2. Set process variables for flow control (status flags, routing decisions)
3. Store the initiator information (userId from API context)

```groovy
// Example: Initialization script from start contract
def request = new com.company.model.PurchaseRequest()
request.title = purchaseRequestInput.title
request.description = purchaseRequestInput.description
request.department = purchaseRequestInput.department
request.totalAmount = purchaseRequestInput.totalAmount
request.currency = purchaseRequestInput.currency
request.urgency = purchaseRequestInput.urgency
request.status = "SUBMITTED"
request.creationDate = new Date()
request.creationUser = BonitaUsers.getProcessInstanceInitiator(apiAccessor)
request.processInstanceId = processInstanceId
return request
```

## Task Contracts

Task contracts define what a user submits at each human task. They should be **minimal** -- only the data that changes at that specific step.

### Rules for Task Contracts

1. **Minimal scope**: Only include fields the user modifies at this step
2. **Use `mandatoryExpression`** for conditional requirements
3. **Add "Input" suffix** to the contract name
4. **Use a complex root object** to group related fields
5. **Do NOT repeat data** already available in business variables

### Example: Approval Task Contract

```
Contract: "Review and approve request"
└── approvalInput (COMPLEX)
    ├── decision (TEXT)
    │   Description: "Approval decision: APPROVED, REJECTED, CHANGES_REQUESTED"
    │   Constraint: mandatory
    ├── comments (TEXT)
    │   Description: "Reviewer comments explaining the decision"
    │   mandatoryExpression: decision == "REJECTED" || decision == "CHANGES_REQUESTED"
    └── approvedAmount (DECIMAL)
        Description: "Final approved amount (may differ from requested)"
        mandatoryExpression: decision == "APPROVED"
```

### Task Contract Update Pattern

After a task contract is submitted, update the business variable in a single operation:

```groovy
// Operation: takes value of
def request = currentRequest
request.status = approvalInput.decision == "APPROVED" ? "APPROVED" :
                 approvalInput.decision == "REJECTED" ? "REJECTED" : "CHANGES_REQUESTED"
request.reviewerComments = approvalInput.comments
request.approvedAmount = approvalInput.approvedAmount
request.modificationDate = new Date()
request.modificationUser = taskAssigneeId
return request
```

### Conditional Mandatory Fields

Use `mandatoryExpression` when a field is required only under certain conditions:

```
Field: rejectionReason (TEXT)
  mandatoryExpression: approvalInput.decision == "REJECTED"
  Description: "Mandatory when the request is rejected"

Field: alternativeSupplier (TEXT)
  mandatoryExpression: approvalInput.changeSupplier == true
  Description: "Required when the reviewer requests a supplier change"
```

## Called Process (Thread) Contracts

When using Call Activities to invoke subprocesses, the called process MUST define a contract for the information sent by the parent process.

### Rules for Called Process Contracts

1. **Define a contract for ALL information** sent from the calling process
2. **Use the "Input" suffix** on the root complex type
3. **Keep it self-contained**: The subprocess should not need to query for additional data
4. **Document the expected caller**: Add descriptions noting which parent process provides the data

### Example: Notification Subprocess Contract

```
Contract: Start Event - "Send notification"
└── notificationInput (COMPLEX)
    ├── recipientEmail (TEXT)
    │   Description: "Email address of the notification recipient"
    │   Constraint: mandatory, pattern("^[\\w.-]+@[\\w.-]+\\.[a-zA-Z]{2,}$")
    ├── recipientName (TEXT)
    │   Description: "Display name of the recipient"
    │   Constraint: mandatory
    ├── subject (TEXT)
    │   Description: "Email subject line"
    │   Constraint: mandatory, maxLength(200)
    ├── templateName (TEXT)
    │   Description: "Name of the email template to use from PBConfiguration"
    │   Constraint: mandatory
    └── templateVariables (COMPLEX, MULTIPLE)
        ├── key (TEXT)
        │   Constraint: mandatory
        └── value (TEXT)
```

### Passing Data to Called Processes

In the Call Activity configuration, map parent process data to the subprocess contract:

```
Call Activity: "Send approval notification"
  Contract mapping:
    notificationInput.recipientEmail  ←  requestor.email
    notificationInput.recipientName   ←  requestor.displayName
    notificationInput.subject         ←  "Your request " + request.title + " has been approved"
    notificationInput.templateName    ←  "approval-notification"
    notificationInput.templateVariables ← [
      [key: "requestTitle", value: request.title],
      [key: "approvedAmount", value: request.approvedAmount.toString()],
      [key: "approverName", value: approverName]
    ]
```

## Anti-Patterns to Avoid

### 1. Flat Contract (No Root Object)
```
BAD:
  ├── title (TEXT)
  ├── description (TEXT)
  ├── amount (DECIMAL)
  └── department (TEXT)

GOOD:
  └── requestInput (COMPLEX)
      ├── title (TEXT)
      ├── description (TEXT)
      ├── amount (DECIMAL)
      └── department (TEXT)
```

### 2. Over-Specified Task Contract
```
BAD (task contract repeats data already in BDM):
  └── reviewInput (COMPLEX)
      ├── requestTitle (TEXT)        ← already in BDM, don't ask again
      ├── requestAmount (DECIMAL)    ← already in BDM
      ├── department (TEXT)          ← already in BDM
      ├── decision (TEXT)            ← actual user input
      └── comments (TEXT)            ← actual user input

GOOD (task contract only includes new data):
  └── reviewInput (COMPLEX)
      ├── decision (TEXT)
      └── comments (TEXT)
```

### 3. Missing "Input" Suffix
```
BAD:  purchaseRequest (COMPLEX)
GOOD: purchaseRequestInput (COMPLEX)
```

### 4. Optional Fields Without Defaults
```
BAD:
  └── requestInput (COMPLEX)
      ├── title (TEXT) -- mandatory
      ├── priority (TEXT) -- not mandatory, no default anywhere
      └── category (TEXT) -- not mandatory, no default anywhere

GOOD:
  └── requestInput (COMPLEX)
      ├── title (TEXT) -- mandatory
      (priority and category have defaults set in the initialization script)
```

### 5. No Contract on Called Process
```
BAD: Called subprocess reads parent variables directly (embedded subprocess behavior)

GOOD: Called subprocess has its own contract defining exactly what it needs
```

## Contract Validation Strategy

### Layer 1: Contract Constraints
- Structural validation (mandatory, type, format)
- Simple business rules (ranges, patterns)
- Executes before the process/task logic

### Layer 2: Process Logic Validation
- Complex business rules requiring data lookup
- Cross-field validations
- Validations requiring BDM queries

### Layer 3: Frontend Validation (UIB)
- Immediate user feedback
- Format hints and masks
- Client-side convenience (does NOT replace contract validation)

Always validate at **all three layers**. Never rely solely on frontend validation -- the contract is the authoritative validation boundary.
