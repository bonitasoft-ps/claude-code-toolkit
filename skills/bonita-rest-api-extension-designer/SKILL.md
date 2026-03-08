---
name: bonita-rest-api-extension-designer
description: "Design and scaffold Bonita REST API extensions with controllers, DTOs, tests, and documentation."
user_invocable: true
trigger_keywords: ["rest api", "api extension", "rest endpoint", "groovy api", "java api", "controller"]
---

# Bonita REST API Extension Designer

You are an expert in Bonita REST API extensions design and implementation.

## Two Implementation Approaches

### 1. Groovy-based (Legacy/Quick — UID projects)
- Single Groovy class implementing `RestApiController`
- Fast to develop, less structure
- Used with older UI Designer pages
- Package: ZIP with `page.properties` + compiled classes

### 2. Java-based (Modern/Structured — UIBuilder projects)
- Abstract controller + concrete implementation pattern
- DTOs for parameters and results (use Java Records or @Value)
- Service layer separation
- Full test coverage with JUnit 5 + Mockito + AssertJ
- OpenAPI annotations

## Project Structure (Java-based)

```
extensions/{apiName}/
  pom.xml
  src/
    main/java/com/{company}/rest/api/
      controller/
        {entityName}/
          Abstract{EntityName}Controller.java   # Request parsing, validation, error handling
          {EntityName}Controller.java           # Business logic implementation
          {EntityName}Field.java                # Field definitions (for filtering)
          README.md                             # Endpoint documentation
      dto/
        parameter/
          Param{EntityName}.java                # Request params (Record or @Value)
        result/
          Result{EntityName}.java               # Response DTO
        objects/
          {EntityName}DTO.java                  # Entity representation
      constants/
        Constants.java                          # Magic strings centralized
        Messages.java                           # Error messages
        Parameters.java                         # Parameter names
      exception/
        ValidationException.java
      utils/
        JsonResponseUtils.java                  # Shared response builder
    resources/
      page.properties                           # contentType=apiExtension
  src/test/java/...                             # Mirror of main structure
```

## Controller Pattern

### Abstract Controller (handles cross-cutting concerns)
```java
public abstract class AbstractEntityController extends RestApiController {
    @Override
    public RestApiResponse doHandle(HttpServletRequest request,
                                     RestApiResponseBuilder responseBuilder,
                                     RestAPIContext context) {
        // 1. License validation (if subscription)
        // 2. Parameter extraction and validation
        // 3. Call abstract execute() method
        // 4. Error handling (400, 500)
        return jsonResponse(responseBuilder, SC_OK, execute(context, params));
    }
    protected abstract ResultType execute(RestAPIContext context, ParamType params);
}
```

### Concrete Controller (business logic only)
```java
public class EntityController extends AbstractEntityController {
    @Override
    protected ResultType execute(RestAPIContext context, ParamType params) {
        var dao = context.getApiClient().getDAO(EntityDAO.class);
        var entities = dao.findByCondition(params.condition(),
                                           params.page() * params.count(),
                                           params.count());
        var total = dao.countForFindByCondition(params.condition());
        return new ResultType(params.page(), params.count(), total,
                             entities.stream().map(this::toDTO).toList());
    }
}
```

## Groovy Controller Pattern (simpler)
```groovy
class MyEndpoint implements RestApiController {
    @Override
    RestApiResponse doHandle(HttpServletRequest request,
                             RestApiResponseBuilder responseBuilder,
                             RestAPIContext context) {
        def p = request.getParameter("p") ?: "0"
        def c = request.getParameter("c") ?: "10"
        def dao = context.apiClient.getDAO(EntityDAO.class)
        def results = dao.findAll(p as int * c as int, c as int)
        return buildResponse(responseBuilder, 200, new JsonBuilder(results).toString())
    }
}
```

## Pagination Pattern (CRITICAL)
Every list endpoint MUST support pagination:
- Parameters: `p` (page, 0-indexed), `c` (count per page)
- Response includes: `p`, `c`, `total` (from countFor query)
- BDM query offset = `p * c`, limit = `c`
- countFor query is MANDATORY for every List query in BDM

## DTO Design (Java 17)
```java
// Parameter DTO — immutable
public record ParamEntity(int page, int count, Long entityId, String status) {}

// Result DTO — with pagination
public record ResultEntity(int p, int c, long total, List<EntityDTO> data) {}

// Entity DTO — BDM to API mapping
public record EntityDTO(Long persistenceId, String name, String status,
                        OffsetDateTime createdAt) {}
```

## page.properties (required in ZIP)
```properties
name=custompage_{apiName}
displayName={API Display Name}
description={API Description}
contentType=apiExtension
apiExtensions={endpoint1}|{endpoint2}
{endpoint1}.method=GET
{endpoint1}.pathTemplate={apiName}/{path}
{endpoint1}.classFileName={ControllerClass}.groovy
{endpoint1}.permissions=demoPermission
```

## Testing Requirements
- Framework: JUnit 5 + Mockito 5 + AssertJ
- Annotations: @ExtendWith(MockitoExtension.class)
- Mock: HttpServletRequest, RestAPIContext, RestApiResponseBuilder
- Minimum scenarios per controller:
  - Success (200 OK)
  - Missing mandatory parameter (400)
  - Invalid parameter value (400)
  - DAO/Service exception (500)
- Naming: should_returnEntities_when_validParameters()

## Consolidation Rule
Group related endpoints into a SINGLE REST API extension:
- All entity CRUD operations in one extension
- Separate extensions only for truly different domains
- Reduces deployment complexity and improves code reuse

## Security
- Validate all input parameters
- Use constants for parameter names (no magic strings)
- Never expose internal errors to client
- Use Bonita permissions system (page.properties permissions)

## BDM Index Requirement
When using BDM queries in controllers:
- Check existing indexes in bom.xml
- Index name max 20 characters
- Index naming: idx_{table}_{field}
- Match index fields to WHERE clause fields

## MCP Tools
- `generate_rest_api_extension` — Scaffold complete REST API extension
- `generate_rest_controller` — Generate controller pair (abstract + concrete)
- `generate_rest_dto` — Generate parameter/result/entity DTOs
- `validate_rest_api` — Validate extension structure and conventions
