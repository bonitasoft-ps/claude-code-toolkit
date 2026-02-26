# Connector and Event Handler Standards

This reference covers coding standards, error handling patterns, and best practices specific to
Bonita Connectors, Event Handlers, and Actor Filters.

---

## 1. Connector Development Standards

### 1.1 Error Handling (MANDATORY)

Every connector MUST implement robust error handling. A connector that fails silently is
unacceptable.

**Required pattern:**

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ExternalServiceConnector extends AbstractConnectorImpl {

    private static final Logger logger = LoggerFactory.getLogger(ExternalServiceConnector.class);

    private static final String ERROR_CONNECTION_FAILED = "Failed to connect to external service: %s";
    private static final String ERROR_RESPONSE_INVALID = "Invalid response from service: status=%d, body=%s";

    @Override
    protected void executeBusinessLogic() throws ConnectorException {
        var serviceUrl = (String) getInputParameter("serviceUrl");
        var requestPayload = (String) getInputParameter("requestPayload");

        try {
            logger.info("Calling external service at: {}", serviceUrl);
            var response = callExternalService(serviceUrl, requestPayload);
            validateResponse(response);
            setOutputParameter("result", mapToJavaObject(response));
            logger.info("External service call successful");

        } catch (ConnectionException e) {
            var message = ERROR_CONNECTION_FAILED.formatted(serviceUrl);
            logger.error(message, e);
            throw new ConnectorException(message, e);

        } catch (ValidationException e) {
            logger.error("Response validation failed: {}", e.getMessage(), e);
            throw new ConnectorException(e.getMessage(), e);

        } catch (Exception e) {
            logger.error("Unexpected error during connector execution", e);
            throw new ConnectorException(
                "Unexpected error: " + e.getMessage(), e);
        }
    }
}
```

**Key rules:**

- ALWAYS wrap the entire business logic in a try-catch block.
- ALWAYS log the error with sufficient context BEFORE re-throwing.
- Include the original exception as the cause when throwing `ConnectorException`.
- Use specific exception types for different failure modes.
- Log at appropriate levels: `INFO` for normal flow, `WARN` for recoverable issues, `ERROR` for failures.

### 1.2 Connection Management (MANDATORY)

Connectors that open connections to external systems (databases, APIs, file systems) MUST
close those connections, even when an error occurs.

**Required pattern:**

```java
@Override
protected void executeBusinessLogic() throws ConnectorException {
    Connection connection = null;
    try {
        connection = dataSource.getConnection();
        // ... business logic using connection ...
        setOutputParameter("result", result);

    } catch (SQLException e) {
        logger.error("Database query failed: {}", e.getMessage(), e);
        throw new ConnectorException("Database error", e);

    } finally {
        if (connection != null) {
            try {
                connection.close();
                logger.debug("Database connection closed successfully");
            } catch (SQLException e) {
                logger.warn("Failed to close database connection", e);
            }
        }
    }
}
```

**Better: Use try-with-resources when possible:**

```java
@Override
protected void executeBusinessLogic() throws ConnectorException {
    try (var connection = dataSource.getConnection();
         var statement = connection.prepareStatement(QUERY)) {

        statement.setString(1, inputParam);
        try (var resultSet = statement.executeQuery()) {
            var result = mapResults(resultSet);
            setOutputParameter("result", result);
        }
    } catch (SQLException e) {
        logger.error("Database operation failed: {}", e.getMessage(), e);
        throw new ConnectorException("Database error", e);
    }
}
```

### 1.3 Return Value Rules (MANDATORY)

Connectors MUST return standard Java objects. This prevents classloader issues and library
conflicts between the connector and the process.

**Allowed return types:**

- `String`
- `Integer`, `Long`, `Double`, `Boolean` (and other boxed primitives)
- `Map<String, Object>` (preferred for structured data)
- `List<Map<String, Object>>` (for collections)
- `java.time` types (`LocalDate`, `LocalDateTime`, `Instant`)

**Prohibited return types:**

- BDM objects (the process should create/update BDM from the returned data)
- JSON library objects (`JsonObject`, `JsonNode`, etc.) -- the library must be available in both connector and process
- Library-specific objects (`Invoice`, `HttpResponse`, etc.)
- Connected/proxied objects (e.g., database ResultSets, open streams)

**Example of proper return value mapping:**

```java
/**
 * Maps an external service response to a standard Map.
 * This avoids returning library-specific objects.
 */
