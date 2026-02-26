# REST API Controller Creation Checklist (F.1 - F.8)

Complete reference for creating new REST API controllers in the Process Builder REST API extension.

---

## F.1. Directory and File Structure

When creating a new controller, create the following structure:

```
src/main/java/com/bonitasoft/processbuilder/rest/api/
├── controller/
│   └── {controllerName}/                              # Package named after the controller
│       ├── Abstract{ControllerName}.java              # Abstract base class
│       ├── {ControllerName}.java                      # Concrete implementation
│       ├── {ControllerName}Field.java                 # Field definitions (constants for filtering/ordering)
│       └── README.md                                  # Controller documentation (11 sections)
├── dto/
│   ├── parameter/
│   │   └── Param{ControllerName}.java                 # Request parameters DTO (@Value)
│   ├── result/
│   │   └── Result{ControllerName}.java                # Response result DTO (@Value + @Builder)
│   └── objects/
│       └── {EntityName}DTO.java                       # Entity-specific DTOs (@Value)
```

### Test File Structure

```
src/test/java/com/bonitasoft/processbuilder/rest/api/
├── controller/
│   └── {controllerName}/
│       ├── Abstract{ControllerName}Test.java          # Tests for abstract class (doHandle flow)
│       ├── {ControllerName}Test.java                  # Tests for business logic (execute)
│       └── {ControllerName}PropertyTest.java          # Property-based tests (jqwik, optional)
├── dto/
│   ├── parameter/
│   │   └── Param{ControllerName}Test.java             # Parameter DTO tests
│   └── result/
│       └── Result{ControllerName}Test.java            # Result DTO tests
```

### Naming Conventions

| Component | Naming Pattern | Example |
|-----------|---------------|---------|
| Controller package | camelCase | `processesAccessible` |
| Abstract class | `Abstract` + PascalCase | `AbstractProcessesAccessible` |
| Concrete class | PascalCase | `ProcessesAccessible` |
| Field class | PascalCase + `Field` | `ProcessesAccessibleField` |
| Parameter DTO | `Param` + PascalCase | `ParamProcessesAccessible` |
| Result DTO | `Result` + PascalCase | `ResultProcessesAccessible` |
| Object DTO | PascalCase + `DTO` | `PBProcessDTO` |

---

## F.2. Controller Classes

### F.2.1. Abstract Class (`Abstract{ControllerName}.java`)

The abstract class handles all cross-cutting concerns:

**Responsibilities:**
- HTTP request parsing and validation
- License validation via `LicenseValidator`
- Parameter extraction via abstract `validateInputParameters()`
- Error handling (400, 500) and response building
- OpenAPI/Swagger annotations
- ObjectMapper configuration

**Complete Template:**

