# Bonita-Specific Test Mocking Patterns

This reference provides comprehensive mocking patterns for testing Bonita Platform REST API extensions, controllers, connectors, and event handlers.

## Table of Contents

1. [APIAccessor Mocking](#apiaccessor-mocking)
2. [IdentityAPI Mocking](#identityapi-mocking)
3. [ProcessAPI Mocking](#processapi-mocking)
4. [BusinessObjectDAO Mocking](#businessobjectdao-mocking)
5. [RestAPIContext Mocking](#restapicontext-mocking)
6. [HttpServletRequest Mocking](#httpservletrequest-mocking)
7. [ResourceProvider Mocking](#resourceprovider-mocking)
8. [Complete Controller Test Example](#complete-controller-test-example)
9. [Common Pitfalls](#common-pitfalls)

---

## APIAccessor Mocking

The `APIAccessor` is the gateway to all Bonita APIs. Mock it to provide access to sub-APIs.

### Basic setup

```java
@Mock
private APIAccessor apiAccessor;

@Mock
private IdentityAPI identityAPI;

@Mock
private ProcessAPI processAPI;

@BeforeEach
void setUp() {
    when(apiAccessor.getIdentityAPI()).thenReturn(identityAPI);
    when(apiAccessor.getProcessAPI()).thenReturn(processAPI);
}
```

### Full APIClient chain (REST API extensions)

In REST API extensions, the API is accessed through `RestAPIContext.getApiClient()`:

```java
@Mock
private RestAPIContext context;

@Mock
private APIClient apiClient;

@Mock
private ProcessAPI processAPI;

@Mock
private IdentityAPI identityAPI;

@Mock
private APISession apiSession;

@BeforeEach
void setUp() {
    when(context.getApiClient()).thenReturn(apiClient);
    when(apiClient.getProcessAPI()).thenReturn(processAPI);
    when(apiClient.getIdentityAPI()).thenReturn(identityAPI);
    when(context.getApiSession()).thenReturn(apiSession);
    when(apiSession.getUserId()).thenReturn(TEST_USER_ID);
}
```

---

## IdentityAPI Mocking

### getUser

```java
private static final Long TEST_USER_ID = 1L;
private static final String TEST_USER_NAME = "john.doe";
private static final String TEST_FIRST_NAME = "John";
private static final String TEST_LAST_NAME = "Doe";

@Mock
private User mockUser;

@BeforeEach
void setUpUser() {
    when(mockUser.getId()).thenReturn(TEST_USER_ID);
    when(mockUser.getUserName()).thenReturn(TEST_USER_NAME);
    when(mockUser.getFirstName()).thenReturn(TEST_FIRST_NAME);
    when(mockUser.getLastName()).thenReturn(TEST_LAST_NAME);
}

@Test
void should_retrieve_user_by_id() throws Exception {
    // Given
    when(identityAPI.getUser(TEST_USER_ID)).thenReturn(mockUser);

    // When
    var result = service.getUserInfo(TEST_USER_ID);

    // Then
    assertThat(result.getUserName()).isEqualTo(TEST_USER_NAME);
    verify(identityAPI).getUser(TEST_USER_ID);
}
```

### getUserByUserName

```java
@Test
void should_retrieve_user_by_username() throws Exception {
    when(identityAPI.getUserByUserName(TEST_USER_NAME))
        .thenReturn(mockUser);

    var result = service.findUser(TEST_USER_NAME);

    assertThat(result.getId()).isEqualTo(TEST_USER_ID);
}
```

### getRole and getGroup

```java
private static final Long TEST_ROLE_ID = 10L;
private static final String TEST_ROLE_NAME = "member";
private static final Long TEST_GROUP_ID = 20L;
private static final String TEST_GROUP_PATH = "/acme/hr";

@Mock
private Role mockRole;

@Mock
private Group mockGroup;

@Test
void should_retrieve_user_role() throws Exception {
    when(mockRole.getId()).thenReturn(TEST_ROLE_ID);
    when(mockRole.getName()).thenReturn(TEST_ROLE_NAME);
    when(identityAPI.getRoleByName(TEST_ROLE_NAME)).thenReturn(mockRole);

    var result = identityAPI.getRoleByName(TEST_ROLE_NAME);

    assertThat(result.getName()).isEqualTo(TEST_ROLE_NAME);
}

@Test
void should_retrieve_user_group() throws Exception {
    when(mockGroup.getId()).thenReturn(TEST_GROUP_ID);
    when(mockGroup.getPath()).thenReturn(TEST_GROUP_PATH);
    when(identityAPI.getGroupByPath(TEST_GROUP_PATH)).thenReturn(mockGroup);

    var result = identityAPI.getGroupByPath(TEST_GROUP_PATH);

    assertThat(result.getPath()).isEqualTo(TEST_GROUP_PATH);
}
```

### User membership checks

```java
@Test
void should_check_user_membership() throws Exception {
    var memberships = List.of(mock(UserMembership.class));
    when(identityAPI.getUserMemberships(
            eq(TEST_USER_ID),
            eq(0),
            eq(100),
            any(UserMembershipCriterion.class)))
        .thenReturn(memberships);

    var result = identityAPI.getUserMemberships(
        TEST_USER_ID, 0, 100, UserMembershipCriterion.ASSIGNED_DATE_ASC);

    assertThat(result).hasSize(1);
}
```

---

## ProcessAPI Mocking

### getProcessInstance

```java
private static final Long TEST_PROCESS_INSTANCE_ID = 456L;
private static final String TEST_PROCESS_NAME = "LoanRequest";

@Mock
private ProcessInstance mockProcessInstance;

@Test
void should_retrieve_process_instance() throws Exception {
    when(mockProcessInstance.getId()).thenReturn(TEST_PROCESS_INSTANCE_ID);
    when(mockProcessInstance.getName()).thenReturn(TEST_PROCESS_NAME);
    when(processAPI.getProcessInstance(TEST_PROCESS_INSTANCE_ID))
        .thenReturn(mockProcessInstance);

    var result = processAPI.getProcessInstance(TEST_PROCESS_INSTANCE_ID);

    assertThat(result.getId()).isEqualTo(TEST_PROCESS_INSTANCE_ID);
    assertThat(result.getName()).isEqualTo(TEST_PROCESS_NAME);
}
```

### searchHumanTaskInstances

```java
@SuppressWarnings("unchecked")
@Test
void should_search_human_task_instances() throws Exception {
    // Given
    SearchResult<HumanTaskInstance> searchResult = mock(SearchResult.class);
    HumanTaskInstance task1 = mock(HumanTaskInstance.class);
    HumanTaskInstance task2 = mock(HumanTaskInstance.class);

    when(task1.getName()).thenReturn("Review");
    when(task2.getName()).thenReturn("Approve");
    when(searchResult.getResult()).thenReturn(List.of(task1, task2));
    when(searchResult.getCount()).thenReturn(2L);

    when(processAPI.searchHumanTaskInstances(any(SearchOptions.class)))
        .thenReturn(searchResult);

    // When
    var result = processAPI.searchHumanTaskInstances(
        new SearchOptionsBuilder(0, 10).done());

    // Then
    assertThat(result.getCount()).isEqualTo(2L);
    assertThat(result.getResult()).hasSize(2);
    assertThat(result.getResult().get(0).getName()).isEqualTo("Review");
}
```

### Cancelling a process instance

```java
@Test
void should_cancel_process_instance() throws Exception {
    // Given - no setup needed, cancelProcessInstance is void

    // When
    processAPI.cancelProcessInstance(TEST_PROCESS_INSTANCE_ID);

    // Then
    verify(processAPI).cancelProcessInstance(TEST_PROCESS_INSTANCE_ID);
}

@Test
void should_throw_when_cancelling_nonexistent_process() throws Exception {
    doThrow(new ProcessInstanceNotFoundException(
            "Process instance not found: " + TEST_PROCESS_INSTANCE_ID))
        .when(processAPI)
        .cancelProcessInstance(TEST_PROCESS_INSTANCE_ID);

    assertThatThrownBy(() ->
        processAPI.cancelProcessInstance(TEST_PROCESS_INSTANCE_ID))
        .isInstanceOf(ProcessInstanceNotFoundException.class);
}
```

---

## BusinessObjectDAO Mocking

### Typed DAO setup

```java
private static final String TEST_BDM_ENTITY_CLASS =
    "com.company.model.LoanRequest";

@Mock
private BusinessObjectDAOFactory daoFactory;

@Mock
private LoanRequestDAO loanRequestDAO;

@BeforeEach
void setUpDAO() {
    when(context.getApiClient().getDAO(LoanRequestDAO.class))
        .thenReturn(loanRequestDAO);
}
```

### Query results

```java
@Test
void should_find_loan_requests_by_status() {
    // Given
    var request1 = mock(LoanRequest.class);
    var request2 = mock(LoanRequest.class);
    when(request1.getPersistenceId()).thenReturn(1L);
    when(request2.getPersistenceId()).thenReturn(2L);
    when(request1.getStatus()).thenReturn("PENDING");
    when(request2.getStatus()).thenReturn("PENDING");

    when(loanRequestDAO.findByStatus("PENDING", 0, 10))
        .thenReturn(List.of(request1, request2));

    // When
    var results = loanRequestDAO.findByStatus("PENDING", 0, 10);

    // Then
    assertThat(results).hasSize(2);
    assertThat(results).extracting("persistenceId").containsExactly(1L, 2L);
}
```

### Count queries

```java
@Test
void should_count_loan_requests_by_status() {
    when(loanRequestDAO.countForFindByStatus("PENDING"))
        .thenReturn(15L);

    var count = loanRequestDAO.countForFindByStatus("PENDING");

    assertThat(count).isEqualTo(15L);
}
```

### findByPersistenceId

```java
@Test
void should_find_by_persistence_id() {
    var entity = mock(LoanRequest.class);
    when(entity.getPersistenceId()).thenReturn(TEST_PERSISTENCE_ID);
    when(entity.getStatus()).thenReturn("ACTIVE");

    when(loanRequestDAO.findByPersistenceId(TEST_PERSISTENCE_ID))
        .thenReturn(entity);

    var result = loanRequestDAO.findByPersistenceId(TEST_PERSISTENCE_ID);

    assertThat(result).isNotNull();
    assertThat(result.getPersistenceId()).isEqualTo(TEST_PERSISTENCE_ID);
}

@Test
void should_return_null_when_entity_not_found() {
    when(loanRequestDAO.findByPersistenceId(999L))
        .thenReturn(null);

    var result = loanRequestDAO.findByPersistenceId(999L);

    assertThat(result).isNull();
}
```

---

## RestAPIContext Mocking

### Complete context setup

```java
@Mock
private RestAPIContext context;

@Mock
private APIClient apiClient;

@Mock
private APISession apiSession;

@Mock
private ResourceProvider resourceProvider;

@BeforeEach
void setUpContext() {
    when(context.getApiClient()).thenReturn(apiClient);
    when(context.getApiSession()).thenReturn(apiSession);
    when(context.getResourceProvider()).thenReturn(resourceProvider);
    when(apiSession.getUserId()).thenReturn(TEST_USER_ID);
    when(apiSession.getUserName()).thenReturn(TEST_USER_NAME);
}
```

### Locale and timezone

```java
@Test
void should_use_context_locale() {
    when(context.getLocale()).thenReturn(Locale.FRENCH);

    var result = service.getLocalizedMessage(context);

    assertThat(result).contains("Bonjour");
}
```

---

## HttpServletRequest Mocking

### Query parameters

```java
@Mock
private HttpServletRequest httpRequest;

@Test
void should_extract_query_parameters() {
    when(httpRequest.getParameter("entityId")).thenReturn("123");
    when(httpRequest.getParameter("page")).thenReturn("0");
    when(httpRequest.getParameter("count")).thenReturn("10");
    when(httpRequest.getParameter("status")).thenReturn("ACTIVE");

    var params = controller.validateInputParameters(httpRequest, context);

    assertThat(params.getEntityId()).isEqualTo(123L);
    assertThat(params.getPage()).isZero();
    assertThat(params.getCount()).isEqualTo(10);
}
```

### Missing parameters

```java
@Test
void should_throw_when_required_parameter_is_missing() {
    when(httpRequest.getParameter("entityId")).thenReturn(null);

    assertThatThrownBy(() ->
        controller.validateInputParameters(httpRequest, context))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("entityId");
}
```

### Headers

```java
@Test
void should_read_authorization_header() {
    when(httpRequest.getHeader("Authorization"))
        .thenReturn("Bearer test-token-123");

    var token = httpRequest.getHeader("Authorization");

    assertThat(token).startsWith("Bearer ");
}
```

### Request body (POST/PUT)

```java
@Test
void should_parse_json_body() throws Exception {
    String jsonBody = "{\"name\":\"Test\",\"status\":\"ACTIVE\"}";
    BufferedReader reader = new BufferedReader(new StringReader(jsonBody));
    when(httpRequest.getReader()).thenReturn(reader);

    var body = controller.parseRequestBody(httpRequest);

    assertThat(body.getName()).isEqualTo("Test");
    assertThat(body.getStatus()).isEqualTo("ACTIVE");
}
```

### Multipart file upload

```java
@Mock
private Part filePart;

@Test
void should_handle_file_upload() throws Exception {
    when(httpRequest.getPart("file")).thenReturn(filePart);
    when(filePart.getSubmittedFileName()).thenReturn("document.pdf");
    when(filePart.getSize()).thenReturn(1024L);
    when(filePart.getInputStream())
        .thenReturn(new ByteArrayInputStream("content".getBytes()));

    var result = controller.handleUpload(httpRequest, context);

    assertThat(result.getFileName()).isEqualTo("document.pdf");
}
```

---

## ResourceProvider Mocking

The `ResourceProvider` provides access to files bundled with the REST API extension.

```java
@Mock
private ResourceProvider resourceProvider;

@Test
void should_read_configuration_file() throws Exception {
    String configContent = "{\"maxRetries\": 3, \"timeout\": 5000}";
    InputStream configStream =
        new ByteArrayInputStream(configContent.getBytes());

    when(resourceProvider.getResourceAsStream("config.json"))
        .thenReturn(configStream);

    var config = service.loadConfiguration(resourceProvider);

    assertThat(config.getMaxRetries()).isEqualTo(3);
    assertThat(config.getTimeout()).isEqualTo(5000);
}

@Test
void should_handle_missing_configuration_file() throws Exception {
    when(resourceProvider.getResourceAsStream("config.json"))
        .thenReturn(null);

    assertThatThrownBy(() -> service.loadConfiguration(resourceProvider))
        .isInstanceOf(ConfigurationException.class)
        .hasMessageContaining("config.json not found");
}
```

---

## Complete Controller Test Example

This example shows a complete test class for a Bonita REST API controller with all required test scenarios:

```java
package com.bonitasoft.processbuilder.rest.api.controller.loanRequest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;

import javax.servlet.http.HttpServletRequest;

import org.bonitasoft.engine.api.APIClient;
import org.bonitasoft.engine.session.APISession;
import org.bonitasoft.web.extension.rest.RestAPIContext;
import org.bonitasoft.web.extension.rest.RestApiResponse;
import org.bonitasoft.web.extension.rest.RestApiResponseBuilder;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import com.bonitasoft.processbuilder.rest.api.dto.parameter.ParamLoanRequest;
import com.bonitasoft.processbuilder.rest.api.dto.result.ResultLoanRequest;
import com.bonitasoft.processbuilder.rest.api.exception.ValidationException;
import com.bonitasoft.processbuilder.rest.api.utils.LicenseValidator;
import com.company.model.LoanRequestDAO;

/**
 * Comprehensive unit tests for the LoanRequest REST API controller.
 *
 * Test Coverage:
 * - doHandle success path with valid parameters (200 OK)
 * - Missing required parameter (400 Bad Request)
 * - Invalid parameter format (400 Bad Request)
 * - DAO exception during execution (500 Internal Server Error)
 * - License validation failure (403 Forbidden)
 * - Null handling and edge cases
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
@DisplayName("LoanRequest Controller - retrieves loan requests with pagination")
class AbstractLoanRequestTest {

    // =========================================================================
    // Constants
    // =========================================================================

    private static final Long TEST_USER_ID = 1L;
    private static final Long TEST_LOAN_ID = 123L;
    private static final String TEST_STATUS = "PENDING";
    private static final int TEST_PAGE = 0;
    private static final int TEST_COUNT = 10;
    private static final String TEST_VALIDATION_ERROR =
        "status parameter is required";
    private static final String TEST_INVALID_PARAM_ERROR =
        "page must be a non-negative integer";
    private static final String TEST_DAO_ERROR =
        "Failed to query loan requests";

    // =========================================================================
    // Mocks
    // =========================================================================

    @Spy
    private TestableLoanRequest controller;

    @Mock
    private HttpServletRequest httpRequest;

    @Mock
    private RestApiResponseBuilder responseBuilder;

    @Mock
    private RestAPIContext context;

    @Mock
    private APIClient apiClient;

    @Mock
    private APISession apiSession;

    @Mock
    private LoanRequestDAO loanRequestDAO;

    @Mock
    private RestApiResponse mockResponse;

    // =========================================================================
    // Setup and Teardown
    // =========================================================================

    @BeforeEach
    void setUp() {
        LicenseValidator.enableTestMode();

        // Response builder chain
        when(responseBuilder.withResponseStatus(any(Integer.class)))
            .thenReturn(responseBuilder);
        when(responseBuilder.withResponse(any(String.class)))
            .thenReturn(responseBuilder);
        when(responseBuilder.build()).thenReturn(mockResponse);

        // API context chain
        when(context.getApiClient()).thenReturn(apiClient);
        when(context.getApiSession()).thenReturn(apiSession);
        when(apiSession.getUserId()).thenReturn(TEST_USER_ID);
        when(apiClient.getDAO(LoanRequestDAO.class))
            .thenReturn(loanRequestDAO);
    }

    @AfterEach
    void tearDown() {
        LicenseValidator.disableTestMode();
    }

    // =========================================================================
    // I. Tests for Success Path (200 OK)
    // =========================================================================

    @Nested
    @DisplayName("doHandle - Success")
    class DoHandleSuccess {

        @Test
        @DisplayName("should return 200 OK when loan requests are found")
        void should_return_200_OK_when_loan_requests_are_found() {
            // Given
            var params = new ParamLoanRequest(
                TEST_PAGE, TEST_COUNT, TEST_STATUS);
            var result = ResultLoanRequest.builder()
                .p(TEST_PAGE)
                .c(TEST_COUNT)
                .total(1L)
                .data(List.of())
                .build();

            doReturn(params).when(controller)
                .validateInputParameters(httpRequest, context);
            doReturn(result).when(controller).execute(context, params);

            // When
            RestApiResponse response = controller.doHandle(
                httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(200);
        }

        @Test
        @DisplayName("should call validate then execute in order")
        void should_call_validate_then_execute_in_order() {
            // Given
            var params = new ParamLoanRequest(
                TEST_PAGE, TEST_COUNT, TEST_STATUS);
            var result = ResultLoanRequest.builder().build();

            doReturn(params).when(controller)
                .validateInputParameters(httpRequest, context);
            doReturn(result).when(controller).execute(context, params);

            // When
            controller.doHandle(httpRequest, responseBuilder, context);

            // Then
            verify(controller).validateInputParameters(
                httpRequest, context);
            verify(controller).execute(context, params);
        }
    }

    // =========================================================================
    // II. Tests for Missing Parameter (400 Bad Request)
    // =========================================================================

    @Nested
    @DisplayName("doHandle - Missing Parameter")
    class DoHandleMissingParameter {

        @Test
        @DisplayName("should return 400 when required parameter is missing")
        void should_return_400_when_required_parameter_is_missing() {
            // Given
            doThrow(new ValidationException(TEST_VALIDATION_ERROR))
                .when(controller)
                .validateInputParameters(httpRequest, context);

            // When
            RestApiResponse response = controller.doHandle(
                httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(400);
        }

        @Test
        @DisplayName("should not call execute when validation fails")
        void should_not_call_execute_when_validation_fails() {
            // Given
            doThrow(new ValidationException(TEST_VALIDATION_ERROR))
                .when(controller)
                .validateInputParameters(httpRequest, context);

            // When
            controller.doHandle(httpRequest, responseBuilder, context);

            // Then
            verify(controller, never()).execute(any(), any());
        }
    }

    // =========================================================================
    // III. Tests for Invalid Parameter (400 Bad Request)
    // =========================================================================

    @Nested
    @DisplayName("doHandle - Invalid Parameter")
    class DoHandleInvalidParameter {

        @Test
        @DisplayName("should return 400 when parameter format is invalid")
        void should_return_400_when_parameter_format_is_invalid() {
            // Given
            doThrow(new ValidationException(TEST_INVALID_PARAM_ERROR))
                .when(controller)
                .validateInputParameters(httpRequest, context);

            // When
            RestApiResponse response = controller.doHandle(
                httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(400);
        }
    }

    // =========================================================================
    // IV. Tests for DAO Exception (500 Internal Server Error)
    // =========================================================================

    @Nested
    @DisplayName("doHandle - DAO Exception")
    class DoHandleDaoException {

        @Test
        @DisplayName("should return 500 when DAO throws exception")
        void should_return_500_when_DAO_throws_exception() {
            // Given
            var params = new ParamLoanRequest(
                TEST_PAGE, TEST_COUNT, TEST_STATUS);
            doReturn(params).when(controller)
                .validateInputParameters(httpRequest, context);
            doThrow(new RuntimeException(TEST_DAO_ERROR))
                .when(controller).execute(context, params);

            // When
            RestApiResponse response = controller.doHandle(
                httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(500);
        }

        @Test
        @DisplayName("should include error details in 500 response")
        void should_include_error_details_in_500_response() {
            // Given
            var params = new ParamLoanRequest(
                TEST_PAGE, TEST_COUNT, TEST_STATUS);
            doReturn(params).when(controller)
                .validateInputParameters(httpRequest, context);
            doThrow(new RuntimeException(TEST_DAO_ERROR))
                .when(controller).execute(context, params);

            // When
            controller.doHandle(httpRequest, responseBuilder, context);

            // Then
            verify(responseBuilder).withResponse(any(String.class));
        }
    }

    // =========================================================================
    // V. Tests for License Validation (403 Forbidden)
    // =========================================================================

    @Nested
    @DisplayName("doHandle - License Validation")
    class DoHandleLicenseValidation {

        @Test
        @DisplayName("should return 403 when license is invalid")
        void should_return_403_when_license_is_invalid() {
            // Given
            LicenseValidator.disableTestMode();

            // When
            RestApiResponse response = controller.doHandle(
                httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            verify(controller, never()).execute(any(), any());
        }
    }

    // =========================================================================
    // VI. Tests for Null / Edge Cases
    // =========================================================================

    @Nested
    @DisplayName("doHandle - Null and Edge Cases")
    class DoHandleNullAndEdgeCases {

        @Test
        @DisplayName("should handle null validation error message")
        void should_handle_null_validation_error_message() {
            // Given
            doThrow(new ValidationException(null))
                .when(controller)
                .validateInputParameters(httpRequest, context);

            // When
            RestApiResponse response = controller.doHandle(
                httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(400);
        }

        @Test
        @DisplayName("should handle null execution error message")
        void should_handle_null_execution_error_message() {
            // Given
            var params = new ParamLoanRequest(
                TEST_PAGE, TEST_COUNT, TEST_STATUS);
            doReturn(params).when(controller)
                .validateInputParameters(httpRequest, context);
            doThrow(new RuntimeException((String) null))
                .when(controller).execute(context, params);

            // When
            RestApiResponse response = controller.doHandle(
                httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(500);
        }
    }

    // =========================================================================
    // VII. Testable Concrete Implementation
    // =========================================================================

    static class TestableLoanRequest extends AbstractLoanRequest {

        @Override
        protected ResultLoanRequest execute(
                RestAPIContext context, ParamLoanRequest params) {
            return ResultLoanRequest.builder().build();
        }

        @Override
        protected ParamLoanRequest validateInputParameters(
                HttpServletRequest request,
                RestAPIContext context) throws ValidationException {
            return new ParamLoanRequest(0, 10, "PENDING");
        }
    }
}
```

---

## Common Pitfalls

### DO NOT mock DTOs, records, or pure functions

```java
// BAD - Mocking a DTO
@Mock
private ParamMyEntity params;  // DON'T DO THIS

// GOOD - Create a real instance
var params = new ParamMyEntity(TEST_ENTITY_ID, TEST_PAGE, TEST_COUNT);
```

DTOs are simple data holders. There is no benefit to mocking them, and doing so makes tests less readable and more fragile.

### DO NOT mock the class under test

```java
// BAD - Mocking the service being tested
@Mock
private MyService myService;  // This is the CUT, not a dependency!

// GOOD - Use @InjectMocks for the class under test
@InjectMocks
private MyService myService;
```

Exception: Use `@Spy` when testing abstract classes where you need to stub some abstract methods while testing concrete ones.

### DO mock external dependencies

```java
// GOOD - Mock all external interactions
@Mock
private LoanRequestDAO loanRequestDAO;  // Database access

@Mock
private ProcessAPI processAPI;           // Bonita engine API

@Mock
private HttpServletRequest httpRequest;  // HTTP infrastructure

@Mock
private RestAPIContext context;          // Bonita context
```

### DO NOT forget to enable/disable LicenseValidator test mode

```java
// CRITICAL: Always manage LicenseValidator state
@BeforeEach
void setUp() {
    LicenseValidator.enableTestMode();  // MUST enable
    // ... other setup
}

@AfterEach
void tearDown() {
    LicenseValidator.disableTestMode();  // MUST disable
}
```

Forgetting to enable test mode causes all tests to fail with 403 responses. Forgetting to disable it can leak state to other test classes.

### DO NOT use raw types with SearchResult

```java
// BAD - Raw type warning
SearchResult searchResult = mock(SearchResult.class);

// GOOD - Suppress the unavoidable unchecked warning
@SuppressWarnings("unchecked")
SearchResult<HumanTaskInstance> searchResult =
    mock(SearchResult.class);
```

### DO verify side effects for void methods

```java
// BAD - Calling void method without verification
@Test
void should_cancel_process() {
    service.cancelProcess(TEST_ID);
    // No verification! Mutation test will survive.
}

// GOOD - Verify the side effect
@Test
void should_call_processAPI_to_cancel() {
    service.cancelProcess(TEST_ID);
    verify(processAPI).cancelProcessInstance(TEST_ID);
}
```

### DO use doReturn/doThrow for @Spy objects

```java
// BAD - when() with @Spy can call the real method
when(controller.validateInputParameters(request, context))
    .thenReturn(params);  // Real method is called first!

// GOOD - doReturn() stubs without calling the real method
doReturn(params).when(controller)
    .validateInputParameters(request, context);
```
