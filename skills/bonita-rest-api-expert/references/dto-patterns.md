# DTO Patterns and Examples

This reference covers all DTO design patterns used in the Process Builder REST API extension.

---

## Overview

DTOs (Data Transfer Objects) serve as the contract between the REST API and its consumers. The project uses three categories of DTOs:

| Category | Location | Purpose | Primary Annotation |
|----------|----------|---------|-------------------|
| **Parameter DTOs** | `dto/parameter/` | Encapsulate request parameters | `@Value` |
| **Result DTOs** | `dto/result/` | Encapsulate response payloads | `@Value` + `@Builder` |
| **Object DTOs** | `dto/objects/` | Represent domain entities | `@Value` |

---

## 1. Parameter DTOs (`dto/parameter/Param{ControllerName}.java`)

Parameter DTOs encapsulate validated request parameters extracted from the HTTP request. They are always **immutable** since request data should not change after validation.

### Pattern: Lombok `@Value`

```java
package com.bonitasoft.processbuilder.rest.api.dto.parameter;

import java.util.List;
import java.util.Map;

import com.bonitasoft.processbuilder.rest.api.utils.enums.ProcessOrderField;

import lombok.Value;

/**
 * DTO encapsulating request parameters for the ProcessesAccessible endpoint.
 * <p>
 * Uses Lombok's @Value to generate:
 * - All-args constructor
 * - Getters for all fields
 * - equals(), hashCode(), toString()
 * - All fields are private final (immutable)
 */
@Value
public class ParamProcessesAccessible {
    /** Page index (0-based pagination). */
    Integer p;
    /** Number of items per page. */
    Integer c;
    /** Optional filter map: key = field name, value = filter value. */
    Map<String, String> filters;
    /** Optional ordering criteria. */
    List<OrderParam<ProcessOrderField>> order;
}
```

### Real Project Example: Simple Parameter DTO

```java
package com.bonitasoft.processbuilder.rest.api.dto.parameter;

import lombok.Value;

/**
 * DTO for external document download parameters.
 */
@Value
public class ParamExternalDocumentDownload {
    /** The document identifier in the external storage. */
    String documentId;
    /** The storage type (e.g., "S3", "AZURE_BLOB"). */
    String storageType;
}
```

### Real Project Example: Complex Parameter DTO with Nested Types

```java
package com.bonitasoft.processbuilder.rest.api.dto.parameter;

import lombok.Value;

/**
 * DTO for SQL datasource execution parameters.
 */
@Value
public class ExecuteSqlDatasourceParameters {
    /** JNDI datasource name. */
    String datasourceName;
    /** SQL query to execute. */
    String query;
    /** Query parameters as JSON array. */
    String queryParams;
    /** Maximum number of rows to return. */
    Integer maxRows;
}
```

### When to Use Parameter DTOs

- Always create one for each controller endpoint
- Even if there is only one parameter (keeps the pattern consistent)
- Never put business logic in parameter DTOs

---

## 2. Result DTOs (`dto/result/Result{ControllerName}.java`)

Result DTOs encapsulate the response payload. They use `@Builder` for convenient construction in the controller's `execute()` method and `@JsonDeserialize` for Jackson compatibility.

### Pattern: Lombok `@Value` + `@Builder` + `@JsonDeserialize`

```java
package com.bonitasoft.processbuilder.rest.api.dto.result;

import java.util.List;

import com.bonitasoft.processbuilder.rest.api.dto.bdm.PBProcessDTO;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;

import lombok.Builder;
import lombok.Value;

/**
 * DTO encapsulating the response for the ProcessesAccessible endpoint.
 * <p>
 * Uses Lombok's @Value for immutability and @Builder for the builder pattern.
 * The @JsonDeserialize annotation enables Jackson to use the Lombok-generated builder
 * for deserialization (useful in tests).
 */
@Value
@Builder
@JsonDeserialize(builder = ResultProcessesAccessible.ResultProcessesAccessibleBuilder.class)
public class ResultProcessesAccessible {
    /** Current page index. */
    Integer p;
    /** Page size (items per page). */
    Integer c;
    /** Total number of matching records across all pages. */
    Long total;
    /** List of process DTOs for the current page. */
    List<PBProcessDTO> listPBProcessDTO;
}
```

### Paginated Result Pattern

For endpoints returning paginated data, always include `p`, `c`, and `total`:

```java
@Value
@Builder
@JsonDeserialize(builder = ResultProcessList.ResultProcessListBuilder.class)
public class ResultProcessList {
    /** Page index. */
    Integer p;
    /** Page size. */
    Integer c;
    /** Total matching records. */
    Long total;
    /** Data for current page. */
    List<ProcessDTO> data;
}
```

**Usage in controller:**

```java
return ResultProcessList.builder()
    .p(params.getP())
    .c(params.getC())
    .total(dao.countForFindAll())
    .data(entities.stream().map(this::toDTO).toList())
    .build();
```

### Non-Paginated Result Pattern

For endpoints returning a single object or a fixed structure:

```java
@Value
@Builder
@JsonDeserialize(builder = ResultDocumentation.ResultDocumentationBuilder.class)
public class ResultDocumentation {
    /** The API documentation content. */
    String content;
    /** The API version. */
    String version;
    /** List of available endpoints. */
    List<EndpointInfo> endpoints;
}
```

### Result with Nested Objects

```java
@Value
@Builder
@JsonDeserialize(builder = ResultDashboardKpis.ResultDashboardKpisBuilder.class)
public class ResultDashboardKpis {
    /** Summary KPIs. */
    DashboardKpisDTO summary;
    /** Process-level KPIs. */
    List<ProcessKpisDTO> processes;
    /** User productivity data. */
    List<UserProductivityItemDTO> userProductivity;
}
```

---

## 3. Object DTOs (`dto/objects/{EntityName}DTO.java`)

Object DTOs represent domain entities in API responses. They map BDM (Business Data Model) entities to a clean API representation, hiding internal implementation details.

### Pattern: Lombok `@Value`

```java
package com.bonitasoft.processbuilder.rest.api.dto.objects;

import java.time.LocalDateTime;
import lombok.Value;

/**
 * DTO representing a process instance (case) in API responses.
 * <p>
 * Maps from the BDM PBProcessInstance entity, exposing only the fields
 * relevant to API consumers.
 */
@Value
public class CaseDTO {
    /** Unique BDM persistence identifier. */
    Long persistenceId;
    /** Case number (Bonita caseId). */
    Long caseId;
    /** Display name of the process. */
    String processDisplayName;
    /** Current status (ACTIVE, COMPLETED, ERROR). */
    String status;
    /** User who started the case. */
    String startedBy;
    /** Case start timestamp. */
    LocalDateTime startDate;
    /** Case end timestamp (null if still active). */
    LocalDateTime endDate;
}
```

### Real Project Example: DTO with Permission Flags

```java
package com.bonitasoft.processbuilder.rest.api.dto.bdm;

import java.time.LocalDateTime;
import lombok.Value;
import lombok.Builder;

/**
 * DTO representing a process definition with user-specific permissions.
 */
@Value
@Builder
public class PBProcessDTO {
    Long persistenceId;
    String fullName;
    String displayName;
    String description;
    String version;
    String categoryName;
    String status;
    String creatorName;
    LocalDateTime creationDate;
    LocalDateTime modificationDate;
    /** Whether the current user can launch this process. */
    Boolean launchable;
    /** Whether the current user can edit this process. */
    Boolean editable;
    /** Whether the current user can edit the configuration. */
    Boolean canEdit;
    /** Whether the current user can delete this process. */
    Boolean canDelete;
}
```

### Real Project Example: KPI/Metrics DTO

```java
package com.bonitasoft.processbuilder.rest.api.dto.kpis;

import lombok.Value;

/**
 * DTO for dashboard-level KPI aggregations.
 */
@Value
public class DashboardKpisDTO {
    /** Total number of active processes. */
    Long totalActiveProcesses;
    /** Total number of open cases. */
    Long totalOpenCases;
    /** Total number of pending tasks. */
    Long totalPendingTasks;
    /** Average case completion time in milliseconds. */
    Long averageCompletionTimeMs;
}
```

---

## 4. Java 17 Records Alternative

For simple DTOs without Lombok dependencies, Java 17 Records provide a built-in immutable data class:

### When to Prefer Records Over Lombok

| Use Records When | Use Lombok `@Value` When |
|-----------------|-------------------------|
| Simple data carrier (few fields) | Need `@Builder` pattern |
| No Jackson deserialization needed | Need `@JsonDeserialize` with builder |
| No inheritance required | Need compatibility with existing Lombok DTOs |
| New code with no Lombok dependency | Existing codebase uses Lombok consistently |

### Record Examples

**Simple Parameter Record:**

```java
package com.bonitasoft.processbuilder.rest.api.dto.parameter;

/**
 * Request parameters for the single-entity endpoint.
 *
 * @param entityId The entity identifier.
 * @param includeDetails Whether to include detailed information.
 */
public record ParamEntityDetail(
    Long entityId,
    Boolean includeDetails
) {}
```

**Object Record:**

```java
package com.bonitasoft.processbuilder.rest.api.dto.objects;

import java.time.LocalDateTime;

/**
 * Represents a menu item in the navigation structure.
 *
 * @param id Unique identifier.
 * @param label Display label.
 * @param url Navigation URL.
 * @param icon Icon class name.
 * @param sortOrder Display order.
 */
public record MenuItemDTO(
    Long id,
    String label,
    String url,
    String icon,
    Integer sortOrder
) {}
```

**Record with Compact Constructor (Validation):**

```java
public record ParamPagination(
    Integer p,
    Integer c
) {
    /**
     * Compact constructor with validation.
     */
    public ParamPagination {
        if (p == null || p < 0) {
            throw new IllegalArgumentException("Page index 'p' must be >= 0");
        }
        if (c == null || c < 1 || c > 500) {
            throw new IllegalArgumentException("Page size 'c' must be between 1 and 500");
        }
    }
}
```

---

## 5. The Error DTO

The project uses a shared `Error` DTO for all error responses:

