# Java 17 Patterns and Best Practices for Bonita Projects

This reference provides comprehensive examples of Java 17 features that are **mandatory** in all
new Bonita project code. Each section includes the pattern rationale, usage guidelines, and
concrete code examples.

---

## 1. Records for DTOs and Value Objects

Records provide a concise syntax for immutable data carriers. They automatically generate
`equals()`, `hashCode()`, `toString()`, and accessor methods.

### When to use

- Data Transfer Objects (DTOs) between layers.
- Value objects that carry data without behavior.
- API response/request representations.
- Configuration holders.

### When NOT to use

- Classes that need mutable state.
- Classes requiring inheritance (Records are implicitly `final`).
- Classes with complex builder patterns (use Lombok `@Builder` instead).

### Examples

```java
/**
 * Represents a paginated API response.
 *
 * @param page    current page index (0-based)
 * @param count   items per page
 * @param total   total number of matching items
 * @param data    list of items for the current page
 */
public record PaginatedResponse<T>(
    int page,
    int count,
    long total,
    List<T> data
) {
    /**
     * Compact constructor with validation.
     */
    public PaginatedResponse {
        if (page < 0) {
            throw new IllegalArgumentException("Page index must be non-negative");
        }
        if (count <= 0) {
            throw new IllegalArgumentException("Count must be positive");
        }
        data = List.copyOf(data); // Defensive copy for immutability
    }

    /**
     * Returns true if there are more pages available.
     */
    public boolean hasNextPage() {
        return (long) (page + 1) * count < total;
    }
}
```

```java
/**
 * DTO representing a user in API responses.
 */
public record UserDTO(
    Long persistenceId,
    String userName,
    String firstName,
    String lastName,
    String email,
    LocalDateTime creationDate
) {}
```

```java
/**
 * Immutable parameter container for search queries.
 */
public record SearchParams(
    String query,
    int page,
    int count,
    String sortField,
    SortOrder sortOrder
) {
    public enum SortOrder { ASC, DESC }

    public SearchParams {
        query = query != null ? query.trim() : "";
        if (page < 0) page = 0;
        if (count <= 0) count = 10;
        if (sortField == null) sortField = "creationDate";
        if (sortOrder == null) sortOrder = SortOrder.DESC;
    }
}
```

---

## 2. Pattern Matching for instanceof

Pattern Matching eliminates the need for explicit casting after an `instanceof` check, improving
readability and reducing the risk of `ClassCastException`.

### Before (prohibited in new code)

```java
// BAD: Explicit cast after instanceof
if (obj instanceof String) {
    String s = (String) obj;
    logger.info("String value: {}", s.toLowerCase());
}
```

### After (required)

```java
// GOOD: Pattern matching with instanceof
if (obj instanceof String s) {
    logger.info("String value: {}", s.toLowerCase());
}
```

### Advanced patterns

```java
/**
 * Processes a Bonita API response based on its runtime type.
 */
public String describeResponse(Object response) {
    if (response instanceof ErrorResponse error && error.code() >= 500) {
        return "Server error: " + error.message();
    }
    if (response instanceof PaginatedResponse<?> paginated) {
        return "Found %d items (page %d)".formatted(paginated.total(), paginated.page());
    }
    if (response instanceof String message) {
        return "Simple message: " + message;
    }
    return "Unknown response type: " + response.getClass().getSimpleName();
}
```

```java
/**
 * Type-safe extraction from heterogeneous collections.
 */
public List<Long> extractIds(List<Object> items) {
    return items.stream()
        .filter(item -> item instanceof HasId hasId && hasId.getId() != null)
        .map(item -> ((HasId) item).getId())
        .toList();
}
```

---

## 3. Text Blocks for Multi-line Strings

Text Blocks preserve formatting and eliminate the need for string concatenation or escape
sequences in multi-line content. Use them for SQL, JSON, HTML, and log messages.

### SQL Queries

```java
private static final String FIND_BY_STATUS_QUERY = """
    SELECT e.persistenceId, e.name, e.status, e.creationDate
    FROM Entity e
    WHERE e.status = :status
      AND e.processInstanceId = :processInstanceId
    ORDER BY e.creationDate DESC
    """;
```

### JSON Templates