```java
package com.bonitasoft.processbuilder.rest.api.controller.myController;

import org.bonitasoft.web.extension.rest.RestAPIContext;
import org.bonitasoft.web.extension.rest.RestApiController;
import org.bonitasoft.web.extension.rest.RestApiResponse;
import org.bonitasoft.web.extension.rest.RestApiResponseBuilder;

import com.bonitasoft.processbuilder.rest.api.utils.constants.ErrorMessages;
import com.bonitasoft.processbuilder.rest.api.utils.LicenseValidator;
import com.bonitasoft.processbuilder.rest.api.dto.Error;
import com.bonitasoft.processbuilder.rest.api.dto.parameter.ParamMyController;
import com.bonitasoft.processbuilder.rest.api.dto.result.ResultMyController;
import com.bonitasoft.processbuilder.rest.api.exception.ValidationException;
import com.bonitasoft.processbuilder.rest.api.utils.Utils;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import java.util.Optional;

import static javax.servlet.http.HttpServletResponse.SC_BAD_REQUEST;
import static javax.servlet.http.HttpServletResponse.SC_OK;
import static javax.servlet.http.HttpServletResponse.SC_INTERNAL_SERVER_ERROR;

/**
 * Abstract controller class providing the common structure for the MyController endpoint.
 * <p>
 * Handles parameter validation, execution orchestration, and error handling
 * (400 client errors and 500 server errors) in a standardized way.
 */
@Path("/myResource")
public abstract class AbstractMyController implements RestApiController {

    /** Logger for this class. */
    private static final Logger LOGGER = LoggerFactory.getLogger(AbstractMyController.class.getName());

    /** ObjectMapper configured for JSON serialization with Java 8 Date/Time support. */
    private final ObjectMapper mapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    /**
     * Returns the configured ObjectMapper instance.
     *
     * @return The ObjectMapper for REST response serialization.
     */
    public ObjectMapper getMapper() {
        return mapper;
    }

    /**
     * Main handler method for the REST API request.
     * <p>
     * Orchestrates: 1) License check, 2) Parameter validation, 3) Business logic execution.
     *
     * @param request         The incoming HTTP request.
     * @param responseBuilder The builder for constructing the HTTP response.
     * @param context         The Bonita REST API context.
     * @return A {@link RestApiResponse} with the result or an error message.
     */
    @GET
    @Path("/endpoint")
    @Operation(
        summary = "Brief endpoint description",
        tags = {"process-builder"},
        description = "Detailed endpoint description",
        parameters = {
            @Parameter(in = ParameterIn.QUERY, name = "p",
                description = "Page index (0-based)", required = true,
                schema = @Schema(type = "integer", defaultValue = "0")),
            @Parameter(in = ParameterIn.QUERY, name = "c",
                description = "Items per page", required = true,
                schema = @Schema(type = "integer", defaultValue = "10"))
        },
        responses = {
            @ApiResponse(responseCode = "200", description = "Successful operation",
                content = @Content(mediaType = "application/json",
                    schema = @Schema(implementation = ResultMyController.class))),
            @ApiResponse(responseCode = "400", description = "Invalid input parameters"),
            @ApiResponse(responseCode = "403", description = "License validation failed"),
            @ApiResponse(responseCode = "500", description = "Internal server error")
        }
    )
    @Override
    public RestApiResponse doHandle(
            @Parameter(hidden = true) HttpServletRequest request,
            @Parameter(hidden = true) RestApiResponseBuilder responseBuilder,
            @Parameter(hidden = true) RestAPIContext context) {

        // 1. License validation
        Optional<RestApiResponse> licenseError = LicenseValidator
            .checkLicenseAndReturnForbiddenIfInvalid(request, responseBuilder, context);
        if (licenseError.isPresent()) {
            return licenseError.get();
        }

        ParamMyController params = null;

        try {
            // 2. Validate and convert input parameters (400 handler)
            params = validateInputParameters(request);
        } catch (ValidationException e) {
            LOGGER.error("Request for this REST API extension is not valid", e);
            return Utils.jsonResponse(responseBuilder, mapper, SC_BAD_REQUEST,
                Error.builder().message(e.getMessage()).build());
        }

        try {
            // 3. Execute business logic (500 handler)
            ResultMyController result = execute(context, params);

            // 4. Return 200 OK with result
            // For paginated results, use Utils.pagedJsonResponse():
            // return Utils.pagedJsonResponse(responseBuilder, mapper, SC_OK,
            //     result.getData(), result.getP(), result.getC(), result.getTotal());
            return Utils.jsonResponse(responseBuilder, mapper, SC_OK, result);
        } catch (Exception e) {
            LOGGER.error(ErrorMessages.INTERNAL_EXECUTION_LOG_MESSAGE, e);
            return Utils.jsonResponse(responseBuilder, mapper, SC_INTERNAL_SERVER_ERROR,
                Error.builder().message(ErrorMessages.INTERNAL_SERVER_ERROR_MESSAGE).build());
        }
    }

    /**
     * Core business logic - implemented by concrete controllers.
     *
     * @param context The Bonita REST API context.
     * @param params  The validated input parameters.
     * @return The result DTO.
     */
    protected abstract ResultMyController execute(RestAPIContext context, ParamMyController params);

    /**
     * Validates and converts raw HTTP request parameters into a typed DTO.
     *
     * @param request The incoming HTTP request.
     * @return A typed parameter DTO.
     * @throws ValidationException If any parameter is missing or invalid.
     */
    protected abstract ParamMyController validateInputParameters(HttpServletRequest request)
        throws ValidationException;
}
```

