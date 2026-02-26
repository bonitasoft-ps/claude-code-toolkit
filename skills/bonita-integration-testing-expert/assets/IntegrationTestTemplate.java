package com.bonitasoft.processbuilder.rest.api.controller.TEMPLATE_PACKAGE;

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
import org.bonitasoft.engine.api.IdentityAPI;
import org.bonitasoft.engine.api.ProcessAPI;
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
import org.mockito.Mockito;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.bonitasoft.processbuilder.rest.api.exception.ValidationException;
import com.bonitasoft.processbuilder.rest.api.utils.LicenseValidator;
// TODO: Import your parameter DTO
// import com.bonitasoft.processbuilder.rest.api.dto.parameter.ParamYourController;
// TODO: Import your result DTO
// import com.bonitasoft.processbuilder.rest.api.dto.result.ResultYourController;
// TODO: Import your BDM DAO(s)
// import com.processbuilder.model.YourEntityDAO;

/**
 * Integration tests for Abstract{YourController} doHandle() flow.
 *
 * Tests the FULL request lifecycle through doHandle():
 *   HTTP request --> validation --> execution --> response building
 *
 * Covers all HTTP status code paths:
 * - 200 OK: Successful validation and execution
 * - 400 Bad Request: ValidationException from parameter validation
 * - 403 Forbidden: License validation failure
 * - 500 Internal Server Error: RuntimeException during execution
 *
 * Testing Standards Applied:
 * - Framework: JUnit Jupiter (JUnit 5)
 * - Mocking: Mockito 5
 * - Assertions: AssertJ (NEVER native JUnit assertions)
 * - Annotations: @ExtendWith(MockitoExtension.class) + @MockitoSettings(strictness = Strictness.LENIENT)
 * - Method naming: should_verb_noun_when_condition pattern
 * - Constants: private static final for all test data
 * - BDD: Given/When/Then structure in all tests
 *
 * @author Process-Builder Development Team
 * @version 1.0
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
@DisplayName("Abstract{YourController} - Integration Tests")  // TODO: Replace {YourController}
class AbstractYourControllerTest {  // TODO: Rename class

    private static final Logger LOGGER = LoggerFactory.getLogger(AbstractYourControllerTest.class.getName());

    // =========================================================================
    // I. Test Constants - CUSTOMIZE THESE
    // =========================================================================

    // Pagination constants
    private static final Integer TEST_PAGE_INDEX = 0;
    private static final Integer TEST_PAGE_SIZE = 10;
    private static final Long TEST_TOTAL_COUNT = 25L;

    // User constants
    private static final Long TEST_USER_ID = 789L;
    private static final String TEST_USERNAME = "john.doe";

    // Entity constants - TODO: Add your entity-specific constants
    private static final Long TEST_PERSISTENCE_ID = 123L;
    private static final Long TEST_PROCESS_INSTANCE_ID = 456L;
    private static final String TEST_ENTITY_NAME = "Test Entity";
    private static final String TEST_ENTITY_STATUS = "active";

    // Error message constants
    private static final String TEST_VALIDATION_ERROR = "Required parameter 'p' is missing";
    private static final String TEST_INVALID_PARAM_ERROR = "Parameter 'p' must be a valid integer";
    private static final String TEST_EXECUTION_ERROR = "Database connection failed";

    // =========================================================================
    // II. Mock Declarations
    // =========================================================================

    /**
     * The controller under test. Uses @Spy on a testable concrete subclass
     * so we can stub validateInputParameters() and execute() while testing
     * the real doHandle() orchestration logic.
     */
    @Spy
    private TestableController controller;  // TODO: Rename

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
    private ProcessAPI processAPI;

    @Mock
    private IdentityAPI identityAPI;

    // TODO: Add your BDM DAO mocks
    // @Mock
    // private YourEntityDAO yourEntityDAO;

    @Mock
    private RestApiResponse mockResponse;

    // =========================================================================
    // III. Setup and Teardown
    // =========================================================================

    @BeforeEach
    void setUp() {
        // MANDATORY: Enable test mode to bypass license validation
        LicenseValidator.enableTestMode();

        // Response builder fluent chain setup
        // Every method returns the builder itself for chaining
        when(responseBuilder.withResponseStatus(any(Integer.class)))
            .thenReturn(responseBuilder);
        when(responseBuilder.withResponse(any(String.class)))
            .thenReturn(responseBuilder);
        when(responseBuilder.withMediaType(any(String.class)))
            .thenReturn(responseBuilder);
        when(responseBuilder.withContentRange(
            any(Integer.class), any(Integer.class), any(Long.class)))
            .thenReturn(responseBuilder);
        when(responseBuilder.withAdditionalHeader(any(String.class), any(String.class)))
            .thenReturn(responseBuilder);
        when(responseBuilder.build())
            .thenReturn(mockResponse);

        // API context chain setup
        when(context.getApiClient()).thenReturn(apiClient);
        when(context.getApiSession()).thenReturn(apiSession);
        when(apiSession.getUserId()).thenReturn(TEST_USER_ID);
        when(apiSession.getUserName()).thenReturn(TEST_USERNAME);

        // Engine API setup
        when(apiClient.getProcessAPI()).thenReturn(processAPI);
        when(apiClient.getIdentityAPI()).thenReturn(identityAPI);

        // TODO: BDM DAO setup
        // when(apiClient.getDAO(YourEntityDAO.class)).thenReturn(yourEntityDAO);
    }

    @AfterEach
    void tearDown() {
        // MANDATORY: Disable test mode to prevent state leak between test classes
        LicenseValidator.disableTestMode();
    }

    // =========================================================================
    // IV. doHandle - Success (200 OK)
    // =========================================================================

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
        @DisplayName("should include pagination headers in 200 response")
        void should_include_pagination_headers_in_200_response() {
            // Given
            var params = createTestParams();
            var result = createTestResult();
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

        @Test
        @DisplayName("should handle empty result set successfully")
        void should_handle_empty_result_set_successfully() {
            // Given
            var params = createTestParams();
            var emptyResult = createEmptyTestResult();
            doReturn(params).when(controller).validateInputParameters(httpRequest);
            doReturn(emptyResult).when(controller).execute(context, params);

            // When
            RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(eq(200));
            verify(responseBuilder).withContentRange(
                eq(TEST_PAGE_INDEX), eq(TEST_PAGE_SIZE), eq(0L));
        }

        @Test
        @DisplayName("should handle large result set pagination")
        void should_handle_large_result_set_pagination() {
            // Given
            var params = createTestParams();
            // TODO: Create result with large dataset
            var largeResult = createTestResult(); // Replace with large result
            doReturn(params).when(controller).validateInputParameters(httpRequest);
            doReturn(largeResult).when(controller).execute(context, params);

            // When
            RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(eq(200));
        }
    }

    // =========================================================================
    // V. doHandle - Validation Failure (400 Bad Request)
    // =========================================================================

    @Nested
    @DisplayName("doHandle - Validation Failure (400 Bad Request)")
    class DoHandleValidationFailure {

        @Test
        @DisplayName("should return 400 when required parameter is missing")
        void should_return_400_when_required_parameter_is_missing() {
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
        @DisplayName("should return 400 when parameter format is invalid")
        void should_return_400_when_parameter_format_is_invalid() {
            // Given
            doThrow(new ValidationException(TEST_INVALID_PARAM_ERROR))
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
            verify(controller).validateInputParameters(httpRequest);
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
    }

    // =========================================================================
    // VI. doHandle - Execution Failure (500 Internal Server Error)
    // =========================================================================

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
        @DisplayName("should return 500 when execution throws NullPointerException")
        void should_return_500_when_execution_throws_NullPointerException() {
            // Given
            var params = createTestParams();
            doReturn(params).when(controller).validateInputParameters(httpRequest);
            doThrow(new NullPointerException("Null entity data"))
                .when(controller).execute(context, params);

            // When
            RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(eq(500));
        }

        @Test
        @DisplayName("should return 500 when execution throws IllegalStateException")
        void should_return_500_when_execution_throws_IllegalStateException() {
            // Given
            var params = createTestParams();
            doReturn(params).when(controller).validateInputParameters(httpRequest);
            doThrow(new IllegalStateException("Invalid state transition"))
                .when(controller).execute(context, params);

            // When
            RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(eq(500));
        }

        @Test
        @DisplayName("should include error details in 500 response body")
        void should_include_error_details_in_500_response_body() {
            // Given
            var params = createTestParams();
            doReturn(params).when(controller).validateInputParameters(httpRequest);
            doThrow(new RuntimeException(TEST_EXECUTION_ERROR))
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
            var params = createTestParams();
            doReturn(params).when(controller).validateInputParameters(httpRequest);
            doThrow(new RuntimeException((String) null))
                .when(controller).execute(context, params);

            // When
            RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(eq(500));
        }
    }

    // =========================================================================
    // VII. doHandle - License Failure (403 Forbidden)
    // =========================================================================

    @Nested
    @DisplayName("doHandle - License Failure (403 Forbidden)")
    class DoHandleLicenseFailure {

        @Test
        @DisplayName("should return 403 when license is invalid")
        void should_return_403_when_license_is_invalid() {
            // Given - disable test mode to simulate real license check
            LicenseValidator.disableTestMode();

            // When
            RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            // Validation and execution should not be reached
            verify(controller, never()).execute(any(), any());
        }
    }

    // =========================================================================
    // VIII. doHandle - Edge Cases and Null Handling
    // =========================================================================

    @Nested
    @DisplayName("doHandle - Edge Cases")
    class DoHandleEdgeCases {

        @Test
        @DisplayName("should handle null result from execute")
        void should_handle_null_result_from_execute() {
            // Given
            var params = createTestParams();
            doReturn(params).when(controller).validateInputParameters(httpRequest);
            doReturn(null).when(controller).execute(context, params);

            // When
            RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

            // Then - should handle gracefully (may return 200 or 500 depending on controller)
            assertThat(response).isNotNull();
        }

        @Test
        @DisplayName("should handle result with null data list")
        void should_handle_result_with_null_data_list() {
            // Given
            var params = createTestParams();
            // TODO: Create a result with null data list
            var resultWithNullData = createTestResult(); // Replace with null-data result
            doReturn(params).when(controller).validateInputParameters(httpRequest);
            doReturn(resultWithNullData).when(controller).execute(context, params);

            // When
            RestApiResponse response = controller.doHandle(httpRequest, responseBuilder, context);

            // Then
            assertThat(response).isNotNull();
            verify(responseBuilder).withResponseStatus(eq(200));
        }
    }

    // =========================================================================
    // IX. Helper Methods - CUSTOMIZE THESE
    // =========================================================================

    /**
     * Creates a standard set of test parameters for the controller.
     *
     * TODO: Replace with your actual parameter DTO constructor
     *
     * @return A valid parameter object for testing
     */
    private Object createTestParams() {
        // TODO: Return your actual parameter DTO
        // return new ParamYourController(TEST_PAGE_INDEX, TEST_PAGE_SIZE, null, new HashMap<>());
        return new Object(); // Placeholder - replace with real params
    }

    /**
     * Creates a standard test result with sample data.
     *
     * TODO: Replace with your actual result DTO builder
     *
     * @return A valid result object with test data
     */
    private Object createTestResult() {
        // TODO: Return your actual result DTO
        // return ResultYourController.builder()
        //     .p(TEST_PAGE_INDEX)
        //     .c(TEST_PAGE_SIZE)
        //     .total(TEST_TOTAL_COUNT)
        //     .data(new ArrayList<>())
        //     .build();
        return new Object(); // Placeholder - replace with real result
    }

    /**
     * Creates an empty test result (no data, zero total).
     *
     * TODO: Replace with your actual result DTO builder
     *
     * @return An empty result object
     */
    private Object createEmptyTestResult() {
        // TODO: Return your actual empty result DTO
        // return ResultYourController.builder()
        //     .p(TEST_PAGE_INDEX)
        //     .c(TEST_PAGE_SIZE)
        //     .total(0L)
        //     .data(Collections.emptyList())
        //     .build();
        return new Object(); // Placeholder - replace with real empty result
    }

    // =========================================================================
    // X. Testable Concrete Implementation - CUSTOMIZE THIS
    // =========================================================================

    /**
     * Minimal concrete implementation of the abstract controller for testing.
     *
     * This class provides default implementations of abstract methods that
     * will be overridden by Mockito's @Spy mechanism in tests. The methods
     * return sensible defaults in case they are called without being stubbed.
     *
     * TODO: Rename and adjust signatures to match your controller
     */
    static class TestableController extends Object /* TODO: extends AbstractYourController */ {

        // TODO: Uncomment and implement these methods matching your abstract class
        //
        // @Override
        // protected ResultYourController execute(
        //         RestAPIContext context, ParamYourController params) {
        //     // Default: return empty result (will be mocked in tests)
        //     return ResultYourController.builder()
        //         .p(0).c(10).total(0L).data(new ArrayList<>()).build();
        // }
        //
        // @Override
        // protected ParamYourController validateInputParameters(
        //         HttpServletRequest request) throws ValidationException {
        //     // Default: return default params (will be mocked in tests)
        //     return new ParamYourController(0, 10, null, new HashMap<>());
        // }

        // Placeholder for doHandle - remove when extending real abstract class
        public RestApiResponse doHandle(HttpServletRequest request,
                RestApiResponseBuilder responseBuilder, RestAPIContext context) {
            return null; // TODO: Remove this method; the real one comes from abstract class
        }

        // Placeholder methods - remove when extending real abstract class
        protected Object validateInputParameters(HttpServletRequest request) {
            return null; // TODO: Remove
        }

        protected Object execute(RestAPIContext context, Object params) {
            return null; // TODO: Remove
        }
    }
}

// =============================================================================
// HOW TO USE THIS TEMPLATE
// =============================================================================
//
// 1. COPY this file to your controller's test package:
//    src/test/java/com/bonitasoft/processbuilder/rest/api/controller/{name}/
//
// 2. RENAME the file: Abstract{YourController}Test.java
//
// 3. SEARCH AND REPLACE all TODO markers:
//    - Replace package name
//    - Replace class names (AbstractYourControllerTest, TestableController)
//    - Replace parameter DTO type (ParamYourController)
//    - Replace result DTO type (ResultYourController)
//    - Replace BDM DAO type(s) (YourEntityDAO)
//    - Update test constants with realistic values
//    - Implement createTestParams() and createTestResult() helpers
//    - Implement TestableController extending your real abstract class
//
// 4. ADD controller-specific tests:
//    - Tests for specific validation rules
//    - Tests for specific business logic scenarios
//    - Tests for specific error conditions
//    - Tests for specific pagination/filtering behavior
//
// 5. RUN the tests:
//    mvn test -f extensions/pom.xml -Dtest=AbstractYourControllerTest
//
// 6. CHECK coverage:
//    mvn jacoco:report -f extensions/pom.xml
//    Target: 80%+ line coverage, 70%+ branch coverage
//
// =============================================================================
