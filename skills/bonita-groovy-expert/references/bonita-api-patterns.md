# Bonita API Patterns -- Detailed Reference

This document provides comprehensive patterns for using the Bonita Engine APIs from Groovy scripts embedded in process definitions.

## APIAccessor Overview

The `apiAccessor` object is automatically available in all Groovy script contexts within Bonita processes. It is the gateway to all Bonita Engine APIs.

```groovy
// Type: com.bonitasoft.engine.api.APIAccessor
// Available in: initProcess scripts, script tasks, connectors, operations, conditions

def identityAPI  = apiAccessor.getIdentityAPI()       // User, role, group operations
def processAPI   = apiAccessor.getProcessAPI()         // Process instance operations
def genericDAO   = apiAccessor.getBusinessObjectDAO()  // Generic BDM DAO
def typedDAO     = apiAccessor.getDAO(MyObjectDAO.class) // Typed DAO (preferred)
```

---

## IdentityAPI Patterns

The Identity API manages users, roles, groups, and memberships.

### Get user by username

```groovy
import org.slf4j.LoggerFactory

def logger = LoggerFactory.getLogger("org.bonitasoft.groovy.script.identity")
def identityAPI = apiAccessor.getIdentityAPI()

try {
    def user = identityAPI.getUserByUserName("john.doe")
    logger.info("Found user: {} (ID: {})", user.getUserName(), user.getId())
    return user
} catch (Exception e) {
    logger.error("User lookup failed for 'john.doe': {}", e.message, e)
    throw e
}
```

### Get user by ID

```groovy
def identityAPI = apiAccessor.getIdentityAPI()
def user = identityAPI.getUser(userId)
def fullName = user.getFirstName() + " " + user.getLastName()
```

### Get user by process initiator (common pattern)

```groovy
import org.slf4j.LoggerFactory

def logger = LoggerFactory.getLogger("org.bonitasoft.groovy.script.getInitiator")

try {
    def processAPI = apiAccessor.getProcessAPI()
    def identityAPI = apiAccessor.getIdentityAPI()
    def startedByUserId = processAPI.getProcessInstance(processInstanceId).getStartedBy()
    def user = identityAPI.getUser(startedByUserId)
    logger.info("Process initiator: {} {} (ID: {})",
        user.getFirstName(), user.getLastName(), user.getId())
    return user
} catch (Exception e) {
    logger.error("Failed to get process initiator: {}", e.message, e)
    throw e
}
```

### Get role by name

```groovy
def identityAPI = apiAccessor.getIdentityAPI()

try {
    def role = identityAPI.getRoleByName("manager")
    logger.info("Role '{}' has ID: {}", role.getName(), role.getId())
    return role
} catch (Exception e) {
    logger.error("Role 'manager' not found: {}", e.message, e)
    return null
}
```

### Get group by path

```groovy
def identityAPI = apiAccessor.getIdentityAPI()

try {
    // Group paths use forward slashes: /acme/hr/recruitment
    def group = identityAPI.getGroupByPath("/acme/hr")
    logger.info("Group '{}' has ID: {}", group.getName(), group.getId())
    return group
} catch (Exception e) {
    logger.error("Group '/acme/hr' not found: {}", e.message, e)
    return null
}
```

### Get user memberships

```groovy
def identityAPI = apiAccessor.getIdentityAPI()

// Get first 100 memberships for user
def memberships = identityAPI.getUserMemberships(userId, 0, 100,
    org.bonitasoft.engine.identity.UserMembershipCriterion.GROUP_NAME_ASC)

memberships.each { membership ->
    logger.info("User {} has role {} in group {}",
        userId, membership.getRoleName(), membership.getGroupName())
}
```

### Build membership key (using extension library)

```groovy
import com.bonitasoft.processbuilder.extension.MembershipUtils

// Composite key for BDM queries: "groupId$roleId"
def membershipKey = MembershipUtils.buildMembershipKey(groupId, roleId)
if (membershipKey != null) {
    def results = dao.findByMembershipKey(membershipKey, 0, 100)
}
```

---

## ProcessAPI Patterns

The Process API manages process instances, tasks, and execution flow.

### Get process instance

```groovy
def processAPI = apiAccessor.getProcessAPI()

try {
    def instance = processAPI.getProcessInstance(processInstanceId)
    def startedBy = instance.getStartedBy()
    def startDate = instance.getStartDate()
    logger.info("Process {} started by user {} on {}",
        processInstanceId, startedBy, startDate)
    return instance
} catch (Exception e) {
    logger.error("Process instance {} not found: {}", processInstanceId, e.message, e)
    throw e
}
```

