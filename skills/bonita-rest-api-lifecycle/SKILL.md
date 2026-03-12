---
name: bonita-rest-api-lifecycle
description: |
  Complete lifecycle for REST API Extensions: spec → document → publish/save →
  validate → implement → test → build → deploy → update docs → deliver.
  Covers RestApiController, DTOs, OpenAPI, permissions, page.properties.
  Trigger: "create REST API", "REST extension", "API extension", "rest api lifecycle"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, mcp__claude_ai_Atlassian_2__createConfluencePage, mcp__claude_ai_Atlassian_2__updateConfluencePage, mcp__Bonita-AI-Agent__build_pdf
user_invocable: true
---

# Bonita REST API Extension Lifecycle — Documentation-First

## Lifecycle
```
SPEC → DOCUMENT → CHOOSE DESTINATION → VALIDATE ✓ → IMPLEMENT → TEST → BUILD → DEPLOY → UPDATE DOC → DELIVER
```

## Phase 1: SPEC
Ask the user:
- API name and base path
- Endpoints: method, path, description, parameters, request/response body
- DTOs: fields, types, validation
- Security: required permissions, profiles
- Data sources: BDM queries, process data, external APIs
- Bonita version

## Phase 2-4: DOCUMENT → PUBLISH → VALIDATE
Generate API spec with endpoints, DTOs, security. Use `confluence-publish-workflow`.

## Phase 5: IMPLEMENT

### Project Structure
```
rest-api-extension/
├── pom.xml
├── src/main/
│   ├── groovy/          # or java/
│   │   └── com/bonitasoft/ps/api/
│   │       ├── IndexController.groovy    # Main controller
│   │       ├── dto/                      # DTO Records
│   │       └── service/                  # Business logic
│   └── resources/
│       └── page.properties              # Endpoint mapping
└── src/test/
    ├── groovy/          # Unit tests
    └── resources/       # Test fixtures
```

### Controller Pattern
```groovy
class IndexController implements RestApiController {
    @Override
    RestApiResponse doHandle(HttpServletRequest request,
                             RestApiResponseBuilder responseBuilder,
                             RestAPIContext context) {
        // Extract parameters
        // Call business logic
        // Return JSON response
        return responseBuilder
            .withResponseStatus(HttpServletResponse.SC_OK)
            .withResponse(new ObjectMapper().writeValueAsString(result))
            .build()
    }
}
```

### page.properties
```properties
name=customRestAPI
displayName=Custom REST API
description=Custom REST API Extension
apiExtensions=GET|extension/myapi,POST|extension/myapi
GET|extension/myapi.classname=com.bonitasoft.ps.api.GetController
GET|extension/myapi.permissions=myapi_read
POST|extension/myapi.classname=com.bonitasoft.ps.api.PostController
POST|extension/myapi.permissions=myapi_write
```

### DTO with Records
```java
public record UserDTO(long id, String name, String email) {}
```

## Phase 6: TEST
- **Unit**: JUnit 5 + Mockito for RestAPIContext
- **Property**: jqwik for input parameter fuzzing
- **Mutation**: PIT on business logic
- **Integration**: REST Assured against running Bonita

## Phase 7: BUILD
```bash
mvn clean package -B
```
Produces ZIP with page.properties + JARs.

## Phase 8: DEPLOY
Upload REST API extension via Bonita Portal or REST API.

## Phase 9-10: UPDATE DOC → DELIVER
Update spec with actual endpoints, test results. Generate PDF if needed.