### F.2.2. Concrete Class (`{ControllerName}.java`)

The concrete class implements actual business logic:

**Responsibilities:**
- `validateInputParameters()` - Parameter parsing using `QueryParamValidator`
- `execute()` - Business logic with DAO/service calls
- Data transformation (entity -> DTO)

**Complete Template:**

```java
package com.bonitasoft.processbuilder.rest.api.controller.myController;

import com.bonitasoft.processbuilder.rest.api.utils.QueryParamValidator;
import com.bonitasoft.processbuilder.rest.api.utils.constants.Parameters;
import com.bonitasoft.processbuilder.rest.api.dto.parameter.ParamMyController;
import com.bonitasoft.processbuilder.rest.api.dto.result.ResultMyController;
import com.bonitasoft.processbuilder.rest.api.dto.objects.MyEntityDTO;
import com.bonitasoft.processbuilder.rest.api.exception.ValidationException;

import org.bonitasoft.engine.bdm.BusinessObjectDaoCreationException;
import org.bonitasoft.web.extension.rest.RestAPIContext;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.Path;
import java.util.List;
import java.util.Map;

import static java.lang.String.format;

/**
 * Concrete controller for retrieving MyEntity resources.
 * <p>
 * Implements parameter validation and business logic for the /myResource endpoint.
 */
@Path("/myResource")
public class MyController extends AbstractMyController {

    private static final Logger LOGGER = LoggerFactory.getLogger(MyController.class.getName());

    /**
     * Validates and converts HTTP request parameters into a typed DTO.
     *
     * @param request The incoming HTTP request.
     * @return A validated {@link ParamMyController} DTO.
     * @throws ValidationException If parameters are missing or invalid.
     */
    @Override
    public ParamMyController validateInputParameters(HttpServletRequest request)
            throws ValidationException {

        // 1. Mandatory pagination parameters
        Integer p = QueryParamValidator.validateMandatoryInteger(request, Parameters.PARAM_INPUT_P);
        Integer c = QueryParamValidator.validateMandatoryInteger(request, Parameters.PARAM_INPUT_C);

        // 2. Optional filter parameters
        Map<String, String> filters = QueryParamValidator.validateFilterParameters(
            request, Parameters.PARAM_FILTER, MyControllerField.ALLOWED_FILTER_FIELDS);

        return new ParamMyController(p, c, filters);
    }

    /**
     * Executes the business logic to retrieve MyEntity resources.
     *
     * @param context The Bonita REST API context.
     * @param params  The validated input parameters.
     * @return A {@link ResultMyController} with the results and pagination metadata.
     */
    @Override
    public ResultMyController execute(RestAPIContext context, ParamMyController params) {
        LOGGER.info(format("Execute myController with params: %s",
            (params != null) ? params.toString() : ""));

        // 1. Get DAO
        MyEntityDAO dao;
        try {
            dao = context.getApiClient().getDAO(MyEntityDAO.class);
        } catch (BusinessObjectDaoCreationException e) {
            throw new RuntimeException("Failed to obtain MyEntityDAO.", e);
        }

        // 2. Calculate pagination offset
        int offset = params.getP() * params.getC();
        int limit = params.getC();

        // 3. Execute query with filters
        String nameFilter = QueryParamValidator.getValidatedFilter(
            MyControllerField.NAME, params.getFilters());

        List<MyEntity> entities = dao.findByName(nameFilter, offset, limit);
        Long total = dao.countForFindByName(nameFilter);

        // 4. Map to DTOs
        List<MyEntityDTO> dtos = entities.stream()
            .map(this::toDTO)
            .toList();

        LOGGER.info(format("Executed myController with total: %s",
            (total != null) ? total.toString() : "0"));

        return ResultMyController.builder()
            .p(params.getP())
            .c(params.getC())
            .total(total)
            .data(dtos)
            .build();
    }

    /**
     * Maps a BDM entity to its DTO representation.
     *
     * @param entity The BDM entity.
     * @return The mapped DTO.
     */
    private MyEntityDTO toDTO(MyEntity entity) {
        return new MyEntityDTO(
            entity.getPersistenceId(),
            entity.getName(),
            entity.getStatus(),
            entity.getCreationDate()
        );
    }
}
```

