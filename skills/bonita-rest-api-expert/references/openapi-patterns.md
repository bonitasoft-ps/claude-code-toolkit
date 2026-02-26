# OpenAPI Documentation Patterns

This reference covers OpenAPI/Swagger annotation patterns used in Bonita REST API controllers.

---

## Overview

The project uses **Swagger/OpenAPI 3.0 annotations** (from `io.swagger.v3.oas.annotations`) on the abstract controller's `doHandle()` method to document the REST API. These annotations are processed to generate OpenAPI specification files.

### Required Imports

```java
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;

import javax.ws.rs.GET;    // or POST, PUT, DELETE
import javax.ws.rs.Path;
```

---

## 1. Class-Level Annotations

Apply `@Path` to both the abstract and concrete classes:

```java
@Path("/myResource")
public abstract class AbstractMyController implements RestApiController {
    // ...
}

@Path("/myResource")
public class MyController extends AbstractMyController {
    // ...
}
```

---

## 2. Method-Level: The `@Operation` Annotation

The `@Operation` annotation documents the endpoint on the abstract class's `doHandle()` method. It contains:

### 2.1. Summary and Description

```java
@Operation(
    summary = "Brief one-line description (shown in endpoint list)",
    description = "Detailed multi-line description explaining what the endpoint does, "
        + "who should use it, and any important notes about behavior.",
    tags = {"process-builder"}
)
```

**Guidelines:**
- `summary`: Max ~80 characters, action-oriented (e.g., "Retrieve accessible processes")
- `description`: Full explanation including filtering/ordering capabilities
- `tags`: Always use `"process-builder"` for grouping

### 2.2. Parameters

Document each query parameter with `@Parameter`:

```java
@Operation(
    // ...
    parameters = {
        @Parameter(
            in = ParameterIn.QUERY,
            name = "p",
            description = "Page index (0-based). Example: p=0 for the first page.",
            required = true,
            schema = @Schema(type = "integer", defaultValue = "0")
        ),
        @Parameter(
            in = ParameterIn.QUERY,
            name = "c",
            description = "Number of items per page. Example: c=10 for 10 items.",
            required = true,
            schema = @Schema(type = "integer", defaultValue = "10")
        ),
        @Parameter(
            in = ParameterIn.QUERY,
            name = "f",
            description = "Filter parameter. Format: f={field}={value}. "
                + "Supported fields: 'name', 'description'. "
                + "Example: f=name=Sales",
            required = false
        ),
        @Parameter(
            in = ParameterIn.QUERY,
            name = "o",
            description = "Order-by parameter. Format: o={field} {ASC|DESC}. "
                + "Supported fields: 'name', 'modificationDate'. "
                + "Example: o=modificationDate DESC",
            required = false
        )
    }
)
```

**Parameter Types:**

| `in` Value | Use For |
|-----------|---------|
| `ParameterIn.QUERY` | Query string parameters (`?p=0&c=10`) |
| `ParameterIn.PATH` | URL path parameters (`/resource/{id}`) |
| `ParameterIn.HEADER` | HTTP headers |

**Schema Types:**

| `type` | Java Type | Example |
|--------|-----------|---------|
| `"integer"` | Integer, Long | Page index, count |
| `"string"` | String | Filter values, names |
| `"boolean"` | Boolean | Feature flags |
| `"number"` | Double, Float | Decimal values |

### 2.3. Responses

Document all possible HTTP responses:

```java
@Operation(
    // ...
    responses = {
        @ApiResponse(
            responseCode = "200",
            description = "Successfully retrieved the list of entities.",
            content = @Content(
                mediaType = "application/json",
                schema = @Schema(implementation = ResultMyController.class)
            )
        ),
        @ApiResponse(
            responseCode = "400",
            description = "Invalid input parameters. Possible causes: "
                + "missing 'p' or 'c', invalid filter field, invalid order direction."
        ),
        @ApiResponse(
            responseCode = "403",
            description = "License validation failed. The Bonita license is invalid or expired."
        ),
        @ApiResponse(
            responseCode = "500",
            description = "Internal server error during execution. "
                + "Check server logs for details."
        )
    }
)
```

