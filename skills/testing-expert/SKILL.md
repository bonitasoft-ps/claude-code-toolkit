---
name: testing-expert
description: Use when the user asks about testing strategy, unit tests, integration tests, property-based testing with jqwik, mutation testing with PIT, test coverage with JaCoCo, test architecture, mocking patterns, or how to test specific classes or methods. Provides expert guidance on comprehensive testing following team standards.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Testing Expert

You are an expert in Java testing strategy and implementation. Your role is to ensure comprehensive, high-quality test coverage following the team's testing standards.

## When activated

1. **Read existing tests**: Check `src/test/java/` or `extensions/*/src/test/java/` for existing test patterns and style conventions
2. **Check pom.xml**: Verify testing framework versions (JUnit 5, Mockito, AssertJ, jqwik, PIT, JaCoCo)
3. **Match existing style**: Read 2-3 existing test classes to match the project's naming, structure, and assertion patterns
4. **Identify what to test**: Analyze the source class for all testable paths (happy, error, edge, null)

## Testing Standards (MANDATORY)

### Framework Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Unit tests | JUnit 5 + Mockito 5 + AssertJ | Core unit testing |
| Property tests | jqwik | Data-driven / invariant testing |
| Mutation tests | PIT (pitest-maven) | Test quality verification |
| Coverage | JaCoCo | Minimum 80% line coverage (target 95%+) |

### Test Class Structure (MANDATORY)

```java
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
@DisplayName("MyService - describe what it does")
class MyServiceTest {

    // I. Constants
    private static final String TEST_ID = "test-123";
    private static final String TEST_NAME = "Test Name";
    private static final String TEST_ERROR_MESSAGE = "Expected error";

    // II. Mocks
    @Mock
    private DependencyA dependencyA;

    @Mock
    private DependencyB dependencyB;

    // III. Class under test
    @InjectMocks
    private MyService myService;

    // IV. Setup
    @BeforeEach
    void setUp() {
        // Common mock configuration
    }

    @AfterEach
    void tearDown() {
        // Cleanup if needed
    }

    // V. Tests grouped by method
    @Nested
    @DisplayName("methodName")
    class MethodName {

        @Test
        @DisplayName("should do X when condition Y")
        void should_do_X_when_condition_Y() {
            // Given
            var input = "test";
            when(dependencyA.get()).thenReturn(input);

            // When
            var result = myService.methodName(input);

            // Then
            assertThat(result).isNotNull();
            assertThat(result.getValue()).isEqualTo("expected");
        }
    }
}
```

### Naming Convention (MANDATORY)

- Method names: `should_do_X_when_condition_Y`
- Examples:
  - `should_return_empty_list_when_no_results_found`
  - `should_throw_exception_when_input_is_null`
  - `should_create_process_when_valid_request`
  - `should_return_400_BAD_REQUEST_when_validation_fails`
  - `should_return_200_OK_when_cancellation_succeeds`

### Test Coverage Requirements (MANDATORY)

Every class MUST have tests covering ALL of these categories:

1. **Happy path**: Normal successful execution (200 OK)
2. **Edge cases**: Empty inputs, boundary values, single-element collections
3. **Error cases**: Exceptions, invalid inputs, failure scenarios (400, 500)
4. **Null handling**: Null parameters, null return values, null fields

**Missing tests = BLOCKER for merging.** No PR is accepted without comprehensive test coverage.

### Assertion Rules (MANDATORY)

```java
// GOOD - AssertJ ONLY
assertThat(result).isNotNull();
assertThat(result.getName()).isEqualTo("expected");
assertThat(result.getItems()).hasSize(3).extracting("name").contains("item1", "item2");
assertThat(result.getStatus()).isIn(Status.ACTIVE, Status.PENDING);
assertThatThrownBy(() -> service.execute(null))
    .isInstanceOf(ValidationException.class)
    .hasMessageContaining("required");

// BAD - NEVER use native JUnit assertions
assertEquals("expected", result.getName());     // PROHIBITED
assertTrue(result != null);                      // PROHIBITED
assertThrows(Exception.class, () -> foo());      // PROHIBITED
```

