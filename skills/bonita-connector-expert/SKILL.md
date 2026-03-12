---
name: bonita-connector-expert
description: |
  Use when the user works on Bonita extension points: actor filters, event handlers, or REST API extensions.
  For connector development, use the bonita-connectors-generator-toolkit instead.
  Auto-invoked when working with *Filter*.java, *Handler*.java, RestAPI*.java, or *Controller*.java files.
  Provides lifecycle patterns, error handling, testing, and deployment guidance for non-connector extension types.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
user-invocable: true
---

# Bonita Extension Points Expert

You are a **Senior Bonita Platform Engineer** specializing in Bonita extension points: actor filters, event handlers, and REST API extensions. You implement production-grade extensions following Bonita SDK patterns and best practices.

## When activated

1. **Identify extension type**: Determine whether the request concerns an actor filter, event handler, or REST API extension
2. **Check existing code**: Scan the project for existing extensions of the same type to understand local conventions
3. **Check Bonita version**: Look for `bonita.version` in `pom.xml` to determine which APIs apply (7.x vs 2021+ vs 2024+)
4. **Apply the correct lifecycle pattern** for the identified extension type

---

## Connectors

For comprehensive connector development guidance (lifecycle, .def/.impl rules, shade plugin, multi-module Maven, testing, deployment), use the **bonita-connectors-generator-toolkit** which contains:

- **Skills**: connector-spec, connector-generate, connector-test, connector-review, connector-migrate
- **Knowledge base**: connector-lifecycle, emf-def-rules, impl-and-filtering, shade-plugin-guide, multi-module-structure, common-mistakes, common-patterns, auth-templates
- **Templates**: POM, Java, XML, test templates for all project types

### Quick Reference: Connector Lifecycle

```
VALIDATE -> CONNECT -> EXECUTE -> DISCONNECT
```

| Phase | Method | Exception |
|-------|--------|-----------|
| VALIDATE | `validateInputParameters()` | `ConnectorValidationException` |
| CONNECT | `connect()` | `ConnectorException` |
| EXECUTE | `executeBusinessLogic()` | `ConnectorException` |
| DISCONNECT | `disconnect()` | Log only (never throw) |

---

## Actor Filters

See `references/actor-filter-patterns.md` for complete AbstractUserFilter lifecycle, code examples, and common filter patterns (Manager, Group, Role, Custom attribute).

---

## Event Handlers

See `references/event-handler-registration.md` for SHandler interface implementation, common event types, and registration in Bonita 7.x and 2024+.

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
class MyExtensionTest {

    @Mock
    private SomeService mockService;

    @InjectMocks
    private MyExtension extension;

    @Test
    void should_return_result_when_service_responds_ok() {
        // Given
        when(mockService.call(any())).thenReturn(new Response(200, "ok"));

        // When
        var result = extension.execute();

        // Then
        assertThat(result.getStatus()).isEqualTo(200);
        assertThat(result.getBody()).isEqualTo("ok");
    }

    @Test
    void should_throw_when_input_is_invalid() {
        assertThatThrownBy(() -> extension.validate(""))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("required");
    }
}
```

### Property Tests (jqwik)

```java
@Property
void should_reject_non_http_urls(@ForAll @StringLength(min = 1) String url) {
    Assume.that(!url.startsWith("http://") && !url.startsWith("https://"));
    assertThatThrownBy(() -> extension.validate(url))
            .isInstanceOf(IllegalArgumentException.class);
}
```

### Integration Tests (WireMock)

```java
@ExtendWith(WireMockExtension.class)
class MyExtensionIT {

    @WireMock
    WireMockServer wireMock;

    @Test
    void should_call_real_endpoint_and_parse_response() {
        wireMock.stubFor(post("/api/send")
                .willReturn(okJson("{\"result\":\"ok\",\"code\":200}")));

        var extension = new MyExtension();
        extension.configure(wireMock.baseUrl() + "/api/send");
        var result = extension.execute();

        assertThat(result.getBody()).isEqualTo("ok");
    }
}
```

### Test Naming Convention

All test methods follow the pattern: `should_X_when_Y()`

- `should_return_ok_when_input_is_valid()`
- `should_throw_validation_exception_when_url_is_blank()`
- `should_retry_when_transient_error_occurs()`

### Integration Test Class Naming

- Suffix: `*IT.java` (Maven Failsafe plugin convention)
- Unit test suffix: `*Test.java` (Maven Surefire plugin convention)

---

## Pool-Level vs Activity-Level Connectors

### Placement

| Level | Scope | XML Location |
|-------|-------|-------------|
| **Pool-level** | Fires when the entire process instance completes or is cancelled | Direct child of `<elements xmi:type="process:Pool">` |
| **Activity-level** | Fires when a specific task starts or completes | Child of a task element (e.g., `<elements xmi:type="process:Task">`) |

### Transaction Isolation

**Each pool-level ON_FINISH connector runs in its own database transaction.**

```
Process completes -> End Event
  -> Connector 1 script -> Output mapping 1 -> TX1 COMMIT
  -> Connector 2 script -> Output mapping 2 -> TX2 COMMIT
  -> Connector 3 script -> Output mapping 3 -> TX3 COMMIT
```

Execution order is **sequential**, determined by XML document order in the `.proc` file (top to bottom).

If Connector 2 fails:
- TX1 changes are **committed** (already done)
- TX2 changes are **rolled back**
- TX3 may or may not execute depending on `ignoreErrors`

### Self-Destructive Connector Pattern

When a pool-level ON_FINISH connector calls `cancelProcessInstance()` on its own root process:

1. Cascade cancellation triggers (all subprocesses in the same `rootProcessInstanceId` tree are cancelled)
2. The cascade deletes `connector_instance` rows for the cancelled process
3. When the output mapping transaction tries to commit, it fails with `SConnectorInstanceNotFoundException`

**Fix -- Two-Connector Pattern:**

```
Connector 1 (TX1): Persist BDM data -> COMMIT (ok)
Connector 2 (TX2): Call cancelProcessInstance -> cascade kills TX2 -> ROLLBACK (acceptable)
```

- Move all BDM writes to a preceding connector (separate transaction)
- Remove output mappings from the connector that calls cancel
- Accept that the cancel connector's transaction will be rolled back

---

## Version Compatibility

| Feature | Bonita 7.x | Bonita 2021.x-2023.x | Bonita 2024+ |
|---------|-----------|---------------------|-------------|
| Connector API | `AbstractConnector` | `AbstractConnector` | `AbstractConnector` |
| Event handler registration | `bonita-tenant-sp-custom.xml` | XML config | Configuration service |
| REST API extension permissions | `resources-permissions-mapping-custom.properties` | Same | Same + dynamic permissions API |
| Actor filter API | `AbstractUserFilter` | `AbstractUserFilter` | `AbstractUserFilter` |
| Page API version | 6.x | 7.x | 7.x+ |

---

## Progressive Disclosure -- Reference Documents

For deeper guidance on specific topics, load these references:

- **For actor filter advanced patterns (LDAP, custom attributes)**, read `references/actor-filter-patterns.md`
- **For event handler registration (all Bonita versions)**, read `references/event-handler-registration.md`
- **For REST API extension full pattern**, use `bonita-rest-api-expert` skill
- **For connector development**, use the `bonita-connectors-generator-toolkit`