---

## F.3. DTO Classes

### F.3.1. Parameter DTOs (`dto/parameter/Param{ControllerName}.java`)

Use `@Value` for immutable request parameters:

```java
package com.bonitasoft.processbuilder.rest.api.dto.parameter;

import java.util.List;
import java.util.Map;
import lombok.Value;

/**
 * DTO encapsulating request parameters for the MyController endpoint.
 * Uses Lombok @Value for immutability.
 */
@Value
public class ParamMyController {
    /** Page index (0-based). */
    Integer p;
    /** Number of items per page. */
    Integer c;
    /** Optional filter map (key=field, value=filter). */
    Map<String, String> filters;
}
```

### F.3.2. Result DTOs (`dto/result/Result{ControllerName}.java`)

Use `@Value` + `@Builder` for responses:

```java
package com.bonitasoft.processbuilder.rest.api.dto.result;

import java.util.List;
import com.bonitasoft.processbuilder.rest.api.dto.objects.MyEntityDTO;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import lombok.Builder;
import lombok.Value;

/**
 * DTO encapsulating the response for the MyController endpoint.
 * Uses Lombok @Value for immutability and @Builder for construction.
 */
@Value
@Builder
@JsonDeserialize(builder = ResultMyController.ResultMyControllerBuilder.class)
public class ResultMyController {
    /** Current page index. */
    Integer p;
    /** Page size. */
    Integer c;
    /** Total number of matching records. */
    Long total;
    /** List of entity DTOs. */
    List<MyEntityDTO> data;
}
```

### F.3.3. Object DTOs (`dto/objects/{EntityName}DTO.java`)

Use `@Value` for entity representations:

```java
package com.bonitasoft.processbuilder.rest.api.dto.objects;

import java.time.LocalDateTime;
import lombok.Value;

/**
 * DTO representing a MyEntity in API responses.
 */
@Value
public class MyEntityDTO {
    /** Unique BDM persistence identifier. */
    Long persistenceId;
    /** Entity name. */
    String name;
    /** Current status. */
    String status;
    /** Creation timestamp. */
    LocalDateTime createdAt;
}
```

---

## F.4. README Documentation (MANDATORY - 11 Sections)

Every controller directory MUST have a `README.md` with these 11 sections:

1. **Overview** - Brief description of the controller's purpose
2. **Architecture** - ASCII diagram showing component flow (Controller -> DAO -> BDM)
3. **Endpoint** - HTTP method and URL path (`http://localhost:8080/bonita/API/extension/{endpoint}`)
4. **Request Parameters** - Table with: Parameter, Type, Required, Description, Example
5. **Response Format** - JSON structure with field descriptions and types
6. **Use Cases and Examples** - At least 3 examples with JavaScript fetch code and curl commands
7. **Business Logic Details** - Explanation of core algorithms, execution flow, decision trees
8. **Error Handling** - All possible HTTP status codes with error message examples
9. **Key Classes** - Table of main classes with their responsibilities
10. **Dependencies** - External services, DAOs, utilities used
11. **Testing** - Test class names, manual testing with curl

**URL Format:** Always use `http://localhost:8080/bonita/API/extension/{endpoint}` (NEVER `API/extension/restApiName/`)

> For the complete README template with a filled-in example, read `references/readme-template.md`
> For a ready-to-copy template, use `assets/controller-readme-template.md`

---

## F.5. Testing Requirements (MANDATORY)

### F.5.1. Unit Tests

