# Property-Based Testing with jqwik

This reference provides comprehensive guidance on property-based testing using jqwik in the project. Property tests complement traditional example-based tests by verifying invariants across many random inputs.

## Table of Contents

1. [What Property Tests Verify](#what-property-tests-verify)
2. [Core Annotations](#core-annotations)
3. [Built-in Providers](#built-in-providers)
4. [Constraint Annotations](#constraint-annotations)
5. [Custom Providers](#custom-providers)
6. [Combining Arbitraries](#combining-arbitraries)
7. [Testing DTOs](#testing-dtos)
8. [Testing Validators](#testing-validators)
9. [Testing Converters](#testing-converters)
10. [Testing Utilities](#testing-utilities)
11. [Complete Examples](#complete-examples)

---

## What Property Tests Verify

Property tests verify **invariants** -- things that should ALWAYS be true regardless of input:

| Invariant Type | Example |
|---------------|---------|
| **Roundtrip** | Serialize then deserialize = original object |
| **Preservation** | Constructor stores values, getters return them |
| **Reflexivity** | `x.equals(x)` is always true |
| **Consistency** | `hashCode()` returns the same value on repeated calls |
| **Validity** | Validator always accepts valid inputs, always rejects invalid inputs |
| **Idempotency** | `f(f(x)) == f(x)` for normalization functions |
| **Boundary** | Output is always within expected range |

**When to write property tests:**
- DTOs / Value Objects / Records (field preservation, equals, hashCode, toString)
- Validators (always-valid, always-invalid properties)
- Converters / Mappers (roundtrip, idempotency)
- Utility functions (boundary, invariant properties)
- Collection operations (size invariants, element preservation)

---

## Core Annotations

### @Property

Marks a method as a property test. jqwik will execute it multiple times with random inputs.

```java
@Property
void should_always_preserve_field_values(
        @ForAll @LongRange(min = 1, max = Long.MAX_VALUE) Long id) {
    var dto = new EntityDTO(id, "name");
    assertThat(dto.getId()).isEqualTo(id);
}
```

### @Property with tries

Control how many random inputs are generated:

```java
@Property(tries = 50)
void should_accept_any_positive_long(@ForAll @LongRange(min = 1) long value) {
    assertThat(value).isPositive();
}

@Property(tries = 200)  // More tries for critical invariants
void should_roundtrip_serialize(@ForAll("validDTOs") EntityDTO dto) {
    var json = mapper.writeValueAsString(dto);
    var restored = mapper.readValue(json, EntityDTO.class);
    assertThat(restored).isEqualTo(dto);
}
```

### @ForAll

Injects a randomly generated value. Works with built-in types or custom `@Provide` methods.

```java
@Property
void should_handle_any_string(@ForAll String input) {
    assertThat(sanitizer.sanitize(input)).isNotNull();
}
```

### @Label

Provides a human-readable description (alternative to `@DisplayName` for property tests):

```java
@Property
@Label("should always produce valid output for any input")
void should_always_produce_valid_output(@ForAll @StringLength(min = 1, max = 100) String input) {
    var result = MyConverter.convert(input);
    assertThat(result).isNotNull();
}
```

---

## Built-in Providers

jqwik provides automatic generation for common types:

| Type | Default Range | Example |
|------|--------------|---------|
| `String` | Any Unicode characters, 0-255 length | `@ForAll String s` |
| `Integer` / `int` | Integer.MIN_VALUE to Integer.MAX_VALUE | `@ForAll int n` |
| `Long` / `long` | Long.MIN_VALUE to Long.MAX_VALUE | `@ForAll long n` |
| `Double` / `double` | Any finite double | `@ForAll double d` |
| `Boolean` / `boolean` | true or false | `@ForAll boolean b` |
| `List<T>` | 0-255 elements of type T | `@ForAll List<String> items` |
| `Set<T>` | 0-255 unique elements | `@ForAll Set<Integer> ids` |
| `Map<K,V>` | 0-255 entries | `@ForAll Map<String, Integer> map` |
| `Optional<T>` | Empty or present | `@ForAll Optional<String> opt` |

---

## Constraint Annotations

### String constraints

```java
@ForAll @StringLength(min = 1, max = 100) String name
@ForAll @StringLength(max = 255) String description
@ForAll @NotBlank String requiredField
```

### Numeric constraints

```java
@ForAll @IntRange(min = 0, max = 100) int page
@ForAll @IntRange(min = 1, max = 50) int count
@ForAll @LongRange(min = 1, max = Long.MAX_VALUE) Long persistenceId
@ForAll @DoubleRange(min = 0.0, max = 1.0) double percentage
@ForAll @Positive int positiveNumber
@ForAll @Negative int negativeNumber
```

### Collection constraints

```java
@ForAll @Size(min = 1, max = 10) List<String> nonEmptyList
@ForAll @Size(max = 5) Set<Integer> smallSet
@ForAll @UniqueElements List<String> uniqueItems
```

---

## Custom Providers

Use `@Provide` to create reusable value generators:

### Basic providers

```java
@Provide
Arbitrary<Long> positiveIds() {
    return Arbitraries.longs().between(1L, Long.MAX_VALUE);
}

@Provide
Arbitrary<String> idStrings() {
    return Arbitraries.longs().between(1L, Long.MAX_VALUE).map(Object::toString);
}

@Provide
Arbitrary<String> names() {
    return Arbitraries.oneOf(
        Arbitraries.strings().alpha().ofMinLength(3).ofMaxLength(50),
        Arbitraries.of("HR", "Finance", "IT", "Operations", "Sales")
    );
}
```

### Enum providers

```java
@Provide
Arbitrary<Status> validStatuses() {
    return Arbitraries.of(Status.ACTIVE, Status.PENDING, Status.COMPLETED);
}

@Provide
Arbitrary<Status> invalidStatuses() {
    return Arbitraries.of(Status.CANCELLED, Status.DELETED, Status.ERROR);
}
```

### Email providers

```java
@Provide
Arbitrary<String> validEmails() {
    Arbitrary<String> localPart = Arbitraries.strings()
        .alpha().numeric()
        .ofMinLength(3).ofMaxLength(20);
    Arbitrary<String> domain = Arbitraries.of(
        "example.com", "company.org", "test.net");
    return Combinators.combine(localPart, domain)
        .as((local, dom) -> local + "@" + dom);
}
```

### Using @Provide in a test

```java
@Property
void should_preserve_all_fields(
        @ForAll("positiveIds") Long id,
        @ForAll("names") String name) {
    var dto = new EntityDTO(id, name);
    assertThat(dto.getId()).isEqualTo(id);
    assertThat(dto.getName()).isEqualTo(name);
}
```

---

## Combining Arbitraries

Use `Combinators.combine()` to build complex objects from simpler arbitraries:

```java
@Provide
Arbitrary<PBCategoryDTO> categories() {
    return Combinators.combine(positiveIds(), idStrings(), names())
        .as(PBCategoryDTO::new);
}

@Provide
Arbitrary<ParamMyEntity> validParams() {
    return Combinators.combine(
        Arbitraries.longs().between(1L, 10000L),
        Arbitraries.integers().between(0, 100),
        Arbitraries.integers().between(1, 50)
    ).as((entityId, page, count) ->
        new ParamMyEntity(entityId, page, count));
}
```

### Flat-mapping for dependent values

```java
@Provide
Arbitrary<ProcessInstanceDTO> processInstances() {
    return Arbitraries.longs().between(1L, 10000L)
        .flatMap(id -> Arbitraries.strings().alpha().ofMinLength(3).ofMaxLength(30)
            .map(name -> ProcessInstanceDTO.builder()
                .id(id)
                .name(name)
                .idString(String.valueOf(id))
                .build()));
}
```

---

## Testing DTOs

DTOs are the primary candidates for property testing. Test these invariants:

### Field preservation

```java
@Property
@DisplayName("should preserve all field values")
void should_preserve_all_field_values(
        @ForAll("positiveIds") Long persistenceId,
        @ForAll("idStrings") String persistenceIdString,
        @ForAll("names") String fullName) {
    PBCategoryDTO dto = new PBCategoryDTO(persistenceId, persistenceIdString, fullName);

    assertThat(dto.getPersistenceId()).isEqualTo(persistenceId);
    assertThat(dto.getPersistenceId_string()).isEqualTo(persistenceIdString);
    assertThat(dto.getFullName()).isEqualTo(fullName);
}
```

### Reflexive equality

```java
@Property
@DisplayName("should be reflexively equal")
void should_be_reflexive(@ForAll("categories") PBCategoryDTO dto) {
    assertThat(dto).isEqualTo(dto);
}
```

### Consistent hashCode

```java
@Property
@DisplayName("should have consistent hashCode")
void should_have_consistent_hashCode(@ForAll("categories") PBCategoryDTO dto) {
    assertThat(dto.hashCode()).isEqualTo(dto.hashCode());
}
```

### Symmetric equality

```java
@Property
@DisplayName("should have symmetric equality")
void should_have_symmetric_equality(
        @ForAll("positiveIds") Long id,
        @ForAll("names") String name) {
    var dto1 = new EntityDTO(id, name);
    var dto2 = new EntityDTO(id, name);

    assertThat(dto1).isEqualTo(dto2);
    assertThat(dto2).isEqualTo(dto1);
}
```

### Null field handling

```java
@Property
@DisplayName("should handle null fields")
void should_handle_null_fields(@ForAll("positiveIds") Long id) {
    PBCategoryDTO dto = new PBCategoryDTO(id, null, null);
    assertThat(dto.getPersistenceId()).isEqualTo(id);
    assertThat(dto.getPersistenceId_string()).isNull();
    assertThat(dto.getFullName()).isNull();
}
```

### toString non-null

```java
@Property
@DisplayName("should generate non-null toString")
void should_generate_non_null_toString(@ForAll("categories") PBCategoryDTO dto) {
    assertThat(dto.toString()).isNotNull();
    assertThat(dto.toString()).contains("PBCategoryDTO");
}
```

---

## Testing Validators

### Always-valid property

```java
@Property(tries = 100)
@DisplayName("should accept all valid inputs")
void should_accept_all_valid_inputs(
        @ForAll @StringLength(min = 1, max = 100) String processName,
        @ForAll @LongRange(min = 1) Long entityId) {

    var params = new ParamMyEntity(entityId, processName);

    assertThatCode(() -> validator.validate(params))
        .doesNotThrowAnyException();
}
```

### Always-invalid property

```java
@Property(tries = 100)
@DisplayName("should reject all blank process names")
void should_reject_all_blank_process_names(
        @ForAll @From("blankStrings") String blankName) {

    var params = new ParamMyEntity(1L, blankName);

    assertThatThrownBy(() -> validator.validate(params))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("processName");
}

@Provide
Arbitrary<String> blankStrings() {
    return Arbitraries.oneOf(
        Arbitraries.just(""),
        Arbitraries.just(" "),
        Arbitraries.just("  "),
        Arbitraries.just("\t"),
        Arbitraries.just("\n"),
        Arbitraries.just(" \t \n ")
    );
}
```

---

## Testing Converters

### Roundtrip property (serialize/deserialize)

```java
@Property(tries = 50)
@DisplayName("should roundtrip through JSON serialization")
void should_roundtrip_through_JSON_serialization(
        @ForAll("validDTOs") EntityDTO original) throws Exception {

    ObjectMapper mapper = new ObjectMapper();
    mapper.registerModule(new JavaTimeModule());
    mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    // Serialize
    String json = mapper.writeValueAsString(original);

    // Deserialize
    EntityDTO restored = mapper.readValue(json, EntityDTO.class);

    // Verify roundtrip
    assertThat(restored).isEqualTo(original);
}
```

### Idempotency property

```java
@Property(tries = 100)
@DisplayName("should be idempotent - applying twice equals applying once")
void should_be_idempotent(
        @ForAll @StringLength(min = 0, max = 200) String input) {

    String normalized1 = StringNormalizer.normalize(input);
    String normalized2 = StringNormalizer.normalize(normalized1);

    assertThat(normalized2).isEqualTo(normalized1);
}
```

### Conversion preserves information

```java
@Property(tries = 50)
@DisplayName("should preserve entity ID through conversion")
void should_preserve_entity_ID_through_conversion(
        @ForAll @LongRange(min = 1) Long entityId,
        @ForAll @StringLength(min = 1, max = 50) String name) {

    var entity = createEntity(entityId, name);
    var dto = EntityMapper.toDTO(entity);

    assertThat(dto.getId()).isEqualTo(entity.getId());
    assertThat(dto.getName()).isEqualTo(entity.getName());
}
```

---

## Testing Utilities

### Collection operation invariants

```java
@Property
@DisplayName("should preserve list size after mapping")
void should_preserve_list_size_after_mapping(
        @ForAll @Size(min = 0, max = 50) List<@StringLength(min = 1, max = 20) String> input) {

    var result = ListUtils.mapToUpperCase(input);

    assertThat(result).hasSameSizeAs(input);
}

@Property
@DisplayName("should sort in non-decreasing order")
void should_sort_in_non_decreasing_order(
        @ForAll List<@IntRange(min = -1000, max = 1000) Integer> input) {

    var sorted = SortUtils.sort(input);

    for (int i = 1; i < sorted.size(); i++) {
        assertThat(sorted.get(i)).isGreaterThanOrEqualTo(sorted.get(i - 1));
    }
}
```

### String utility invariants

```java
@Property
@DisplayName("should never increase string length after truncation")
void should_never_increase_string_length_after_truncation(
        @ForAll String input,
        @ForAll @IntRange(min = 0, max = 100) int maxLength) {

    var result = StringUtils.truncate(input, maxLength);

    assertThat(result.length()).isLessThanOrEqualTo(maxLength);
}

@Property
@DisplayName("should preserve original when shorter than max")
void should_preserve_original_when_shorter_than_max(
        @ForAll @StringLength(max = 10) String input) {

    var result = StringUtils.truncate(input, 100);

    assertThat(result).isEqualTo(input);
}
```

---

## Complete Examples

### Complete DTO Property Test

```java
package com.bonitasoft.processbuilder.rest.api.dto.bdm;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.DisplayName;

import net.jqwik.api.Arbitraries;
import net.jqwik.api.Arbitrary;
import net.jqwik.api.Combinators;
import net.jqwik.api.ForAll;
import net.jqwik.api.Property;
import net.jqwik.api.Provide;

/**
 * Property-Based Tests for {@link PBCategoryDTO}.
 * Verifies invariants: field preservation, equality, hashCode, null handling.
 */
@DisplayName("PBCategoryDTO Property-Based Tests")
class PBCategoryDTOPropertyTest {

    @Property
    @DisplayName("should preserve all field values")
    void should_preserve_all_field_values(
            @ForAll("positiveIds") Long persistenceId,
            @ForAll("idStrings") String persistenceIdString,
            @ForAll("names") String fullName) {
        PBCategoryDTO dto = new PBCategoryDTO(
            persistenceId, persistenceIdString, fullName);

        assertThat(dto.getPersistenceId()).isEqualTo(persistenceId);
        assertThat(dto.getPersistenceId_string())
            .isEqualTo(persistenceIdString);
        assertThat(dto.getFullName()).isEqualTo(fullName);
    }

    @Property
    @DisplayName("should be reflexively equal")
    void should_be_reflexive(
            @ForAll("categories") PBCategoryDTO dto) {
        assertThat(dto).isEqualTo(dto);
    }

    @Property
    @DisplayName("should have consistent hashCode")
    void should_have_consistent_hashCode(
            @ForAll("categories") PBCategoryDTO dto) {
        assertThat(dto.hashCode()).isEqualTo(dto.hashCode());
    }

    @Property
    @DisplayName("should handle null fields")
    void should_handle_null_fields(
            @ForAll("positiveIds") Long id) {
        PBCategoryDTO dto = new PBCategoryDTO(id, null, null);
        assertThat(dto.getPersistenceId()).isEqualTo(id);
        assertThat(dto.getPersistenceId_string()).isNull();
        assertThat(dto.getFullName()).isNull();
    }

    @Property
    @DisplayName("should generate non-null toString")
    void should_generate_non_null_toString(
            @ForAll("categories") PBCategoryDTO dto) {
        assertThat(dto.toString()).isNotNull();
        assertThat(dto.toString()).contains("PBCategoryDTO");
    }

    @Provide
    Arbitrary<Long> positiveIds() {
        return Arbitraries.longs().between(1L, Long.MAX_VALUE);
    }

    @Provide
    Arbitrary<String> idStrings() {
        return Arbitraries.longs().between(1L, Long.MAX_VALUE)
            .map(Object::toString);
    }

    @Provide
    Arbitrary<String> names() {
        return Arbitraries.oneOf(
            Arbitraries.strings().alpha()
                .ofMinLength(3).ofMaxLength(50),
            Arbitraries.of(
                "HR", "Finance", "IT", "Operations", "Sales")
        );
    }

    @Provide
    Arbitrary<PBCategoryDTO> categories() {
        return Combinators.combine(
            positiveIds(), idStrings(), names())
            .as(PBCategoryDTO::new);
    }
}
```

### Complete Validator Property Test with Mocking

```java
package com.bonitasoft.processbuilder.rest.api.controller.myEntity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import javax.servlet.http.HttpServletRequest;

import org.bonitasoft.web.extension.rest.RestAPIContext;

import com.bonitasoft.processbuilder.rest.api.exception.ValidationException;
import com.bonitasoft.processbuilder.rest.api.utils.LicenseValidator;

import net.jqwik.api.ForAll;
import net.jqwik.api.Property;
import net.jqwik.api.constraints.LongRange;
import net.jqwik.api.constraints.StringLength;

/**
 * Property-based tests for parameter validation in MyEntityController.
 */
class MyEntityPropertyTest {

    private static final String TEST_PROCESS_NAME = "TestProcess";

    @Property(tries = 50)
    void should_accept_any_positive_id(
            @ForAll @LongRange(min = 1, max = Long.MAX_VALUE) long entityId) {

        // Given
        HttpServletRequest request = mock(HttpServletRequest.class);
        RestAPIContext context = mock(RestAPIContext.class);
        LicenseValidator.enableTestMode();

        when(request.getParameter("entityId"))
            .thenReturn(String.valueOf(entityId));

        var controller = new MyEntity();

        // When
        var result = controller.validateInputParameters(request, context);

        // Then
        assertThat(result.getEntityId()).isEqualTo(entityId);

        LicenseValidator.disableTestMode();
    }

    @Property(tries = 50)
    void should_reject_any_non_numeric_id(
            @ForAll @StringLength(min = 1, max = 20) String nonNumericValue) {

        // Filter out valid numeric strings
        try {
            Long.parseLong(nonNumericValue.trim());
            return; // Skip valid numeric strings
        } catch (NumberFormatException ignored) {
            // Non-numeric - proceed with test
        }

        if (nonNumericValue.trim().isEmpty()) {
            return; // Skip blank strings (different validation path)
        }

        // Given
        HttpServletRequest request = mock(HttpServletRequest.class);
        RestAPIContext context = mock(RestAPIContext.class);
        LicenseValidator.enableTestMode();

        when(request.getParameter("entityId")).thenReturn(nonNumericValue);

        var controller = new MyEntity();

        // When / Then
        assertThatThrownBy(() ->
            controller.validateInputParameters(request, context))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("entityId");

        LicenseValidator.disableTestMode();
    }
}
```
