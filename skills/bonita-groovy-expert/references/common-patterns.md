# Common Groovy Script Patterns for Bonita

This document provides ready-to-use Groovy script patterns for common operations in Bonita BPM processes. All examples follow Bonita conventions: SLF4J logging, try-catch for external calls, max 30 lines, and extension library enum constants.

---

## Initialize a Business Variable (Complete Example)

This is the most common script type -- it initializes a BDM object at process start.

```groovy
import java.time.OffsetDateTime
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import com.bonitasoft.processbuilder.enums.ProcessStateType
import com.bonitasoft.processbuilder.records.UserRecord
import com.bonitasoft.processbuilder.extension.BDMAuditUtils
import com.processbuilder.model.PBProcess

Logger logger = LoggerFactory.getLogger("org.bonitasoft.groovy.script.initProcess")
logger.info("Initializing PBProcess business variable")

try {
    def processAPI = apiAccessor.getProcessAPI()
    def identityAPI = apiAccessor.getIdentityAPI()
    def startedBy = processAPI.getProcessInstance(processInstanceId).getStartedBy()
    def user = identityAPI.getUser(startedBy)
    def initiator = new UserRecord(user.getId(),
        user.getFirstName() + " " + user.getLastName())

    def pbProcess = new PBProcess()
    pbProcess.setStatus(ProcessStateType.DRAFT.getKey())
    pbProcess.setCreationDate(OffsetDateTime.now())
    pbProcess.setCreatorId(initiator.id())
    pbProcess.setCreatorName(initiator.fullName())

    logger.info("PBProcess initialized with status '{}'", pbProcess.getStatus())
    return pbProcess
} catch (Exception e) {
    logger.error("Failed to initialize PBProcess: {}", e.message, e)
    throw new RuntimeException("PBProcess init failure: " + e.message, e)
}
```

**Referenced elements needed in .proc**: `processInstanceId` (TYPE_ENGINE_CONSTANT), `apiAccessor` (TYPE_ENGINE_CONSTANT)

---

## Initialize a List of Business Variables (Batch Pattern)

Used when initializing master data (enums to BDM entries).

```groovy
import java.time.OffsetDateTime
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import com.bonitasoft.processbuilder.enums.CriticalityType
import com.bonitasoft.processbuilder.extension.PBStringUtils
import com.processbuilder.model.PBGenericEntry

Logger logger = LoggerFactory.getLogger("org.bonitasoft.groovy.script.initGenericEntries")

try {
    def now = OffsetDateTime.now()
    Map<String, String> criticalityData = CriticalityType.getAllData()

    List<PBGenericEntry> resultList = []
    int index = 1

    criticalityData.each { key, description ->
        def entry = pBGenericEntryDAO.findByFullNameAndRefEntityTypeId(
            PBStringUtils.toUpperSnakeCase(key), entityTypeId)

        if (entry == null) {
            entry = new PBGenericEntry()
            entry.setCreationDate(now)
            entry.setCreatorId(startedByUserId)
        }

        entry.setFullName(PBStringUtils.toUpperSnakeCase(key))
        entry.setLabel(key)
        entry.setDisplayName(key)
        entry.setIndexOrder(index++)
        entry.setFullDescription(description)
        entry.setEnabled(true)
        resultList.add(entry)
    }

    logger.info("Generated {} PBGenericEntry objects", resultList.size())
    return resultList
} catch (Exception e) {
    logger.error("Failed to initialize entries: {}", e.message, e)
    throw new RuntimeException("GenericEntry init failure: " + e.message, e)
}
```

---

## Query BDM with DAO (Pagination and Filtering)

### Simple paginated query

```groovy
import org.slf4j.LoggerFactory

def logger = LoggerFactory.getLogger("org.bonitasoft.groovy.script.queryProcesses")

try {
    def dao = apiAccessor.getDAO(com.processbuilder.model.PBProcessDAO.class)
    def results = dao.findByStatus("Running", 0, 50)
    logger.info("Found {} running processes", results.size())
    return results
} catch (Exception e) {
    logger.error("DAO query failed: {}", e.message, e)
    return []
}
```

### Query with count for pagination