```java
private static final String ERROR_RESPONSE_TEMPLATE = """
    {
        "success": false,
        "error": {
            "code": %d,
            "message": "%s",
            "timestamp": "%s"
        }
    }
    """;

public String buildErrorJson(int code, String message) {
    return ERROR_RESPONSE_TEMPLATE.formatted(
        code,
        message,
        Instant.now().toString()
    );
}
```

### HTML Templates

```java
private static final String EMAIL_TEMPLATE = """
    <html>
    <body>
        <h1>Task Assignment Notification</h1>
        <p>Hello %s,</p>
        <p>You have been assigned to task: <strong>%s</strong></p>
        <p>Due date: %s</p>
        <a href="%s">Open Task</a>
    </body>
    </html>
    """;
```

### Log Messages

```java
logger.debug("""
    Processing request:
      Endpoint: {}
      User: {}
      Parameters: {}
    """, endpoint, userId, params);
```

---

## 4. Sealed Classes for Restricted Hierarchies

Sealed classes restrict which classes can extend or implement them, providing exhaustive type
checking at compile time.

### When to use

- API response types with a fixed set of outcomes.
- State machines with known states.
- Command/Event patterns with defined variants.

### Examples

```java
/**
 * Represents all possible outcomes of an API operation.
 */
public sealed interface ApiResult<T>
    permits ApiResult.Success, ApiResult.NotFound, ApiResult.ValidationError, ApiResult.ServerError {

    record Success<T>(T data) implements ApiResult<T> {}
    record NotFound<T>(String resourceId) implements ApiResult<T> {}
    record ValidationError<T>(List<String> errors) implements ApiResult<T> {}
    record ServerError<T>(String message, Throwable cause) implements ApiResult<T> {}
}
```

```java
/**
 * Process instance lifecycle states.
 */
public sealed interface ProcessState
    permits ProcessState.Draft, ProcessState.Active, ProcessState.Suspended,
            ProcessState.Completed, ProcessState.Cancelled {

    record Draft(LocalDateTime createdAt) implements ProcessState {}
    record Active(LocalDateTime startedAt, String assignee) implements ProcessState {}
    record Suspended(LocalDateTime suspendedAt, String reason) implements ProcessState {}
    record Completed(LocalDateTime completedAt, Duration duration) implements ProcessState {}
    record Cancelled(LocalDateTime cancelledAt, String cancelledBy) implements ProcessState {}
}
```

---

## 5. Switch Expressions

Switch expressions return values and support pattern matching. They must be exhaustive (cover
all cases), which the compiler enforces.

### Basic switch expression

```java
/**
 * Maps HTTP status codes to user-friendly messages.
 */
public String statusMessage(int httpStatus) {
    return switch (httpStatus) {
        case 200 -> "Operation completed successfully";
        case 400 -> "Invalid request parameters";
        case 403 -> "Access denied: insufficient permissions";
        case 404 -> "Requested resource not found";
        case 500 -> "Internal server error";
        default -> "Unexpected status: " + httpStatus;
    };
}
```

### Switch with pattern matching (Java 17+ preview, stable in later versions)

```java
/**
 * Converts an API result to an HTTP response.
 */
public RestApiResponse toResponse(ApiResult<?> result, RestApiResponseBuilder builder) {
    return switch (result) {
        case ApiResult.Success<?> s ->
            JsonResponseUtils.jsonResponse(builder, SC_OK, s.data());
        case ApiResult.NotFound<?> nf ->
            JsonResponseUtils.jsonResponse(builder, SC_NOT_FOUND,
                Error.builder().message("Not found: " + nf.resourceId()).build());
        case ApiResult.ValidationError<?> ve ->
            JsonResponseUtils.jsonResponse(builder, SC_BAD_REQUEST,
                Error.builder().message(String.join("; ", ve.errors())).build());
        case ApiResult.ServerError<?> se ->
            JsonResponseUtils.jsonResponse(builder, SC_INTERNAL_SERVER_ERROR,
                Error.builder().message(se.message()).build());
    };
}
```

---

## 6. Stream API Patterns

Streams provide a declarative approach to collection processing. Prefer streams over manual
loops for filtering, mapping, and aggregation.

### Collectors and groupingBy

