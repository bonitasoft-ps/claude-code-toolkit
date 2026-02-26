# Connector and Error Handling Patterns

This document defines the patterns and standards for connector implementation, error handling, actor filters, and event handlers in Bonita processes.

## Error Handling in Processes

### Error Boundary Events

Error boundary events catch failures that occur within a task or subprocess. They are the primary mechanism for handling errors in Bonita processes.

**When to use:**
- On Service Tasks with connectors (REST, SMTP, database)
- On Call Activities (catch subprocess failures)
- On Script Tasks with complex logic that may fail

**Pattern:**
```
[Service Task: Call external API]
  │
  ├── (normal flow) → Continue process
  │
  └── (error boundary) → [Log error details] → [Notify administrator] → End (error)
```

**Example: REST API call with error boundary**
```
[Call payment gateway]
  ├── Success → Update payment status → Continue
  └── Error boundary: "Payment failed"
       → Log failure details (script task)
       → <Retry possible?>
           → Yes: [Wait 5 minutes (timer)] → Loop back to Call payment gateway
           → No: [Send failure notification] → End (payment failed)
```

### Error End Events

Error end events terminate a process or subprocess with an error status. The error propagates to the parent process (if called via a Call Activity).

**When to use:**
- When a subprocess encounters an unrecoverable error
- When the process must signal failure to the calling process
- When business logic determines the process cannot continue

**Pattern:**
```
Level 2 Subprocess:
  ... → <Validation passed?>
    → No: Set error details → Error End Event ("VALIDATION_FAILED")

Level 1 Main Process:
  [Call Activity: Validation subprocess]
    └── Error boundary: "VALIDATION_FAILED"
         → Handle validation failure
```

### Compensation Handlers

Compensation handlers implement **rollback logic** when a process needs to undo completed steps.

**When to use:**
- Multi-step transactions where later steps may fail
- Operations that create external side effects (API calls, database writes)
- Processes that must maintain consistency across systems

**Pattern:**
```
[Create order in ERP]  ──(compensation)──→ [Cancel order in ERP]
  │
  ↓
[Reserve inventory]    ──(compensation)──→ [Release inventory]
  │
  ↓
[Charge payment]
  └── Error → Trigger compensation → (rolls back inventory, then order)
```

### Timer + Loop for Retry

Use timer events combined with loops for retrying operations that may fail due to transient issues (network timeouts, service unavailability).

**Pattern:**
```
→ [Call external service]
    ├── Success → Continue
    └── Error boundary → Increment retryCount
        → <retryCount < maxRetries?>
            → Yes: [Wait (timer: exponential backoff)] → Loop back to Call
            → No: [Log permanent failure] → End (error)
```

**Retry configuration guidelines:**
| Scenario | Max Retries | Backoff | Timeout |
|----------|-------------|---------|---------|
| REST API call | 3 | 30s, 60s, 120s | 30s per attempt |
| Email sending | 2 | 60s, 300s | 60s per attempt |
| Database operation | 2 | 10s, 30s | 15s per attempt |
| File system operation | 1 | 30s | 60s per attempt |

## Connector Implementation Standards

### MANDATORY: Try-Catch with Detailed Logging

Every connector MUST implement error handling with try-catch blocks and detailed logging. This is non-negotiable.

```groovy
import org.slf4j.Logger
import org.slf4j.LoggerFactory

Logger logger = LoggerFactory.getLogger("com.company.connector.PaymentConnector")

try {
    logger.info("Starting payment processing for order: {}", orderId)

    // Connector logic here
    def response = callPaymentGateway(paymentData)

    logger.info("Payment processed successfully. Transaction ID: {}", response.transactionId)
    return response

} catch (ConnectTimeoutException e) {
    logger.error("Connection timeout to payment gateway for order: {}. Error: {}", orderId, e.message)
    throw new ConnectorException("Payment gateway unreachable: " + e.message, e)

} catch (Exception e) {
    logger.error("Unexpected error processing payment for order: {}. Error: {}", orderId, e.message, e)
    throw new ConnectorException("Payment processing failed: " + e.message, e)

} finally {
    // Always close connections
    if (connection != null) {
        try {
            connection.close()
            logger.debug("Connection closed successfully")
        } catch (Exception e) {
            logger.warn("Error closing connection: {}", e.message)
        }
    }
}
```

### Close Connections and Return Java Objects