```groovy
def dao = apiAccessor.getDAO(com.processbuilder.model.PBProcessDAO.class)
def page = 0
def pageSize = 20

def totalCount = dao.countForFindByStatus("Running")
def results = dao.findByStatus("Running", page * pageSize, pageSize)

// Return a map with pagination metadata
return [
    data: results,
    total: totalCount,
    page: page,
    pageSize: pageSize,
    totalPages: Math.ceil(totalCount / pageSize) as int
]
```

### Multi-criteria query

```groovy
def dao = apiAccessor.getDAO(com.processbuilder.model.PBConfigurationDAO.class)

// DAO method name follows BDM convention: findBy{Field1}And{Field2}
def config = dao.findByFullNameAndRefEntityTypeName(
    configKey.toUpperCase(),
    entityTypeName.toUpperCase()
)

if (config == null) {
    logger.warn("Configuration not found: {} / {}", configKey, entityTypeName)
    return defaultValue
}
return config.getConfigValue()
```

---

## Safe Null Handling Patterns

### Groovy safe navigation operator

```groovy
// Safe navigation -- returns null instead of NPE
def userName = user?.getFirstName() ?: "Unknown"
def email = user?.getProfessionalContactData()?.getEmail() ?: ""
```

### Null-safe process variable access

```groovy
def value = execution.getProcessVariableValue("optionalVar")
return value?.toString()?.trim() ?: ""
```

### Null-safe list operations

```groovy
def items = dao.findByStatus("ACTIVE", 0, 100) ?: []
def names = items?.collect { it?.getName() }?.findAll { it != null } ?: []
return names
```

### Optional-style pattern

```groovy
import java.util.Optional

def result = Optional.ofNullable(dao.findByPersistenceId(id))
    .map { it.getStatus() }
    .orElse("NOT_FOUND")
return result
```

---

## Date Manipulation

### Formatting dates

```groovy
import java.time.OffsetDateTime
import java.time.format.DateTimeFormatter

def now = OffsetDateTime.now()

// ISO 8601 format (default for BDM OffsetDateTime fields)
def isoString = now.format(DateTimeFormatter.ISO_OFFSET_DATE_TIME)

// Custom format
def formatted = now.format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"))

// Date only
def dateOnly = now.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"))
```

### Parsing dates

```groovy
import java.time.OffsetDateTime
import java.time.LocalDate
import java.time.format.DateTimeFormatter

// Parse ISO string
def parsed = OffsetDateTime.parse("2025-06-15T10:30:00+02:00")

// Parse custom format
def date = LocalDate.parse("15/06/2025",
    DateTimeFormatter.ofPattern("dd/MM/yyyy"))
```

### Calculating duration

```groovy
import java.time.OffsetDateTime
import java.time.Duration
import java.time.temporal.ChronoUnit

def startDate = OffsetDateTime.parse(startDateString)
def endDate = OffsetDateTime.now()

def duration = Duration.between(startDate, endDate)
def hours = duration.toHours()
def days = ChronoUnit.DAYS.between(startDate, endDate)

logger.info("Process duration: {} days, {} hours", days, hours % 24)
```

---

## JSON Parsing and Building

### Parse JSON with JsonSlurper

```groovy
import groovy.json.JsonSlurper

def jsonText = '{"name": "John", "age": 30, "roles": ["admin", "user"]}'
def parsed = new JsonSlurper().parseText(jsonText)

def name = parsed.name         // "John"
def firstRole = parsed.roles[0] // "admin"
```

### Parse JSON from a process variable

```groovy
import groovy.json.JsonSlurper

def jsonInput = execution.getProcessVariableValue("configJson")
if (jsonInput != null && !jsonInput.toString().trim().isEmpty()) {
    def config = new JsonSlurper().parseText(jsonInput.toString())
    return config.settingValue ?: "default"
}
return "default"
```

### Build JSON with JsonBuilder

```groovy
import groovy.json.JsonBuilder

def builder = new JsonBuilder()
builder {
    processId processInstanceId
    status "RUNNING"
    metadata {
        createdAt new Date().format("yyyy-MM-dd'T'HH:mm:ss")
        initiator userName
    }
    tags(["production", "critical"])
}

return builder.toString()
// {"processId":12345,"status":"RUNNING","metadata":{...},"tags":["production","critical"]}
```

### Build JSON from a list of objects

