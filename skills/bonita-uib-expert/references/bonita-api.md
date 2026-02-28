# Bonita API Reference and Task Execution

> Bonita Version: 2024.3+

## Bonita API Endpoints

### BPM API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/bonita/API/bpm/userTask?p={p}&c={c}` | GET | List user tasks |
| `/bonita/API/bpm/userTask/{taskId}` | GET | Get task by ID |
| `/bonita/API/bpm/userTask/{taskId}/execution?assign=true` | POST | Execute task **(CRITICAL: ?assign=true)** |
| `/bonita/API/bpm/userTask/{taskId}/contract` | GET | Get task contract |
| `/bonita/API/bpm/process?p={p}&c={c}` | GET | List processes |
| `/bonita/API/bpm/process/{processId}/instantiation` | POST | Start a new case |
| `/bonita/API/bpm/process/{processId}/contract` | GET | Get process contract |
| `/bonita/API/bpm/case?p={p}&c={c}` | GET | List cases |
| `/bonita/API/bpm/case/{caseId}` | GET | Get case by ID |
| `/bonita/API/bpm/archivedCase?p={p}&c={c}` | GET | List archived cases |
| `/bonita/API/bpm/humanTask?p={p}&c={c}` | GET | List human tasks |
| `/bonita/API/bpm/activity?p={p}&c={c}` | GET | List activities |
| `/bonita/API/bpm/flowNode?p={p}&c={c}` | GET | List flow nodes |

### BDM API (Business Data Model)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/bonita/API/bdm/businessData/{qualifiedName}?p={p}&c={c}` | GET | List business objects |
| `/bonita/API/bdm/businessData/{qualifiedName}/{persistenceId}` | GET | Get by ID |

### Identity API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/bonita/API/identity/user/{userId}` | GET | Get user by ID |
| `/bonita/API/identity/user?p={p}&c={c}` | GET | List users |
| `/bonita/API/identity/membership?p={p}&c={c}` | GET | List memberships |

### System API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/bonita/API/system/session/unusedId` | GET | Current session info |

### REST API Extensions

```
GET /bonita/API/extension/{extensionName}?param1=value1
```

Custom endpoints deployed separately on the Bonita server.

## Task Execution Rules (CRITICAL)

### 1. Always Use ?assign=true

**ALWAYS** append `?assign=true` when executing user tasks:

```
POST /bonita/API/bpm/userTask/{taskId}/execution?assign=true
```

Without `?assign=true`:
- Task not assigned to current user → execution **fails silently** or returns 403
- `?assign=true` auto-assigns and executes in one call

### 2. Contract Fields — Include ALL Fields (CRITICAL)

The task contract requires **ALL fields** in the payload. Send `null` for unused fields:

```json
{
  "nameInput": "John Doe",
  "amountInput": 1500.00,
  "commentInput": null,
  "approvedInput": null,
  "documentsInput": null
}
```

**Missing a field** = contract violation error.

### 3. String Values Must Use Correct Case

Enum/status values must use the **exact case** defined in the process:

```json
{
  "statusInput": "APPROVED",
  "priorityInput": "HIGH"
}
```

### 4. Task Execution in JSObject

```javascript
executeTask: function() {
  var self = this;
  self.isSubmitting.value = true;
  try {
    var taskId = appsmith.URL.queryParams.id;
    executeUserTask.run({
      taskId: taskId,
      field1: self.formData.field1,
      field2: self.formData.field2,
      amount: self.formData.amount,
      comment: self.formData.comment || null,
      approved: self.formData.approved || null
    });
    showAlert('Task completed successfully', 'success');
    navigateTo('Home', {}, 'SAME_WINDOW');
  } catch(e) {
    showAlert('Error executing task: ' + e.message, 'error');
  } finally {
    self.isSubmitting.value = false;
  }
}
```

### 5. Looping Tasks (Multi-instance)

After executing one iteration, a new task with a new ID is created. Re-query:

```javascript
executeLoopingTask: function() {
  var self = this;
  try {
    var taskId = appsmith.URL.queryParams.id;
    executeUserTask.run({ taskId: taskId, dataInput: self.formData.data });
    var nextTask = getNextTask.run({ caseId: self.caseId });
    if (nextTask && nextTask.length > 0) {
      navigateTo('TaskForm', { id: nextTask[0].id }, 'SAME_WINDOW');
    } else {
      navigateTo('Home', {}, 'SAME_WINDOW');
    }
  } catch(e) {
    showAlert('Error: ' + e.message, 'error');
  }
}
```

## Process Instantiation

```
POST /bonita/API/bpm/process/{processId}/instantiation
```

Body must include ALL contract fields. Same rules as task execution.

## Pagination Pattern

Bonita API uses `p` (page, 0-based) and `c` (count):

```
/bonita/API/bpm/userTask?p=0&c=10&f=state=ready
```

### Getting Total Count

Use `c=0` and read the `Content-Range` response header:

```
GET /bonita/API/bpm/userTask?p=0&c=0&f=state=ready
Response header: Content-Range: 0-0/42  → total = 42
```

## Filtering and Sorting

### Filter Syntax

```
f=fieldName=value              # Exact match
f=fieldName=value1,value2      # Multiple values (OR)
```

Multiple filters (AND):
```
?f=state=ready&f=assigned_id=123
```

### Sort Syntax

```
o=fieldName ASC
o=fieldName DESC
```

## File Upload

### File Upload Query

```
POST /bonita/API/formFileUpload
Headers:
  Content-Type: application/octet-stream
  Content-Disposition: form-data; name="file"; filename="myfile.pdf"
```

### File Upload in JSObject

```javascript
uploadDocument: function(fileData) {
  var self = this;
  try {
    var base64 = fileData.base64;
    var fileName = fileData.name;
    uploadFile.run({ fileName: fileName, fileContent: base64 });
    showAlert('File uploaded', 'success');
  } catch(e) {
    showAlert('Upload error: ' + e.message, 'error');
  }
}
```

## Query Execution

> See `js-environment.md` → "Run Queries" for query execution syntax from JSObjects (`.run()`, parameters, sequential calls).

## Anti-patterns

- Forgetting `?assign=true` on task execution
- Missing contract fields in POST body (contract violation error)
- Using wrong case for enum values (e.g., `approved` instead of `APPROVED`)
- Setting `executeOnLoad: true` on POST/PUT/DELETE queries
- Using browser `fetch()` instead of Bonita queries
- Hardcoding Bonita URLs instead of using datasource configuration
- Not handling pagination (only getting first page of results)
- Forgetting Content-Type header on POST requests