**MANDATORY**: Always close connections in a `finally` block and return standard Java objects (not connected objects).

```groovy
// BAD: Returning a connected ResultSet (connection may close)
return resultSet

// BAD: Returning a library-specific object
return new JsonObject(response)

// GOOD: Return a Map
def result = [:]
result.put("status", response.status)
result.put("transactionId", response.transactionId)
result.put("amount", response.amount)
return result

// GOOD: Return a List of Maps
def items = []
resultSet.each { row ->
    items.add([
        id: row.getLong("id"),
        name: row.getString("name"),
        value: row.getBigDecimal("value")
    ])
}
return items
```

### Avoid Complex Objects Dependent on Libraries

Do NOT return objects that require external libraries to deserialize or use. The process engine and other consumers may not have those libraries available.

```groovy
// BAD: Returns a JSON library object (requires the library everywhere)
return new org.json.JSONObject(responseBody)

// BAD: Returns a BDM object from within a connector
return myBdmObject

// BAD: Returns an "Invoice" object from a connector-specific library
return invoiceObject

// GOOD: Return a Map (always available in Groovy/Java)
return [
    invoiceId: invoice.getId(),
    amount: invoice.getAmount(),
    currency: invoice.getCurrency(),
    status: invoice.getStatus()
]
```

### Minimize Dependencies

Connectors should encapsulate their logic and minimize external dependencies:

- Use built-in Java/Groovy libraries when possible
- If an external library is needed, include it in the connector JAR
- Do NOT expect libraries to be available on the application server
- Injecting libraries into `../lib` is a **last resort** option

### Use Expression Editor for Parameters

Use the **expression editor** to define input data for connectors. This:
- Makes parameter sources explicit and traceable
- Allows referencing process variables, business variables, and scripts
- Provides type checking at design time
- Makes the connector configuration readable in the Studio

```
Connector Input Configuration:
  url      → Expression: pBConfiguration.paymentGatewayUrl
  apiKey   → Expression: pBConfiguration.paymentApiKey
  orderId  → Expression: currentOrder.persistenceId.toString()
  amount   → Expression: currentOrder.totalAmount.toString()
```

### Connector Output Mapping

Map connector outputs to process variables or business variable updates:

```groovy
// Connector output script
def result = connectorOutput  // the Map returned by the connector

// Update business variable
def order = currentOrder
order.paymentTransactionId = result.get("transactionId")
order.paymentStatus = result.get("status")
order.modificationDate = new Date()
return order
```

## Actor Filter Rules

Actor filters determine which users can perform a human task. They MUST be highly performant because they execute at task assignment time and can block the process engine.

### Performance Requirements

Actor filters are called by the process engine during task creation. A slow actor filter delays task assignment for ALL processes.

**Rules:**
1. **Must be highly performant** -- execute in milliseconds, not seconds
2. **Avoid complex BDM queries** -- no multi-table joins, no full scans
3. **Avoid external calls** -- no REST APIs, no LDAP queries, no database calls outside Bonita
4. **Simple criteria only** -- use Bonita organization data (users, roles, groups, memberships)

### Good Actor Filter Patterns

```groovy
// GOOD: Filter by role
def candidates = IdentityAPI.getUsersInRole(roleId, 0, Integer.MAX_VALUE)
return candidates*.id

// GOOD: Filter by group membership
def candidates = IdentityAPI.getUsersInGroup(groupId, 0, Integer.MAX_VALUE)
return candidates*.id

// GOOD: Filter by process variable (already in memory)
return [taskAssigneeId]  // Single user from process variable

// GOOD: Filter by manager of initiator
def initiator = processInitiatorId
def manager = IdentityAPI.getUser(initiator).managerId
return [manager]
```

### Bad Actor Filter Patterns

```groovy
// BAD: Complex BDM query in actor filter
def dao = apiAccessor.getDAO(RequestDAO.class)
def request = dao.findByProcessInstanceId(processInstanceId)
def department = request.department
def approvers = dao.findApproversByDepartment(department)
return approvers*.userId

// BAD: External REST API call
def response = new URL("https://api.company.com/approvers").text
def approvers = new JsonSlurper().parseText(response)
return approvers.collect { it.bonitaUserId }

// BAD: LDAP query
def ldap = connectToLDAP()
def users = ldap.search("ou=approvers,dc=company")
return users*.getAttribute("bonitaId")
```