---

## 3. Hiding Internal Parameters

The `doHandle()` method receives `HttpServletRequest`, `RestApiResponseBuilder`, and `RestAPIContext` as parameters. These are framework-internal and should be hidden from the API documentation:

```java
@Override
public RestApiResponse doHandle(
        @Parameter(hidden = true) HttpServletRequest request,
        @Parameter(hidden = true) RestApiResponseBuilder responseBuilder,
        @Parameter(hidden = true) RestAPIContext context) {
    // ...
}
```

---

## 4. Complete Annotated Example: GET Endpoint

```java
@GET
@Path("/accessible")
@Operation(
    summary = "Retrieve Accessible Processes for User (Launchable OR Editable).",
    tags = {"process-builder"},
    description = "Returns a paginated list of processes that the current user is authorized "
        + "to start OR edit, applying optional filters and sorting. "
        + "Access level depends on user profile: "
        + "PB Administrator sees all processes, "
        + "PB Process Manager sees launchable and editable processes, "
        + "PB User sees only launchable processes.",
    parameters = {
        @Parameter(
            in = ParameterIn.QUERY,
            name = "p",
            description = "The requested page index (e.g., 0, 1, ...).",
            required = true,
            schema = @Schema(type = "integer", defaultValue = "0")
        ),
        @Parameter(
            in = ParameterIn.QUERY,
            name = "c",
            description = "The number of elements per page.",
            required = true,
            schema = @Schema(type = "integer", defaultValue = "10")
        ),
        @Parameter(
            in = ParameterIn.QUERY,
            name = "f",
            description = "Filter parameter. Format is 'f={field}={value}'. "
                + "Example: 'f=name=Sales'. "
                + "Supported fields: 'name', 'description'.",
            required = false
        ),
        @Parameter(
            in = ParameterIn.QUERY,
            name = "o",
            description = "Order-by parameter. Format is 'o={field} {direction}'. "
                + "Example: 'o=updatedAt DESC'. "
                + "Supported fields: 'name', 'updatedAt'. "
                + "Supported directions: 'ASC', 'DESC'.",
            required = false
        )
    },
    responses = {
        @ApiResponse(
            responseCode = "200",
            description = "Successfully retrieved the list of accessible processes.",
            content = @Content(
                mediaType = "application/json",
                schema = @Schema(implementation = ResultProcessesAccessible.class)
            )
        ),
        @ApiResponse(
            responseCode = "400",
            description = "Invalid input parameters (e.g., missing 'p' or 'c', "
                + "invalid filter field)."
        ),
        @ApiResponse(
            responseCode = "403",
            description = "License validation failed."
        ),
        @ApiResponse(
            responseCode = "500",
            description = "Internal server error during execution."
        )
    }
)
@Override
public RestApiResponse doHandle(
        @Parameter(hidden = true) HttpServletRequest request,
        @Parameter(hidden = true) RestApiResponseBuilder responseBuilder,
        @Parameter(hidden = true) RestAPIContext context) {
    // Implementation...
}
```

---

## 5. Complete Annotated Example: POST Endpoint

