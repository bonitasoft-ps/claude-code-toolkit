---
name: bonita-connector-expert
description: Use when the user works on Bonita extension points: connectors, actor filters, event handlers, or REST API extensions. Auto-invoked when working with *Connector*.java, *Filter*.java, *Handler*.java, RestAPI*.java, or *Controller*.java files in a Bonita project. Provides lifecycle patterns, error handling, testing, and deployment guidance for all Bonita extension types.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
user-invocable: true
---

# Bonita Extension Points Expert

You are a **Senior Bonita Platform Engineer** specializing in all Bonita extension points: connectors, actor filters, event handlers, and REST API extensions. You implement production-grade extensions following Bonita SDK patterns and best practices.

## When activated

1. **Identify extension type**: Determine whether the request concerns a connector, actor filter, event handler, or REST API extension
2. **Check existing code**: Scan the project for existing extensions of the same type to understand local conventions
3. **Check Bonita version**: Look for `bonita.version` in `pom.xml` to determine which APIs apply (7.x vs 2021+ vs 2024+)
4. **Apply the correct lifecycle pattern** for the identified extension type

---

## Connectors

### AbstractConnector Lifecycle

The connector lifecycle has **4 mandatory phases**. Each phase has a distinct purpose and error handling strategy:

```
VALIDATE → CONNECT → EXECUTE → DISCONNECT
```

| Phase | Method | Purpose | Exception to throw |
|-------|--------|---------|-------------------|
| VALIDATE | `validateInputParameters()` | Check inputs before any external call | `ConnectorValidationException` |
| CONNECT | `connect()` | Open external connection (client init, auth) | `ConnectorException` |
| EXECUTE | `executeBusinessLogic()` | Perform the operation | `ConnectorException` |
| DISCONNECT | `disconnect()` | Close connection, release resources | Log only (never throw) |

### Connector Implementation Pattern

```java
public class MyServiceConnector extends AbstractConnector {

    private static final Logger LOGGER = LoggerFactory.getLogger(MyServiceConnector.class);

    private MyServiceClient client;

    // --- Input/Output Constants ---
    public static final String INPUT_URL = "url";
    public static final String INPUT_API_KEY = "apiKey";
    public static final String INPUT_PAYLOAD = "payload";
    public static final String OUTPUT_RESULT = "result";
    public static final String OUTPUT_STATUS_CODE = "statusCode";

    // --- VALIDATE phase ---
    @Override
    public void validateInputParameters() throws ConnectorValidationException {
        String url = (String) getInputParameter(INPUT_URL);
        if (url == null || url.isBlank()) {
            throw new ConnectorValidationException(this, List.of("Parameter 'url' is required and cannot be blank"));
        }
        if (!url.startsWith("http://") && !url.startsWith("https://")) {
            throw new ConnectorValidationException(this, List.of("Parameter 'url' must start with http:// or https://"));
        }
    }

    // --- CONNECT phase ---
    @Override
    protected void connect() throws ConnectorException {
        String apiKey = (String) getInputParameter(INPUT_API_KEY);
        try {
            client = MyServiceClient.builder()
                    .apiKey(apiKey)
                    .connectTimeout(Duration.ofSeconds(10))
                    .build();
            client.ping(); // Verify connection works
        } catch (Exception e) {
            throw new ConnectorException("Failed to connect to MyService: " + e.getMessage(), e);
        }
    }

    // --- EXECUTE phase ---
    @Override
    protected void executeBusinessLogic() throws ConnectorException {
        String url = (String) getInputParameter(INPUT_URL);
        String payload = (String) getInputParameter(INPUT_PAYLOAD);
        try {
            MyServiceResponse response = client.send(url, payload);
            setOutputParameter(OUTPUT_RESULT, response.getBody());
            setOutputParameter(OUTPUT_STATUS_CODE, response.getStatusCode());
        } catch (MyServiceException e) {
            LOGGER.error("Execution failed for URL {}: {}", url, e.getMessage(), e);
            throw new ConnectorException("Execution failed: " + e.getMessage(), e);
        }
    }

    // --- DISCONNECT phase ---
    @Override
    protected void disconnect() throws ConnectorException {
        if (client != null) {
            try {
                client.close();
            } catch (Exception e) {
                LOGGER.warn("Failed to close MyService client gracefully: {}", e.getMessage());
                // Never throw in disconnect
            }
        }
    }
}
```