Every controller MUST have corresponding test classes:

```
src/test/java/com/bonitasoft/processbuilder/rest/api/
├── controller/{controllerName}/
│   ├── Abstract{ControllerName}Test.java   # Tests doHandle orchestration
│   └── {ControllerName}Test.java           # Tests execute() business logic
├── dto/parameter/
│   └── Param{ControllerName}Test.java      # Parameter DTO tests
└── dto/result/
    └── Result{ControllerName}Test.java     # Result DTO tests
```

**Minimum Test Coverage (5 scenarios):**

| Scenario | HTTP Status | What to Test |
|----------|-------------|--------------|
| Success | 200 OK | Valid params, correct result, pagination headers |
| Missing mandatory param | 400 Bad Request | `p` or `c` missing |
| Invalid param value | 400 Bad Request | Non-integer for `p`, invalid filter field |
| DAO/Service exception | 500 Internal Server Error | RuntimeException in execute() |
| License validation | 403 Forbidden | Invalid or expired license |

**Test Class Template:**

```java
package com.bonitasoft.processbuilder.rest.api.controller.myController;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import javax.servlet.http.HttpServletRequest;
import org.bonitasoft.web.extension.rest.RestAPIContext;
import org.bonitasoft.web.extension.rest.RestApiResponse;
import org.bonitasoft.web.extension.rest.RestApiResponseBuilder;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import com.bonitasoft.processbuilder.rest.api.dto.parameter.ParamMyController;
import com.bonitasoft.processbuilder.rest.api.dto.result.ResultMyController;
import com.bonitasoft.processbuilder.rest.api.exception.ValidationException;
import com.bonitasoft.processbuilder.rest.api.utils.LicenseValidator;

/**
 * Unit tests for AbstractMyController.
 *
 * @see AbstractMyController
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AbstractMyControllerTest {

    // Test constants
    private static final Integer TEST_PAGE_INDEX = 0;
    private static final Integer TEST_PAGE_SIZE = 10;
    private static final Long TEST_TOTAL_COUNT = 25L;
    private static final String TEST_VALIDATION_ERROR = "The required parameter 'p' is missing.";
    private static final String TEST_EXECUTION_ERROR = "Database connection failed";

    @Spy
    private TestableAbstractMyController controller;

    @Mock
    private HttpServletRequest httpRequest;

    @Mock
    private RestApiResponseBuilder responseBuilder;

    @Mock
    private RestAPIContext context;

    @Mock
    private RestApiResponse mockResponse;

    @BeforeEach
    void setUp() {
        LicenseValidator.enableTestMode();
        when(responseBuilder.withResponseStatus(any(Integer.class))).thenReturn(responseBuilder);
        when(responseBuilder.withResponse(any(String.class))).thenReturn(responseBuilder);
        when(responseBuilder.build()).thenReturn(mockResponse);
    }

    @AfterEach
    void tearDown() {
        LicenseValidator.disableTestMode();
    }

    @Test
    @DisplayName("should_return_200_OK_when_validation_and_execution_succeed")
    void should_return_200_OK_when_validation_and_execution_succeed() {
        // Given
        ParamMyController params = createTestParams();
        ResultMyController result = createTestResult();
        doReturn(params).when(controller).validateInputParameters(httpRequest);
        doReturn(result).when(controller).execute(context, params);

        // When
        RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

        // Then
        assertThat(response).isNotNull();
        verify(responseBuilder).withResponseStatus(eq(200));
    }

    @Test
    @DisplayName("should_return_400_BAD_REQUEST_when_validation_fails")
    void should_return_400_BAD_REQUEST_when_validation_fails() {
        // Given
        doThrow(new ValidationException(TEST_VALIDATION_ERROR))
            .when(controller).validateInputParameters(httpRequest);

        // When
        RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

        // Then
        assertThat(response).isNotNull();
        verify(responseBuilder).withResponseStatus(eq(400));
        verify(controller, never()).execute(any(), any());
    }

    @Test
    @DisplayName("should_return_500_INTERNAL_SERVER_ERROR_when_execution_fails")
    void should_return_500_INTERNAL_SERVER_ERROR_when_execution_fails() {
        // Given
        ParamMyController params = createTestParams();
        doReturn(params).when(controller).validateInputParameters(httpRequest);
        doThrow(new RuntimeException(TEST_EXECUTION_ERROR))
            .when(controller).execute(context, params);

        // When
        RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

        // Then
        assertThat(response).isNotNull();
        verify(responseBuilder).withResponseStatus(eq(500));
    }

    // --- Helper methods ---

    private ParamMyController createTestParams() {
        return new ParamMyController(TEST_PAGE_INDEX, TEST_PAGE_SIZE, new java.util.HashMap<>());
    }

    private ResultMyController createTestResult() {
        return ResultMyController.builder()
            .p(TEST_PAGE_INDEX).c(TEST_PAGE_SIZE)
            .total(TEST_TOTAL_COUNT).data(new java.util.ArrayList<>())
            .build();
    }

    /** Testable concrete implementation of the abstract class. */
    static class TestableAbstractMyController extends AbstractMyController {
        @Override
        protected ResultMyController execute(RestAPIContext ctx, ParamMyController p) {
            return ResultMyController.builder().build();
        }
        @Override
        protected ParamMyController validateInputParameters(HttpServletRequest req) {
            return new ParamMyController(0, 10, new java.util.HashMap<>());
        }
    }
}
```

