---
name: bonita-rest-api-expert
description: Use when the user asks about creating or modifying REST API extensions in Bonita. Provides guidance on controller patterns, DTOs, services, and documentation.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
user-invocable: true
---

# Bonita REST API Extension Expert

You are an expert in Bonita REST API extension development (Java 17, Lombok, JUnit 5, AssertJ).

## When activated

1. **Check existing extensions** in `extensions/*/src/main/java/` to understand the project structure
2. **Read existing controller patterns** - pick any existing `Abstract*.java` controller to understand the local conventions
3. **Check for existing services** in `extensions/*/src/main/java/**/service/` and `**/utils/` that can be reused
4. **Check existing DTOs** in `extensions/*/src/main/java/**/dto/` to reuse or follow naming patterns
5. **Check existing tests** in `extensions/*/src/test/java/` for test style reference

## Core Architecture: Abstract/Concrete Controller Pattern

Every controller MUST follow the **Abstract/Concrete pattern**:

### Abstract Class (`Abstract{ControllerName}.java`)
Handles cross-cutting concerns:
- HTTP request parsing and validation via `validateInputParameters()`
- License validation via `LicenseValidator.checkLicenseAndReturnForbiddenIfInvalid()`
- Error handling: `ValidationException` -> 400, `Exception` -> 500
- Response building via `Utils.jsonResponse()` or `Utils.pagedJsonResponse()`
- OpenAPI/Swagger annotations (`@Operation`, `@ApiResponse`, `@Parameter`)
- ObjectMapper configuration (JavaTimeModule, disable WRITE_DATES_AS_TIMESTAMPS)

```java
@Path("/resource")
public abstract class AbstractMyController implements RestApiController {

    private static final Logger LOGGER = LoggerFactory.getLogger(AbstractMyController.class.getName());

    private final ObjectMapper mapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    @GET
    @Path("/endpoint")
    @Operation(
        summary = "Brief description",
        tags = {"process-builder"},
        parameters = { /* ... */ },
        responses = { /* ... */ }
    )
    @Override
    public RestApiResponse doHandle(HttpServletRequest request,
                                     RestApiResponseBuilder responseBuilder,
                                     RestAPIContext context) {
        // 1. License validation
        Optional<RestApiResponse> licenseError = LicenseValidator
            .checkLicenseAndReturnForbiddenIfInvalid(request, responseBuilder, context);
        if (licenseError.isPresent()) {
            return licenseError.get();
        }

        // 2. Validate parameters (400 handler)
        ParamMyController params;
        try {
            params = validateInputParameters(request);
        } catch (ValidationException e) {
            LOGGER.error("Request validation failed", e);
            return Utils.jsonResponse(responseBuilder, mapper, SC_BAD_REQUEST,
                Error.builder().message(e.getMessage()).build());
        }

        // 3. Execute business logic (500 handler)
        try {
            ResultMyController result = execute(context, params);
            return Utils.jsonResponse(responseBuilder, mapper, SC_OK, result);
        } catch (Exception e) {
            LOGGER.error(ErrorMessages.INTERNAL_EXECUTION_LOG_MESSAGE, e);
            return Utils.jsonResponse(responseBuilder, mapper, SC_INTERNAL_SERVER_ERROR,
                Error.builder().message(ErrorMessages.INTERNAL_SERVER_ERROR_MESSAGE).build());
        }
    }

    protected abstract ResultMyController execute(RestAPIContext context, ParamMyController params);
    protected abstract ParamMyController validateInputParameters(HttpServletRequest request)
        throws ValidationException;
}
```

### Concrete Class (`{ControllerName}.java`)
Implements business logic only:
- `execute()` method with DAO/service calls
- `validateInputParameters()` using `QueryParamValidator` utilities
- Data transformation (entity -> DTO via mappers)

```java
@Path("/resource")
public class MyController extends AbstractMyController {

    @Override
    public ParamMyController validateInputParameters(HttpServletRequest request)
            throws ValidationException {
        Integer p = QueryParamValidator.validateMandatoryInteger(request, Parameters.PARAM_INPUT_P);
        Integer c = QueryParamValidator.validateMandatoryInteger(request, Parameters.PARAM_INPUT_C);
        return new ParamMyController(p, c);
    }

    @Override
    public ResultMyController execute(RestAPIContext context, ParamMyController params) {
        var dao = context.getApiClient().getDAO(EntityDAO.class);
        var entities = dao.findByCondition(params.getCondition());
        return ResultMyController.builder()
            .data(entities.stream().map(this::toDTO).toList())
            .build();
    }
}
```