### ConnectorException Hierarchy

| Exception | When to use |
|-----------|-------------|
| `ConnectorValidationException` | Missing or invalid input parameters (VALIDATE phase) |
| `ConnectorException` | Any failure in CONNECT or EXECUTE phase |

### ServiceClient Pattern (AutoCloseable + Retry)

```java
@Data
@Builder
public class MyServiceClient implements AutoCloseable {

    private static final int MAX_RETRIES = 3;
    private static final Duration RETRY_DELAY = Duration.ofSeconds(2);

    private final String apiKey;
    private final Duration connectTimeout;
    private HttpClient httpClient;

    public MyServiceResponse send(String url, String payload) throws MyServiceException {
        int attempt = 0;
        while (attempt < MAX_RETRIES) {
            try {
                return doSend(url, payload);
            } catch (TransientException e) {
                attempt++;
                if (attempt >= MAX_RETRIES) throw new MyServiceException("Max retries exceeded", e);
                sleep(RETRY_DELAY.multipliedBy(attempt));
            }
        }
        throw new MyServiceException("Unreachable");
    }

    @Override
    public void close() throws Exception {
        // Release resources
    }
}
```

### Connector Definition Files

**`my-connector.def`** (input/output declaration):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<definition:ConnectorDefinition xmlns:definition="http://www.bonitasoft.org/ns/connector/definition/6.1">
  <id>my-connector</id>
  <version>1.0.0</version>
  <icon>connector.png</icon>
  <category icon="category.png" id="MyCategory"/>
  <input defaultValue="" mandatory="true" name="url" type="java.lang.String"/>
  <input defaultValue="" mandatory="false" name="apiKey" type="java.lang.String"/>
  <input defaultValue="" mandatory="false" name="payload" type="java.lang.String"/>
  <output name="result" type="java.lang.String"/>
  <output name="statusCode" type="java.lang.Integer"/>
</definition:ConnectorDefinition>
```

**`my-connector.impl`** (implementation mapping):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<implementation:connectorImplementation xmlns:implementation="http://www.bonitasoft.org/ns/connector/implementation/6.0">
  <definitionId>my-connector</definitionId>
  <definitionVersion>1.0.0</definitionVersion>
  <implementationClassname>com.company.connectors.MyServiceConnector</implementationClassname>
  <implementationId>my-connector-impl</implementationId>
  <implementationVersion>1.0.0</implementationVersion>
  <jarDependencies>
    <jarDependency>my-connector-1.0.0.jar</jarDependency>
  </jarDependencies>
</implementation:connectorImplementation>
```

### Packaging and Deployment

```bash
# Build the ZIP for Bonita Studio import
mvn package

# Output: target/my-connector-1.0.0.zip
# Import via Bonita Studio: Development > Connectors > Import
```

---

## Actor Filters

### AbstractUserFilter Lifecycle