### F.5.2. Property-Based Tests (jqwik)

For DTOs, add property-based tests to verify invariants across random inputs:

```java
package com.bonitasoft.processbuilder.rest.api.controller.myController;

import static org.assertj.core.api.Assertions.assertThat;

import net.jqwik.api.*;
import net.jqwik.api.constraints.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;

import com.bonitasoft.processbuilder.rest.api.dto.objects.MyEntityDTO;

/**
 * Property-based tests for MyEntityDTO using jqwik.
 */
@ExtendWith(MockitoExtension.class)
class MyEntityDTOPropertyTest {

    @Property
    void shouldProvideAccessorsForAllFields(
            @ForAll @LongRange(min = 1, max = Long.MAX_VALUE) Long id,
            @ForAll @StringLength(min = 1, max = 100) String name,
            @ForAll @StringLength(min = 1, max = 50) String status) {

        MyEntityDTO dto = new MyEntityDTO(id, name, status, null);

        assertThat(dto.getPersistenceId()).isEqualTo(id);
        assertThat(dto.getName()).isEqualTo(name);
        assertThat(dto.getStatus()).isEqualTo(status);
    }

    @Property
    void shouldImplementEqualsAndHashCodeCorrectly(
            @ForAll @LongRange(min = 1, max = 1000) Long id,
            @ForAll @StringLength(min = 1, max = 50) String name) {

        MyEntityDTO dto1 = new MyEntityDTO(id, name, "ACTIVE", null);
        MyEntityDTO dto2 = new MyEntityDTO(id, name, "ACTIVE", null);

        assertThat(dto1).isEqualTo(dto2);
        assertThat(dto1.hashCode()).isEqualTo(dto2.hashCode());
    }
}
```

---

## F.6. BDM Index Requirements

When using BDM queries in controllers:

1. **Check existing indexes** in `bom.xml` before adding new queries
2. **Index naming:** Maximum 20 characters
3. **Index fields:** Must match query `WHERE` clause fields
4. **Index pattern:** `idx_{table}_{field}` or `idx_{table}_{f1}_{f2}`
5. **Every finder MUST have a `countFor` counterpart** for pagination

**Example `bom.xml` index:**