```java
/**
 * Groups tasks by their assigned user.
 */
public Map<String, List<TaskDTO>> groupTasksByAssignee(List<TaskDTO> tasks) {
    return tasks.stream()
        .filter(task -> task.assignee() != null)
        .collect(Collectors.groupingBy(TaskDTO::assignee));
}

/**
 * Counts tasks per status.
 */
public Map<String, Long> countByStatus(List<TaskDTO> tasks) {
    return tasks.stream()
        .collect(Collectors.groupingBy(
            TaskDTO::status,
            Collectors.counting()
        ));
}
```

### flatMap for nested structures

```java
/**
 * Extracts all unique tags from a list of processes.
 */
public Set<String> extractAllTags(List<ProcessDTO> processes) {
    return processes.stream()
        .map(ProcessDTO::tags)
        .flatMap(Collection::stream)
        .collect(Collectors.toUnmodifiableSet());
}
```

### toList() (Java 16+)

```java
/**
 * Converts BDM entities to DTOs.
 * Note: .toList() returns an unmodifiable list (preferred over .collect(Collectors.toList())).
 */
public List<UserDTO> convertToDTO(List<UserDAO> entities) {
    return entities.stream()
        .map(entity -> new UserDTO(
            entity.getPersistenceId(),
            entity.getUserName(),
            entity.getFirstName(),
            entity.getLastName(),
            entity.getEmail(),
            entity.getCreationDate()
        ))
        .toList();
}
```

### Reducing and summarizing

```java
/**
 * Calculates statistics for processing times.
 */
public DoubleSummaryStatistics processingTimeStats(List<TaskDTO> tasks) {
    return tasks.stream()
        .filter(t -> t.completedAt() != null && t.startedAt() != null)
        .mapToDouble(t -> Duration.between(t.startedAt(), t.completedAt()).toMinutes())
        .summaryStatistics();
}
```

---

## 7. Optional Patterns

`Optional<T>` makes the absence of a value explicit. Use it for method return types, NOT for
fields or method parameters.

### orElseThrow with meaningful exceptions

```java
/**
 * Retrieves a user by ID or throws a descriptive exception.
 */
public UserDTO findUserOrThrow(Long userId) {
    return userDAO.findByPersistenceId(userId)
        .map(this::toDTO)
        .orElseThrow(() -> new ResourceNotFoundException(
            "User with ID %d not found".formatted(userId)
        ));
}
```

### map and flatMap for transformation chains

```java
/**
 * Safely extracts the manager's email from a user.
 */
public Optional<String> getManagerEmail(Long userId) {
    return userDAO.findByPersistenceId(userId)
        .map(UserEntity::getManagerId)
        .flatMap(userDAO::findByPersistenceId)
        .map(UserEntity::getEmail);
}
```

### or() for fallback chains

```java
/**
 * Finds configuration from multiple sources with fallback.
 */
public String getConfigValue(String key) {
    return findInEnvironment(key)
        .or(() -> findInDatabase(key))
        .or(() -> findInDefaults(key))
        .orElseThrow(() -> new ConfigurationException(
            "Configuration key '%s' not found in any source".formatted(key)
        ));
}
```

### ifPresentOrElse for side effects

```java
/**
 * Logs the outcome of a user lookup.
 */
public void processUser(Long userId) {
    userDAO.findByPersistenceId(userId)
        .ifPresentOrElse(
            user -> logger.info("Processing user: {}", user.getUserName()),
            () -> logger.warn("User {} not found, skipping", userId)
        );
}
```

### Anti-patterns to avoid

```java
// BAD: Using Optional.get() without isPresent()
Optional<User> user = findUser(id);
user.get(); // Throws NoSuchElementException!

// BAD: Using Optional for fields
public class UserDTO {
    private Optional<String> email; // WRONG - use nullable field instead
}

// BAD: Using Optional as method parameter
public void sendEmail(Optional<String> address) { // WRONG
}

// GOOD: Use nullable parameter with null check
public void sendEmail(@Nullable String address) {
    if (address == null) return;
    // ...
}
```

---

## 8. var Keyword Usage

The `var` keyword enables local variable type inference. Use it when the type is obvious from
the right-hand side of the assignment.

### Appropriate usage