### Search human task instances

```groovy
import org.bonitasoft.engine.search.SearchOptionsBuilder
import org.bonitasoft.engine.bpm.flownode.HumanTaskInstanceSearchDescriptor

def processAPI = apiAccessor.getProcessAPI()

def searchBuilder = new SearchOptionsBuilder(0, 100)
searchBuilder.filter(HumanTaskInstanceSearchDescriptor.PROCESS_INSTANCE_ID, processInstanceId)
searchBuilder.filter(HumanTaskInstanceSearchDescriptor.STATE_NAME, "ready")

def searchResult = processAPI.searchHumanTaskInstances(searchBuilder.done())
logger.info("Found {} ready tasks for process {}", searchResult.getCount(), processInstanceId)

searchResult.getResult().each { task ->
    logger.info("Task: {} (ID: {}, Assignee: {})",
        task.getName(), task.getId(), task.getAssigneeId())
}
```

### Assign a user task

```groovy
def processAPI = apiAccessor.getProcessAPI()

try {
    processAPI.assignUserTask(taskId, userId)
    logger.info("Task {} assigned to user {}", taskId, userId)
} catch (Exception e) {
    logger.error("Failed to assign task {} to user {}: {}", taskId, userId, e.message, e)
    throw e
}
```

### Execute a flow node (complete a task programmatically)

```groovy
def processAPI = apiAccessor.getProcessAPI()

try {
    // Assign then execute
    processAPI.assignUserTask(taskId, userId)
    processAPI.executeFlowNode(taskId)
    logger.info("Task {} executed by user {}", taskId, userId)
} catch (Exception e) {
    logger.error("Failed to execute task {}: {}", taskId, e.message, e)
    throw e
}
```

### Get process definition info

```groovy
def processAPI = apiAccessor.getProcessAPI()
def instance = processAPI.getProcessInstance(processInstanceId)
def definition = processAPI.getProcessDefinition(instance.getProcessDefinitionId())

logger.info("Process: {} v{}", definition.getName(), definition.getVersion())
```

---

## BusinessObjectDAO Patterns

### Generic DAO access

```groovy
// Generic DAO -- requires casting, less type-safe
def genericDAO = apiAccessor.getBusinessObjectDAO()
```

### Typed DAO access (preferred)

```groovy
// Typed DAO -- type-safe, IDE-friendly
def processDAO = apiAccessor.getDAO(com.processbuilder.model.PBProcessDAO.class)
def configDAO  = apiAccessor.getDAO(com.processbuilder.model.PBConfigurationDAO.class)
```

### Find by primary key

```groovy
def dao = apiAccessor.getDAO(com.processbuilder.model.PBProcessDAO.class)

try {
    def process = dao.findByPersistenceId(persistenceId)
    if (process == null) {
        logger.warn("PBProcess with ID {} not found", persistenceId)
    }
    return process
} catch (Exception e) {
    logger.error("DAO lookup failed for ID {}: {}", persistenceId, e.message, e)
    throw e
}
```

### Custom query with pagination

```groovy
def dao = apiAccessor.getDAO(com.processbuilder.model.PBProcessDAO.class)

// BDM queries use startIndex and maxResults for pagination
def startIndex = 0
def maxResults = 50

def results = dao.findByStatus("RUNNING", startIndex, maxResults)
logger.info("Found {} running processes (page: {}, size: {})",
    results.size(), startIndex, maxResults)
return results
```

### Custom query with multiple filters

```groovy
def dao = apiAccessor.getDAO(com.processbuilder.model.PBGenericEntryDAO.class)

// DAO method names follow BDM query naming: findBy{Field1}And{Field2}
def entry = dao.findByFullNameAndRefEntityTypeId(
    fullName.toUpperCase(),
    entityTypeId
)
return entry
```

### Count query for pagination

```groovy
// Every findBy* query should have a corresponding countFor* query
def dao = apiAccessor.getDAO(com.processbuilder.model.PBProcessDAO.class)

def totalCount = dao.countForFindByStatus("RUNNING")
def results = dao.findByStatus("RUNNING", page * pageSize, pageSize)

logger.info("Page {}/{}: {} results", page, (totalCount / pageSize) as int, results.size())
```

---

## Error Handling Patterns

### Standard try-catch with logging