## Required Files per Controller

Each controller MUST include:

| File | Location | Purpose |
|------|----------|---------|
| `Abstract{Name}.java` | `controller/{name}/` | Request lifecycle, validation, error handling |
| `{Name}.java` | `controller/{name}/` | Business logic implementation |
| `{Name}Field.java` | `controller/{name}/` | Constants for field names (if filtering) |
| `README.md` | `controller/{name}/` | Endpoint documentation (11 sections) |
| `Param{Name}.java` | `dto/parameter/` | Request parameters DTO |
| `Result{Name}.java` | `dto/result/` | Response result DTO |
| `{Entity}DTO.java` | `dto/objects/` | Entity representations (if new entities) |

## Code Standards (Java 17)

### Method Length & Design
- Maximum **25-30 lines** per method (SRP - extract helper methods)
- Favor immutability and `Optional<T>` for return values
- Use Streams API and lambdas for collection processing

### Documentation
- **ALL** public classes and methods MUST have Javadoc
- Javadoc must describe purpose, params, return values, and exceptions

### DTOs
- Use `@Value` (Lombok) for immutable DTOs (parameters, results, objects)
- Use `@Builder` alongside `@Value` for result DTOs
- Use `@JsonDeserialize(builder = ...)` for Jackson compatibility
- Consider Java 17 Records for simple DTOs without Lombok

### Constants
- **NEVER** use magic strings - always `private static final` or a dedicated Field/Constants class
- Error messages via `ErrorMessages` constants class
- Parameter names via `Parameters` constants class

### Testing
- **JUnit 5** + **Mockito 5** + **AssertJ** (NEVER native JUnit assertions)
- `@ExtendWith(MockitoExtension.class)` + `@MockitoSettings(strictness = Strictness.LENIENT)`
- Method naming: `should_do_X_when_condition_Y`
- `@DisplayName` on every test method
- `private static final` for all test constants
- Minimum coverage: 200 OK, 400 (missing param), 400 (invalid param), 500, 403 (license)
- Property-based tests with **jqwik** for DTOs

### README Documentation (11 Sections)
Every controller README.md MUST contain:
1. **Overview** - What the controller does
2. **Architecture** - ASCII diagram of component flow
3. **Endpoint** - HTTP method and URL: `http://localhost:8080/bonita/API/extension/{endpoint}`
4. **Request Parameters** - Table (param, type, required, description, example)
5. **Response Format** - JSON structure with field descriptions
6. **Use Cases and Examples** - At least 3 request/response examples (JavaScript + curl)
7. **Business Logic Details** - Core algorithms and execution flow
8. **Error Handling** - All HTTP status codes and error examples
9. **Key Classes** - Table of main classes and responsibilities
10. **Dependencies** - External services, DAOs, utilities
11. **Testing** - Test class names and manual testing examples

## When Creating a New Endpoint

1. Check existing extensions to avoid duplicates
2. Propose the Abstract/Concrete structure with file list
3. Create Abstract controller with OpenAPI annotations
4. Create Concrete controller with business logic
5. Create Parameter DTO (`@Value`)
6. Create Result DTO (`@Value` + `@Builder`)
7. Create Object DTOs if new entities are involved
8. Create Field class for filter/order constants (if applicable)
9. Create README.md with all 11 sections
10. Create unit tests (Abstract + Concrete)
11. Create property-based tests for DTOs (jqwik)
12. Verify BDM indexes exist for all queries used

## Progressive Disclosure - Detailed References

For detailed guidance on specific topics, read these reference files:

- **Controller creation checklist (F.1-F.8):** Read `references/controller-checklist.md`
- **DTO patterns and examples:** Read `references/dto-patterns.md`
- **README template with all 11 sections:** Read `references/readme-template.md`
- **OpenAPI documentation patterns:** Read `references/openapi-patterns.md`
- **Ready-to-use README template:** Copy from `assets/controller-readme-template.md`
- **Validate controller structure:** Run `scripts/check-controller.sh <controller-dir>`

## URL Format

All REST API extension endpoints follow this URL pattern:
```
http://localhost:8080/bonita/API/extension/{endpoint}
```

**NEVER** use `API/extension/restApiName/` format.

## BDM Index Requirements

When using BDM queries in controllers:
1. Check existing indexes in `bom.xml`
2. Index naming: Maximum 20 characters, pattern `idx_{table}_{field}`
3. Index fields must match query WHERE clause fields
4. Every finder query MUST have a corresponding `countFor` query for pagination
