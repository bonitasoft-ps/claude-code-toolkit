# README Template for REST API Controllers

This reference provides the complete README.md template with all 11 required sections, followed by a filled-in example.

---

## Template Structure (All 11 Sections)

```markdown
# {Controller Display Name} API

{Brief one-line description of the endpoint.}

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Endpoint](#endpoint)
4. [Request Parameters](#request-parameters)
5. [Response Format](#response-format)
6. [Use Cases and Examples](#use-cases-and-examples)
7. [Business Logic Details](#business-logic-details)
8. [Error Handling](#error-handling)
9. [Key Classes](#key-classes)
10. [Dependencies](#dependencies)
11. [Testing](#testing)

---

## 1. Overview

{2-3 sentences describing what this controller does, who uses it, and the primary use case.}

**Key Features:**
- {Feature 1}
- {Feature 2}
- {Feature 3}

---

## 2. Architecture

{ASCII diagram showing the data flow from frontend to BDM.}

\```
+---------------+     +----------------------+     +----------------+
|  UI Builder   |---->| {ControllerName}     |---->|  {BDM Entity}  |
|  (Frontend)   |     |    Controller        |     |    (BDM)       |
+---------------+     +----------------------+     +----------------+
                              |
                              +-->  {ServiceA} (description)
                              +-->  {ServiceB} (description)
                              +-->  {Mapper} (entity -> DTO)
\```

---

## 3. Endpoint

### URL
\```
{METHOD} http://localhost:8080/bonita/API/extension/{endpoint}
\```

### HTTP Method
`{GET|POST|PUT|DELETE}`

### Content-Type
- Request: `{application/json | N/A}`
- Response: `application/json`

---

## 4. Request Parameters

### Query Parameters

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `p` | Integer | **Yes** | Page index (0-based) | `p=0` |
| `c` | Integer | **Yes** | Items per page | `c=10` |
| `f` | String | No | Filter: `f={field}={value}` | `f=name=Sales` |
| `o` | String | No | Order: `o={field} {ASC\|DESC}` | `o=name ASC` |

### Supported Filter Fields

| Filter Key | Description | Example |
|------------|-------------|---------|
| `{field1}` | {Description} | `f={field1}={value}` |
| `{field2}` | {Description} | `f={field2}={value}` |

### Supported Order Fields

| Order Field | Description | Example |
|-------------|-------------|---------|
| `{field1}` | {Description} | `o={field1} ASC` |
| `{field2}` | {Description} | `o={field2} DESC` |

---

## 5. Response Format

### Success Response (200 OK)

\```json
{
  "p": 0,
  "c": 10,
  "total": 42,
  "data": [
    {
      "persistenceId": 1001,
      "name": "Example Entity",
      "status": "ACTIVE",
      "createdAt": "2025-01-15T09:30:00Z"
    }
  ]
}
\```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `p` | Integer | Current page index |
| `c` | Integer | Page size |
| `total` | Long | Total matching records |
| `data` | Array | List of entity objects |
| `data[].persistenceId` | Long | Unique BDM identifier |
| `data[].name` | String | Entity name |
| `data[].status` | String | Current status |
| `data[].createdAt` | DateTime | Creation timestamp (ISO-8601) |

---

## 6. Use Cases and Examples

### Use Case 1: {Basic Data Retrieval}

**Scenario:** {Description of the scenario.}

**JavaScript (fetch):**

\```javascript
async function loadEntities(page = 0, pageSize = 20) {
  const response = await fetch(
    `/API/extension/{endpoint}?p=${page}&c=${pageSize}`,
    { method: 'GET', headers: { 'Accept': 'application/json' } }
  );
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.json();
}
\```

**curl:**

\```bash
curl -X GET "http://localhost:8080/bonita/API/extension/{endpoint}?p=0&c=10" \
  -H "Accept: application/json" \
  -b cookies.txt
\```

### Use Case 2: {Filtered Search}

**Scenario:** {Description of the filtering scenario.}

**JavaScript:**

\```javascript
async function searchEntities(searchTerm) {
  const response = await fetch(
    `/API/extension/{endpoint}?p=0&c=50&f=name=${encodeURIComponent(searchTerm)}`,
    { method: 'GET', headers: { 'Accept': 'application/json' } }
  );
  const result = await response.json();
  console.log(`Found ${result.total} matching entities`);
  return result.data;
}
\```

**curl:**

\```bash
curl -X GET "http://localhost:8080/bonita/API/extension/{endpoint}?p=0&c=50&f=name=Sales" \
  -H "Accept: application/json" \
  -b cookies.txt
\```

### Use Case 3: {Sorted Results}

**Scenario:** {Description of the sorting scenario.}

**JavaScript:**

\```javascript
async function loadSortedEntities(sortField, direction) {
  const response = await fetch(
    `/API/extension/{endpoint}?p=0&c=10&o=${sortField} ${direction}`,
    { method: 'GET', headers: { 'Accept': 'application/json' } }
  );
  return response.json();
}

// Usage: most recently modified first
loadSortedEntities('modificationDate', 'DESC');
\```

**curl:**

\```bash
curl -X GET "http://localhost:8080/bonita/API/extension/{endpoint}?p=0&c=10&o=modificationDate DESC" \
  -H "Accept: application/json" \
  -b cookies.txt
\```

---

## 7. Business Logic Details

### Execution Flow

1. **License Validation:** Check Bonita license via `LicenseValidator`
2. **Parameter Validation:** Parse and validate `p`, `c`, optional filters and ordering
3. **{Step 3}:** {Description of business logic step}
4. **{Step 4}:** {Description of business logic step}
5. **Response Building:** Map entities to DTOs and construct paginated response

### {Business Rule Name}

{Detailed description of the core business rule or algorithm.}

\```java
// Pseudocode or key code snippet
if (condition) {
    // Branch A logic
} else {
    // Branch B logic
}
\```

### Query Strategy

| Condition | Query Used | Description |
|-----------|-----------|-------------|
| {Condition A} | `dao.findMethodA()` | {Description} |
| {Condition B} | `dao.findMethodB()` | {Description} |

---

## 8. Error Handling

### HTTP Status Codes

| Code | Description | When |
|------|-------------|------|
| 200 | Success | Valid request, data returned |
| 400 | Bad Request | Missing/invalid parameters |
| 403 | Forbidden | License validation failed |
| 500 | Internal Server Error | Unhandled exception in execute() |

### Error Response Format

\```json
{
  "message": "Human-readable error description"
}
\```

### Error Examples

| Request | Status | Error Message |
|---------|--------|---------------|
| `?c=10` (missing `p`) | 400 | "The required parameter 'p' is missing." |
| `?p=abc&c=10` | 400 | "Parameter 'p' must be a valid integer." |
| `?p=0&c=10&f=invalid=x` | 400 | "Invalid filter field: invalid" |
| `?p=0&c=10&o=name INVALID` | 400 | "Invalid order direction. Use ASC or DESC." |
| (database error) | 500 | "An internal server error occurred." |

---

## 9. Key Classes

| Class | Location | Responsibility |
|-------|----------|---------------|
| **{ControllerName}.java** | `controller/{name}/` | Concrete controller with business logic |
| **Abstract{ControllerName}.java** | `controller/{name}/` | Base controller (validation, error handling) |
| **Param{ControllerName}** | `dto/parameter/` | Request parameters DTO |
| **Result{ControllerName}** | `dto/result/` | Response result DTO |
| **{Entity}DTO** | `dto/objects/` | Entity representation DTO |
| **{Name}Field** | `controller/{name}/` | Filter/order field constants |

---

## 10. Dependencies

### Internal Dependencies

| Component | Type | Purpose |
|-----------|------|---------|
| `LicenseValidator` | Utility | License validation |
| `QueryParamValidator` | Utility | Parameter parsing and validation |
| `Utils` | Utility | JSON response building |
| `ErrorMessages` | Constants | Standardized error messages |
| `Parameters` | Constants | Parameter name constants |

### BDM Dependencies

| DAO | BDM Entity | Queries Used |
|-----|-----------|-------------|
| `{Entity}DAO` | `{Entity}` | `findByX()`, `countForFindByX()` |

### Bonita API Dependencies

| API | Purpose |
|-----|---------|
| `ProfileAPI` | {If used: user profile checks} |
| `IdentityAPI` | {If used: user memberships} |
| `ProcessAPI` | {If used: process operations} |

---

## 11. Testing

### Test Classes

| Test Class | Type | Coverage |
|-----------|------|----------|
| `Abstract{ControllerName}Test` | Unit | doHandle flow: 200, 400, 500, pagination |
| `{ControllerName}Test` | Unit | execute() business logic, DAO calls |
| `Param{ControllerName}Test` | Unit | Parameter DTO construction, immutability |
| `Result{ControllerName}Test` | Unit | Result DTO builder, serialization |

### Manual Testing with curl

\```bash
# Basic request
curl -X GET "http://localhost:8080/bonita/API/extension/{endpoint}?p=0&c=10" \
  -H "Accept: application/json" \
  -b cookies.txt

# With filter
curl -X GET "http://localhost:8080/bonita/API/extension/{endpoint}?p=0&c=10&f=name=Sales" \
  -H "Accept: application/json" \
  -b cookies.txt

# With ordering
curl -X GET "http://localhost:8080/bonita/API/extension/{endpoint}?p=0&c=10&o=name ASC" \
  -H "Accept: application/json" \
  -b cookies.txt
\```

---

## Files in This Package

| File | Description |
|------|-------------|
| `{ControllerName}.java` | Concrete controller implementation |
| `Abstract{ControllerName}.java` | Abstract base controller |
| `{ControllerName}Field.java` | Filter/order field constants |
| `README.md` | This documentation |
```