```java
@POST
@Path("/execute")
@Operation(
    summary = "Execute a master process instance.",
    tags = {"process-builder"},
    description = "Starts a new instance of the specified master process with the given "
        + "input parameters. The process is identified by its BDM persistenceId.",
    parameters = {
        @Parameter(
            in = ParameterIn.QUERY,
            name = "processId",
            description = "The BDM persistenceId of the process to execute.",
            required = true,
            schema = @Schema(type = "integer", format = "int64")
        )
    },
    responses = {
        @ApiResponse(
            responseCode = "200",
            description = "Process instance started successfully.",
            content = @Content(
                mediaType = "application/json",
                schema = @Schema(implementation = ResultExecuteMasterProcess.class)
            )
        ),
        @ApiResponse(
            responseCode = "400",
            description = "Invalid or missing processId parameter."
        ),
        @ApiResponse(
            responseCode = "403",
            description = "User does not have permission to start this process, "
                + "or license validation failed."
        ),
        @ApiResponse(
            responseCode = "500",
            description = "Internal server error during process instantiation."
        )
    }
)
@Override
public RestApiResponse doHandle(
        @Parameter(hidden = true) HttpServletRequest request,
        @Parameter(hidden = true) RestApiResponseBuilder responseBuilder,
        @Parameter(hidden = true) RestAPIContext context) {
    // Implementation...
}
```

---

## 6. Schema References for Complex Types

When the response contains nested objects, reference specific DTO classes:

```java
@ApiResponse(
    responseCode = "200",
    description = "Dashboard KPIs retrieved successfully.",
    content = @Content(
        mediaType = "application/json",
        schema = @Schema(implementation = ResultDashboardKpis.class)
    )
)
```

For array responses, you can use:

```java
@ApiResponse(
    responseCode = "200",
    description = "List of entities.",
    content = @Content(
        mediaType = "application/json",
        array = @ArraySchema(schema = @Schema(implementation = MyEntityDTO.class))
    )
)
```

**Additional import needed:**
```java
import io.swagger.v3.oas.annotations.media.ArraySchema;
```

---

## 7. OpenAPI YAML Specification

If the project maintains a centralized `doc/api/openapi.yaml`, add the new endpoint there as well:

```yaml
paths:
  /API/extension/myResource:
    get:
      summary: Retrieve entities by criteria
      description: Returns a paginated list of entities filtered by the given criteria.
      tags:
        - process-builder
      parameters:
        - name: p
          in: query
          required: true
          description: Page index (0-based)
          schema:
            type: integer
            default: 0
        - name: c
          in: query
          required: true
          description: Items per page
          schema:
            type: integer
            default: 10
        - name: f
          in: query
          required: false
          description: "Filter: f={field}={value}"
          schema:
            type: string
        - name: o
          in: query
          required: false
          description: "Order: o={field} {ASC|DESC}"
          schema:
            type: string
      responses:
        '200':
          description: Successful operation
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ResultMyController'
        '400':
          description: Invalid parameters
        '403':
          description: License validation failed
        '500':
          description: Internal server error

components:
  schemas:
    ResultMyController:
      type: object
      properties:
        p:
          type: integer
          description: Current page index
        c:
          type: integer
          description: Page size
        total:
          type: integer
          format: int64
          description: Total matching records
        data:
          type: array
          items:
            $ref: '#/components/schemas/MyEntityDTO'
    MyEntityDTO:
      type: object
      properties:
        persistenceId:
          type: integer
          format: int64
        name:
          type: string
        status:
          type: string
        createdAt:
          type: string
          format: date-time
```

---

## 8. Checklist for OpenAPI Documentation

- [ ] `@Operation` with `summary`, `description`, and `tags` on abstract `doHandle()`
- [ ] `@Parameter` for each query/path parameter with `name`, `description`, `required`, `schema`
- [ ] `@ApiResponse` for all possible HTTP status codes (200, 400, 403, 500)
- [ ] `@Content` with `mediaType` and `@Schema(implementation = ...)` for 200 response
- [ ] `@Parameter(hidden = true)` on `HttpServletRequest`, `RestApiResponseBuilder`, `RestAPIContext`
- [ ] HTTP method annotation (`@GET`, `@POST`, etc.) matches actual endpoint behavior
- [ ] `@Path` annotation matches the actual endpoint URL path
- [ ] `openapi.yaml` updated (if project maintains centralized spec file)