private Map<String, Object> mapToJavaObject(ServiceResponse response) {
    var result = new HashMap<String, Object>();
    result.put("id", response.getId());
    result.put("status", response.getStatus().name());
    result.put("amount", response.getAmount().doubleValue());
    result.put("createdAt", response.getCreatedAt().toString());
    result.put("metadata", mapMetadata(response.getMetadata()));
    return result;
}
```

### 1.4 Dependency Management

- **Minimize dependencies.** Each additional dependency increases the risk of classloader conflicts and connector size.
- **Encapsulate logic** within the connector. Do not rely on external utility classes that would need to be deployed separately.
- **Shade or relocate** dependencies that conflict with Bonita runtime libraries.
- **Document** all external dependencies in the connector's pom.xml with comments explaining why each is needed.

### 1.5 Input Parameters

- **Use the expression editor** to define input data for the connector. Do not hardcode values.
- **Validate inputs** at the start of `executeBusinessLogic()` before performing any operations.
- **Use constants** for input/output parameter names:

```java
private static final String INPUT_SERVICE_URL = "serviceUrl";
private static final String INPUT_REQUEST_PAYLOAD = "requestPayload";
private static final String OUTPUT_RESULT = "result";

@Override
protected void executeBusinessLogic() throws ConnectorException {
    var serviceUrl = (String) getInputParameter(INPUT_SERVICE_URL);
    if (serviceUrl == null || serviceUrl.isBlank()) {
        throw new ConnectorException("Service URL is required");
    }
    // ...
    setOutputParameter(OUTPUT_RESULT, result);
}
```

### 1.6 Unit Testing (MANDATORY for External Connectors)

Connectors developed outside Bonita Studio MUST include unit tests.

```java
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ExternalServiceConnectorTest {

    private static final String TEST_SERVICE_URL = "https://api.example.com/v1/resource";
    private static final String TEST_PAYLOAD = """
        {"key": "value"}
        """;

    @InjectMocks
    private ExternalServiceConnector connector;

    @Mock
    private HttpClient httpClient;

    @Test
    @DisplayName("should return mapped result when service responds successfully")
    void should_return_mapped_result_when_service_responds_successfully() throws Exception {
        // Given
        connector.setInputParameter("serviceUrl", TEST_SERVICE_URL);
        connector.setInputParameter("requestPayload", TEST_PAYLOAD);
        when(httpClient.send(any())).thenReturn(mockSuccessResponse());

        // When
        connector.executeBusinessLogic();

        // Then
        var result = (Map<String, Object>) connector.getOutputParameter("result");
        assertThat(result).isNotNull();
        assertThat(result).containsKey("id");
        assertThat(result).containsKey("status");
    }

    @Test
    @DisplayName("should throw ConnectorException when service is unreachable")
    void should_throw_exception_when_service_unreachable() {
        // Given
        connector.setInputParameter("serviceUrl", TEST_SERVICE_URL);
        when(httpClient.send(any())).thenThrow(new ConnectionException("Connection refused"));

        // Then
        assertThatThrownBy(() -> connector.executeBusinessLogic())
            .isInstanceOf(ConnectorException.class)
            .hasMessageContaining("Failed to connect");
    }
}
```

---

## 2. Event Handler Standards

### 2.1 Context Rules (MANDATORY)

Event Handlers MUST only use data from:
- The **process context** (variables, case data)
- The **BDM** (business data model)

Event Handlers MUST NOT:
- Contain complex business logic.
- Call external services directly.
- Perform long-running operations.

**Rationale:** Event Handlers execute within the Bonita Engine transaction. Long-running or
failure-prone operations can block the engine and cause transaction timeouts.

### 2.2 Error Handling in Event Handlers

```java
public class TaskAssignmentHandler implements SHandler<SEvent> {

    private static final Logger logger = LoggerFactory.getLogger(TaskAssignmentHandler.class);

    @Override
    public void execute(SEvent event) throws SHandlerExecutionException {
        try {
            if (event instanceof SActivityStateChangedEvent stateEvent) {
                processStateChange(stateEvent);
            }
        } catch (Exception e) {
            logger.error("Event handler failed for event: {}", event, e);
            // Decide: re-throw to roll back transaction or swallow to allow continuation
            throw new SHandlerExecutionException(
                "Failed to handle task assignment event", e);
        }
    }