---

## Complete Filled-In Example: Processes Accessible API

Below is a complete, real-world README based on the `processesAccessible` controller:

```markdown
# Processes Accessible API

Retrieve processes that the authenticated user is authorized to launch OR edit.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Endpoint](#endpoint)
4. [Request Parameters](#request-parameters)
5. [Response Format](#response-format)
6. [Use Cases and Examples](#use-cases-and-examples)
7. [Business Logic Details](#business-logic-details)
8. [Error Handling](#error-handling)
9. [Key Classes](#key-classes)
10. [Dependencies](#dependencies)
11. [Testing](#testing)

---

## 1. Overview

The Processes Accessible API returns a paginated list of processes based on the authenticated
user's authorization level. Administrators see all processes, process managers see launchable
and editable processes, and regular users see only launchable processes.

**Key Features:**
- Profile-based access control (PB Administrator, PB Process Manager, PB User)
- Permission calculation (launchable/editable flags per process)
- Filtering by name and description
- Ordering by name or modification date
- Full pagination support

---

## 2. Architecture

\```
+---------------+     +----------------------+     +----------------+
|  UI Builder   |---->| ProcessesAccessible  |---->|   PBProcess    |
|  (Frontend)   |     |    Controller        |     |    (BDM)       |
+---------------+     +----------------------+     +----------------+
                              |
                              +-->  ProfileAPI (check user profile)
                              +-->  IdentityAPI (get memberships)
                              +-->  ProcessMapper (calculate permissions)
\```

---

## 3. Endpoint

### URL
\```
GET http://localhost:8080/bonita/API/extension/processes
\```

### HTTP Method
`GET`

### Content-Type
- Response: `application/json`

---

## 4. Request Parameters

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `p` | Integer | **Yes** | Page index (0-based) | `p=0` |
| `c` | Integer | **Yes** | Items per page | `c=10` |
| `f` | String | No | Filter: `f={field}={value}` | `f=name=Sales` |
| `o` | String | No | Order: `o={field} {ASC|DESC}` | `o=name ASC` |

### Supported Filter Fields

| Filter Key | Description | Example |
|------------|-------------|---------|
| `name` | Process full name (LIKE match) | `f=name=Sales Order` |
| `description` | Process description (LIKE match) | `f=description=employee` |

### Supported Order Fields

| Order Field | Description | Example |
|-------------|-------------|---------|
| `name` | Order by process full name | `o=name ASC` |
| `modificationDate` | Order by last modification date | `o=modificationDate DESC` |

---

## 5. Response Format

### Success Response (200 OK)

\```json
{
  "p": 0,
  "c": 10,
  "total": 15,
  "listPBProcessDTO": [
    {
      "persistenceId": 1001,
      "fullName": "Sales_Order_Process",
      "displayName": "Sales Order Management",
      "description": "Process for managing sales orders",
      "version": "1.0",
      "categoryName": "Sales",
      "status": "RUNNING",
      "creatorName": "john.doe",
      "creationDate": "2025-01-15T09:30:00Z",
      "modificationDate": "2025-01-20T14:45:00Z",
      "launchable": true,
      "editable": true,
      "canEdit": true,
      "canDelete": false
    }
  ]
}
\```

### Permission Flags

| Flag | Description | Granted To |
|------|-------------|-----------|
| `launchable` | User can start new instances | User in involvedUserList with canLaunchProcess=true |
| `editable` | User can modify the process | Process creator OR last modifier |
| `canEdit` | User can edit configuration | Process creator OR PB Admin |
| `canDelete` | User can delete the process | Process creator OR PB Admin |

---

## 6. Use Cases and Examples

### Use Case 1: Dashboard - Load User's Processes

**Scenario:** Display all processes the user can interact with on the main dashboard.

**JavaScript:**
\```javascript
async function loadAccessibleProcesses(page = 0, pageSize = 20) {
  const response = await fetch(
    `/API/extension/processes?p=${page}&c=${pageSize}`,
    { method: 'GET', headers: { 'Accept': 'application/json' } }
  );
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  const result = await response.json();
  const launchable = result.listPBProcessDTO.filter(p => p.launchable);
  const editable = result.listPBProcessDTO.filter(p => p.editable);
  return { total: result.total, launchable, editable };
}
\```

### Use Case 2: Search by Name

**Scenario:** User types a search term to find specific processes.

\```bash
curl -X GET "http://localhost:8080/bonita/API/extension/processes?p=0&c=50&f=name=Sales" \
  -H "Accept: application/json" -b cookies.txt
\```

### Use Case 3: Sort by Recent Modifications

**Scenario:** Show most recently modified processes first.

\```bash
curl -X GET "http://localhost:8080/bonita/API/extension/processes?p=0&c=10&o=modificationDate DESC" \
  -H "Accept: application/json" -b cookies.txt
\```

---

## 7. Business Logic Details

### Access Control by Profile

| Profile | Access Level | Query |
|---------|-------------|-------|
| PB Administrator | ALL processes | `findAllProcesses()` |
| PB Process Manager | Launchable + Editable | `findBySessionUserIdAccessible()` |
| PB User (default) | Launchable only | `findBySessionUserIdMyProcesses()` |

### Execution Flow

1. Extract userId from session
2. Load user profiles via ProfileAPI
3. Load user memberships (groups, roles) via IdentityAPI
4. Select query based on highest profile
5. Execute query with filters and pagination
6. Calculate permissions via ProcessMapper
7. Build paginated response

---

## 8. Error Handling

| Code | When | Example Message |
|------|------|-----------------|
| 200 | Success | (data returned) |
| 400 | Missing `p` | "The required parameter 'p' is missing." |
| 400 | Invalid filter | "Invalid filter field: invalidField" |
| 403 | License expired | "License validation failed." |
| 500 | Database error | "An internal server error occurred." |

---

## 9. Key Classes

| Class | Responsibility |
|-------|---------------|
| **ProcessesAccessible** | Business logic: profile checks, query selection |
| **AbstractProcessesAccessible** | Request lifecycle, validation, error handling |
| **ParamProcessesAccessible** | Request parameters DTO |
| **ResultProcessesAccessible** | Response DTO with pagination |
| **PBProcessDTO** | Process DTO with permission flags |
| **ProcessMapper** | Entity-to-DTO mapping with permission calculation |
| **UserContext** | User memberships and role context |

---

## 10. Dependencies

| Component | Purpose |
|-----------|---------|
| `LicenseValidator` | License validation |
| `QueryParamValidator` | Parameter validation |
| `PBProcessDAO` | BDM data access |
| `ProfileAPI` | User profile retrieval |
| `IdentityAPI` | User membership retrieval |
| `ProcessMapper` | Entity-to-DTO mapping |
| `MembershipUtils` | Membership key generation |

---

## 11. Testing

| Test Class | Coverage |
|-----------|----------|
| `AbstractProcessesAccessibleTest` | doHandle: 200, 400, 500, pagination, filtering |
| `ProcessesAccessibleTest` | execute: admin/manager/user queries, permissions |

### Manual Testing

\```bash
# Basic
curl -X GET "http://localhost:8080/bonita/API/extension/processes?p=0&c=10" \
  -H "Accept: application/json" -b cookies.txt

# Filtered
curl -X GET "http://localhost:8080/bonita/API/extension/processes?p=0&c=10&f=name=Sales" \
  -H "Accept: application/json" -b cookies.txt

# Ordered
curl -X GET "http://localhost:8080/bonita/API/extension/processes?p=0&c=10&o=modificationDate DESC" \
  -H "Accept: application/json" -b cookies.txt
\```

---

## Files in This Package

| File | Description |
|------|-------------|
| `ProcessesAccessible.java` | Concrete controller |
| `AbstractProcessesAccessible.java` | Abstract base controller |
| `README.md` | This documentation |
```