### Recommended Approach for Complex Assignment

If you need complex logic to determine task assignees:
1. Compute the assignee(s) in a **preceding script task** or **connector**
2. Store the result in a process variable (e.g., `taskAssigneeId` or `taskCandidateIds`)
3. Use a simple actor filter that reads the process variable

```
[Determine approver (script task)]    ← Complex logic here
  │ Sets: approverUserId
  ↓
[Approval task]                       ← Simple actor filter: return [approverUserId]
```

## Event Handler Rules

Event handlers respond to Bonita engine events (process started, task completed, etc.). They run inside the engine transaction and must be carefully designed.

### Rules

1. **Use only process context or BDM** -- event handlers have access to the engine APIs and BDM
2. **Avoid complex business logic** -- keep handlers lightweight
3. **No external calls** -- do not call REST APIs, send emails, or perform I/O in event handlers
4. **No long-running operations** -- event handlers block the engine transaction
5. **Log minimally** -- excessive logging in event handlers impacts performance

### Good Event Handler Patterns

```groovy
// GOOD: Update a BDM field when a task is completed
def processInstance = engineAPI.getProcessInstance(event.processInstanceId)
def dao = apiAccessor.getDAO(AuditLogDAO.class)
def log = new AuditLog()
log.processInstanceId = event.processInstanceId
log.eventType = "TASK_COMPLETED"
log.timestamp = new Date()
log.userId = event.userId
dao.save(log)
```

### Bad Event Handler Patterns

```groovy
// BAD: Sending email in event handler (blocks engine transaction)
def smtp = new SMTPClient()
smtp.send(email)

// BAD: Calling external API (network latency blocks transaction)
def response = new URL("https://api.company.com/webhook").text

// BAD: Complex business logic with multiple BDM queries
def request = requestDAO.findByProcessInstanceId(pid)
def department = departmentDAO.findByCode(request.departmentCode)
def budget = budgetDAO.findCurrentByDepartmentId(department.persistenceId)
budget.spent += request.totalAmount
budgetDAO.save(budget)
```

### Recommended Approach for Complex Event Handling

If you need complex logic triggered by an event:
1. In the event handler, **set a flag or create a simple record** in BDM
2. Have a **separate process or timer** that picks up flagged records and processes them
3. This decouples the event from the heavy processing

```
Event Handler (lightweight):
  → Create BDM record: PendingAction(type="NOTIFY", processInstanceId=pid)

Separate "Process Pending Actions" timer process:
  → Query PendingAction records
  → Process each: send emails, call APIs, complex logic
  → Mark as processed
```

## Error Handling Decision Matrix

| Scenario | Pattern | Level |
|----------|---------|-------|
| Connector timeout (transient) | Timer + retry loop | L3 |
| Connector permanent failure | Error boundary → notify + end | L3 |
| Business validation failure | Error end event → parent handles | L2 |
| Subprocess failure | Error boundary on Call Activity | L1 |
| SLA deadline missed | Timer boundary → escalation | L2 |
| Unexpected script error | Error boundary → log + notify | L2/L3 |
| External system down | Timer + retry + circuit breaker | L3 |
| Data integrity issue | Error end → compensation chain | L1/L2 |

## Logging Standards

### Log Levels in Connectors and Scripts

| Level | Use For | Example |
|-------|---------|---------|
| `ERROR` | Failures requiring attention | "Payment gateway returned 500" |
| `WARN` | Unexpected but recoverable | "Retry attempt 2 of 3" |
| `INFO` | Significant business events | "Order #123 payment processed" |
| `DEBUG` | Detailed technical info | "Request payload: {...}" |

### Logging Pattern

```groovy
import org.slf4j.Logger
import org.slf4j.LoggerFactory

// Use a meaningful logger name (package + class/connector name)
Logger logger = LoggerFactory.getLogger("com.company.process.connector.PaymentConnector")

// Include context in every log message
logger.info("[Order:{}] Starting payment processing, amount: {}", orderId, amount)
logger.error("[Order:{}] Payment failed after {} retries. Last error: {}",
    orderId, retryCount, lastError.message)
```

### What to Log
- **Always**: Operation start, operation result (success/failure), error details
- **On error**: Input parameters (sanitized -- no secrets), stack trace, retry count
- **Never**: Passwords, API keys, tokens, personal data (GDPR), full request/response bodies in production
