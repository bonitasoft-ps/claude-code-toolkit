---
name: bonita-groovy-scripting
description: "Write Groovy scripts for Bonita process operations, BDM initialization, contract-to-BDM mapping, and DAO queries."
user_invocable: true
trigger_keywords: ["groovy", "script", "operation", "bdm script", "default value", "dao", "groovy expression", "process script"]
allowed-tools: Read, Grep, Glob, Bash
---

# Bonita Groovy Scripting Patterns

You are an expert in Groovy scripting within Bonita processes.

## Context: Where Scripts Run

### Process Default Value Scripts
- Initialize business data when process starts
- Access: apiAccessor, processInstanceId, contract inputs, DAOs
- Return type: the BDM entity or collection

### Task Operation Scripts
- Execute after task completion
- Update BDM entities with contract input values
- Access: apiAccessor, taskId, BDM data, contract inputs, DAOs

### Connector Scripts
- Input/output expressions for connectors
- Access: process variables, BDM data, engine constants

### Transition Conditions
- Boolean expressions on exclusive/inclusive gateway transitions
- Access: process variables, BDM data

## Available Engine Constants
```groovy
apiAccessor          // Access to all Bonita APIs
processInstanceId    // Current process instance ID (Long)
activityInstanceId   // Current task ID (Long)
taskAssigneeId       // User assigned to current task (Long)
loggedUserId         // Currently logged-in user ID (Long)
```

## BDM Entity Initialization Pattern
```groovy
import com.company.model.Entity
import java.time.OffsetDateTime

// Get current user info
def user = apiAccessor.identityAPI.getUser(
    apiAccessor.processAPI.getProcessInstance(processInstanceId).startedBy
)

// Create new BDM entity from contract inputs
def entity = new Entity()
entity.name = entityInput.name
entity.description = entityInput.description
entity.status = "New"
entity.createdBy = user.firstName + " " + user.lastName
entity.creationDate = OffsetDateTime.now()
    .truncatedTo(java.time.temporal.ChronoUnit.MICROS)

return entity
```

## Contract-to-BDM Mapping Pattern
```groovy
// Task operation: update entity from contract
entity.fieldName = contractInput.fieldValue
entity.modificationDate = OffsetDateTime.now()
    .truncatedTo(java.time.temporal.ChronoUnit.MICROS)

return entity
```

## DAO Query Patterns
```groovy
// Find by persistenceId (built-in)
def entity = entityDAO.findByPersistenceId(entityInput.persistenceId)

// Find with custom query
def results = entityDAO.findByStatus("Active", 0, 100)

// Find single result from list
def found = entityDAO.findByCode(code, 0, 1)
if (!found.isEmpty()) {
    return found.get(0)
}

// Count query for pagination
def total = entityDAO.countForFindByStatus("Active")
```

## Relation Handling
```groovy
// Set single relation via DAO lookup
entity.parent = parentDAO.findByPersistenceId(entityInput.parentId)

// Set collection relation
def items = []
for (def itemInput : entityInput.items) {
    def item = itemDAO.findByPersistenceId(itemInput.persistenceId)
    if (item != null) items.add(item)
}
entity.itemsList = items

// Set relation using JAVA_METHOD operator
// Left operand: entity (TYPE_VARIABLE)
// Right operand: relatedEntity (expression)
// Operator: JAVA_METHOD, expression: "setRelation"
```

## OffsetDateTime Handling (CRITICAL)
Bonita uses OffsetDateTime for timestamps. Always truncate to microseconds:
```groovy
import java.time.OffsetDateTime
import java.time.temporal.ChronoUnit

// CORRECT - truncated to microseconds
def now = OffsetDateTime.now().truncatedTo(ChronoUnit.MICROS)

// WRONG - nanosecond precision causes issues
def now = OffsetDateTime.now()
```

## Custom User Info Access
```groovy
// Read custom user information fields
def userInfos = apiAccessor.identityAPI.getCustomUserInfo(userId, 0, 100)
for (def info : userInfos) {
    if (info.definition.name == "customFieldName") {
        return info.value
    }
}
```

## Process Instance Metadata
```groovy
// Get process instance
def processInstance = apiAccessor.processAPI.getProcessInstance(processInstanceId)

// Read search keys (string indexes)
def key1 = processInstance.stringIndex1  // Used for custom case IDs
def key2 = processInstance.stringIndex2

// Get started-by user
def startedBy = processInstance.startedBy
```

## Error Handling
```groovy
import org.slf4j.LoggerFactory

def logger = LoggerFactory.getLogger('ScriptName')

try {
    // Business logic
    def result = someOperation()
    logger.info("Operation succeeded: {}", result)
    return result
} catch (Exception e) {
    logger.error("Operation failed: {}", e.message)
    throw new IllegalStateException("Descriptive error message", e)
}
```

## Common Expression Types in .proc
```xml
<!-- Constant -->
<expression type="TYPE_CONSTANT" returnType="java.lang.String" content="Active"/>

<!-- Groovy Script -->
<expression type="TYPE_READ_ONLY_SCRIPT" interpreter="GROOVY"
            returnType="com.company.Entity" content="...script...">
    <referencedElements .../> <!-- Variables used in script -->
</expression>

<!-- Variable reference -->
<expression type="TYPE_VARIABLE" content="entityVar"
            returnType="com.company.Entity"/>

<!-- Contract input -->
<expression type="TYPE_CONTRACT_INPUT" content="nameInput"
            returnType="java.lang.String"/>

<!-- Engine constant -->
<expression type="TYPE_ENGINE_CONSTANT" content="apiAccessor"
            returnType="com.bonitasoft.engine.api.APIAccessor"/>

<!-- DAO reference -->
<expression type="TYPE_BUSINESS_OBJECT_DAO" content="entityDAO"
            returnType="com.company.EntityDAO" returnTypeFixed="true"/>
```

## Operation Types in .proc
```xml
<!-- Simple assignment -->
<operator type="ASSIGNMENT"/>

<!-- Java method call (for BDM setters) -->
<operator type="JAVA_METHOD" expression="setFieldName">
    <inputTypes>java.lang.String</inputTypes>
</operator>
```

## Best Practices
1. Always use `def logger = LoggerFactory.getLogger('...')` for logging
2. Truncate OffsetDateTime to MICROS
3. Null-safe navigation: `entityInput?.field?.subField`
4. Check collections before accessing: `if (!list.isEmpty())`
5. Use typed imports for BDM classes
6. Keep scripts short (< 30 lines) -- extract logic to shared Groovy classes
7. Never hardcode IDs or magic strings

## MCP Tools
- `generate_bpmn` -- Generates process with operations and scripts
- `validate_bpmn` -- Validates script expressions