```groovy
import groovy.json.JsonBuilder

def processes = dao.findByStatus("RUNNING", 0, 50)

def jsonList = processes.collect { p ->
    [
        id: p.getPersistenceId(),
        name: p.getName(),
        status: p.getStatus(),
        createdAt: p.getCreationDate()?.toString()
    ]
}

return new JsonBuilder(jsonList).toString()
```

---

## List and Map Operations

### collect (transform)

```groovy
def users = identityAPI.getUsers(0, 100,
    org.bonitasoft.engine.identity.UserCriterion.FIRST_NAME_ASC)
def userNames = users.collect { "${it.getFirstName()} ${it.getLastName()}" }
```

### findAll (filter)

```groovy
def allProcesses = dao.findAll(0, 200)
def activeProcesses = allProcesses.findAll { it.getStatus() == "Running" }
def criticalActive = activeProcesses.findAll { it.getCriticality() == "High" }
```

### find (first match)

```groovy
def targetProcess = processes.find { it.getName() == targetName }
if (targetProcess == null) {
    logger.warn("Process '{}' not found", targetName)
}
```

### groupBy

```groovy
def processes = dao.findAll(0, 500)
def byStatus = processes.groupBy { it.getStatus() }
// Result: [Running: [...], Draft: [...], Stopped: [...]]

byStatus.each { status, list ->
    logger.info("Status '{}': {} processes", status, list.size())
}
```

### sort and unique

```groovy
def names = items.collect { it.getName() }
    .findAll { it != null }
    .unique()
    .sort()
```

### inject (reduce/fold)

```groovy
def total = items.inject(0) { sum, item -> sum + item.getQuantity() }
```

---

## String Operations

### Template strings (GStrings)

```groovy
def name = "John"
def message = "Hello ${name}, your process ID is ${processInstanceId}"

// Multi-line with triple quotes
def emailBody = """
Dear ${user.getFirstName()},

Your request #${requestId} has been ${status}.

Best regards,
The Process Team
"""
```

### Regex matching

```groovy
// Check if string matches a pattern
def isValidEmail = email ==~ /^[\w.+\-]+@[\w.\-]+\.\w{2,}$/

// Extract groups
def matcher = ("REQ-2025-001" =~ /^(\w+)-(\d{4})-(\d+)$/)
if (matcher.matches()) {
    def prefix = matcher[0][1]  // "REQ"
    def year = matcher[0][2]    // "2025"
    def number = matcher[0][3]  // "001"
}
```

### String padding and formatting

```groovy
// Pad a number for display
def formatted = String.format("REQ-%04d", sequenceNumber) // "REQ-0042"

// Left/right pad
def padded = "Hello".padLeft(10)  // "     Hello"
def padded2 = "42".padLeft(5, '0') // "00042"
```

---

## Calling REST APIs from Scripts

### GET request

```groovy
import groovy.json.JsonSlurper
import org.slf4j.LoggerFactory

def logger = LoggerFactory.getLogger("org.bonitasoft.groovy.script.restCall")

try {
    def url = new URL("https://api.example.com/data/${resourceId}")
    def connection = (java.net.HttpURLConnection) url.openConnection()
    connection.setRequestMethod("GET")
    connection.setRequestProperty("Accept", "application/json")
    connection.setConnectTimeout(5000)
    connection.setReadTimeout(10000)

    def responseCode = connection.getResponseCode()
    if (responseCode == 200) {
        def response = new JsonSlurper().parseText(connection.inputStream.text)
        logger.info("REST call successful: {}", response)
        return response
    } else {
        logger.error("REST call failed with status {}", responseCode)
        throw new RuntimeException("REST API returned ${responseCode}")
    }
} catch (Exception e) {
    logger.error("REST call error: {}", e.message, e)
    throw e
} finally {
    connection?.disconnect()
}
```

### POST request with JSON body

