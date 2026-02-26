# Mutation Testing with PIT

This reference provides comprehensive guidance on mutation testing using PIT (pitest-maven) to verify test quality beyond simple code coverage.

## Table of Contents

1. [What Is Mutation Testing](#what-is-mutation-testing)
2. [Why It Matters](#why-it-matters)
3. [Maven Configuration](#maven-configuration)
4. [Running PIT](#running-pit)
5. [Interpreting Results](#interpreting-results)
6. [Targets and Thresholds](#targets-and-thresholds)
7. [Common Surviving Mutants and How to Kill Them](#common-surviving-mutants-and-how-to-kill-them)
8. [PIT Configuration in pom.xml](#pit-configuration-in-pomxml)
9. [Workflow Integration](#workflow-integration)

---

## What Is Mutation Testing

Mutation testing evaluates the **quality of your tests**, not just whether code is executed. It works by:

1. **Mutating** your production code (introducing small bugs)
2. **Running** your test suite against each mutant
3. **Checking** if the tests catch the bug (kill the mutant)

| Term | Meaning |
|------|---------|
| **Mutant** | A copy of your code with one small change (a "bug") |
| **Killed mutant** | A mutant detected by a failing test (GOOD) |
| **Surviving mutant** | A mutant NOT detected by any test (BAD - test gap) |
| **Mutation score** | `killed / (killed + survived)` as a percentage |

### Example

Original code:
```java
public boolean isAdult(int age) {
    return age >= 18;
}
```

PIT creates mutants:
```java
// Mutant 1: Changed >= to >
return age > 18;    // Tests should catch this!

// Mutant 2: Changed >= to <=
return age <= 18;   // Tests should catch this!

// Mutant 3: Changed 18 to 19
return age >= 19;   // Tests should catch this!

// Mutant 4: Replaced return with true
return true;        // Tests should catch this!
```

If your test only checks `isAdult(20)`, mutants 1 and 3 SURVIVE because 20 > 18 and 20 >= 19 are both true. You need boundary tests like `isAdult(18)` and `isAdult(17)`.

---

## Why It Matters

Code coverage tells you which lines were **executed**. Mutation testing tells you which lines were **verified**.

| Metric | What it measures | Limitation |
|--------|-----------------|------------|
| Line coverage | Lines executed during tests | A line can be executed without being tested |
| Branch coverage | Decision paths taken | Both branches can be taken without checking results |
| Mutation score | Whether tests actually catch bugs | Slower to compute |

**Real-world example of the gap:**

```java
// 100% line coverage but useless test
@Test
void should_calculate_total() {
    service.calculateTotal(items);  // Executes all lines
    // But NO assertions! Line coverage is 100%, mutation score is 0%.
}

// Proper test that kills mutants
@Test
void should_calculate_total_when_items_have_prices() {
    var result = service.calculateTotal(items);
    assertThat(result).isEqualTo(150.0);  // This kills mutants
}
```

---

## Maven Configuration

### Minimal PIT plugin configuration

Add to your `pom.xml` in the `<build><plugins>` section:

```xml
<plugin>
    <groupId>org.pitest</groupId>
    <artifactId>pitest-maven</artifactId>
    <version>1.15.3</version>
    <dependencies>
        <!-- JUnit 5 support -->
        <dependency>
            <groupId>org.pitest</groupId>
            <artifactId>pitest-junit5-plugin</artifactId>
            <version>1.2.1</version>
        </dependency>
    </dependencies>
    <configuration>
        <targetClasses>
            <param>com.bonitasoft.processbuilder.rest.api.*</param>
        </targetClasses>
        <targetTests>
            <param>com.bonitasoft.processbuilder.rest.api.*Test</param>
        </targetTests>
        <mutators>
            <mutator>DEFAULTS</mutator>
        </mutators>
        <outputFormats>
            <param>HTML</param>
            <param>XML</param>
        </outputFormats>
        <timestampedReports>false</timestampedReports>
        <verbose>false</verbose>
    </configuration>
</plugin>
```

### Extended configuration with thresholds

```xml
<configuration>
    <targetClasses>
        <param>com.bonitasoft.processbuilder.rest.api.controller.*</param>
        <param>com.bonitasoft.processbuilder.rest.api.utils.*</param>
    </targetClasses>
    <targetTests>
        <param>com.bonitasoft.processbuilder.rest.api.*Test</param>
        <param>com.bonitasoft.processbuilder.rest.api.*PropertyTest</param>
    </targetTests>
    <excludedClasses>
        <param>com.bonitasoft.processbuilder.rest.api.dto.*</param>
    </excludedClasses>
    <mutators>
        <mutator>DEFAULTS</mutator>
    </mutators>
    <mutationThreshold>60</mutationThreshold>
    <coverageThreshold>80</coverageThreshold>
    <outputFormats>
        <param>HTML</param>
        <param>XML</param>
    </outputFormats>
    <timestampedReports>false</timestampedReports>
    <threads>4</threads>
    <timeoutConstant>8000</timeoutConstant>
</configuration>
```

---

## Running PIT

### Run against a specific class

```bash
mvn org.pitest:pitest-maven:mutationCoverage \
    -f extensions/pom.xml \
    -DtargetClasses=com.bonitasoft.processbuilder.rest.api.controller.myEntity.MyEntity
```

### Run against a package

```bash
mvn org.pitest:pitest-maven:mutationCoverage \
    -f extensions/pom.xml \
    -DtargetClasses="com.bonitasoft.processbuilder.rest.api.controller.myEntity.*"
```

### Run against all configured classes

```bash
mvn org.pitest:pitest-maven:mutationCoverage -f extensions/pom.xml
```

### Run with specific tests

```bash
mvn org.pitest:pitest-maven:mutationCoverage \
    -f extensions/pom.xml \
    -DtargetClasses=com.bonitasoft.processbuilder.rest.api.controller.myEntity.MyEntity \
    -DtargetTests=com.bonitasoft.processbuilder.rest.api.controller.myEntity.MyEntityTest
```

### Output location

Reports are generated in:
```
target/pit-reports/index.html
```

Open this HTML file in a browser to see detailed mutation results per class and line.

---

## Interpreting Results

### HTML Report Structure

The PIT report shows:

1. **Summary page**: Overall mutation score, number of mutants killed/survived
2. **Package breakdown**: Scores per package
3. **Class details**: Line-by-line mutations with status

### Mutation statuses

| Status | Color | Meaning |
|--------|-------|---------|
| **KILLED** | Green | Test detected the mutation (GOOD) |
| **SURVIVED** | Red | No test detected the mutation (BAD) |
| **NO_COVERAGE** | Orange | The line has no test coverage at all |
| **TIMED_OUT** | Grey | The mutation caused an infinite loop (usually GOOD) |
| **NON_VIABLE** | Grey | The mutation caused a compilation error (ignore) |

### Example output

```
================================================================================
- Statistics
================================================================================
>> Generated 47 mutations Killed 38 (81%)
>> Mutations with no coverage 3. Test strength 90%
>> Ran 124 tests (2.64 tests per mutation)
```

**Interpretation:**
- 81% mutation score (38 killed out of 47)
- 3 mutations have no coverage at all (need more tests)
- 9 mutations survived (need stronger assertions)
- 90% test strength (killed / (total - no_coverage))

---

## Targets and Thresholds

| Classification | Mutation Score | Action |
|---------------|---------------|--------|
| **Critical classes** (validators, security, business logic) | > 80% | Required |
| **Standard classes** (controllers, services) | > 60% | Required |
| **Simple classes** (DTOs, mappers) | > 40% | Nice to have |

**Project standard: > 60% mutation score on critical classes.**

---

## Common Surviving Mutants and How to Kill Them

### 1. Negated Conditionals

**Mutant:** `if (age >= 18)` becomes `if (age < 18)`

**Fix:** Add boundary tests

```java
// BEFORE: Only tests with age=20 (far from boundary)
@Test
void should_allow_adult() {
    assertThat(service.isAdult(20)).isTrue();
}

// AFTER: Add boundary tests
@Test
void should_allow_exactly_18() {
    assertThat(service.isAdult(18)).isTrue();
}

@Test
void should_reject_17() {
    assertThat(service.isAdult(17)).isFalse();
}
```

### 2. Replaced Return Values

**Mutant:** `return result;` becomes `return null;` or `return 0;`

**Fix:** Assert on the return value

```java
// BEFORE: Method called but return value not checked
@Test
void should_execute_calculation() {
    service.calculate(input);  // No assertion on return!
}

// AFTER: Assert the return value
@Test
void should_return_correct_calculation() {
    var result = service.calculate(input);
    assertThat(result).isEqualTo(expectedValue);
}
```

### 3. Removed Method Calls

**Mutant:** `notificationService.send(message);` is removed entirely

**Fix:** Verify the call with Mockito

```java
// BEFORE: No verification of side effects
@Test
void should_process_order() {
    service.processOrder(order);
    assertThat(order.getStatus()).isEqualTo("PROCESSED");
}

// AFTER: Verify the side effect call
@Test
void should_send_notification_when_order_is_processed() {
    service.processOrder(order);
    verify(notificationService).send(any(Message.class));
}
```

### 4. Changed Math Operators

**Mutant:** `a + b` becomes `a - b` or `a * b`

**Fix:** Test with values where the operators produce different results

```java
// BEFORE: Test with values that could pass with different operators
@Test
void should_calculate_total() {
    // With price=0, quantity=5: 0+5=5, 0*5=0, 0-5=-5
    // But 1+1=2, 1*1=1, 1-1=0 -- these differ
    assertThat(calculator.total(0, 5)).isEqualTo(5);  // Not great
}

// AFTER: Use values that distinguish operators
@Test
void should_add_price_and_tax() {
    assertThat(calculator.total(10, 3)).isEqualTo(13);  // Only + gives 13
}
```

### 5. Changed Boolean Returns

**Mutant:** `return true;` becomes `return false;`

**Fix:** Test both true and false paths

```java
// BEFORE: Only test the true case
@Test
void should_validate_when_valid() {
    assertThat(validator.isValid(goodInput)).isTrue();
}

// AFTER: Also test the false case
@Test
void should_reject_when_invalid() {
    assertThat(validator.isValid(badInput)).isFalse();
}
```

### 6. Empty Returns (void methods)

**Mutant:** Body of void method is emptied

**Fix:** Verify observable side effects

```java
// BEFORE: Just call the method
@Test
void should_update_status() {
    service.markAsComplete(entityId);
}

// AFTER: Verify the side effect
@Test
void should_call_dao_to_update_status() {
    service.markAsComplete(entityId);
    verify(dao).updateStatus(entityId, "COMPLETE");
}
```

---

## PIT Configuration in pom.xml

### Default mutators (DEFAULTS group)

The DEFAULTS group includes these mutations:

| Mutator | What it does |
|---------|-------------|
| ConditionalsBoundaryMutator | `<` to `<=`, `>=` to `>`, etc. |
| IncrementsMutator | `++` to `--`, `--` to `++` |
| InvertNegsMutator | `-x` to `x` |
| MathMutator | `+` to `-`, `*` to `/`, etc. |
| NegateConditionalsMutator | `==` to `!=`, `<` to `>=`, etc. |
| ReturnValsMutator | Change return values |
| VoidMethodCallMutator | Remove void method calls |
| EmptyObjectReturnValsMutator | Return empty collections, "" for strings |
| FalseReturnValsMutator | Return false for boolean methods |
| TrueReturnValsMutator | Return true for boolean methods |
| NullReturnValsMutator | Return null for object methods |
| PrimitiveReturnsMutator | Return 0 for int, 0.0 for double, etc. |

### Excluding classes from mutation

```xml
<excludedClasses>
    <!-- Exclude DTOs (tested by property tests instead) -->
    <param>com.bonitasoft.processbuilder.rest.api.dto.*</param>
    <!-- Exclude auto-generated code -->
    <param>*Builder</param>
    <param>*Builder$*</param>
</excludedClasses>
```

### Excluding specific methods

```xml
<excludedMethods>
    <!-- Exclude Lombok-generated methods -->
    <param>toString</param>
    <param>hashCode</param>
    <param>equals</param>
    <!-- Exclude getters/setters if using Lombok -->
    <param>get*</param>
    <param>set*</param>
</excludedMethods>
```

### Performance tuning

```xml
<configuration>
    <!-- Parallel execution -->
    <threads>4</threads>
    <!-- Timeout for each mutant (ms) -->
    <timeoutConstant>8000</timeoutConstant>
    <!-- Timeout factor -->
    <timeoutFactor>1.5</timeoutFactor>
    <!-- Only mutate changed code (faster for CI) -->
    <features>
        <feature>+auto_threads</feature>
    </features>
</configuration>
```

---

## Workflow Integration

### Recommended workflow for new code

1. Write the production code
2. Write comprehensive unit tests (happy + edge + error + null)
3. Run unit tests: `mvn test -f extensions/pom.xml -Dtest=MyClassTest`
4. Check line coverage: `mvn jacoco:report -f extensions/pom.xml`
5. Run mutation tests: `mvn org.pitest:pitest-maven:mutationCoverage -f extensions/pom.xml -DtargetClasses=com.company.MyClass`
6. Open `target/pit-reports/index.html`
7. For each surviving mutant:
   - Understand what the mutant changed
   - Add a test that would fail if that change were real
   - Re-run PIT to verify the mutant is now killed
8. Repeat until mutation score > 60% (target 80%+)

### CI/CD integration

```xml
<!-- Fail the build if mutation score is below threshold -->
<configuration>
    <mutationThreshold>60</mutationThreshold>
    <coverageThreshold>80</coverageThreshold>
</configuration>
```

With these thresholds, `mvn org.pitest:pitest-maven:mutationCoverage` will fail the build if:
- Mutation score drops below 60%
- Line coverage drops below 80%