```java
package com.bonitasoft.processbuilder.rest.api.dto;

import lombok.Builder;
import lombok.Value;

/**
 * Standard error response DTO used across all controllers.
 */
@Value
@Builder
public class Error {
    /** Human-readable error message. */
    String message;
}
```

**Usage in controllers:**

```java
// 400 Bad Request
return Utils.jsonResponse(responseBuilder, mapper, SC_BAD_REQUEST,
    Error.builder().message("The required parameter 'p' is missing.").build());

// 500 Internal Server Error
return Utils.jsonResponse(responseBuilder, mapper, SC_INTERNAL_SERVER_ERROR,
    Error.builder().message(ErrorMessages.INTERNAL_SERVER_ERROR_MESSAGE).build());
```

---

## 6. DTO Mapping Patterns

### Entity to DTO Mapping

Always create a dedicated mapping method (or a Mapper utility class):

```java
/**
 * Maps a BDM PBProcess entity to its DTO representation.
 *
 * @param entity The BDM entity.
 * @param userContext The user context for permission calculation.
 * @return The mapped DTO with permissions.
 */
private PBProcessDTO toDTO(PBProcess entity, UserContext userContext) {
    return PBProcessDTO.builder()
        .persistenceId(entity.getPersistenceId())
        .fullName(entity.getFullName())
        .displayName(entity.getDisplayName())
        .description(entity.getDescription())
        .version(entity.getVersion())
        .status(entity.getStatus())
        .creationDate(entity.getCreationDate())
        .modificationDate(entity.getModificationDate())
        .launchable(calculateLaunchable(entity, userContext))
        .editable(calculateEditable(entity, userContext))
        .build();
}
```

### Batch Mapping with Streams

```java
List<PBProcessDTO> dtos = entities.stream()
    .map(entity -> toDTO(entity, userContext))
    .toList();
```

### Using a Dedicated Mapper Class

For complex mappings shared across multiple controllers:

```java
package com.bonitasoft.processbuilder.rest.api.utils.mapper;

/**
 * Utility class for mapping PBProcess entities to DTOs.
 */
public final class ProcessMapper {

    private ProcessMapper() {
        // Utility class - no instantiation
    }

    /**
     * Maps a list of entities to DTOs with user-specific permissions.
     */
    public static List<PBProcessDTO> toDtoList(List<PBProcess> entities, UserContext ctx) {
        return entities.stream()
            .map(entity -> toDto(entity, ctx))
            .toList();
    }

    /**
     * Maps a single entity to a DTO.
     */
    public static PBProcessDTO toDto(PBProcess entity, UserContext ctx) {
        return PBProcessDTO.builder()
            .persistenceId(entity.getPersistenceId())
            .fullName(entity.getFullName())
            // ... more fields ...
            .build();
    }
}
```

---

## 7. DTO Testing Patterns

### Testing Lombok `@Value` DTOs

```java
@Test
@DisplayName("should_create_immutable_param_with_all_fields")
void should_create_immutable_param_with_all_fields() {
    // Given
    Integer p = 0;
    Integer c = 10;
    Map<String, String> filters = Map.of("name", "Sales");

    // When
    ParamMyController param = new ParamMyController(p, c, filters);

    // Then
    assertThat(param.getP()).isEqualTo(p);
    assertThat(param.getC()).isEqualTo(c);
    assertThat(param.getFilters()).containsEntry("name", "Sales");
}

@Test
@DisplayName("should_implement_equals_for_identical_params")
void should_implement_equals_for_identical_params() {
    // Given
    ParamMyController param1 = new ParamMyController(0, 10, Map.of());
    ParamMyController param2 = new ParamMyController(0, 10, Map.of());

    // Then
    assertThat(param1).isEqualTo(param2);
    assertThat(param1.hashCode()).isEqualTo(param2.hashCode());
}
```

### Testing `@Builder` DTOs

```java
@Test
@DisplayName("should_build_result_with_all_fields")
void should_build_result_with_all_fields() {
    // Given / When
    ResultMyController result = ResultMyController.builder()
        .p(0)
        .c(10)
        .total(100L)
        .data(List.of())
        .build();

    // Then
    assertThat(result.getP()).isZero();
    assertThat(result.getC()).isEqualTo(10);
    assertThat(result.getTotal()).isEqualTo(100L);
    assertThat(result.getData()).isEmpty();
}
```

### Testing with Jackson Serialization

```java
@Test
@DisplayName("should_serialize_result_to_JSON_correctly")
void should_serialize_result_to_JSON_correctly() throws Exception {
    // Given
    ObjectMapper mapper = new ObjectMapper()
        .registerModule(new JavaTimeModule())
        .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    ResultMyController result = ResultMyController.builder()
        .p(0).c(10).total(1L)
        .data(List.of(new MyEntityDTO(1L, "Test", "ACTIVE", null)))
        .build();

    // When
    String json = mapper.writeValueAsString(result);

    // Then
    assertThat(json).contains("\"p\":0");
    assertThat(json).contains("\"total\":1");
    assertThat(json).contains("\"name\":\"Test\"");
}
```