```groovy
import groovy.json.JsonBuilder
import groovy.json.JsonSlurper
import org.slf4j.LoggerFactory

def logger = LoggerFactory.getLogger("org.bonitasoft.groovy.script.restPost")

try {
    def payload = new JsonBuilder([
        name: processName,
        status: "active",
        owner: userId
    ]).toString()

    def url = new URL("https://api.example.com/resources")
    def connection = (java.net.HttpURLConnection) url.openConnection()
    connection.setRequestMethod("POST")
    connection.setRequestProperty("Content-Type", "application/json")
    connection.setRequestProperty("Accept", "application/json")
    connection.setDoOutput(true)
    connection.setConnectTimeout(5000)
    connection.setReadTimeout(10000)

    connection.outputStream.withWriter("UTF-8") { it.write(payload) }

    def responseCode = connection.getResponseCode()
    if (responseCode >= 200 && responseCode < 300) {
        def response = new JsonSlurper().parseText(connection.inputStream.text)
        logger.info("POST successful, ID: {}", response.id)
        return response
    } else {
        def errorBody = connection.errorStream?.text ?: "No error body"
        logger.error("POST failed ({}): {}", responseCode, errorBody)
        throw new RuntimeException("REST POST failed: ${responseCode}")
    }
} catch (Exception e) {
    logger.error("REST POST error: {}", e.message, e)
    throw e
}
```

---

## Sending Emails Programmatically

Use Bonita's email connector for production. For script-level email (rare cases):

```groovy
import org.slf4j.LoggerFactory

def logger = LoggerFactory.getLogger("org.bonitasoft.groovy.script.sendEmail")

// Prefer using Bonita's SMTP connector instead of direct email from scripts.
// This pattern is for edge cases only.

try {
    def props = new Properties()
    props.put("mail.smtp.host", smtpHost)
    props.put("mail.smtp.port", smtpPort)
    props.put("mail.smtp.auth", "true")
    props.put("mail.smtp.starttls.enable", "true")

    def session = javax.mail.Session.getInstance(props,
        new javax.mail.Authenticator() {
            protected javax.mail.PasswordAuthentication getPasswordAuthentication() {
                return new javax.mail.PasswordAuthentication(smtpUser, smtpPassword)
            }
        })

    def message = new javax.mail.internet.MimeMessage(session)
    message.setFrom(new javax.mail.internet.InternetAddress(fromAddress))
    message.setRecipients(javax.mail.Message.RecipientType.TO,
        javax.mail.internet.InternetAddress.parse(toAddress))
    message.setSubject(subject)
    message.setText(body)

    javax.mail.Transport.send(message)
    logger.info("Email sent to {}", toAddress)
} catch (Exception e) {
    logger.error("Failed to send email to {}: {}", toAddress, e.message, e)
    throw e
}
```

---

## Working with Process Variables

### Get a process variable

```groovy
def myVar = execution.getProcessVariableValue("businessVariable")
```

### Check if a variable exists and has value

```groovy
def value = execution.getProcessVariableValue("optionalVar")
def hasValue = value != null && value.toString().trim() != ""
```

### Access contract inputs (available directly as variables)

```groovy
// If the contract defines: taskInput (String), taskAmount (Double)
// They are available directly:
logger.info("Input: {}, Amount: {}", taskInput, taskAmount)

// For complex contract inputs (maps/lists)
def items = taskInputItems  // List<Map> from contract
items.each { item ->
    logger.info("Item: {} - Qty: {}", item.name, item.quantity)
}
```

---

## Working with Documents

### Attach a document to a process

```groovy
import org.bonitasoft.engine.bpm.document.DocumentValue

def processAPI = apiAccessor.getProcessAPI()

try {
    def docValue = new DocumentValue(
        fileContent,           // byte[] content
        "application/pdf",     // MIME type
        "report.pdf"           // file name
    )

    processAPI.attachDocument(
        processInstanceId,
        "myDocument",          // document variable name
        "Report document",     // description
        docValue
    )
    logger.info("Document 'report.pdf' attached to process {}", processInstanceId)
} catch (Exception e) {
    logger.error("Failed to attach document: {}", e.message, e)
    throw e
}
```

### Retrieve a document

```groovy
def processAPI = apiAccessor.getProcessAPI()

try {
    def document = processAPI.getLastDocument(processInstanceId, "myDocument")
    def content = processAPI.getDocumentContent(document.getContentStorageId())

    logger.info("Retrieved document: {} ({} bytes)",
        document.getContentFileName(), content.length)
    return [
        fileName: document.getContentFileName(),
        mimeType: document.getContentMimeType(),
        content: content
    ]
} catch (Exception e) {
    logger.error("Failed to retrieve document: {}", e.message, e)
    throw e
}
```

---

## Gateway Condition Examples

### Exclusive gateway (XOR) -- exactly one path