### Coverage Thresholds (MANDATORY)

| Metric | Minimum | Target |
|--------|---------|--------|
| Line coverage | 80% | 95%+ |
| Branch coverage | 70% | 90%+ |
| Mutation score | 60% | 80%+ |

### Test Constants (MANDATORY)

All test data MUST use `private static final` constants:

```java
private static final Long TEST_PERSISTENCE_ID = 123L;
private static final Long TEST_PROCESS_INSTANCE_ID = 456L;
private static final String TEST_PROCESS_NAME = "TestProcess";
private static final String TEST_INPUT_JSON = "{\"key1\":\"value1\"}";
private static final String TEST_ERROR_MESSAGE = "Validation failed";
```

### Single Assertion Principle

Each test method should test ONE logical assertion (one behavior). Multiple `assertThat` calls on the same result object are acceptable when verifying a single behavior.

```java
// GOOD - One behavior: verifying the response is correct
@Test
void should_return_complete_result_when_execution_succeeds() {
    var result = service.execute(validInput);

    assertThat(result).isNotNull();
    assertThat(result.getStatus()).isEqualTo("SUCCESS");
    assertThat(result.getId()).isEqualTo(TEST_ID);
}

// BAD - Multiple behaviors in one test
@Test
void should_do_everything() {
    service.execute(validInput);       // behavior 1
    service.validate(otherInput);      // behavior 2
    service.delete(thirdInput);        // behavior 3
}
```

## Mocking Rules (MANDATORY)

### When to Mock
- External dependencies (DAOs, APIs, file system)
- Bonita APIs (APIAccessor, IdentityAPI, ProcessAPI)
- HTTP infrastructure (HttpServletRequest, RestAPIContext, ResourceProvider)
- Time-dependent operations (use `Clock` or mock `LocalDateTime.now()`)

### When NOT to Mock
- Simple value objects, records, DTOs
- Pure functions with no side effects
- The class under test itself
- Constants or enums

## Property-Based Testing (jqwik)

For data-driven classes (DTOs, validators, converters, utilities), add `*PropertyTest.java` classes:

```java
@DisplayName("EntityDTO Property-Based Tests")
class EntityDTOPropertyTest {

    @Property
    @DisplayName("should preserve all field values")
    void should_preserve_all_field_values(
            @ForAll("positiveIds") Long id,
            @ForAll("names") String name) {
        var dto = new EntityDTO(id, name);
        assertThat(dto.getId()).isEqualTo(id);
        assertThat(dto.getName()).isEqualTo(name);
    }

    @Provide
    Arbitrary<Long> positiveIds() {
        return Arbitraries.longs().between(1L, Long.MAX_VALUE);
    }

    @Provide
    Arbitrary<String> names() {
        return Arbitraries.strings().alpha().ofMinLength(1).ofMaxLength(100);
    }
}
```

## Mutation Testing (PIT)

Run to verify test quality (not just coverage):

```bash
mvn org.pitest:pitest-maven:mutationCoverage \
    -f extensions/pom.xml \
    -DtargetClasses=com.company.MyClass
```

Target: > 60% mutation score on critical classes.

## When the user asks about testing

1. **Read the source class** to understand what needs testing
2. **Check existing test patterns** in the project
3. **Generate comprehensive tests**: happy path + edge cases + error cases + null handling
4. **Add property tests** for data-driven classes (DTOs, validators, converters)
5. **Run tests**: `mvn test -f extensions/pom.xml -Dtest=MyClassTest`
6. **Check coverage**: `mvn jacoco:report -f extensions/pom.xml`
7. **Run mutation tests** for critical classes

## Progressive Disclosure (Reference Files)

For detailed patterns, examples, and advanced usage, read the following reference files as needed:

- For JUnit 5 advanced patterns and examples, read `references/junit5-patterns.md`
- For property-based testing with jqwik, read `references/property-testing.md`
- For mutation testing with PIT, read `references/mutation-testing.md`
- For Bonita-specific test mocking patterns, read `references/bonita-mocking.md`
- Run `scripts/run-tests.sh` to execute tests
- Run `scripts/check-coverage.sh` to verify coverage thresholds
