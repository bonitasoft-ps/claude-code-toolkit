# Bonita Test Harness: Mock Environment Setup

This reference provides detailed guidance on setting up the complete Bonita mock environment for integration testing of REST API extension controllers.

## Table of Contents

1. [APIClient Mock Chain](#apiclient-mock-chain)
2. [ProcessAPI Mocking](#processapi-mocking)
3. [IdentityAPI Mocking](#identityapi-mocking)
4. [BDM DAO Mocking](#bdm-dao-mocking)
5. [LicenseValidator Test Mode](#licensevalidator-test-mode)
6. [TechnicalUserValidator Mocking](#technicaluservalidator-mocking)
7. [ObjectMapper Configuration](#objectmapper-configuration)
8. [RestApiResponseBuilder Chain Setup](#restapiresponsebuilder-chain-setup)
9. [Common Bonita Exceptions](#common-bonita-exceptions)
10. [Static Method Mocking with MockedStatic](#static-method-mocking)

---

## APIClient Mock Chain

The core dependency chain in Bonita REST API extensions flows from `RestAPIContext` through `APIClient` to specific APIs and DAOs.

### Complete Chain Setup

```java
// =========================================================================
// Mock declarations
// =========================================================================
@Mock
private RestAPIContext context;

@Mock
private APIClient apiClient;

@Mock
private APISession apiSession;

@Mock
private ProcessAPI processAPI;

@Mock
private IdentityAPI identityAPI;

@Mock
private MyEntityDAO myEntityDAO;

// =========================================================================
// @BeforeEach chain setup
// =========================================================================
@BeforeEach
void setUp() {
    // Context -> APIClient
    when(context.getApiClient()).thenReturn(apiClient);

    // Context -> APISession (for user identity)
    when(context.getApiSession()).thenReturn(apiSession);
    when(apiSession.getUserId()).thenReturn(TEST_USER_ID);
    when(apiSession.getUserName()).thenReturn(TEST_USERNAME);

    // APIClient -> Engine APIs
    when(apiClient.getProcessAPI()).thenReturn(processAPI);
    when(apiClient.getIdentityAPI()).thenReturn(identityAPI);

    // APIClient -> BDM DAOs
    when(apiClient.getDAO(MyEntityDAO.class)).thenReturn(myEntityDAO);
}
```

### Important: Cast for APIClient

In some project configurations, the `getApiClient()` return type requires casting:

```java
// If your project has this pattern:
when(context.getApiClient()).thenReturn((APIClient) apiClient);
```

### Multiple DAOs

When a controller accesses multiple BDM DAOs, declare and configure each one:

```java
@Mock
private PBProcessDAO pbProcessDAO;

@Mock
private PBProcessInstanceDAO pbProcessInstanceDAO;

@Mock
private PBStepDAO pbStepDAO;

@BeforeEach
void setUp() {
    when(apiClient.getDAO(PBProcessDAO.class)).thenReturn(pbProcessDAO);
    when(apiClient.getDAO(PBProcessInstanceDAO.class)).thenReturn(pbProcessInstanceDAO);
    when(apiClient.getDAO(PBStepDAO.class)).thenReturn(pbStepDAO);
}
```

---

## ProcessAPI Mocking

### Common ProcessAPI Methods

```java
// Get a process instance
when(processAPI.getProcessInstance(TEST_PROCESS_INSTANCE_ID))
    .thenReturn(mockProcessInstance);

// Get process definition
when(processAPI.getProcessDefinition(TEST_PROCESS_DEFINITION_ID))
    .thenReturn(mockProcessDefinition);

// Search human tasks
@SuppressWarnings("unchecked")
SearchResult<HumanTaskInstance> searchResult = mock(SearchResult.class);
when(searchResult.getResult()).thenReturn(List.of(mockTask1, mockTask2));
when(searchResult.getCount()).thenReturn(2L);
when(processAPI.searchHumanTaskInstances(any(SearchOptions.class)))
    .thenReturn(searchResult);

// Send a message
when(processAPI.sendMessage(
    any(String.class),       // messageName
    any(Expression.class),   // targetProcess
    any(Expression.class),   // targetFlowNode
    any(Map.class),          // messageContent
    any(Map.class)           // correlations
)).thenReturn(/* void */);

// Cancel process instance
doNothing().when(processAPI).cancelProcessInstance(TEST_PROCESS_INSTANCE_ID);
```

### ProcessInstance State Mocking

```java
@Mock
private ProcessInstance mockBpmProcessInstance;

// Different states for different test scenarios
when(mockBpmProcessInstance.getState()).thenReturn("started");        // Running
when(mockBpmProcessInstance.getState()).thenReturn("completed");      // Completed
when(mockBpmProcessInstance.getState()).thenReturn("CANCELLED");      // Cancelled
when(mockBpmProcessInstance.getState()).thenReturn("ABORTED");        // Aborted
when(mockBpmProcessInstance.getId()).thenReturn(TEST_PROCESS_INSTANCE_ID);
when(mockBpmProcessInstance.getName()).thenReturn(TEST_PROCESS_NAME);
```

---

## IdentityAPI Mocking

### User Retrieval

```java
@Mock
private User mockUser;

when(mockUser.getId()).thenReturn(TEST_USER_ID);
when(mockUser.getUserName()).thenReturn(TEST_USERNAME);
when(mockUser.getFirstName()).thenReturn(TEST_FIRST_NAME);
when(mockUser.getLastName()).thenReturn(TEST_LAST_NAME);

when(identityAPI.getUser(TEST_USER_ID)).thenReturn(mockUser);
when(identityAPI.getUserByUserName(TEST_USERNAME)).thenReturn(mockUser);
```

### Role and Group

```java
@Mock
private Role mockRole;

@Mock
private Group mockGroup;

when(identityAPI.getRoleByName("manager")).thenReturn(mockRole);
when(identityAPI.getGroupByPath("/acme/sales")).thenReturn(mockGroup);
```

---

## BDM DAO Mocking

### Standard DAO Methods

BDM DAO interfaces follow a standard pattern with `findBy*`, `countForFindBy*`, and `findByPersistenceId` methods.

```java
@Mock
private PBProcessDAO pbProcessDAO;

@Mock
private PBProcess mockPBProcess;

// findByPersistenceId
when(pbProcessDAO.findByPersistenceId(TEST_PERSISTENCE_ID))
    .thenReturn(mockPBProcess);

// findByPersistenceId returning null (entity not found)
when(pbProcessDAO.findByPersistenceId(999L))
    .thenReturn(null);

// Paginated finder
when(pbProcessDAO.find(0, 10))
    .thenReturn(List.of(mockPBProcess1, mockPBProcess2));

// Count query
when(pbProcessDAO.countForFind())
    .thenReturn(25L);

// Finder with filters
when(pbProcessDAO.findByStatus("active", 0, 10))
    .thenReturn(List.of(mockPBProcess));
when(pbProcessDAO.countForFindByStatus("active"))
    .thenReturn(1L);
```

### BDM Entity Field Mocking

```java
@Mock
private PBProcessInstance mockPBProcessInstance;

when(mockPBProcessInstance.getPersistenceId()).thenReturn(TEST_PERSISTENCE_ID);
when(mockPBProcessInstance.getPersistenceId_string()).thenReturn(TEST_PERSISTENCE_ID.toString());
when(mockPBProcessInstance.getProcessInstanceId()).thenReturn(TEST_PROCESS_INSTANCE_ID);
when(mockPBProcessInstance.getProcessStatus()).thenReturn("running");
when(mockPBProcessInstance.getProcessName()).thenReturn(TEST_PROCESS_NAME);
when(mockPBProcessInstance.getStartDate()).thenReturn(LocalDate.now());
```

### DAO Access Pattern Through APIClient

The critical pattern: controllers access DAOs via `context.getApiClient().getDAO(DaoClass.class)`:

```java
// In @BeforeEach:
when(context.getApiClient()).thenReturn(apiClient);
when(apiClient.getDAO(PBProcessDAO.class)).thenReturn(pbProcessDAO);

// The controller does this internally:
// PBProcessDAO dao = context.getApiClient().getDAO(PBProcessDAO.class);
// List<PBProcess> results = dao.findByStatus(status, offset, limit);
```

---

## LicenseValidator Test Mode

`LicenseValidator` is a static utility that validates the Bonita license before allowing controller access. In test mode, it returns `Optional.empty()` (no error), bypassing the license check.

### Standard Pattern

```java
@BeforeEach
void setUp() {
    LicenseValidator.enableTestMode();    // MUST be first
    // ... other setup
}

@AfterEach
void tearDown() {
    LicenseValidator.disableTestMode();   // MUST be called to prevent state leak
}
```

### Testing License Failure (403 Forbidden)

```java
@Test
@DisplayName("should return 403 when license is invalid")
void should_return_403_when_license_is_invalid() {
    // Given - disable test mode to simulate real license check
    LicenseValidator.disableTestMode();

    // When
    RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

    // Then
    assertThat(response).isNotNull();
    verify(controller, never()).execute(any(), any());
    // Note: the exact status verification depends on how the controller handles the license
}
```

### Why Both Enable AND Disable

- **`enableTestMode()`**: Without this, every test gets 403 Forbidden because there is no real Bonita license in the test environment
- **`disableTestMode()`**: Without this, test mode "leaks" to other test classes running in the same JVM, masking real license issues

---

## TechnicalUserValidator Mocking

For controllers in the `developerIntegrationRestAPI` module that use `TechnicalUserValidator.validateTechnicalAccess()`:

### Granting Access (Most Tests)

```java
@Test
void should_return_200_when_technical_user_is_valid() {
    try (MockedStatic<TechnicalUserValidator> validatorMock =
            mockStatic(TechnicalUserValidator.class)) {

        validatorMock.when(() -> TechnicalUserValidator.validateTechnicalAccess(
                any(RestAPIContext.class),
                any(RestApiResponseBuilder.class),
                any(ObjectMapper.class)))
            .thenReturn(Optional.empty());  // Access granted

        // Test the controller normally
        RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);
        assertThat(response).isNotNull();
    }
}
```

### Testing Access Denial (401/403)

```java
@Test
void should_return_401_when_user_is_not_authenticated() {
    try (MockedStatic<TechnicalUserValidator> validatorMock =
            mockStatic(TechnicalUserValidator.class)) {

        RestApiResponse forbiddenResponse = mock(RestApiResponse.class);
        validatorMock.when(() -> TechnicalUserValidator.validateTechnicalAccess(
                any(), any(), any()))
            .thenReturn(Optional.of(forbiddenResponse));  // Access denied

        RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

        assertThat(response).isSameAs(forbiddenResponse);
        verify(controller, never()).execute(any(), any());
    }
}
```

---

## ObjectMapper Configuration

The standard ObjectMapper configuration used across controllers:

```java
private final ObjectMapper mapper = new ObjectMapper()
    .registerModule(new JavaTimeModule())
    .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
```

### In Tests

When you need to verify JSON output or test serialization:

```java
private static final ObjectMapper TEST_MAPPER = new ObjectMapper()
    .registerModule(new JavaTimeModule())
    .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

@Test
void should_return_configured_ObjectMapper_with_JavaTimeModule() {
    ObjectMapper mapper = controller.getMapper();

    assertThat(mapper).isNotNull();
    assertThat(mapper.getRegisteredModuleIds())
        .contains(new JavaTimeModule().getTypeId());
}

@Test
void should_disable_WRITE_DATES_AS_TIMESTAMPS_in_ObjectMapper() {
    ObjectMapper mapper = controller.getMapper();

    assertThat(mapper.isEnabled(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS))
        .isFalse();
}
```

---

## RestApiResponseBuilder Chain Setup

The response builder uses a **fluent builder pattern** where every method returns `this`. In tests, you must configure every method in the chain to return the mock itself.

### Complete Chain Configuration

```java
@Mock
private RestApiResponseBuilder responseBuilder;

@Mock
private RestApiResponse mockResponse;

@BeforeEach
void setUp() {
    // Each method returns the builder for chaining
    when(responseBuilder.withResponseStatus(any(Integer.class))).thenReturn(responseBuilder);
    when(responseBuilder.withResponse(any(String.class))).thenReturn(responseBuilder);
    when(responseBuilder.withMediaType(any(String.class))).thenReturn(responseBuilder);
    when(responseBuilder.withContentRange(
        any(Integer.class), any(Integer.class), any(Long.class)))
        .thenReturn(responseBuilder);
    when(responseBuilder.withAdditionalHeader(any(String.class), any(String.class)))
        .thenReturn(responseBuilder);
    when(responseBuilder.build()).thenReturn(mockResponse);
}
```

### Why This Matters

Without this setup, any `responseBuilder.withResponseStatus(200).withResponse(json)` call returns `null` at the second method call, causing a `NullPointerException` in the controller code.

### Verifying Response Builder Interactions

```java
// Verify specific status code
verify(responseBuilder).withResponseStatus(eq(200));

// Verify response body was set
verify(responseBuilder).withResponse(any(String.class));

// Verify pagination headers
verify(responseBuilder).withContentRange(
    eq(TEST_PAGE_INDEX), eq(TEST_PAGE_SIZE), eq(TEST_TOTAL_COUNT));

// Verify execution order
var inOrder = Mockito.inOrder(controller, responseBuilder);
inOrder.verify(controller).validateInputParameters(httpRequest);
inOrder.verify(controller).execute(context, params);
inOrder.verify(responseBuilder).withResponseStatus(eq(200));
```

---

## Common Bonita Exceptions

These exceptions are commonly thrown by Bonita APIs and should be tested:

### Engine Exceptions

| Exception | API | HTTP Status | Test Scenario |
|-----------|-----|-------------|---------------|
| `ProcessInstanceNotFoundException` | ProcessAPI | 400/404 | Process instance ID does not exist |
| `ProcessDefinitionNotFoundException` | ProcessAPI | 400/404 | Process definition not deployed |
| `ContractViolationException` | ProcessAPI | 400 | Invalid contract input when starting process |
| `ProcessActivationException` | ProcessAPI | 400 | Process is disabled |
| `ProcessExecutionException` | ProcessAPI | 500 | Process start/execution failed |
| `ExecutionException` | Engine | 400/500 | General execution failure |
| `UserNotFoundException` | IdentityAPI | 404 | User ID does not exist |
| `SearchException` | Any search API | 500 | Search query failed |
| `ArchivedProcessInstanceNotFoundException` | ProcessAPI | 404 | Archived instance not found |

### Application Exceptions

| Exception | Source | HTTP Status | Test Scenario |
|-----------|--------|-------------|---------------|
| `ValidationException` | Custom | 400 | Parameter validation failed |
| `RuntimeException` | Any | 500 | Unexpected error during execution |
| `NullPointerException` | Any | 500 | Null reference in data |
| `IllegalStateException` | Any | 500 | Invalid state transition |
| `IllegalArgumentException` | Any | 500 | Invalid method argument |
| `NumberFormatException` | Parsing | 400 | Non-numeric parameter value |

### Testing Exception Scenarios

```java
// ProcessInstanceNotFoundException
when(processAPI.getProcessInstance(TEST_PROCESS_INSTANCE_ID))
    .thenThrow(new ProcessInstanceNotFoundException(TEST_PROCESS_INSTANCE_ID));

// ContractViolationException
when(processAPI.startProcessWithInputs(any(), any()))
    .thenThrow(new ContractViolationException(
        "Contract violation", "field1", List.of("field1 is required")));

// ExecutionException
doThrow(new ExecutionException("SQL query failed"))
    .when(controller).execute(eq(context), any());

// ValidationException (thrown from validateInputParameters)
doThrow(new ValidationException("Parameter 'p' must be a valid integer"))
    .when(controller).validateInputParameters(httpRequest);
```

---

## Static Method Mocking

Some utility classes in the project use static methods. Use `MockedStatic` to mock them.

### Utils.getQuery() Pattern

```java
@Test
void should_execute_query_when_parameters_are_valid() {
    try (MockedStatic<Utils> utilsMock = mockStatic(Utils.class)) {
        utilsMock.when(() -> Utils.getQuery(anyString(), any(RestAPIContext.class)))
            .thenReturn("SELECT * FROM customer WHERE status = :status");

        utilsMock.when(() -> Utils.getSqlParameters(any(), anyMap()))
            .thenReturn(Map.of("status", "active"));

        utilsMock.when(() -> Utils.buildSql(any(), anyString()))
            .thenReturn(mockSql);

        RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

        assertThat(response).isNotNull();
    }
}
```

### QueryParamValidator Static Methods

```java
@Test
void should_validate_mandatory_integer_parameter() {
    try (MockedStatic<QueryParamValidator> validatorMock =
            mockStatic(QueryParamValidator.class)) {

        validatorMock.when(() -> QueryParamValidator.validateMandatoryInteger(
                eq(httpRequest), eq("p")))
            .thenReturn(0);

        validatorMock.when(() -> QueryParamValidator.validateMandatoryInteger(
                eq(httpRequest), eq("c")))
            .thenReturn(10);

        var params = controller.validateInputParameters(httpRequest);

        assertThat(params.getP()).isZero();
        assertThat(params.getC()).isEqualTo(10);
    }
}
```

### Important: MockedStatic Scope

`MockedStatic` MUST be used within a try-with-resources block to ensure proper cleanup:

```java
// CORRECT: try-with-resources ensures cleanup
try (MockedStatic<Utils> utilsMock = mockStatic(Utils.class)) {
    // Mock is active here
    utilsMock.when(() -> Utils.getQuery(any(), any())).thenReturn("SELECT 1");
    controller.doHandle(httpRequest, responseBuilder, context);
}
// Mock is automatically cleaned up here

// WRONG: Manual management is error-prone
MockedStatic<Utils> utilsMock = mockStatic(Utils.class);
// If an exception occurs, the mock is never closed!
```

### Multiple Static Mocks

When you need to mock multiple static classes, nest them:

```java
try (MockedStatic<Utils> utilsMock = mockStatic(Utils.class);
     MockedStatic<JsonResponseUtils> jsonMock = mockStatic(JsonResponseUtils.class)) {

    utilsMock.when(() -> Utils.getQuery(any(), any())).thenReturn("SELECT 1");
    jsonMock.when(() -> JsonResponseUtils.jsonResponse(any(), any(), any()))
        .thenReturn(mock(RestApiResponse.class));

    controller.doHandle(httpRequest, responseBuilder, context);
}
```