```groovy
// Condition on "Approved" path
return status == "APPROVED"
```

```groovy
// Condition on "Rejected" path
return status == "REJECTED"
```

```groovy
// Condition with threshold
return amount != null && amount > 10000
```

### Inclusive gateway (OR) -- one or more paths

```groovy
// Path: "Needs Manager Approval"
return amount > 5000

// Path: "Needs Finance Review"
return department == "FINANCE" || amount > 20000

// Path: "Standard Processing" (default path -- no condition needed)
```

### Complex condition with multiple checks

```groovy
import com.bonitasoft.processbuilder.enums.CriticalityType

// Route to escalation path if high criticality and overdue
def isHighCriticality = criticality == CriticalityType.HIGH.getKey()
def isOverdue = dueDate != null && java.time.OffsetDateTime.now().isAfter(dueDate)
return isHighCriticality && isOverdue
```

---

## Actor Filter Scripts

Actor filters determine which users can perform a task. They must be fast and simple.

```groovy
// Filter: users with a specific role in a specific group
import com.bonitasoft.processbuilder.extension.MembershipUtils

def identityAPI = apiAccessor.getIdentityAPI()

try {
    def role = identityAPI.getRoleByName("manager")
    def group = identityAPI.getGroupByPath("/acme/hr")

    def memberships = identityAPI.getUserMemberships(0, 200,
        org.bonitasoft.engine.identity.UserMembershipCriterion.GROUP_NAME_ASC)

    def eligibleUserIds = memberships
        .findAll { it.getRoleId() == role.getId() && it.getGroupId() == group.getId() }
        .collect { it.getUserId() }
        .unique()

    logger.info("Found {} eligible users for manager/hr filter", eligibleUserIds.size())
    return eligibleUserIds
} catch (Exception e) {
    logger.error("Actor filter failed: {}", e.message, e)
    return []
}
```

---

## Connector Input/Output Mapping Scripts

### REST connector input mapping

```groovy
import groovy.json.JsonBuilder

// Build the request body for a REST connector
def body = new JsonBuilder([
    processId: processInstanceId,
    action: actionType,
    data: [
        name: objectName,
        status: objectStatus
    ]
]).toString()

return body
```

### REST connector output mapping

```groovy
import groovy.json.JsonSlurper

// Parse the connector response and extract relevant data
def response = new JsonSlurper().parseText(bodyAsString)
def resultId = response?.data?.id
def resultStatus = response?.data?.status

if (resultId == null) {
    logger.warn("REST connector returned no ID in response")
}
return resultId?.toString() ?: ""
```

### Email connector recipient mapping

```groovy
import com.bonitasoft.processbuilder.enums.RecipientsType

// Build recipient list from process data
def recipients = []

if (notifyManager && managerEmail) {
    recipients.add(managerEmail)
}
if (notifyInitiator && initiatorEmail) {
    recipients.add(initiatorEmail)
}

return recipients.join(",")
```

---

## Using Extension Library Enums (Quick Reference)

```groovy
import com.bonitasoft.processbuilder.enums.ProcessStateType
import com.bonitasoft.processbuilder.enums.ActionType
import com.bonitasoft.processbuilder.enums.CriticalityType
import com.bonitasoft.processbuilder.enums.ProcessStorageType

// Get a key value for BDM field assignment
myObject.setStatus(ProcessStateType.RUNNING.getKey())       // "Running"
myObject.setCriticality(CriticalityType.MODERATE.getKey())   // "Moderate"

// Validate an input string against the enum
if (!ProcessStateType.isValid(statusInput)) {
    throw new IllegalArgumentException("Invalid status: '${statusInput}'")
}

// Check action type validity with persistence ID
def action = ActionType.valueOf(actionInput.toUpperCase())
if (!action.isValid(persistenceId)) {
    throw new IllegalArgumentException(
        "${action.getKey()} requires ${action == ActionType.INSERT ? 'empty' : 'numeric'} ID")
}

// Get all values for validation or UI dropdowns
def allStates = ProcessStateType.getAllKeysList()
// ["Draft", "Running", "Stopped", "Archived", "Healthy", "In Error"]

def stateMap = ProcessStateType.getAllData()
// {Draft: "Definition is under construction.", Running: "Process is enabled...", ...}
```
