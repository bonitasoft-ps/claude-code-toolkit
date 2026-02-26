# {Controller Display Name} API

{Brief one-line description of what this endpoint does.}

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

## Overview

{2-3 sentences describing what this controller does, who uses it, and the primary use case.}

**Key Features:**
- {Feature 1: e.g., Profile-based access control}
- {Feature 2: e.g., Filtering and ordering support}
- {Feature 3: e.g., Full pagination support}

---

## Architecture

```
┌──────────────┐     ┌──────────────────────┐     ┌────────────────┐
│  UI Builder  │────>│ {ControllerName}     │────>│  {BDM Entity}  │
│  (Frontend)  │     │    Controller        │     │    (BDM)       │
└──────────────┘     └──────────────────────┘     └────────────────┘
                              │
                              ├──>  {ServiceA} ({purpose})
                              ├──>  {ServiceB} ({purpose})
                              └──>  {Mapper} (entity -> DTO)
```

---

## Endpoint

### URL

```
{GET|POST|PUT|DELETE} http://localhost:8080/bonita/API/extension/{endpoint}
```

### HTTP Method
`{GET|POST|PUT|DELETE}`

### Content-Type
- Request: `{application/json | N/A for GET}`
- Response: `application/json`

---

## Request Parameters

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `p` | Integer | **Yes** | Page index (0-based) | `p=0` |
| `c` | Integer | **Yes** | Items per page | `c=10` |
| `f` | String | No | Filter: `f={field}={value}` | `f=name=Sales` |
| `o` | String | No | Order: `o={field} {ASC\|DESC}` | `o=name ASC` |

### Supported Filter Fields

| Filter Key | Description | Example |
|------------|-------------|---------|
| `{field1}` | {Description of what this filter does} | `f={field1}={value}` |
| `{field2}` | {Description of what this filter does} | `f={field2}={value}` |

### Supported Order Fields

| Order Field | Description | Example |
|-------------|-------------|---------|
| `{field1}` | {Description} | `o={field1} ASC` |
| `{field2}` | {Description} | `o={field2} DESC` |

**Order Direction:** `ASC` (ascending) or `DESC` (descending)

---

## Response Format

### Success Response (200 OK)

```json
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
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `p` | Integer | Current page index |
| `c` | Integer | Page size |
| `total` | Long | Total matching records across all pages |
| `data` | Array | List of entity objects for current page |
| `data[].persistenceId` | Long | Unique BDM persistence identifier |
| `data[].name` | String | {Description} |
| `data[].status` | String | {Description: possible values} |
| `data[].createdAt` | DateTime | Creation timestamp (ISO-8601) |

---

## Use Cases and Examples

### Use Case 1: {Basic Data Retrieval}

**Scenario:** {Description of the scenario, e.g., "Load the first page of entities for the dashboard."}

**JavaScript (fetch):**

```javascript
async function loadEntities(page = 0, pageSize = 20) {
  try {
    const response = await fetch(
      `/API/extension/{endpoint}?p=${page}&c=${pageSize}`,
      {
        method: 'GET',
        headers: { 'Accept': 'application/json' }
      }
    );

    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }

    const result = await response.json();
    console.log(`Total entities: ${result.total}`);
    return result;
  } catch (error) {
    console.error('Error loading entities:', error);
    throw error;
  }
}

// Usage
loadEntities();
```

**curl:**

```bash
curl -X GET "http://localhost:8080/bonita/API/extension/{endpoint}?p=0&c=10" \
  -H "Accept: application/json" \
  -b cookies.txt
```

### Use Case 2: {Filtered Search}

**Scenario:** {Description, e.g., "Search entities by name."}

**JavaScript:**

```javascript
async function searchEntities(searchTerm) {
  const response = await fetch(
    `/API/extension/{endpoint}?p=0&c=50&f=name=${encodeURIComponent(searchTerm)}`,
    {
      method: 'GET',
      headers: { 'Accept': 'application/json' }
    }
  );

  const result = await response.json();
  console.log(`Found ${result.total} matching entities`);
  return result.data;
}

// Usage
searchEntities('Sales');
```

**curl:**

```bash
curl -X GET "http://localhost:8080/bonita/API/extension/{endpoint}?p=0&c=50&f=name=Sales" \
  -H "Accept: application/json" \
  -b cookies.txt
```

### Use Case 3: {Sorted Results}

**Scenario:** {Description, e.g., "Display most recently modified entities first."}

**JavaScript:**

```javascript
async function loadRecentEntities() {
  const response = await fetch(
    '/API/extension/{endpoint}?p=0&c=10&o=modificationDate DESC',
    {
      method: 'GET',
      headers: { 'Accept': 'application/json' }
    }
  );

  const result = await response.json();

  result.data.forEach((entity, index) => {
    console.log(`${index + 1}. ${entity.name} - ${entity.createdAt}`);
  });

  return result;
}
```

**curl:**

```bash
curl -X GET "http://localhost:8080/bonita/API/extension/{endpoint}?p=0&c=10&o=modificationDate DESC" \
  -H "Accept: application/json" \
  -b cookies.txt