```java
// GOOD: Type is obvious from constructor
var users = new ArrayList<UserDTO>();

// GOOD: Type is obvious from method name
var response = JsonResponseUtils.jsonResponse(builder, SC_OK, data);

// GOOD: Type is obvious from stream terminal operation
var activeUsers = users.stream()
    .filter(UserDTO::isActive)
    .toList();

// GOOD: Enhanced for loop with var
for (var entry : configMap.entrySet()) {
    logger.debug("Config: {} = {}", entry.getKey(), entry.getValue());
}
```

### Inappropriate usage (avoid)

```java
// BAD: Type is not obvious
var result = processData(input); // What type is result?

// BAD: Numeric literals are ambiguous
var count = 0; // int? long? Is this intentional?

// BAD: Ternary with different types
var value = condition ? "text" : 42; // Confusing
```

---

## 9. CompletableFuture for Async Operations

Use `CompletableFuture` for non-blocking operations, especially when calling external services
or performing multiple independent I/O operations.

### Basic async pattern

```java
/**
 * Fetches user data and permissions concurrently.
 */
public UserProfile loadUserProfile(Long userId) {
    var userFuture = CompletableFuture.supplyAsync(
        () -> userService.findById(userId)
    );
    var permissionsFuture = CompletableFuture.supplyAsync(
        () -> permissionService.getPermissions(userId)
    );

    return userFuture.thenCombine(permissionsFuture, (user, permissions) ->
        new UserProfile(user, permissions)
    ).join();
}
```

### Error handling with CompletableFuture

```java
/**
 * Calls an external service with timeout and fallback.
 */
public CompletableFuture<ExternalData> fetchExternalData(String resourceId) {
    return CompletableFuture.supplyAsync(() -> externalService.fetch(resourceId))
        .orTimeout(5, TimeUnit.SECONDS)
        .exceptionally(ex -> {
            logger.error("Failed to fetch external data for {}: {}",
                resourceId, ex.getMessage());
            return ExternalData.empty();
        });
}
```

### Composing multiple async operations

```java
/**
 * Processes a batch of items concurrently with bounded parallelism.
 */
public List<ProcessResult> processBatch(List<String> itemIds, Executor executor) {
    var futures = itemIds.stream()
        .map(id -> CompletableFuture.supplyAsync(
            () -> processItem(id), executor
        ))
        .toList();

    return futures.stream()
        .map(CompletableFuture::join)
        .toList();
}
```

---

## 10. Try-with-Resources (Resource Management)

Always use try-with-resources for any object implementing `AutoCloseable` to guarantee resource
cleanup, even when exceptions occur.

```java
/**
 * Executes a database query and returns results.
 */
public List<Map<String, Object>> executeQuery(DataSource dataSource, String sql) {
    try (var connection = dataSource.getConnection();
         var statement = connection.prepareStatement(sql);
         var resultSet = statement.executeQuery()) {

        var results = new ArrayList<Map<String, Object>>();
        var metadata = resultSet.getMetaData();
        var columnCount = metadata.getColumnCount();

        while (resultSet.next()) {
            var row = new LinkedHashMap<String, Object>();
            for (int i = 1; i <= columnCount; i++) {
                row.put(metadata.getColumnName(i), resultSet.getObject(i));
            }
            results.add(row);
        }
        return List.copyOf(results);
    } catch (SQLException e) {
        logger.error("Query execution failed: {}", sql, e);
        throw new DataAccessException("Failed to execute query", e);
    }
}
```

---

## Quick Reference Table

| Feature | Use For | Avoid When |
|---------|---------|------------|
| Records | DTOs, value objects, API payloads | Mutable state needed, inheritance required |
| Pattern Matching | Type checks with variable binding | Simple equality checks |
| Text Blocks | SQL, JSON, HTML, multi-line strings | Single-line strings |
| Sealed Classes | Fixed type hierarchies, state machines | Open extension needed |
| Switch Expressions | Multi-branch value computation | Simple if-else with 2 branches |
| Streams | Collection transformations, filtering | Single-element operations, side effects |
| Optional | Return types for nullable results | Fields, method parameters |
| var | Obvious types from RHS | Ambiguous types, numeric literals |
| CompletableFuture | Parallel I/O, async service calls | CPU-bound computation, simple sync ops |
