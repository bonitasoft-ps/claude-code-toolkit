---
name: bonita-property-testing
description: |
  Property-based testing with jqwik (Java) and fast-check (JavaScript). Generates random inputs
  to verify invariants. Use for contract validation, BDM entity testing, connector input fuzzing,
  REST API parameter validation. Complements unit tests with exhaustive input exploration.
  Trigger: "property test", "jqwik", "fast-check", "fuzz", "random inputs", "invariant testing"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
user_invocable: true
---

# Property-Based Testing for Bonita

## When to Use Property Testing
- Contract input validation (all possible combinations)
- BDM entity field constraints (boundary values)
- Connector input/output mapping (invariants)
- REST API parameter validation (edge cases)
- Groovy expression evaluation (mathematical properties)
- Any code where "for all valid inputs, property X holds"

## Java — jqwik

### Setup (Maven)
```xml
<dependency>
    <groupId>net.jqwik</groupId>
    <artifactId>jqwik</artifactId>
    <version>1.8.4</version>
    <scope>test</scope>
</dependency>
```

### Basic Property
```java
@Property
void should_always_validate_when_input_within_bounds(@ForAll @IntRange(min = 1, max = 100) int value) {
    assertThat(validator.isValid(value)).isTrue();
}
```

### Custom Arbitraries for Bonita
```java
@Provide
Arbitrary<ContractInput> validContractInputs() {
    return Combinators.combine(
        Arbitraries.strings().alpha().ofMinLength(1).ofMaxLength(255),
        Arbitraries.integers().between(1, 1000),
        Arbitraries.of(true, false)
    ).as(ContractInput::new);
}

@Property
void should_process_any_valid_contract(@ForAll("validContractInputs") ContractInput input) {
    Result result = processor.process(input);
    assertThat(result).isNotNull();
    assertThat(result.isValid()).isTrue();
}
```

### Bonita-Specific Patterns

#### Contract Input Fuzzing
```java
@Property(tries = 1000)
void should_reject_invalid_emails(@ForAll @StringLength(min = 1, max = 50) String notAnEmail) {
    Assume.that(!notAnEmail.matches("^[\\w.-]+@[\\w.-]+\\.[a-zA-Z]{2,}$"));
    assertThatThrownBy(() -> contractValidator.validateEmail(notAnEmail))
        .isInstanceOf(ContractViolationException.class);
}
```

#### BDM Entity Invariants
```java
@Property
void should_maintain_total_consistency(
    @ForAll @IntRange(min = 0) int quantity,
    @ForAll @DoubleRange(min = 0.01) double price
) {
    OrderLine line = new OrderLine(quantity, price);
    assertThat(line.getTotal()).isEqualTo(quantity * price, within(0.01));
}
```

### Statistics and Coverage
```java
@Property
void should_handle_all_status_types(@ForAll("statuses") Status status) {
    Statistics.collect(status);
    assertThat(handler.process(status)).isNotNull();
}
```

## JavaScript — fast-check

### Setup
```bash
npm install --save-dev fast-check
```

### Basic Property
```javascript
const fc = require('fast-check');

test('should always produce valid output', () => {
    fc.assert(fc.property(
        fc.string({ minLength: 1, maxLength: 255 }),
        fc.integer({ min: 1, max: 100 }),
        (name, value) => {
            const result = process(name, value);
            expect(result).toBeDefined();
            expect(result.isValid).toBe(true);
        }
    ));
});
```

### Bonita REST API Fuzzing
```javascript
test('should handle any valid query parameters', () => {
    fc.assert(fc.property(
        fc.integer({ min: 0, max: 1000 }),  // page
        fc.integer({ min: 1, max: 100 }),    // size
        fc.constantFrom('asc', 'desc'),      // order
        (page, size, order) => {
            const params = buildQueryParams(page, size, order);
            expect(params.p).toBeGreaterThanOrEqual(0);
            expect(params.c).toBeGreaterThan(0);
        }
    ));
});
```

## Integration with CI
- jqwik runs with Maven Surefire (same as JUnit 5)
- fast-check runs with Jest/Vitest
- Default: 1000 tries per property
- CI: increase to 10000 for release builds
- Seed-based reproducibility: failed seeds are logged for replay

## Naming Convention
- Java: `should_{invariant}_when_{condition}()` with @Property annotation
- JS: `'should {invariant} for any {input type}'`