```groovy
import org.slf4j.Logger
import org.slf4j.LoggerFactory

Logger logger = LoggerFactory.getLogger("org.bonitasoft.groovy.script.myScript")
logger.info("Script execution started")

try {
    // Business logic here
    def result = apiAccessor.getDAO(MyDAO.class).findByPersistenceId(id)
    if (result == null) {
        throw new IllegalStateException("Object with ID ${id} not found")
    }
    logger.info("Script completed successfully")
    return result
} catch (IllegalStateException e) {
    // Known business error -- log as warning
    logger.warn("Business validation failed: {}", e.message)
    throw e
} catch (Exception e) {
    // Unexpected error -- log as error with full stack trace
    logger.error("Unexpected error in myScript: {}", e.message, e)
    throw new RuntimeException("Script execution failed: " + e.message, e)
}
```

### Fail-fast validation

```groovy
// Validate prerequisites before executing business logic
if (storageEntityType == null) {
    throw new IllegalStateException(
        "Required PBEntityType '${typeName}' not found. " +
        "Ensure initialization scripts run first."
    )
}
```

---

## Performance Tips

### Avoid N+1 queries

```groovy
// BAD: N+1 query pattern
items.each { item ->
    def user = identityAPI.getUser(item.getUserId())  // 1 query per item
    item.setUserName(user.getUserName())
}

// GOOD: Batch lookup with a single query or cache
def userIds = items.collect { it.getUserId() }.unique()
def userCache = [:]
userIds.each { id ->
    userCache[id] = identityAPI.getUser(id)
}
items.each { item ->
    item.setUserName(userCache[item.getUserId()]?.getUserName() ?: "Unknown")
}
```

### Cache repeated DAO lookups

```groovy
// Cache DAO reference -- do not call getDAO() repeatedly in loops
def dao = apiAccessor.getDAO(com.processbuilder.model.PBProcessDAO.class)

// Reuse the same DAO for all operations
def activeProcesses = dao.findByStatus("RUNNING", 0, 100)
def draftProcesses = dao.findByStatus("DRAFT", 0, 100)
```

### Minimize API calls in actor filters

```groovy
// Actor filters must be FAST -- avoid complex BDM queries
// Use only simple Identity API lookups
def identityAPI = apiAccessor.getIdentityAPI()
def memberships = identityAPI.getUserMemberships(userId, 0, 10,
    org.bonitasoft.engine.identity.UserMembershipCriterion.ROLE_NAME_ASC)
return memberships.collect { it.getUserId() }
```

---

## Using Extension Library in Scripts

### BDMAuditUtils for creation/modification metadata

```groovy
import com.bonitasoft.processbuilder.extension.BDMAuditUtils
import com.bonitasoft.processbuilder.records.UserRecord

// UserRecord is a Java record: UserRecord(Long id, String fullName)
def initiator = new UserRecord(userId, fullName)

// Automatically sets creation or modification audit fields via reflection
def updatedObject = BDMAuditUtils.createOrUpdateAuditData(
    existingObject,    // null for creation, existing for update
    newObject,         // pre-instantiated new object (used only if existingObject is null)
    MyBDMClass.class,  // the BDM class (for logging)
    initiator,         // UserRecord with id and fullName
    persistenceId      // persistence ID (for logging)
)
```

### ConfigurationUtils for safe config retrieval

```groovy
import com.bonitasoft.processbuilder.extension.ConfigurationUtils

// Safely retrieve a configuration value with default and masking
def smtpHost = ConfigurationUtils.lookupConfigurationValue(
    "SmtpHost",                     // config key
    "SMTP",                         // entity type (for logging)
    { -> configDAO.findByFullNameAndRefEntityTypeName("SmtpHost", "SMTP")?.getConfigValue() },
    "localhost",                     // default value
    false                            // is sensitive (masks in logs if true)
)
```

### Enum constants (never hardcode strings)

```groovy
import com.bonitasoft.processbuilder.enums.ProcessStateType
import com.bonitasoft.processbuilder.enums.ActionType
import com.bonitasoft.processbuilder.enums.CriticalityType

// Use enum keys instead of raw strings
myProcess.setStatus(ProcessStateType.DRAFT.getKey())    // "Draft"
myProcess.setCriticality(CriticalityType.HIGH.getKey()) // "High"

// Validate input against enum
if (!ActionType.isValid(actionInput)) {
    throw new IllegalArgumentException("Invalid action: ${actionInput}")
}

// Get all valid values for dropdowns or validation
def allStates = ProcessStateType.getAllKeysList()  // ["Draft", "Running", "Stopped", ...]
```