```

---

## Business Logic Details

### Execution Flow

1. **License Validation:** Check Bonita license via `LicenseValidator`
2. **Parameter Validation:** Parse and validate `p`, `c`, optional filters/ordering
3. **{Step 3}:** {Describe what happens, e.g., "Get user context and permissions"}
4. **{Step 4}:** {Describe what happens, e.g., "Execute BDM query with filters"}
5. **{Step 5}:** {Describe what happens, e.g., "Map entities to DTOs"}
6. **Response Building:** Construct paginated response with metadata

### {Business Rule / Decision Logic Name}

{Detailed description of the core business rule or algorithm.}

```java
// Key code snippet showing the decision logic
if (conditionA) {
    // Branch A: description
} else if (conditionB) {
    // Branch B: description
} else {
    // Default: description
}
```

### Query Strategy

| Condition | Query Method | Description |
|-----------|-------------|-------------|
| {Condition A} | `dao.findMethodA()` | {When and why this query is used} |
| {Condition B} | `dao.findMethodB()` | {When and why this query is used} |

---

## Error Handling

### HTTP Status Codes

| Code | Description | When |
|------|-------------|------|
| 200 | Success | Valid request, data returned |
| 400 | Bad Request | Missing or invalid parameters |
| 403 | Forbidden | License validation failed |
| 500 | Internal Server Error | Unhandled exception during execution |

### Error Response Format

```json
{
  "message": "Human-readable error description"
}
```

### Error Examples

| Request | Status | Error Message |
|---------|--------|---------------|
| `?c=10` (missing `p`) | 400 | "The required parameter 'p' is missing." |
| `?p=abc&c=10` (invalid type) | 400 | "Parameter 'p' must be a valid integer." |
| `?p=0&c=10&f=invalid=x` | 400 | "Invalid filter field: invalid" |
| `?p=0&c=10&o=name INVALID` | 400 | "Invalid order direction. Use ASC or DESC." |
| (internal error) | 500 | "An internal server error occurred." |
| (license expired) | 403 | "License validation failed." |

---

## Key Classes

| Class | Location | Responsibility |
|-------|----------|---------------|
| **{ControllerName}.java** | `controller/{name}/` | Concrete controller with business logic |
| **Abstract{ControllerName}.java** | `controller/{name}/` | Base controller: validation, error handling, OpenAPI |
| **{ControllerName}Field.java** | `controller/{name}/` | Filter/order field constants |
| **Param{ControllerName}** | `dto/parameter/` | Request parameters DTO (@Value) |
| **Result{ControllerName}** | `dto/result/` | Response result DTO (@Value + @Builder) |
| **{Entity}DTO** | `dto/objects/` | Entity representation DTO |

---

## Dependencies

### Internal Utilities

| Component | Purpose |
|-----------|---------|
| `LicenseValidator` | License validation in doHandle() |
| `QueryParamValidator` | Parameter parsing and validation |
| `Utils` | JSON response building (jsonResponse, pagedJsonResponse) |
| `ErrorMessages` | Standardized error message constants |
| `Parameters` | Parameter name constants (PARAM_INPUT_P, PARAM_INPUT_C, etc.) |

### BDM / Data Access

| DAO | Entity | Queries Used |
|-----|--------|-------------|
| `{Entity}DAO` | `{Entity}` | `findByX()`, `countForFindByX()` |

### Bonita APIs (if used)

| API | Purpose |
|-----|---------|
| `ProfileAPI` | {e.g., Check user profiles for access control} |
| `IdentityAPI` | {e.g., Get user memberships for permission checks} |

---

## Testing

### Test Classes

| Test Class | Type | What It Tests |
|-----------|------|---------------|
| `Abstract{ControllerName}Test` | Unit | doHandle flow: 200 OK, 400 validation, 500 errors, pagination |
| `{ControllerName}Test` | Unit | execute() business logic, DAO interactions, mapping |
| `Param{ControllerName}Test` | Unit | Parameter DTO construction, immutability, equals/hashCode |
| `Result{ControllerName}Test` | Unit | Result DTO builder, serialization, deserialization |

### Manual Testing with curl

```bash
# Basic request
curl -X GET "http://localhost:8080/bonita/API/extension/{endpoint}?p=0&c=10" \
  -H "Accept: application/json" \
  -b cookies.txt

# With name filter
curl -X GET "http://localhost:8080/bonita/API/extension/{endpoint}?p=0&c=10&f=name=Sales" \
  -H "Accept: application/json" \
  -b cookies.txt

# With ordering
curl -X GET "http://localhost:8080/bonita/API/extension/{endpoint}?p=0&c=10&o=modificationDate DESC" \
  -H "Accept: application/json" \
  -b cookies.txt
```

---

## Files in This Package

| File | Description |
|------|-------------|
| `{ControllerName}.java` | Concrete controller implementation |
| `Abstract{ControllerName}.java` | Abstract base controller |
| `{ControllerName}Field.java` | Filter/order field constants |
| `README.md` | This documentation |