```xml
<businessObject qualifiedName="com.processbuilder.model.PBProcess">
    <indexes>
        <index>
            <indexName>idxByProcStatus</indexName>
            <fieldNames>
                <fieldName>processId</fieldName>
                <fieldName>status</fieldName>
            </fieldNames>
        </index>
        <index>
            <indexName>idxByCreatorId</indexName>
            <fieldNames>
                <fieldName>creatorId</fieldName>
            </fieldNames>
        </index>
    </indexes>
    <queries>
        <query name="findByStatus" content="SELECT p FROM PBProcess p WHERE p.status = :status ORDER BY p.name ASC">
            <queryParameters>
                <queryParameter name="status" className="java.lang.String"/>
            </queryParameters>
        </query>
        <query name="countForFindByStatus" content="SELECT COUNT(p) FROM PBProcess p WHERE p.status = :status" returnType="java.lang.Long">
            <queryParameters>
                <queryParameter name="status" className="java.lang.String"/>
            </queryParameters>
        </query>
    </queries>
</businessObject>
```

---

## F.7. Controller Creation Checklist

Before marking a controller as complete, verify ALL items:

- [ ] **F.7.1** Abstract class with license validation and error handling
- [ ] **F.7.2** Concrete class with business logic implementation
- [ ] **F.7.3** Parameter DTO with `@Value` annotation
- [ ] **F.7.4** Result DTO with `@Value` + `@Builder` + `@JsonDeserialize` annotations
- [ ] **F.7.5** Object DTOs for entity representations (if new entities)
- [ ] **F.7.6** Field class with filter/order constants (if filtering/ordering is supported)
- [ ] **F.7.7** README.md with all 11 required sections
- [ ] **F.7.8** Abstract test class with minimum 5 test cases (200, 400x2, 500, flow order)
- [ ] **F.7.9** Concrete test class with business logic tests
- [ ] **F.7.10** Property-based test class for DTOs (jqwik, if applicable)
- [ ] **F.7.11** BDM indexes exist for all used queries + `countFor` queries
- [ ] **F.7.12** Javadoc on ALL public methods and classes

### Quality Gates

| Gate | Requirement |
|------|-------------|
| No magic strings | All strings via Constants/Field classes |
| Max method length | 25-30 lines per method |
| Assertions library | AssertJ only (NEVER native JUnit) |
| Test naming | `should_do_X_when_condition_Y` |
| Error messages | User-friendly, no internal details exposed |
| License check | Present in abstract class `doHandle()` |
| OpenAPI annotations | On abstract class `doHandle()` method |

---

## F.8. OpenAPI Documentation

Add OpenAPI annotations to the abstract class `doHandle()` method:

```java
@GET
@Path("/endpoint")
@Operation(
    summary = "Get entities by criteria",
    description = "Retrieves a paginated list of entities filtered by the given criteria. "
        + "Supports filtering by name and description, ordering by name or modification date.",
    tags = {"process-builder"},
    parameters = {
        @Parameter(in = ParameterIn.QUERY, name = "p",
            description = "Page index (0-based)", required = true,
            schema = @Schema(type = "integer", defaultValue = "0")),
        @Parameter(in = ParameterIn.QUERY, name = "c",
            description = "Items per page", required = true,
            schema = @Schema(type = "integer", defaultValue = "10")),
        @Parameter(in = ParameterIn.QUERY, name = "f",
            description = "Filter: f={field}={value}. Supported: 'name', 'description'.",
            required = false),
        @Parameter(in = ParameterIn.QUERY, name = "o",
            description = "Order: o={field} {ASC|DESC}. Supported: 'name', 'modificationDate'.",
            required = false)
    },
    responses = {
        @ApiResponse(responseCode = "200",
            description = "Successfully retrieved entities",
            content = @Content(mediaType = "application/json",
                schema = @Schema(implementation = ResultMyController.class))),
        @ApiResponse(responseCode = "400",
            description = "Invalid parameters (missing p/c, bad filter field, bad order)"),
        @ApiResponse(responseCode = "403",
            description = "License validation failed"),
        @ApiResponse(responseCode = "500",
            description = "Internal server error during execution")
    }
)
```

Additionally, update `doc/api/openapi.yaml` with the new endpoint specification if the project maintains a centralized OpenAPI file.

**URL convention for OpenAPI:**
```
http://localhost:8080/bonita/API/extension/{endpoint}
```
