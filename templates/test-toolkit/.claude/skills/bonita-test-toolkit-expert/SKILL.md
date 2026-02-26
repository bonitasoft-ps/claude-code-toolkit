---
name: bonita-test-toolkit-expert
description: "Use when the user asks about writing Bonita process integration tests, using the Bonita Test Toolkit API, deploying .bar files, testing process flows, handling timers in tests, accessing BDM data in tests, or building contracts for process instantiation."
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Bonita Test Toolkit Expert

You are an expert in writing integration tests for Bonita processes using the Bonita Test Toolkit 3.1.x.

## When activated

1. Read `CLAUDE.md` and `AGENTS.md` for project context
2. Read relevant `context-ai/` files for specific patterns
3. Check existing test classes for project conventions
4. Apply the rules below

## Test Class Structure

Every integration test class MUST:

```java
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@DisplayName("Description of what process is being tested")
public class MyProcessIT extends AbstractProcessTest {

    private ProcessDefinition process;

    @BeforeAll
    void setUpProcess() {
        process = deployProcess("MyProcess--1.0.bar");
    }

    @Test
    @DisplayName("Process should complete with valid input")
    void should_complete_when_input_is_valid() {
        // ARRANGE
        // ACT
        // ASSERT
    }
}
```

## Mandatory Rules

1. **File naming**: `*IT.java` suffix for integration tests
2. **Extend**: `AbstractProcessTest` always
3. **Annotation**: `@TestInstance(TestInstance.Lifecycle.PER_CLASS)`
4. **Method naming**: `should_XXX_when_YYY()`
5. **Assertions**: AssertJ only (never JUnit Assertions)
6. **Async waits**: Awaitility (never Thread.sleep)
7. **Timer handling**: Force timers explicitly (they don't fire automatically)
8. **Constants**: Use `TestConstants` class, values must match BDM data
9. **Cleanup**: Always in `@AfterEach` or `@AfterAll`
10. **Bar files**: Must exist in `src/test/resources/processes/`

## Core API Patterns

### Deploy and start

```java
ProcessDefinition process = deployProcess("Process--1.0.bar");
ProcessInstance instance = client.start(process)
    .with("inputVar", "value")
    .execute();
```

### Execute user task

```java
client.waitForTask(instance, "Task Name")
    .with("outputVar", "result")
    .execute();
```

### Assert completion

```java
assertThat(instance)
    .isCompleted()
    .hasVariable("result", "expected");
```

### Force timer

```java
await().atMost(Duration.ofSeconds(30))
    .pollInterval(Duration.ofMillis(500))
    .until(() -> {
        try {
            instance.getTimerEventTrigger("Timer Name").execute();
            return true;
        } catch (Exception e) {
            return false;
        }
    });
```

### Build complex contract

```java
ComplexInputBuilder input = ComplexInputBuilder.complexInput()
    .textInput("field", "value")
    .decimalInput("amount", 3000.0)
    .localDateInput("date", LocalDate.now());

Contract contract = ContractBuilder.newContract()
    .complexInput("requestInput", input)
    .build();

ProcessInstance instance = startProcess(process, user, contract);
```

### Access BDM data

```java
BusinessObjectDAO<BusinessData> dao = toolkit.getBusinessObjectDAO(
    "com.company.model.EntityName"
);
List<BusinessData> items = dao.find(0, 10);
String value = items.get(0).getStringField("fieldName");
```

## Test Organization

Use `@Nested` classes for scenario groups:

```java
@Nested
class StandardFlowTests { ... }

@Nested
class HighValueFlowTests { ... }

@Nested
class ErrorFlowTests { ... }
```

## Common Pitfalls

1. **Timer not found**: Process may not have reached the timer yet — use polling
2. **BDM value mismatch**: Test constants must match actual BDM data initialized by master data processes
3. **Contract field types**: Use correct input methods (`textInput`, `decimalInput`, `localDateInput`)
4. **XOR gateway routing**: Verify conditions match test data (e.g., amount thresholds)

## Progressive Disclosure

- **For detailed API patterns and examples**: Read `references/api-patterns.md`
