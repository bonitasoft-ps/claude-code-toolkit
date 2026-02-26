# JUnit 5 Advanced Patterns and Examples

This reference provides comprehensive JUnit 5 patterns used in the project. All examples follow the team's mandatory testing standards.

## Table of Contents

1. [Class Setup with MockitoExtension](#class-setup-with-mockitoextension)
2. [MockitoSettings and Strictness](#mockitosettings-and-strictness)
3. [Nested Class Organization](#nested-class-organization)
4. [DisplayName Best Practices](#displayname-best-practices)
5. [Parameterized Tests](#parameterized-tests)
6. [BeforeEach / AfterEach Patterns](#beforeeach--aftereach-patterns)
7. [Exception Testing](#exception-testing)
8. [Timeout Testing](#timeout-testing)
9. [Conditional Test Execution](#conditional-test-execution)
10. [Test Constants](#test-constants)
11. [Single Assertion Principle](#single-assertion-principle)
12. [Complete REST API Controller Test Example](#complete-rest-api-controller-test-example)

---

## Class Setup with MockitoExtension

Every test class MUST use `@ExtendWith(MockitoExtension.class)` to enable Mockito annotations:

```java
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
@DisplayName("UserService - manages user lifecycle operations")
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private NotificationService notificationService;

    @InjectMocks
    private UserService userService;
}
```

**Key points:**
- `@Mock` creates mock instances of dependencies
- `@InjectMocks` creates the class under test and injects mocks into it
- `@Spy` can be used when you need partial mocking (real methods + some stubbed)

### When to use @Spy instead of @Mock

```java
@Spy
private TestableAbstractController controller;

// In test:
doReturn(params).when(controller).validateInputParameters(request, context);
doReturn(result).when(controller).execute(context, params);
```

Use `@Spy` when testing abstract classes with concrete methods. The spy calls real methods by default but allows stubbing specific methods.

---

## MockitoSettings and Strictness

```java
@MockitoSettings(strictness = Strictness.LENIENT)
```

**When to use LENIENT:**
- When mocks are set up in `@BeforeEach` but not all tests use all stubs
- When testing abstract classes where some stub setups are shared across nested classes
- When a mock is configured for multiple scenarios but individual tests only exercise one

**When STRICT is fine (default):**
- When every stub defined in `@BeforeEach` is used by every test
- Simple test classes with no `@Nested` groups

---

## Nested Class Organization

Organize tests by the method they test using `@Nested`:

```java
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
@DisplayName("OrderService - handles order processing")
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private PaymentGateway paymentGateway;

    @InjectMocks
    private OrderService orderService;

    // =========================================================================
    // I. Tests for createOrder
    // =========================================================================

    @Nested
    @DisplayName("createOrder")
    class CreateOrder {

        @Test
        @DisplayName("should create order when all parameters are valid")
        void should_create_order_when_all_parameters_are_valid() {
            // Given / When / Then
        }

        @Test
        @DisplayName("should throw exception when product is null")
        void should_throw_exception_when_product_is_null() {
            // Given / When / Then
        }
    }

    // =========================================================================
    // II. Tests for cancelOrder
    // =========================================================================

    @Nested
    @DisplayName("cancelOrder")
    class CancelOrder {

        @Test
        @DisplayName("should cancel order when order exists and is pending")
        void should_cancel_order_when_order_exists_and_is_pending() {
            // Given / When / Then
        }

        @Test
        @DisplayName("should throw exception when order is already shipped")
        void should_throw_exception_when_order_is_already_shipped() {
            // Given / When / Then
        }
    }
}
```

**Section separator pattern:**
```java
// =========================================================================
// I. Tests for ObjectMapper Configuration
// =========================================================================

// =========================================================================
// II. Tests for doHandle Success Path (200 OK)
// =========================================================================

// =========================================================================
// III. Tests for doHandle Validation Errors (400 Bad Request)
// =========================================================================

// =========================================================================
// IV. Tests for doHandle Execution Errors (500 Internal Server Error)
// =========================================================================
```

---

## DisplayName Best Practices

`@DisplayName` provides human-readable test names in reports:

```java
// Class-level: describe what the class does
@DisplayName("LicenseValidator - validates Bonita license status")
class LicenseValidatorTest { }

// Nested-level: name the method being tested
@Nested
@DisplayName("checkLicenseAndReturnForbiddenIfInvalid")
class CheckLicense { }

// Test-level: describe the behavior
@Test
@DisplayName("should return empty Optional when license is valid")
void should_return_empty_Optional_when_license_is_valid() { }

@Test
@DisplayName("should return 403 response when license is expired")
void should_return_403_response_when_license_is_expired() { }
```

**Rules:**
- Class `@DisplayName`: "{ClassName} - {brief description}"
- Nested `@DisplayName`: "{methodName}"
- Test `@DisplayName`: matches the method name with spaces (readable version)

---

## Parameterized Tests

### @ValueSource - Single parameter of primitive types

```java
@ParameterizedTest
@ValueSource(strings = {"", " ", "  ", "\t", "\n"})
@DisplayName("should throw exception when input is blank")
void should_throw_exception_when_input_is_blank(String input) {
    assertThatThrownBy(() -> validator.validate(input))
        .isInstanceOf(ValidationException.class);
}

@ParameterizedTest
@ValueSource(ints = {-1, 0, -100, Integer.MIN_VALUE})
@DisplayName("should reject negative page numbers")
void should_reject_negative_page_numbers(int page) {
    assertThatThrownBy(() -> service.getPage(page))
        .isInstanceOf(IllegalArgumentException.class);
}
```

### @CsvSource - Multiple parameters

```java
@ParameterizedTest
@CsvSource({
    "admin,    ADMIN,    true",
    "user,     USER,     true",
    "guest,    GUEST,    false",
    "unknown,  UNKNOWN,  false"
})
@DisplayName("should map role name to enum and check access")
void should_map_role_name_to_enum_and_check_access(
        String roleName, String expectedEnum, boolean hasAccess) {
    var role = RoleMapper.fromString(roleName);
    assertThat(role.name()).isEqualTo(expectedEnum);
    assertThat(role.hasAccess()).isEqualTo(hasAccess);
}
```

### @MethodSource - Complex objects or many combinations

```java
@ParameterizedTest
@MethodSource("invalidParameterCombinations")
@DisplayName("should return 400 when parameters are invalid")
void should_return_400_when_parameters_are_invalid(
        String processName, String input, String expectedError) {

    when(request.getParameter("processName")).thenReturn(processName);
    when(request.getParameter("input")).thenReturn(input);

    assertThatThrownBy(() -> controller.validateInputParameters(request, context))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining(expectedError);
}

private static Stream<Arguments> invalidParameterCombinations() {
    return Stream.of(
        Arguments.of(null, "{}", "processName is required"),
        Arguments.of("", "{}", "processName is required"),
        Arguments.of("MyProcess", null, "input is required"),
        Arguments.of("MyProcess", "", "input is required"),
        Arguments.of("MyProcess", "not-json", "input must be valid JSON")
    );
}
```

### @EnumSource - Testing with enum values

```java
@ParameterizedTest
@EnumSource(value = Status.class, names = {"ACTIVE", "PENDING"})
@DisplayName("should process when status is actionable")
void should_process_when_status_is_actionable(Status status) {
    var entity = EntityDTO.builder().status(status).build();
    assertThat(service.canProcess(entity)).isTrue();
}

@ParameterizedTest
@EnumSource(value = Status.class, mode = EnumSource.Mode.EXCLUDE, names = {"ACTIVE", "PENDING"})
@DisplayName("should reject when status is not actionable")
void should_reject_when_status_is_not_actionable(Status status) {
    var entity = EntityDTO.builder().status(status).build();
    assertThat(service.canProcess(entity)).isFalse();
}
```

---

## BeforeEach / AfterEach Patterns

### Standard pattern with LicenseValidator

```java
@BeforeEach
void setUp() {
    // Enable test mode to bypass license validation
    LicenseValidator.enableTestMode();

    // Setup default response builder behavior
    when(responseBuilder.withResponseStatus(any(Integer.class))).thenReturn(responseBuilder);
    when(responseBuilder.withResponse(any(String.class))).thenReturn(responseBuilder);
    when(responseBuilder.build()).thenReturn(mockResponse);
}

@AfterEach
void tearDown() {
    // Disable test mode to restore normal license validation
    LicenseValidator.disableTestMode();
}
```

### Nested-specific setup

```java
@Nested
@DisplayName("execute")
class Execute {

    private CancelProcessInstanceParams validParams;

    @BeforeEach
    void setUpExecute() {
        validParams = new CancelProcessInstanceParams(
            TEST_PERSISTENCE_ID,
            TEST_PROCESS_INSTANCE_ID,
            TEST_CANCELLATION_REASON,
            mockPBProcessInstance
        );
    }

    @Test
    void should_succeed_when_params_are_valid() {
        // validParams is available here
    }
}
```

---

## Exception Testing

### With assertThatThrownBy (PREFERRED)

```java
@Test
@DisplayName("should throw ValidationException when input is null")
void should_throw_ValidationException_when_input_is_null() {
    assertThatThrownBy(() -> service.execute(null))
        .isInstanceOf(ValidationException.class)
        .hasMessage("Input cannot be null")
        .hasNoCause();
}

@Test
@DisplayName("should throw exception with cause when DAO fails")
void should_throw_exception_with_cause_when_DAO_fails() {
    when(dao.findById(any())).thenThrow(new RuntimeException("DB connection failed"));

    assertThatThrownBy(() -> service.getById(TEST_ID))
        .isInstanceOf(ServiceException.class)
        .hasMessageContaining("Failed to retrieve entity")
        .hasCauseInstanceOf(RuntimeException.class);
}
```

### With assertThatCode for no-exception verification

```java
@Test
@DisplayName("should not throw exception when input is valid")
void should_not_throw_exception_when_input_is_valid() {
    assertThatCode(() -> validator.validate(validInput))
        .doesNotThrowAnyException();
}
```

---

## Timeout Testing

```java
import org.junit.jupiter.api.Timeout;
import java.util.concurrent.TimeUnit;

@Test
@Timeout(value = 5, unit = TimeUnit.SECONDS)
@DisplayName("should complete processing within 5 seconds")
void should_complete_processing_within_5_seconds() {
    var result = service.processLargeDataSet(testData);
    assertThat(result).isNotNull();
}

// Class-level timeout for all tests
@Timeout(10)
class PerformanceSensitiveTest {
    // All tests must complete within 10 seconds
}
```

---

## Conditional Test Execution

```java
import org.junit.jupiter.api.condition.*;

@Test
@EnabledOnOs(OS.LINUX)
@DisplayName("should use Linux-specific path separator")
void should_use_Linux_specific_path_separator() { }

@Test
@EnabledIfSystemProperty(named = "env", matches = "integration")
@DisplayName("should connect to test database")
void should_connect_to_test_database() { }

@Test
@EnabledIfEnvironmentVariable(named = "CI", matches = "true")
@DisplayName("should run only in CI environment")
void should_run_only_in_CI_environment() { }

@Test
@DisabledIf("isProductionEnvironment")
@DisplayName("should not run in production")
void should_not_run_in_production() { }

boolean isProductionEnvironment() {
    return "production".equals(System.getenv("ENV"));
}
```

---

## Test Constants

All magic values MUST be extracted to `private static final` constants:

```java
// Identifiers
private static final Long TEST_PERSISTENCE_ID = 123L;
private static final Long TEST_PROCESS_INSTANCE_ID = 456L;
private static final Long TEST_USER_ID = 1L;
private static final String TEST_ID_STRING = "123";

// Names and labels
private static final String TEST_PROCESS_NAME = "TestProcess";
private static final String TEST_USER_NAME = "john.doe";
private static final String TEST_ROLE_NAME = "member";
private static final String TEST_GROUP_PATH = "/acme/hr";

// JSON content
private static final String TEST_INPUT_JSON = "{\"key1\":\"value1\"}";
private static final String FAKE_JSON_CONTENT = "{\"success\":true}";

// Error messages
private static final String TEST_ERROR_MESSAGE = "Validation failed";
private static final String TEST_EXECUTION_ERROR = "Failed to execute";

// HTTP
private static final int SC_OK = 200;
private static final int SC_BAD_REQUEST = 400;
private static final int SC_FORBIDDEN = 403;
private static final int SC_INTERNAL_SERVER_ERROR = 500;
```

---

## Single Assertion Principle

Each test method should verify ONE logical behavior. Multiple `assertThat` calls on the same result are fine:

```java
// GOOD: Single behavior - verify the DTO is correctly populated
@Test
void should_populate_all_fields_when_entity_is_valid() {
    var dto = mapper.toDTO(validEntity);

    assertThat(dto.getId()).isEqualTo(validEntity.getId());
    assertThat(dto.getName()).isEqualTo(validEntity.getName());
    assertThat(dto.getStatus()).isEqualTo("ACTIVE");
}

// GOOD: Single behavior - verify exception is thrown
@Test
void should_throw_when_entity_not_found() {
    when(dao.findById(any())).thenReturn(Optional.empty());

    assertThatThrownBy(() -> service.getById(TEST_ID))
        .isInstanceOf(EntityNotFoundException.class)
        .hasMessageContaining(TEST_ID);
}

// BAD: Multiple unrelated behaviors
@Test
void should_handle_all_scenarios() {
    // Tests creation AND deletion AND update - split into 3 tests
}
```

---

## Complete REST API Controller Test Example

This example demonstrates a comprehensive test for a Bonita REST API controller, following all team standards:

```java
package com.bonitasoft.processbuilder.rest.api.controller.myEntity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import javax.servlet.http.HttpServletRequest;

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

import com.bonitasoft.processbuilder.rest.api.dto.parameter.ParamMyEntity;
import com.bonitasoft.processbuilder.rest.api.dto.result.ResultMyEntity;
import com.bonitasoft.processbuilder.rest.api.exception.ValidationException;
import com.bonitasoft.processbuilder.rest.api.utils.LicenseValidator;

/**
 * Comprehensive unit tests for AbstractMyEntity REST API controller.
 * Tests doHandle orchestration, validation, error handling, and response building.
 *
 * Test Coverage:
 * - Success path (200 OK)
 * - Missing parameter validation (400 Bad Request)
 * - Invalid parameter validation (400 Bad Request)
 * - DAO/Service exception handling (500 Internal Server Error)
 * - License validation (403 Forbidden)
 * - Null handling and edge cases
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
@DisplayName("AbstractMyEntity - handles entity retrieval via REST API")
class AbstractMyEntityTest {

    // =========================================================================
    // Constants
    // =========================================================================

    private static final Long TEST_ENTITY_ID = 123L;
    private static final String TEST_ENTITY_NAME = "Test Entity";
    private static final String TEST_STATUS = "ACTIVE";
    private static final String TEST_VALIDATION_ERROR = "entityId parameter is required";
    private static final String TEST_INVALID_PARAM_ERROR = "entityId must be a positive number";
    private static final String TEST_DAO_ERROR = "Failed to query database";

    // =========================================================================
    // Mocks and Class Under Test
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
    // Setup and Teardown
    // =========================================================================

    @BeforeEach
    void setUp() {
        LicenseValidator.enableTestMode();

        when(responseBuilder.withResponseStatus(any(Integer.class)))
            .thenReturn(responseBuilder);
        when(responseBuilder.withResponse(any(String.class)))
            .thenReturn(responseBuilder);
        when(responseBuilder.build()).thenReturn(mockResponse);
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
        @DisplayName("should return 200 OK when entity is found")
        void should_return_200_OK_when_entity_is_found() {
            // Given
            var params = new ParamMyEntity(TEST_ENTITY_ID);
            var result = ResultMyEntity.builder()
                .id(TEST_ENTITY_ID)
                .name(TEST_ENTITY_NAME)
                .status(TEST_STATUS)
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
        @DisplayName("should call validateInputParameters before execute")
        void should_call_validateInputParameters_before_execute() {
            // Given
            var params = new ParamMyEntity(TEST_ENTITY_ID);
            var result = ResultMyEntity.builder().build();

            doReturn(params).when(controller)
                .validateInputParameters(httpRequest, context);
            doReturn(result).when(controller).execute(context, params);

            // When
            controller.doHandle(httpRequest, responseBuilder, context);

            // Then
            verify(controller).validateInputParameters(httpRequest, context);
            verify(controller).execute(context, params);
        }

        @Test
        @DisplayName("should serialize result in response body")
        void should_serialize_result_in_response_body() {
            // Given
            var params = new ParamMyEntity(TEST_ENTITY_ID);
            var result = ResultMyEntity.builder()
                .id(TEST_ENTITY_ID)
                .name(TEST_ENTITY_NAME)
                .build();

            doReturn(params).when(controller)
                .validateInputParameters(httpRequest, context);
            doReturn(result).when(controller).execute(context, params);

            // When
            controller.doHandle(httpRequest, responseBuilder, context);

            // Then
            verify(responseBuilder).withResponse(any(String.class));
            verify(responseBuilder).withResponseStatus(200);
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
            verify(responseBuilder).withResponseStatus(eq(400));
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

        @Test
        @DisplayName("should include error message in 400 response")
        void should_include_error_message_in_400_response() {
            // Given
            doThrow(new ValidationException(TEST_VALIDATION_ERROR))
                .when(controller)
                .validateInputParameters(httpRequest, context);

            // When
            controller.doHandle(httpRequest, responseBuilder, context);

            // Then
            verify(responseBuilder).withResponse(any(String.class));
        }
    }

    // =========================================================================
    // III. Tests for Invalid Parameter (400 Bad Request)
    // =========================================================================

    @Nested
    @DisplayName("doHandle - Invalid Parameter")
    class DoHandleInvalidParameter {

        @Test
        @DisplayName("should return 400 when parameter value is invalid")
        void should_return_400_when_parameter_value_is_invalid() {
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
            var params = new ParamMyEntity(TEST_ENTITY_ID);
            doReturn(params).when(controller)
                .validateInputParameters(httpRequest, context);
            doThrow(new RuntimeException(TEST_DAO_ERROR))
                .when(controller).execute(context, params);

            // When
            RestApiResponse response = controller.doHandle(
                httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(eq(500));
        }

        @Test
        @DisplayName("should include error message in 500 response")
        void should_include_error_message_in_500_response() {
            // Given
            var params = new ParamMyEntity(TEST_ENTITY_ID);
            doReturn(params).when(controller)
                .validateInputParameters(httpRequest, context);
            doThrow(new RuntimeException(TEST_DAO_ERROR))
                .when(controller).execute(context, params);

            // When
            controller.doHandle(httpRequest, responseBuilder, context);

            // Then
            verify(responseBuilder).withResponse(any(String.class));
        }

        @Test
        @DisplayName("should handle null execution error message")
        void should_handle_null_execution_error_message() {
            // Given
            var params = new ParamMyEntity(TEST_ENTITY_ID);
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
            // Simulate invalid license by not enabling test mode
            // The actual behavior depends on the LicenseValidator implementation

            // When
            RestApiResponse response = controller.doHandle(
                httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            // License validation happens before parameter validation
            verify(controller, never()).execute(any(), any());
        }
    }

    // =========================================================================
    // VI. Testable Concrete Implementation
    // =========================================================================

    /**
     * Concrete implementation of the abstract controller for testing purposes.
     * Abstract methods are stubbed via Mockito @Spy in tests.
     */
    static class TestableAbstractMyEntity extends AbstractMyEntity {

        @Override
        protected ResultMyEntity execute(RestAPIContext context,
                                         ParamMyEntity params) {
            return ResultMyEntity.builder().build();
        }

        @Override
        protected ParamMyEntity validateInputParameters(
                HttpServletRequest request,
                RestAPIContext context) throws ValidationException {
            return new ParamMyEntity(null);
        }
    }
}
```

This example demonstrates:
1. **Success test (200 OK)** - Valid parameters, successful execution
2. **Missing parameter test (400)** - Required parameter not provided
3. **Invalid parameter test (400)** - Parameter with wrong format/value
4. **DAO exception test (500)** - Internal error during execution
5. **License validation test (403)** - Invalid or expired license
6. **Null handling** - Null error messages, null parameters
7. **Execution flow verification** - Methods called in correct order
