---
name: bonita-flow-testing
description: |
  BPMN process flow testing with Bonita Test Toolkit 3.1.x. Tests process instantiation,
  task execution, gateway routing, timer behavior, connector calls, and variable state.
  Use when testing .proc files, validating process logic, or creating integration test suites.
  Trigger: "test process", "flow test", "process test", "test toolkit", "integration test bonita"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
user_invocable: true
---

# BPMN Flow Testing with Bonita Test Toolkit

## Setup

### Maven Dependencies
```xml
<dependency>
    <groupId>org.bonitasoft</groupId>
    <artifactId>bonita-test-toolkit</artifactId>
    <version>3.1.0</version>
    <scope>test</scope>
</dependency>
```

### Base Test Class
All flow tests extend `AbstractProcessTest`:
```java
class MyProcessIT extends AbstractProcessTest {

    @Override
    protected String getProcessName() { return "MyProcess"; }

    @Override
    protected String getProcessVersion() { return "1.0"; }
}
```

## Test Patterns

### Happy Path
```java
@Test
void should_complete_happy_path() {
    // Start case with contract inputs
    Map<String, Serializable> inputs = Map.of(
        "firstName", "John",
        "lastName", "Doe",
        "amount", 500
    );
    long caseId = startCase(inputs);

    // Execute first human task
    HumanTask reviewTask = waitForUserTask(caseId, "Review Request");
    Map<String, Serializable> reviewInputs = Map.of("approved", true);
    executeTask(reviewTask, reviewInputs);

    // Assert process completed
    assertProcessCompleted(caseId);
}
```

### Gateway Branches
```java
@Test
void should_route_to_approval_when_amount_above_threshold() {
    long caseId = startCase(Map.of("amount", 5000));
    HumanTask task = waitForUserTask(caseId, "Manager Approval");
    assertThat(task).isNotNull();
}

@Test
void should_skip_approval_when_amount_below_threshold() {
    long caseId = startCase(Map.of("amount", 100));
    HumanTask task = waitForUserTask(caseId, "Process Order");
    assertThat(task).isNotNull(); // Skipped Manager Approval
}
```

### Business Data Assertions
```java
@Test
void should_create_order_in_bdm() {
    long caseId = startCase(Map.of("product", "Widget", "quantity", 10));
    executeTask(waitForUserTask(caseId, "Confirm"), Map.of());

    // Assert BDM data
    Map<String, Object> order = getBusinessData(caseId, "order");
    assertThat(order.get("product")).isEqualTo("Widget");
    assertThat(order.get("quantity")).isEqualTo(10);
    assertThat(order.get("status")).isEqualTo("CONFIRMED");
}
```

### Timer Simulation
```java
@Test
void should_escalate_when_timer_expires() {
    long caseId = startCase(defaultInputs());
    waitForUserTask(caseId, "Review");

    // Simulate timer expiration
    advanceTimerBy(Duration.ofHours(48));

    // Assert escalation task appeared
    HumanTask escalation = waitForUserTask(caseId, "Escalation Review");
    assertThat(escalation).isNotNull();
}
```

### Connector Mocking
```java
@Override
protected Map<String, ConnectorMock> getConnectorMocks() {
    return Map.of(
        "emailConnector", ConnectorMock.builder()
            .output("sent", true)
            .output("messageId", "mock-123")
            .build(),
        "restConnector", ConnectorMock.builder()
            .output("responseBody", "{\"status\":\"ok\"}")
            .output("statusCode", 200)
            .build()
    );
}
```

### Multi-Path Coverage
```java
@ParameterizedTest
@MethodSource("gatewayScenarios")
void should_handle_all_gateway_paths(int amount, boolean approved, String expectedTask) {
    long caseId = startCase(Map.of("amount", amount));
    HumanTask review = waitForUserTask(caseId, "Review");
    executeTask(review, Map.of("approved", approved));
    HumanTask next = waitForUserTask(caseId, expectedTask);
    assertThat(next).isNotNull();
}

static Stream<Arguments> gatewayScenarios() {
    return Stream.of(
        Arguments.of(100, true, "Process Order"),
        Arguments.of(5000, true, "Manager Approval"),
        Arguments.of(100, false, "Rejection Notice"),
        Arguments.of(5000, false, "Rejection Notice")
    );
}
```

## Test Naming Convention
- File: `*IT.java` (Maven Failsafe integration tests)
- Method: `should_{expected}_when_{condition}()`

## Running Tests
```bash
# Requires running Bonita instance
export BONITA_URL=http://localhost:8080/bonita
export BONITA_USER=install
export BONITA_PASSWORD=install
mvn verify -Plocal
```

## Coverage Goals
- All gateway branches (100%)
- All task types (human, service, script)
- All boundary events
- Happy path + main error paths
- Timer-triggered flows
