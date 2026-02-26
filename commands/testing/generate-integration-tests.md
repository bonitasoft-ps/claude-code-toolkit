# Generate Integration Tests for a REST API Controller

Generate comprehensive integration-style tests for a Bonita REST API controller, testing the full request lifecycle through `doHandle()`.

## Arguments
- `$ARGUMENTS`: controller class name, file path, or module name

## Instructions

1. **Find the controller** source file and its Abstract parent class
2. **Read existing test patterns** in the module's `src/test/java/` to match conventions
3. **Identify the request lifecycle**:
   - What `doHandle()` does (license check, validation, execution, error handling)
   - What `validateInputParameters()` expects (required/optional params)
   - What `execute()` returns (DTOs, paginated results, single objects)
   - What exceptions are thrown and how they map to HTTP status codes
4. **Generate the integration test class** following this structure:

```java
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
@DisplayName("ControllerName - Integration Tests")
class ControllerNameTest {

    // I. Constants for all test data
    private static final Long TEST_PERSISTENCE_ID = 123L;
    private static final String TEST_PARAM_VALUE = "test-value";

    // II. Mocks for Bonita infrastructure
    @Mock private HttpServletRequest request;
    @Mock private RestApiResponseBuilder responseBuilder;
    @Mock private RestAPIContext context;
    @Mock private APIClient apiClient;
    // ... domain-specific DAOs and APIs

    // III. Controller under test (@Spy if concrete, @InjectMocks otherwise)
    @Spy private ControllerName controller;

    @BeforeEach
    void setUp() {
        // Setup response builder chain
        when(responseBuilder.withResponseStatus(any(Integer.class))).thenReturn(responseBuilder);
        when(responseBuilder.withResponse(anyString())).thenReturn(responseBuilder);
        when(responseBuilder.build()).thenReturn(mock(RestApiResponse.class));
        // Setup context → apiClient → DAO/API chain
        when(context.getApiClient()).thenReturn(apiClient);
    }

    // IV. @Nested test groups
    @Nested @DisplayName("doHandle - Full Request Lifecycle")
    class DoHandle { /* 200 OK, 400 Bad Request, 404 Not Found, 500 Error */ }

    @Nested @DisplayName("validateInputParameters")
    class ValidateInputParameters { /* required params, optional params, invalid values */ }

    @Nested @DisplayName("execute - Business Logic")
    class Execute { /* happy path, edge cases, empty results, exceptions */ }
}
```

5. **Test ALL HTTP paths**:
   - `200 OK` — successful execution with valid data
   - `400 Bad Request` — missing required parameters, invalid values
   - `403 Forbidden` — license/access validation failure (if applicable)
   - `404 Not Found` — resource not found
   - `500 Internal Server Error` — unexpected exception during execution
6. **Test edge cases**:
   - Empty collections, null optional parameters
   - Pagination boundaries (p=0, c=0, large offsets)
   - Filter/search text as null vs empty string
7. **Use constants** for ALL test data (no inline magic strings/numbers)
8. **Run the tests**: `mvn test -f extensions/pom.xml -Dtest=ControllerNameTest`
9. **Fix failures** and re-run until green