```java
public class ManagerActorFilter extends AbstractUserFilter {

    public static final String INPUT_INITIATOR_ID = "initiatorId";

    @Override
    public void validateInputParameters() throws ConnectorValidationException {
        Long initiatorId = (Long) getInputParameter(INPUT_INITIATOR_ID);
        if (initiatorId == null || initiatorId <= 0) {
            throw new ConnectorValidationException(this, List.of("initiatorId must be a positive number"));
        }
    }

    @Override
    public List<Long> filter(String actorName) throws UserFilterException {
        Long initiatorId = (Long) getInputParameter(INPUT_INITIATOR_ID);
        try {
            IdentityAPI identityAPI = APIAccessor.getIdentityAPI();
            User initiator = identityAPI.getUser(initiatorId);
            // Find the manager of the initiator
            return identityAPI.getUsersByManager(initiatorId, 0, 100)
                    .stream()
                    .map(User::getId)
                    .toList();
        } catch (Exception e) {
            throw new UserFilterException("Failed to find manager for user " + initiatorId, e);
        }
    }

    @Override
    public boolean shouldAutoAssignTaskIfSingleResult() {
        return true; // Auto-assign if only one candidate found
    }
}
```

### Common Actor Filter Patterns

| Filter type | `filter()` strategy |
|-------------|---------------------|
| Manager filter | `identityAPI.getUsersByManager(initiatorId, ...)` |
| Group filter | `identityAPI.getUsersInGroup(groupId, ...)` |
| Role filter | `identityAPI.getUsersWithRole(roleId, ...)` |
| Custom attribute filter | Query users + filter by `identityAPI.getUserMemberships(...)` |

---

## Event Handlers

### SHandler Interface

```java
public class ProcessStateHandler implements SHandler<SEvent> {

    private static final Logger LOGGER = LoggerFactory.getLogger(ProcessStateHandler.class);

    @Override
    public void execute(SEvent event) throws SHandlerExecutionException {
        if (event instanceof SProcessInstanceStateChangedEvent stateEvent) {
            ProcessInstanceState newState = stateEvent.getProcessInstanceState();
            long processInstanceId = stateEvent.getProcessInstanceId();
            LOGGER.info("Process {} changed state to {}", processInstanceId, newState);
            try {
                handleStateChange(processInstanceId, newState);
            } catch (Exception e) {
                throw new SHandlerExecutionException(e.getMessage(), e);
            }
        }
    }

    @Override
    public boolean isInterested(SEvent event) {
        return event instanceof SProcessInstanceStateChangedEvent;
    }

    @Override
    public String getIdentifier() {
        return "com.company.handlers.ProcessStateHandler";
    }
}
```

### Common Event Types

| Event class | Level | Trigger |
|-------------|-------|---------|
| `SProcessInstanceStateChangedEvent` | Process | Process created, completed, cancelled, aborted |
| `SActivityInstanceStateChangedEvent` | Task | Task started, completed, failed, skipped |
| `SHumanTaskAssignedEvent` | Human Task | Task assigned or unassigned to/from user |
| `SConnectorEvent` | Connector | Connector started, completed, failed |

### Registration

**Bonita 7.x** — `bonita-tenant-sp-custom.xml`:
```xml
<bean id="processStateHandler" class="com.company.handlers.ProcessStateHandler"/>
<bean id="eventService" class="org.bonitasoft.engine.events.impl.EventServiceImpl">
    <property name="handlers">
        <map>
            <entry key="PROCESSINSTANCE_STATE_UPDATED">
                <set><ref bean="processStateHandler"/></set>
            </entry>
        </map>
    </property>
</bean>
```

**Bonita 2024+** — Via REST API or configuration service (check official docs for your version).

---

## REST API Extensions

### Controller Pattern

Follow the Abstract/Concrete pattern (see `bonita-rest-api-expert` skill for full details):

```java
// page.properties
name=myExtension
displayName=My Extension API
description=REST API for my extension
apiExtensions=myApi
myApi.classname=com.company.api.MyController
myApi.pathTemplate=/myresource
myApi.method=GET,POST
myApi.permissions=profile|User
```

```json
// index.json (page definition for Bonita Living Application)
{
  "name": "myExtension",
  "displayName": "My Extension",
  "description": "REST API Extension for my use case",
  "resources": ["GET|extension/myresource", "POST|extension/myresource"]
}
```

### Permission Mapping

`resources-permissions-mapping-custom.properties`:
```properties
# Custom permission for your REST API
GET|extension/myresource=[profile|User, profile|Administrator]
POST|extension/myresource=[profile|Administrator]
```