    private void processStateChange(SActivityStateChangedEvent event) {
        // Simple logic only: read BDM, update a field, log an action
        logger.info("Task {} transitioned to state {}",
            event.getActivityInstanceId(), event.getNewState());
    }
}
```

### 2.3 Event Handler Anti-patterns

| Anti-pattern | Why it is wrong | Correct approach |
|---|---|---|
| Calling external REST APIs | Transaction timeout risk | Use a connector in a subsequent service task |
| Complex BDM queries with joins | Performance degradation | Use simple single-entity lookups |
| Sending emails | I/O blocking in transaction | Trigger an email connector via a signal/message |
| File system operations | I/O blocking, security risk | Delegate to a service task |
| Thread.sleep() or waiting | Blocks engine thread | Never wait in event handlers |

---

## 3. Actor Filter Standards

### 3.1 Performance Rules (MANDATORY)

Actor Filters execute during task assignment and must be **highly performant**. Slow filters
directly impact user experience because they delay task list rendering.

**Rules:**

- **No complex BDM queries** within Actor Filters. Use simple lookups only.
- **No external service calls** (REST, SOAP, database). Filters must resolve users from in-memory or simple BDM data.
- **Cache results** when the same filter runs repeatedly with the same criteria.
- **Return early** when the result is deterministic (e.g., a single known assignee).

### 3.2 Actor Filter Scope

Actor Filters should ONLY:
- Determine the list of users eligible for a task.
- Apply simple criteria: role, group membership, a BDM field value, process variable.

Actor Filters should NEVER:
- Perform business logic (validation, calculation, transformation).
- Modify data (BDM, process variables).
- Send notifications or trigger side effects.

### 3.3 Actor Filter Example

```java
public class DepartmentManagerFilter extends AbstractUserFilter {

    private static final Logger logger = LoggerFactory.getLogger(DepartmentManagerFilter.class);
    private static final String INPUT_DEPARTMENT_ID = "departmentId";

    @Override
    public List<Long> filter(String actorName) throws UserFilterException {
        var departmentId = (Long) getInputParameter(INPUT_DEPARTMENT_ID);

        if (departmentId == null) {
            logger.warn("Department ID is null, returning empty user list");
            return Collections.emptyList();
        }

        try {
            var managerId = findManagerForDepartment(departmentId);
            logger.debug("Resolved manager {} for department {}", managerId, departmentId);
            return List.of(managerId);

        } catch (Exception e) {
            logger.error("Failed to resolve manager for department {}", departmentId, e);
            throw new UserFilterException("Cannot determine manager", e);
        }
    }

    @Override
    public boolean shouldAutoAssignIfSingleResult() {
        return true;
    }
}
```

---

## 4. Common Patterns Across All Components

### 4.1 Logging Standards

All connectors, event handlers, and actor filters MUST use SLF4J logging.

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

// At class level
private static final Logger logger = LoggerFactory.getLogger(MyClass.class);

// Usage
logger.debug("Processing item: {}", itemId);           // Development/troubleshooting
logger.info("Operation completed: {} items", count);    // Normal operations
logger.warn("Retrying operation, attempt {}", attempt); // Recoverable issues
logger.error("Operation failed: {}", message, exception); // Failures (include exception)
```

**NEVER use:**

```java
System.out.println("Debug: " + value);   // PROHIBITED
System.err.println("Error: " + message); // PROHIBITED
e.printStackTrace();                       // PROHIBITED
```

### 4.2 Constants Pattern

```java
public final class ConnectorConstants {

    private ConnectorConstants() {
        // Prevent instantiation
    }

    // Input parameters
    public static final String INPUT_URL = "url";
    public static final String INPUT_METHOD = "method";
    public static final String INPUT_BODY = "body";
    public static final String INPUT_TIMEOUT = "timeout";

    // Output parameters
    public static final String OUTPUT_STATUS = "statusCode";
    public static final String OUTPUT_BODY = "responseBody";
    public static final String OUTPUT_HEADERS = "responseHeaders";

    // Default values
    public static final int DEFAULT_TIMEOUT_MS = 30_000;
    public static final int DEFAULT_MAX_RETRIES = 3;

    // Error messages
    public static final String ERROR_URL_REQUIRED = "URL is required and cannot be blank";
    public static final String ERROR_TIMEOUT_NEGATIVE = "Timeout must be a positive value";
}
```

### 4.3 Input Validation Pattern

```java
/**
 * Validates all input parameters before execution.
 *
 * @throws ConnectorValidationException if any input is invalid
 */
@Override
public void validateInputParameters() throws ConnectorValidationException {
    var errors = new ArrayList<String>();

    var url = (String) getInputParameter(INPUT_URL);
    if (url == null || url.isBlank()) {
        errors.add(ERROR_URL_REQUIRED);
    }

    var timeout = (Integer) getInputParameter(INPUT_TIMEOUT);
    if (timeout != null && timeout < 0) {
        errors.add(ERROR_TIMEOUT_NEGATIVE);
    }

    if (!errors.isEmpty()) {
        throw new ConnectorValidationException(
            "Input validation failed: " + String.join("; ", errors));
    }
}
```
