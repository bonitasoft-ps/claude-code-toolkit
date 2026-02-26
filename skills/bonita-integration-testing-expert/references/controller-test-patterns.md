# Controller Test Patterns

This reference provides detailed patterns for testing Bonita REST API extension controllers, covering the Template Method pattern, validation testing, execution testing, doHandle integration testing, pagination, filtering, and error handling.

## Table of Contents

1. [Template Method Pattern Testing](#template-method-pattern-testing)
2. [Testing validateInputParameters()](#testing-validateinputparameters)
3. [Testing execute()](#testing-execute)
4. [Testing doHandle() End-to-End](#testing-dohandle-end-to-end)
5. [Pagination Testing Patterns](#pagination-testing-patterns)
6. [Filter and Search Parameter Testing](#filter-and-search-parameter-testing)
7. [Error Handling Verification](#error-handling-verification)
8. [Complete Controller Test Example](#complete-controller-test-example)

---

## Template Method Pattern Testing

Bonita controllers use the **Template Method** pattern where `AbstractController.doHandle()` defines the skeleton algorithm, calling `validateInputParameters()` and `execute()` which are implemented by concrete subclasses.

### Testing the Abstract Class

Create a **testable subclass** that provides minimal implementations:

```java
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AbstractMyControllerTest {

    @Spy
    private TestableMyController controller;

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
        when(responseBuilder.withContentRange(any(Integer.class), any(Integer.class), any(Long.class)))
            .thenReturn(responseBuilder);
        when(responseBuilder.build()).thenReturn(mockResponse);
    }

    @AfterEach
    void tearDown() {
        LicenseValidator.disableTestMode();
    }

    // Tests go here...

    // =========================================================================
    // Testable Concrete Implementation
    // =========================================================================
    static class TestableMyController extends AbstractMyController {

        @Override
        protected ResultMyController execute(RestAPIContext context, ParamMyController params) {
            return ResultMyController.builder().build();
        }

        @Override
        protected ParamMyController validateInputParameters(HttpServletRequest request)
                throws ValidationException {
            return new ParamMyController(0, 10, null, new HashMap<>());
        }
    }
}
```

### Testing the Concrete Class

The concrete class tests focus on **actual validation logic and actual execution logic**:

```java
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class MyControllerTest {

    @InjectMocks
    @Spy
    private MyController controller;

    @Mock
    private HttpServletRequest httpRequest;

    @Mock
    private RestAPIContext context;

    @Mock
    private APIClient apiClient;

    @Mock
    private MyEntityDAO myEntityDAO;

    @BeforeEach
    void setUp() throws Exception {
        LicenseValidator.enableTestMode();
        when(context.getApiClient()).thenReturn(apiClient);
        when(apiClient.getDAO(MyEntityDAO.class)).thenReturn(myEntityDAO);
    }

    @AfterEach
    void tearDown() {
        LicenseValidator.disableTestMode();
    }
}
```

---

## Testing validateInputParameters()

### Pattern: Missing Required Parameter

```java
@Test
@DisplayName("should throw ValidationException when parameter 'p' is missing")
void should_throw_ValidationException_when_p_is_missing() {
    // Given
    when(httpRequest.getParameter("p")).thenReturn(null);
    when(httpRequest.getParameter("c")).thenReturn("10");

    // When / Then
    assertThatThrownBy(() -> controller.validateInputParameters(httpRequest))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("'p'");
}
```

### Pattern: Invalid Parameter Format

```java
@Test
@DisplayName("should throw ValidationException when parameter 'p' is not numerical")
void should_throw_ValidationException_when_p_is_not_numerical() {
    // Given
    when(httpRequest.getParameter("p")).thenReturn("not_a_number");
    when(httpRequest.getParameter("c")).thenReturn("10");

    // When / Then
    assertThatThrownBy(() -> controller.validateInputParameters(httpRequest))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("integer");
}
```

### Pattern: Valid Parameters

```java
@Test
@DisplayName("should return valid params when all mandatory parameters provided")
void should_return_valid_params_when_all_mandatory_parameters_provided() throws ValidationException {
    // Given
    when(httpRequest.getParameter("p")).thenReturn("0");
    when(httpRequest.getParameter("c")).thenReturn("10");
    when(httpRequest.getParameter("s")).thenReturn(null);
    when(httpRequest.getParameterValues("f")).thenReturn(null);

    // When
    var result = controller.validateInputParameters(httpRequest);

    // Then
    assertThat(result).isNotNull();
    assertThat(result.getP()).isZero();
    assertThat(result.getC()).isEqualTo(10);
    assertThat(result.getSearchText()).isNull();
    assertThat(result.getFilters()).isEmpty();
}
```

### Pattern: Using MockedStatic for QueryParamValidator

When the controller delegates to `QueryParamValidator` static methods:

```java
@Test
@DisplayName("should validate mandatory integer parameter via QueryParamValidator")
void should_validate_mandatory_integer_via_QueryParamValidator() {
    try (MockedStatic<QueryParamValidator> qpvMock = mockStatic(QueryParamValidator.class)) {
        // Given
        qpvMock.when(() -> QueryParamValidator.validateMandatoryInteger(httpRequest, "p"))
            .thenReturn(0);
        qpvMock.when(() -> QueryParamValidator.validateMandatoryInteger(httpRequest, "c"))
            .thenReturn(10);
        qpvMock.when(() -> QueryParamValidator.validateOptionalString(httpRequest, "s"))
            .thenReturn(null);

        // When
        var result = controller.validateInputParameters(httpRequest);

        // Then
        assertThat(result).isNotNull();
        qpvMock.verify(() -> QueryParamValidator.validateMandatoryInteger(httpRequest, "p"));
        qpvMock.verify(() -> QueryParamValidator.validateMandatoryInteger(httpRequest, "c"));
    }
}
```

### Pattern: Boundary Value Testing

```java
@Test
@DisplayName("should accept page index of zero")
void should_accept_page_index_of_zero() throws ValidationException {
    when(httpRequest.getParameter("p")).thenReturn("0");
    when(httpRequest.getParameter("c")).thenReturn("10");
    when(httpRequest.getParameterValues("f")).thenReturn(null);

    var result = controller.validateInputParameters(httpRequest);

    assertThat(result.getP()).isZero();
}

@Test
@DisplayName("should accept negative page index if allowed")
void should_reject_negative_page_index() {
    when(httpRequest.getParameter("p")).thenReturn("-1");
    when(httpRequest.getParameter("c")).thenReturn("10");

    assertThatThrownBy(() -> controller.validateInputParameters(httpRequest))
        .isInstanceOf(ValidationException.class);
}

@Test
@DisplayName("should accept maximum page size")
void should_accept_maximum_page_size() throws ValidationException {
    when(httpRequest.getParameter("p")).thenReturn("0");
    when(httpRequest.getParameter("c")).thenReturn("1000");
    when(httpRequest.getParameterValues("f")).thenReturn(null);

    var result = controller.validateInputParameters(httpRequest);

    assertThat(result.getC()).isEqualTo(1000);
}
```

---

## Testing execute()

### Pattern: Successful Execution with Mocked DAOs

```java
@Test
@DisplayName("should return process list when DAO returns data")
void should_return_process_list_when_DAO_returns_data() {
    // Given
    var params = new ParamMyController(TEST_PAGE_INDEX, TEST_PAGE_SIZE, null, Map.of());
    var mockEntity1 = mock(PBProcess.class);
    var mockEntity2 = mock(PBProcess.class);
    when(mockEntity1.getPersistenceId()).thenReturn(1L);
    when(mockEntity2.getPersistenceId()).thenReturn(2L);

    when(pbProcessDAO.find(0, 10)).thenReturn(List.of(mockEntity1, mockEntity2));
    when(pbProcessDAO.countForFind()).thenReturn(25L);

    // When
    var result = controller.execute(context, params);

    // Then
    assertThat(result).isNotNull();
    assertThat(result.getProcesses()).hasSize(2);
    assertThat(result.getTotal()).isEqualTo(25L);
}
```

### Pattern: Empty Result Set

```java
@Test
@DisplayName("should return empty list when DAO returns no data")
void should_return_empty_list_when_DAO_returns_no_data() {
    // Given
    var params = new ParamMyController(0, 10, null, Map.of());
    when(pbProcessDAO.find(0, 10)).thenReturn(Collections.emptyList());
    when(pbProcessDAO.countForFind()).thenReturn(0L);

    // When
    var result = controller.execute(context, params);

    // Then
    assertThat(result).isNotNull();
    assertThat(result.getProcesses()).isEmpty();
    assertThat(result.getTotal()).isZero();
}
```

### Pattern: DAO Exception

```java
@Test
@DisplayName("should propagate RuntimeException when DAO fails")
void should_propagate_RuntimeException_when_DAO_fails() {
    // Given
    var params = new ParamMyController(0, 10, null, Map.of());
    when(pbProcessDAO.find(0, 10)).thenThrow(new RuntimeException("Connection timeout"));

    // When / Then
    assertThatThrownBy(() -> controller.execute(context, params))
        .isInstanceOf(RuntimeException.class)
        .hasMessageContaining("Connection timeout");
}
```

### Pattern: Offset Calculation Verification

```java
@Test
@DisplayName("should calculate correct offset from page index and page size")
void should_calculate_correct_offset() {
    // Given - page 3, size 10 -> offset = 30
    var params = new ParamMyController(3, 10, null, Map.of());

    // When
    controller.execute(context, params);

    // Then - verify the DAO was called with offset = page * size = 30
    verify(pbProcessDAO).find(30, 10);
}
```

---

## Testing doHandle() End-to-End

### Pattern: 200 OK Success Path

```java
@Nested
@DisplayName("doHandle - Success (200 OK)")
class DoHandleSuccess {

    @Test
    @DisplayName("should return 200 OK when validation and execution succeed")
    void should_return_200_OK_when_validation_and_execution_succeed() {
        // Given
        var params = createTestParams();
        var result = createTestResult();
        doReturn(params).when(controller).validateInputParameters(httpRequest);
        doReturn(result).when(controller).execute(context, params);

        // When
        RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

        // Then
        assertThat(response).isNotNull();
        verify(controller).validateInputParameters(httpRequest);
        verify(controller).execute(context, params);
        verify(responseBuilder).withResponseStatus(eq(200));
    }

    @Test
    @DisplayName("should include pagination headers in successful response")
    void should_include_pagination_headers_in_successful_response() {
        // Given
        var params = createTestParams();
        var result = createTestResultWithPagination();
        doReturn(params).when(controller).validateInputParameters(httpRequest);
        doReturn(result).when(controller).execute(context, params);

        // When
        controller.doHandle(httpRequest, responseBuilder, context);

        // Then
        verify(responseBuilder).withContentRange(
            eq(TEST_PAGE_INDEX), eq(TEST_PAGE_SIZE), eq(TEST_TOTAL_COUNT));
    }

    @Test
    @DisplayName("should serialize result to JSON in response body")
    void should_serialize_result_to_JSON_in_response_body() {
        // Given
        var params = createTestParams();
        var result = createTestResult();
        doReturn(params).when(controller).validateInputParameters(httpRequest);
        doReturn(result).when(controller).execute(context, params);

        // When
        controller.doHandle(httpRequest, responseBuilder, context);

        // Then
        verify(responseBuilder).withResponse(any(String.class));
    }
}
```

### Pattern: 400 Bad Request - Validation Failure

```java
@Nested
@DisplayName("doHandle - Validation Failure (400 Bad Request)")
class DoHandleValidationFailure {

    @Test
    @DisplayName("should return 400 when validation throws ValidationException")
    void should_return_400_when_validation_throws_ValidationException() {
        // Given
        doThrow(new ValidationException(TEST_VALIDATION_ERROR))
            .when(controller).validateInputParameters(httpRequest);

        // When
        RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

        // Then
        assertThat(response).isNotNull();
        verify(responseBuilder).withResponseStatus(eq(400));
    }

    @Test
    @DisplayName("should not call execute when validation fails")
    void should_not_call_execute_when_validation_fails() {
        // Given
        doThrow(new ValidationException(TEST_VALIDATION_ERROR))
            .when(controller).validateInputParameters(httpRequest);

        // When
        controller.doHandle(httpRequest, responseBuilder, context);

        // Then
        verify(controller, never()).execute(any(), any());
    }

    @Test
    @DisplayName("should include error message in 400 response body")
    void should_include_error_message_in_400_response_body() {
        // Given
        doThrow(new ValidationException(TEST_VALIDATION_ERROR))
            .when(controller).validateInputParameters(httpRequest);

        // When
        controller.doHandle(httpRequest, responseBuilder, context);

        // Then
        verify(responseBuilder).withResponse(any(String.class));
    }
}
```

### Pattern: 500 Internal Server Error - Execution Failure

```java
@Nested
@DisplayName("doHandle - Execution Failure (500 Internal Server Error)")
class DoHandleExecutionFailure {

    @Test
    @DisplayName("should return 500 when execution throws RuntimeException")
    void should_return_500_when_execution_throws_RuntimeException() {
        // Given
        var params = createTestParams();
        doReturn(params).when(controller).validateInputParameters(httpRequest);
        doThrow(new RuntimeException(TEST_EXECUTION_ERROR))
            .when(controller).execute(context, params);

        // When
        RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

        // Then
        assertThat(response).isNotNull();
        verify(responseBuilder).withResponseStatus(eq(500));
    }

    @Test
    @DisplayName("should handle NullPointerException during execution")
    void should_handle_NullPointerException_during_execution() {
        // Given
        var params = createTestParams();
        doReturn(params).when(controller).validateInputParameters(httpRequest);
        doThrow(new NullPointerException("Null entity"))
            .when(controller).execute(context, params);

        // When
        RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

        // Then
        assertThat(response).isNotNull();
        verify(responseBuilder).withResponseStatus(eq(500));
    }
}
```

### Pattern: 403 Forbidden - License Failure

```java
@Nested
@DisplayName("doHandle - License Failure (403 Forbidden)")
class DoHandleLicenseFailure {

    @Test
    @DisplayName("should return 403 when license is invalid")
    void should_return_403_when_license_is_invalid() {
        // Given
        LicenseValidator.disableTestMode();

        // When
        RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

        // Then
        assertThat(response).isNotNull();
        verify(controller, never()).execute(any(), any());
    }
}
```

### Pattern: Execution Order Verification

```java
@Test
@DisplayName("should execute validation before execution in correct order")
void should_execute_validation_before_execution_in_correct_order() {
    // Given
    var params = createTestParams();
    var result = createTestResult();
    doReturn(params).when(controller).validateInputParameters(httpRequest);
    doReturn(result).when(controller).execute(context, params);

    // When
    controller.doHandle(httpRequest, responseBuilder, context);

    // Then
    var inOrder = Mockito.inOrder(controller, responseBuilder);
    inOrder.verify(controller).validateInputParameters(httpRequest);
    inOrder.verify(controller).execute(context, params);
    inOrder.verify(responseBuilder).withResponseStatus(eq(200));
}
```

---

## Pagination Testing Patterns

### Standard Pagination Parameters (p, c)

```java
private static final Integer TEST_PAGE_INDEX = 0;
private static final Integer TEST_PAGE_SIZE = 10;
private static final Long TEST_TOTAL_COUNT = 25L;

@Test
@DisplayName("should calculate correct offset for page 0")
void should_calculate_correct_offset_for_page_0() {
    // offset = p * c = 0 * 10 = 0
    when(httpRequest.getParameter("p")).thenReturn("0");
    when(httpRequest.getParameter("c")).thenReturn("10");

    var params = controller.validateInputParameters(httpRequest);

    assertThat(params.getP()).isZero();
    assertThat(params.getC()).isEqualTo(10);
}

@Test
@DisplayName("should calculate correct offset for page 5")
void should_calculate_correct_offset_for_page_5() {
    // offset = p * c = 5 * 10 = 50
    when(httpRequest.getParameter("p")).thenReturn("5");
    when(httpRequest.getParameter("c")).thenReturn("10");

    var params = controller.validateInputParameters(httpRequest);

    assertThat(params.getP()).isEqualTo(5);
}
```

### Content-Range Header Verification

```java
@Test
@DisplayName("should set Content-Range header with correct pagination metadata")
void should_set_ContentRange_header_with_correct_pagination_metadata() {
    // Given
    var params = createTestParams();
    var result = ResultMyController.builder()
        .p(TEST_PAGE_INDEX)
        .c(TEST_PAGE_SIZE)
        .total(TEST_TOTAL_COUNT)
        .data(createTestDataList(10))
        .build();

    doReturn(params).when(controller).validateInputParameters(httpRequest);
    doReturn(result).when(controller).execute(context, params);

    // When
    controller.doHandle(httpRequest, responseBuilder, context);

    // Then
    verify(responseBuilder).withContentRange(
        eq(TEST_PAGE_INDEX),
        eq(TEST_PAGE_SIZE),
        eq(TEST_TOTAL_COUNT)
    );
}
```

### Empty Page (No Results)

```java
@Test
@DisplayName("should handle empty result set with zero total count")
void should_handle_empty_result_set_with_zero_total_count() {
    // Given
    var params = createTestParams();
    var result = ResultMyController.builder()
        .p(TEST_PAGE_INDEX)
        .c(TEST_PAGE_SIZE)
        .total(0L)
        .data(Collections.emptyList())
        .build();

    doReturn(params).when(controller).validateInputParameters(httpRequest);
    doReturn(result).when(controller).execute(context, params);

    // When
    RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

    // Then
    assertThat(response).isNotNull();
    verify(responseBuilder).withResponseStatus(eq(200));
    verify(responseBuilder).withContentRange(eq(TEST_PAGE_INDEX), eq(TEST_PAGE_SIZE), eq(0L));
}
```

### Large Dataset Pagination

```java
@Test
@DisplayName("should handle large dataset pagination correctly")
void should_handle_large_dataset_pagination_correctly() {
    // Given
    var params = createTestParams();
    var result = ResultMyController.builder()
        .p(50)
        .c(100)
        .total(100000L)
        .data(createTestDataList(100))
        .build();

    doReturn(params).when(controller).validateInputParameters(httpRequest);
    doReturn(result).when(controller).execute(context, params);

    // When
    RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

    // Then
    assertThat(response).isNotNull();
    verify(responseBuilder).withResponseStatus(eq(200));
    verify(responseBuilder).withContentRange(eq(50), eq(100), eq(100000L));
}
```

---

## Filter and Search Parameter Testing

### Filter Parameter (f)

```java
@Test
@DisplayName("should parse single filter parameter")
void should_parse_single_filter_parameter() throws ValidationException {
    // Given
    when(httpRequest.getParameter("p")).thenReturn("0");
    when(httpRequest.getParameter("c")).thenReturn("10");
    when(httpRequest.getParameter("s")).thenReturn(null);
    when(httpRequest.getParameterValues("f")).thenReturn(new String[]{"status=running"});

    // When
    var result = controller.validateInputParameters(httpRequest);

    // Then
    assertThat(result.getFilters()).isNotEmpty();
}

@Test
@DisplayName("should parse multiple filter parameters")
void should_parse_multiple_filter_parameters() throws ValidationException {
    // Given
    when(httpRequest.getParameter("p")).thenReturn("0");
    when(httpRequest.getParameter("c")).thenReturn("10");
    when(httpRequest.getParameterValues("f")).thenReturn(
        new String[]{"status=running", "category=HR"});

    // When
    var result = controller.validateInputParameters(httpRequest);

    // Then
    assertThat(result.getFilters()).hasSize(2);
}

@Test
@DisplayName("should handle null filter array")
void should_handle_null_filter_array() throws ValidationException {
    // Given
    when(httpRequest.getParameter("p")).thenReturn("0");
    when(httpRequest.getParameter("c")).thenReturn("10");
    when(httpRequest.getParameterValues("f")).thenReturn(null);

    // When
    var result = controller.validateInputParameters(httpRequest);

    // Then
    assertThat(result.getFilters()).isEmpty();
}
```

### Search Parameter (s)

```java
@Test
@DisplayName("should parse search text parameter")
void should_parse_search_text_parameter() throws ValidationException {
    // Given
    when(httpRequest.getParameter("p")).thenReturn("0");
    when(httpRequest.getParameter("c")).thenReturn("10");
    when(httpRequest.getParameter("s")).thenReturn("Sales Process");
    when(httpRequest.getParameterValues("f")).thenReturn(null);

    // When
    var result = controller.validateInputParameters(httpRequest);

    // Then
    assertThat(result.getSearchText()).isEqualTo("Sales Process");
}

@Test
@DisplayName("should handle null search parameter")
void should_handle_null_search_parameter() throws ValidationException {
    // Given
    when(httpRequest.getParameter("p")).thenReturn("0");
    when(httpRequest.getParameter("c")).thenReturn("10");
    when(httpRequest.getParameter("s")).thenReturn(null);
    when(httpRequest.getParameterValues("f")).thenReturn(null);

    // When
    var result = controller.validateInputParameters(httpRequest);

    // Then
    assertThat(result.getSearchText()).isNull();
}
```

---

## Error Handling Verification

### Exception-to-HTTP-Status Mapping

```java
// ValidationException --> 400 Bad Request
@Test
void should_map_ValidationException_to_400() {
    doThrow(new ValidationException("Missing 'p'"))
        .when(controller).validateInputParameters(httpRequest);

    controller.doHandle(httpRequest, responseBuilder, context);

    verify(responseBuilder).withResponseStatus(eq(400));
}

// RuntimeException --> 500 Internal Server Error
@Test
void should_map_RuntimeException_to_500() {
    var params = createTestParams();
    doReturn(params).when(controller).validateInputParameters(httpRequest);
    doThrow(new RuntimeException("Database error"))
        .when(controller).execute(context, params);

    controller.doHandle(httpRequest, responseBuilder, context);

    verify(responseBuilder).withResponseStatus(eq(500));
}

// NullPointerException --> 500 Internal Server Error
@Test
void should_map_NullPointerException_to_500() {
    var params = createTestParams();
    doReturn(params).when(controller).validateInputParameters(httpRequest);
    doThrow(new NullPointerException("null data"))
        .when(controller).execute(context, params);

    controller.doHandle(httpRequest, responseBuilder, context);

    verify(responseBuilder).withResponseStatus(eq(500));
}

// IllegalStateException --> 500 Internal Server Error
@Test
void should_map_IllegalStateException_to_500() {
    var params = createTestParams();
    doReturn(params).when(controller).validateInputParameters(httpRequest);
    doThrow(new IllegalStateException("Invalid state"))
        .when(controller).execute(context, params);

    controller.doHandle(httpRequest, responseBuilder, context);

    verify(responseBuilder).withResponseStatus(eq(500));
}
```

### Null Safety Testing

```java
@Test
@DisplayName("should handle null result from execute gracefully")
void should_handle_null_result_from_execute_gracefully() {
    // Given
    var params = createTestParams();
    doReturn(params).when(controller).validateInputParameters(httpRequest);
    doReturn(null).when(controller).execute(context, params);

    // When
    RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

    // Then - should not throw, handle gracefully
    assertThat(response).isNotNull();
}

@Test
@DisplayName("should handle null validation error message")
void should_handle_null_validation_error_message() {
    // Given
    doThrow(new ValidationException(null))
        .when(controller).validateInputParameters(httpRequest);

    // When
    RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

    // Then
    assertThat(response).isNotNull();
    verify(responseBuilder).withResponseStatus(eq(400));
}
```

---

## Complete Controller Test Example

Here is a complete, production-quality test class for a paginated list controller:

```java
package com.bonitasoft.processbuilder.rest.api.controller.myEntity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;

import javax.servlet.http.HttpServletRequest;

import org.bonitasoft.engine.api.APIClient;
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
import org.mockito.Mockito;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import com.bonitasoft.processbuilder.rest.api.dto.parameter.ParamMyEntity;
import com.bonitasoft.processbuilder.rest.api.dto.result.ResultMyEntity;
import com.bonitasoft.processbuilder.rest.api.exception.ValidationException;
import com.bonitasoft.processbuilder.rest.api.utils.LicenseValidator;
import com.company.model.MyEntityDAO;

/**
 * Integration tests for AbstractMyEntity controller doHandle() flow.
 *
 * Tests the full request lifecycle: HTTP request -> validation -> execution -> response.
 * Covers all HTTP status code paths: 200, 400, 403, 500.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
@DisplayName("AbstractMyEntity - Integration Tests")
class AbstractMyEntityTest {

    // =========================================================================
    // Constants
    // =========================================================================
    private static final Long TEST_USER_ID = 1L;
    private static final Integer TEST_PAGE_INDEX = 0;
    private static final Integer TEST_PAGE_SIZE = 10;
    private static final Long TEST_TOTAL_COUNT = 25L;
    private static final String TEST_VALIDATION_ERROR = "Required parameter 'p' is missing";
    private static final String TEST_EXECUTION_ERROR = "Database connection failed";

    // =========================================================================
    // Mocks
    // =========================================================================
    @Spy
    private TestableAbstractMyEntity controller;

    @Mock
    private HttpServletRequest httpRequest;

    @Mock
    private RestApiResponseBuilder responseBuilder;

    @Mock
    private RestAPIContext context;

    @Mock
    private RestApiResponse mockResponse;

    // =========================================================================
    // Setup / Teardown
    // =========================================================================
    @BeforeEach
    void setUp() {
        LicenseValidator.enableTestMode();

        when(responseBuilder.withResponseStatus(any(Integer.class))).thenReturn(responseBuilder);
        when(responseBuilder.withResponse(any(String.class))).thenReturn(responseBuilder);
        when(responseBuilder.withContentRange(any(Integer.class), any(Integer.class), any(Long.class)))
            .thenReturn(responseBuilder);
        when(responseBuilder.build()).thenReturn(mockResponse);
    }

    @AfterEach
    void tearDown() {
        LicenseValidator.disableTestMode();
    }

    // =========================================================================
    // I. doHandle - Success (200 OK)
    // =========================================================================
    @Nested
    @DisplayName("doHandle - Success (200 OK)")
    class DoHandleSuccess {

        @Test
        @DisplayName("should return 200 OK when validation and execution succeed")
        void should_return_200_OK_when_validation_and_execution_succeed() {
            var params = createTestParams();
            var result = createTestResult();
            doReturn(params).when(controller).validateInputParameters(httpRequest);
            doReturn(result).when(controller).execute(context, params);

            RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(eq(200));
        }

        @Test
        @DisplayName("should include pagination headers in 200 response")
        void should_include_pagination_headers_in_200_response() {
            var params = createTestParams();
            var result = createTestResult();
            doReturn(params).when(controller).validateInputParameters(httpRequest);
            doReturn(result).when(controller).execute(context, params);

            controller.doHandle(httpRequest, responseBuilder, context);

            verify(responseBuilder).withContentRange(
                eq(TEST_PAGE_INDEX), eq(TEST_PAGE_SIZE), eq(TEST_TOTAL_COUNT));
        }

        @Test
        @DisplayName("should call validate then execute in correct order")
        void should_call_validate_then_execute_in_correct_order() {
            var params = createTestParams();
            var result = createTestResult();
            doReturn(params).when(controller).validateInputParameters(httpRequest);
            doReturn(result).when(controller).execute(context, params);

            controller.doHandle(httpRequest, responseBuilder, context);

            var inOrder = Mockito.inOrder(controller, responseBuilder);
            inOrder.verify(controller).validateInputParameters(httpRequest);
            inOrder.verify(controller).execute(context, params);
            inOrder.verify(responseBuilder).withResponseStatus(eq(200));
        }

        @Test
        @DisplayName("should handle empty result set successfully")
        void should_handle_empty_result_set_successfully() {
            var params = createTestParams();
            var emptyResult = ResultMyEntity.builder()
                .p(TEST_PAGE_INDEX).c(TEST_PAGE_SIZE).total(0L)
                .data(Collections.emptyList()).build();
            doReturn(params).when(controller).validateInputParameters(httpRequest);
            doReturn(emptyResult).when(controller).execute(context, params);

            RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(eq(200));
        }
    }

    // =========================================================================
    // II. doHandle - Validation Failure (400 Bad Request)
    // =========================================================================
    @Nested
    @DisplayName("doHandle - Validation Failure (400 Bad Request)")
    class DoHandleValidationFailure {

        @Test
        @DisplayName("should return 400 when validation fails")
        void should_return_400_when_validation_fails() {
            doThrow(new ValidationException(TEST_VALIDATION_ERROR))
                .when(controller).validateInputParameters(httpRequest);

            RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(eq(400));
        }

        @Test
        @DisplayName("should not call execute when validation fails")
        void should_not_call_execute_when_validation_fails() {
            doThrow(new ValidationException(TEST_VALIDATION_ERROR))
                .when(controller).validateInputParameters(httpRequest);

            controller.doHandle(httpRequest, responseBuilder, context);

            verify(controller, never()).execute(any(), any());
        }
    }

    // =========================================================================
    // III. doHandle - Execution Failure (500 Internal Server Error)
    // =========================================================================
    @Nested
    @DisplayName("doHandle - Execution Failure (500 Internal Server Error)")
    class DoHandleExecutionFailure {

        @Test
        @DisplayName("should return 500 when execution throws RuntimeException")
        void should_return_500_when_execution_throws_RuntimeException() {
            var params = createTestParams();
            doReturn(params).when(controller).validateInputParameters(httpRequest);
            doThrow(new RuntimeException(TEST_EXECUTION_ERROR))
                .when(controller).execute(context, params);

            RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(eq(500));
        }
    }

    // =========================================================================
    // IV. doHandle - License Failure (403 Forbidden)
    // =========================================================================
    @Nested
    @DisplayName("doHandle - License Failure (403 Forbidden)")
    class DoHandleLicenseFailure {

        @Test
        @DisplayName("should return 403 when license is invalid")
        void should_return_403_when_license_is_invalid() {
            LicenseValidator.disableTestMode();

            RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

            assertThat(response).isNotNull();
            verify(controller, never()).execute(any(), any());
        }
    }

    // =========================================================================
    // V. Helper Methods
    // =========================================================================
    private ParamMyEntity createTestParams() {
        return new ParamMyEntity(TEST_PAGE_INDEX, TEST_PAGE_SIZE, null, new HashMap<>());
    }

    private ResultMyEntity createTestResult() {
        return ResultMyEntity.builder()
            .p(TEST_PAGE_INDEX)
            .c(TEST_PAGE_SIZE)
            .total(TEST_TOTAL_COUNT)
            .data(new ArrayList<>())
            .build();
    }

    // =========================================================================
    // VI. Testable Concrete Implementation
    // =========================================================================
    static class TestableAbstractMyEntity extends AbstractMyEntity {

        @Override
        protected ResultMyEntity execute(RestAPIContext context, ParamMyEntity params) {
            return ResultMyEntity.builder().build();
        }

        @Override
        protected ParamMyEntity validateInputParameters(HttpServletRequest request)
                throws ValidationException {
            return new ParamMyEntity(0, 10, null, new HashMap<>());
        }
    }
}
```