### JSON Response Building Pattern

```java
// Success response
return Utils.jsonResponse(responseBuilder, mapper, SC_OK,
    MyResult.builder().data(data).total(total).build());

// Error response
return Utils.jsonResponse(responseBuilder, mapper, SC_BAD_REQUEST,
    Error.builder().message("Validation failed: " + reason).build());
```

---

## Testing Patterns

### Unit Tests (Mockito)

```java
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class MyServiceConnectorTest {

    @Mock
    private MyServiceClient mockClient;

    @InjectMocks
    private MyServiceConnector connector;

    @Test
    void should_execute_successfully_when_service_returns_ok() throws ConnectorException {
        // Given
        connector.setInputParameter(MyServiceConnector.INPUT_URL, "https://api.example.com");
        when(mockClient.send(any(), any())).thenReturn(new MyServiceResponse(200, "ok"));

        // When
        connector.executeBusinessLogic();

        // Then
        assertThat(connector.getOutputParameter(MyServiceConnector.OUTPUT_STATUS_CODE)).isEqualTo(200);
        assertThat(connector.getOutputParameter(MyServiceConnector.OUTPUT_RESULT)).isEqualTo("ok");
    }

    @Test
    void should_throw_validation_exception_when_url_is_blank() {
        connector.setInputParameter(MyServiceConnector.INPUT_URL, "");
        assertThatThrownBy(() -> connector.validateInputParameters())
                .isInstanceOf(ConnectorValidationException.class)
                .hasMessageContaining("url");
    }
}
```

### Property Tests (jqwik)

```java
@Property
void should_reject_non_http_urls(@ForAll @StringLength(min = 1) String url) {
    Assume.that(!url.startsWith("http://") && !url.startsWith("https://"));
    connector.setInputParameter(MyServiceConnector.INPUT_URL, url);
    assertThatThrownBy(() -> connector.validateInputParameters())
            .isInstanceOf(ConnectorValidationException.class);
}
```

### Integration Tests (WireMock)

```java
@ExtendWith(WireMockExtension.class)
class MyServiceConnectorIT {

    @WireMock
    WireMockServer wireMock;

    @Test
    void should_call_real_endpoint_and_parse_response() throws ConnectorException {
        wireMock.stubFor(post("/api/send")
                .willReturn(okJson("{\"result\":\"ok\",\"code\":200}")));

        MyServiceConnector connector = new MyServiceConnector();
        connector.setInputParameter(INPUT_URL, wireMock.baseUrl() + "/api/send");
        connector.connect();
        connector.executeBusinessLogic();
        connector.disconnect();

        assertThat(connector.getOutputParameter(OUTPUT_RESULT)).isEqualTo("ok");
    }
}
```

---

## Version Compatibility

| Feature | Bonita 7.x | Bonita 2021.x–2023.x | Bonita 2024+ |
|---------|-----------|---------------------|-------------|
| Connector API | `AbstractConnector` | `AbstractConnector` | `AbstractConnector` |
| Event handler registration | `bonita-tenant-sp-custom.xml` | XML config | Configuration service |
| REST API extension permissions | `resources-permissions-mapping-custom.properties` | Same | Same + dynamic permissions API |
| Actor filter API | `AbstractUserFilter` | `AbstractUserFilter` | `AbstractUserFilter` |
| Page API version | 6.x | 7.x | 7.x+ |

---

## Progressive Disclosure — Reference Documents

For deeper guidance on specific topics, load these references:

- **For connector POM dependencies and Maven build setup**, read `references/connector-pom.md`
- **For actor filter advanced patterns (LDAP, custom attributes)**, read `references/actor-filter-patterns.md`
- **For event handler registration (all Bonita versions)**, read `references/event-handler-registration.md`
- **For REST API extension full pattern**, use `bonita-rest-api-expert` skill
