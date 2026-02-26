# DTO Validation Patterns

This reference provides detailed patterns for testing Data Transfer Objects (DTOs) in Bonita REST API extensions, including jqwik property-based tests, response wrapper validation, error DTO testing, and custom arbitraries for Bonita domain objects.

## Table of Contents

1. [jqwik Property-Based Testing for DTOs](#jqwik-property-based-testing)
2. [Standard DTO Property Tests](#standard-dto-property-tests)
3. [Response Wrapper Testing](#response-wrapper-testing)
4. [Error DTO Testing](#error-dto-testing)
5. [Custom @Provide Arbitraries](#custom-provide-arbitraries)
6. [Combining Property Tests with Unit Tests](#combining-property-tests-with-unit-tests)
7. [Complete DTO Property Test Example](#complete-dto-property-test-example)

---

## jqwik Property-Based Testing

Property-based tests verify **invariants** that must hold for ALL possible inputs, not just specific examples. Use jqwik for DTOs, validators, converters, and utility classes.

### When to Use Property Tests

| Use Case | Why |
|----------|-----|
| DTOs / Records / Value Objects | Verify field preservation, equality, hashCode, toString |
| Validators | Verify all valid inputs are accepted, all invalid are rejected |
| Converters / Mappers | Verify round-trip conversion, no data loss |
| Utility methods | Verify invariants like idempotence, commutativity |

### File Naming Convention

Property test files use the `*PropertyTest.java` suffix:

```
MyEntityDTO.java          --> MyEntityDTOPropertyTest.java
MyEntityDTOTest.java      --> Standard unit tests (specific examples)
MyEntityDTOPropertyTest.java --> Property-based tests (all possible inputs)
```

---

## Standard DTO Property Tests

Every DTO property test class should verify these properties:

### 1. Field Preservation

All field values set through the constructor or builder are preserved when accessed via getters.

```java
@Property
@DisplayName("should preserve all field values")
void should_preserve_all_field_values(
        @ForAll("positiveIds") Long persistenceId,
        @ForAll("names") String name,
        @ForAll("descriptions") String description,
        @ForAll("statuses") String status) {

    var dto = new MyEntityDTO(persistenceId, name, description, status);

    assertThat(dto.getPersistenceId()).isEqualTo(persistenceId);
    assertThat(dto.getName()).isEqualTo(name);
    assertThat(dto.getDescription()).isEqualTo(description);
    assertThat(dto.getStatus()).isEqualTo(status);
}
```

### 2. Reflexive Equality

An object must be equal to itself.

```java
@Property
@DisplayName("should be reflexively equal")
void should_be_reflexive(@ForAll("entities") MyEntityDTO dto) {
    assertThat(dto).isEqualTo(dto);
}
```

### 3. Consistent HashCode

Calling `hashCode()` multiple times on the same object must return the same value.

```java
@Property
@DisplayName("should have consistent hashCode")
void should_have_consistent_hashCode(@ForAll("entities") MyEntityDTO dto) {
    assertThat(dto.hashCode()).isEqualTo(dto.hashCode());
}
```

### 4. Symmetric Equality

If `a.equals(b)` then `b.equals(a)`.

```java
@Property
@DisplayName("should have symmetric equality")
void should_have_symmetric_equality(
        @ForAll("positiveIds") Long id,
        @ForAll("names") String name) {

    var dto1 = new MyEntityDTO(id, name, "desc", "active");
    var dto2 = new MyEntityDTO(id, name, "desc", "active");

    assertThat(dto1).isEqualTo(dto2);
    assertThat(dto2).isEqualTo(dto1);
}
```

### 5. Null Field Handling

DTOs should handle null fields without throwing exceptions.

```java
@Property
@DisplayName("should handle null fields")
void should_handle_null_fields(@ForAll("positiveIds") Long id) {
    var dto = new MyEntityDTO(id, null, null, null);

    assertThat(dto.getPersistenceId()).isEqualTo(id);
    assertThat(dto.getName()).isNull();
    assertThat(dto.getDescription()).isNull();
}
```

### 6. Non-Null toString

The `toString()` method should never return null and should contain the class name.

```java
@Property
@DisplayName("should generate non-null toString")
void should_generate_non_null_toString(@ForAll("entities") MyEntityDTO dto) {
    assertThat(dto.toString()).isNotNull();
    assertThat(dto.toString()).contains("MyEntityDTO");
}
```

### 7. Nested Object Preservation

When a DTO contains nested objects, verify they are preserved correctly.

```java
@Property
@DisplayName("should preserve nested category DTO")
void should_preserve_nested_category(@ForAll("categories") CategoryDTO category) {
    var dto = new MyEntityDTO(1L, "Entity", "Description", "active");
    // If using builder or setter:
    var dtoWithCategory = new MyEntityDTO(1L, "Entity", "Description", "active", category);

    assertThat(dtoWithCategory.getCategory()).isEqualTo(category);
}
```

---

## Response Wrapper Testing

### ApiResponse Wrapper

For integration API response wrappers like `ApiResponse<T>`:

```java
@DisplayName("ApiResponse Property-Based Tests")
class ApiResponsePropertyTest {

    @Property
    @DisplayName("should preserve status and message in success response")
    void should_preserve_success_response(
            @ForAll("names") String message) {

        var response = ApiResponse.success(message);

        assertThat(response.getStatus()).isEqualTo("SUCCESS");
        assertThat(response.getMessage()).isEqualTo(message);
        assertThat(response.getError()).isNull();
    }

    @Property
    @DisplayName("should preserve error code and message in error response")
    void should_preserve_error_response(
            @ForAll("errorCodes") String errorCode,
            @ForAll("names") String message) {

        var response = ApiResponse.error(errorCode, message);

        assertThat(response.getStatus()).isEqualTo("ERROR");
        assertThat(response.getError()).isNotNull();
        assertThat(response.getError().getCode()).isEqualTo(errorCode);
        assertThat(response.getError().getMessage()).isEqualTo(message);
    }

    @Provide
    Arbitrary<String> errorCodes() {
        return Arbitraries.of(
            "BAD_REQUEST", "NOT_FOUND", "FORBIDDEN",
            "UNAUTHORIZED", "INTERNAL_ERROR", "VALIDATION_ERROR"
        );
    }
}
```

### PaginationInfo Testing

```java
@DisplayName("PaginationInfo Property-Based Tests")
class PaginationInfoPropertyTest {

    @Property
    @DisplayName("should preserve pagination values")
    void should_preserve_pagination_values(
            @ForAll("pageIndices") Integer p,
            @ForAll("pageSizes") Integer c,
            @ForAll("totals") Long total) {

        var pagination = new PaginationInfo(p, c, total);

        assertThat(pagination.getP()).isEqualTo(p);
        assertThat(pagination.getC()).isEqualTo(c);
        assertThat(pagination.getTotal()).isEqualTo(total);
    }

    @Property
    @DisplayName("should calculate correct offset")
    void should_calculate_correct_offset(
            @ForAll("pageIndices") Integer p,
            @ForAll("pageSizes") Integer c) {

        var pagination = new PaginationInfo(p, c, 1000L);

        // offset = p * c
        assertThat(pagination.getOffset()).isEqualTo((long) p * c);
    }

    @Provide
    Arbitrary<Integer> pageIndices() {
        return Arbitraries.integers().between(0, 100);
    }

    @Provide
    Arbitrary<Integer> pageSizes() {
        return Arbitraries.integers().between(1, 1000);
    }

    @Provide
    Arbitrary<Long> totals() {
        return Arbitraries.longs().between(0L, 1_000_000L);
    }
}
```

---

## Error DTO Testing

### Error DTO Properties

```java
@DisplayName("Error DTO Property-Based Tests")
class ErrorPropertyTest {

    @Property
    @DisplayName("should preserve error message")
    void should_preserve_error_message(@ForAll("errorMessages") String message) {
        var error = Error.builder().message(message).build();

        assertThat(error.getMessage()).isEqualTo(message);
    }

    @Property
    @DisplayName("should be reflexively equal")
    void should_be_reflexive(@ForAll("errors") Error error) {
        assertThat(error).isEqualTo(error);
    }

    @Property
    @DisplayName("should have consistent hashCode")
    void should_have_consistent_hashCode(@ForAll("errors") Error error) {
        assertThat(error.hashCode()).isEqualTo(error.hashCode());
    }

    @Property
    @DisplayName("should handle null message")
    void should_handle_null_message() {
        var error = Error.builder().message(null).build();

        assertThat(error.getMessage()).isNull();
        assertThat(error.toString()).isNotNull();
    }

    @Provide
    Arbitrary<String> errorMessages() {
        return Arbitraries.oneOf(
            Arbitraries.strings().alpha().ofMinLength(5).ofMaxLength(200),
            Arbitraries.of(
                "Required parameter 'p' is missing",
                "Parameter 'c' must be a valid integer",
                "Internal server error",
                "Entity not found with ID: 123"
            )
        );
    }

    @Provide
    Arbitrary<Error> errors() {
        return errorMessages().map(msg -> Error.builder().message(msg).build());
    }
}
```

### Error Code Mapping Tests

```java
@DisplayName("Error code mapping tests")
class ErrorCodeMappingTest {

    @Test
    @DisplayName("should map ValidationException to BAD_REQUEST error code")
    void should_map_ValidationException_to_BAD_REQUEST() {
        var error = ErrorMapper.fromException(new ValidationException("bad param"));

        assertThat(error.getCode()).isEqualTo("BAD_REQUEST");
        assertThat(error.getMessage()).contains("bad param");
    }

    @Test
    @DisplayName("should map ProcessInstanceNotFoundException to NOT_FOUND error code")
    void should_map_ProcessInstanceNotFoundException_to_NOT_FOUND() {
        var error = ErrorMapper.fromException(
            new ProcessInstanceNotFoundException(123L));

        assertThat(error.getCode()).isEqualTo("NOT_FOUND");
    }

    @Test
    @DisplayName("should map RuntimeException to INTERNAL_ERROR error code")
    void should_map_RuntimeException_to_INTERNAL_ERROR() {
        var error = ErrorMapper.fromException(new RuntimeException("unexpected"));

        assertThat(error.getCode()).isEqualTo("INTERNAL_ERROR");
        // Should NOT expose internal error details
        assertThat(error.getMessage()).doesNotContain("unexpected");
    }
}
```

---

## Custom @Provide Arbitraries

### Standard Bonita Domain Arbitraries

Reusable arbitraries for common Bonita domain types:

```java
// Persistence IDs (always positive)
@Provide
Arbitrary<Long> positiveIds() {
    return Arbitraries.longs().between(1L, Long.MAX_VALUE);
}

// ID strings (string representation of Long IDs)
@Provide
Arbitrary<String> idStrings() {
    return Arbitraries.longs().between(1L, Long.MAX_VALUE).map(Object::toString);
}

// Entity names
@Provide
Arbitrary<String> names() {
    return Arbitraries.oneOf(
        Arbitraries.strings().alpha().ofMinLength(3).ofMaxLength(50),
        Arbitraries.of("Employee Onboarding", "Purchase Order", "Leave Request",
                        "Invoice Approval", "Customer Support Ticket")
    );
}

// Descriptions (may be null)
@Provide
Arbitrary<String> descriptions() {
    return Arbitraries.oneOf(
        Arbitraries.strings().alpha().ofMinLength(10).ofMaxLength(200),
        Arbitraries.just(null)
    );
}

// Process versions
@Provide
Arbitrary<String> versions() {
    return Arbitraries.of("1.0", "1.1", "2.0", "2.1", "3.0", "1.0.1", "2.0.0-SNAPSHOT");
}

// Process/instance statuses
@Provide
Arbitrary<String> statuses() {
    return Arbitraries.of("active", "disabled", "resolved", "initializing",
                          "running", "completed", "cancelled", "aborted");
}

// Nullable booleans
@Provide
Arbitrary<Boolean> booleans() {
    return Arbitraries.of(true, false, null);
}

// User IDs
@Provide
Arbitrary<Long> userIds() {
    return Arbitraries.longs().between(1L, 10000L);
}

// Usernames
@Provide
Arbitrary<String> usernames() {
    return Arbitraries.oneOf(
        Arbitraries.strings().alpha().ofMinLength(3).ofMaxLength(20)
            .map(s -> s.toLowerCase() + "." + s.substring(0, Math.min(3, s.length()))),
        Arbitraries.of("john.doe", "jane.smith", "admin.user", "technical_api")
    );
}
```

### Composite Arbitraries for Nested DTOs

When a DTO contains nested objects, use `Combinators.combine()`:

```java
// Simple nested DTO (up to 8 fields)
@Provide
Arbitrary<PBGenericEntryDTO> genericEntries() {
    return Combinators.combine(
        positiveIds(),
        idStrings(),
        Arbitraries.of("High", "Medium", "Low"),
        Arbitraries.of("High Priority", "Medium Priority", "Low Priority")
    ).as(PBGenericEntryDTO::new);
}

// Nested DTO with nullable injection
@Provide
Arbitrary<PBCategoryDTO> categories() {
    return Combinators.combine(
        positiveIds(),
        idStrings(),
        Arbitraries.of("HR", "Finance", "IT", "Operations")
    ).as(PBCategoryDTO::new);
}
```

### DTOs with More Than 8 Fields

When a DTO constructor has more than 8 parameters, use `flatAs()` to chain combinators:

```java
@Provide
Arbitrary<PBProcessDTO> processes() {
    return Combinators.combine(
        positiveIds(),        // persistenceId
        idStrings(),          // persistenceId_string
        names(),              // fullName
        descriptions(),       // fullDescription
        names(),              // displayName
        versions(),           // version
        statuses(),           // lastStatus
        booleans()            // launchable
    ).flatAs((id, idStr, name, desc, display, ver, status, launch) ->
        Combinators.combine(
            booleans(),                        // editable
            genericEntries().injectNull(0.3),  // criticality (30% null)
            categories().injectNull(0.3)       // category (30% null)
        ).as((edit, crit, cat) ->
            new PBProcessDTO(id, idStr, name, desc, display, ver,
                             status, launch, edit, crit, cat)));
}
```

### Null Injection

Use `.injectNull(probability)` to randomly inject null values:

```java
// 30% chance of null
genericEntries().injectNull(0.3)

// 50% chance of null
descriptions().injectNull(0.5)

// Never null
positiveIds()  // No injectNull
```

---

## Combining Property Tests with Unit Tests

For comprehensive DTO coverage, create BOTH:
- `*PropertyTest.java` -- property-based invariant tests
- `*Test.java` -- example-based unit tests for specific scenarios

### Property Test Focus (Invariants)

```java
// PBProcessDTOPropertyTest.java
@Property
void should_preserve_all_field_values(@ForAll("processes") PBProcessDTO dto) {
    // Invariant: fields are always preserved
    assertThat(dto.getPersistenceId()).isNotNull();
    assertThat(dto.toString()).contains("PBProcessDTO");
}
```

### Unit Test Focus (Specific Scenarios)

```java
// PBProcessDTOTest.java
@Test
@DisplayName("should create DTO with all fields populated")
void should_create_DTO_with_all_fields_populated() {
    // Specific scenario with known values
    var dto = new PBProcessDTO(
        1L, "1", "Sales Process", "Manages sales orders",
        "Sales", "1.0", "active", true, true, null, null);

    assertThat(dto.getPersistenceId()).isEqualTo(1L);
    assertThat(dto.getFullName()).isEqualTo("Sales Process");
    assertThat(dto.getVersion()).isEqualTo("1.0");
}

@Test
@DisplayName("should handle all-null optional fields")
void should_handle_all_null_optional_fields() {
    var dto = new PBProcessDTO(
        1L, "1", null, null, null, null, null, null, null, null, null);

    assertThat(dto.getPersistenceId()).isEqualTo(1L);
    assertThat(dto.getFullName()).isNull();
}

@Test
@DisplayName("should have correct toString format")
void should_have_correct_toString_format() {
    var dto = new PBProcessDTO(
        1L, "1", "Test", "Desc", "Test", "1.0",
        "active", true, true, null, null);

    assertThat(dto.toString())
        .contains("PBProcessDTO")
        .contains("persistenceId=1");
}
```

---

## Complete DTO Property Test Example

Here is a complete, production-quality property test class:

```java
package com.bonitasoft.processbuilder.rest.api.dto.objects;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.time.LocalDateTime;

import org.junit.jupiter.api.DisplayName;

import net.jqwik.api.Arbitraries;
import net.jqwik.api.Arbitrary;
import net.jqwik.api.Combinators;
import net.jqwik.api.ForAll;
import net.jqwik.api.Property;
import net.jqwik.api.Provide;

/**
 * Property-Based Tests for {@link ProcessInstanceDTO}.
 *
 * Verifies invariants that must hold for ALL possible inputs:
 * - Field preservation through construction
 * - Reflexive equality
 * - Consistent hashCode
 * - Null field handling
 * - Non-null toString
 */
@DisplayName("ProcessInstanceDTO Property-Based Tests")
class ProcessInstanceDTOPropertyTest {

    // =========================================================================
    // Property Tests
    // =========================================================================

    @Property
    @DisplayName("should preserve all field values")
    void should_preserve_all_field_values(
            @ForAll("positiveIds") Long persistenceId,
            @ForAll("idStrings") String persistenceIdString,
            @ForAll("names") String processName,
            @ForAll("statuses") String status,
            @ForAll("userIds") Long startedByUserId) {

        var dto = ProcessInstanceDTO.builder()
            .persistenceId(persistenceId)
            .persistenceId_string(persistenceIdString)
            .processName(processName)
            .processStatus(status)
            .startedByUserId(startedByUserId)
            .build();

        assertThat(dto.getPersistenceId()).isEqualTo(persistenceId);
        assertThat(dto.getPersistenceId_string()).isEqualTo(persistenceIdString);
        assertThat(dto.getProcessName()).isEqualTo(processName);
        assertThat(dto.getProcessStatus()).isEqualTo(status);
        assertThat(dto.getStartedByUserId()).isEqualTo(startedByUserId);
    }

    @Property
    @DisplayName("should be reflexively equal")
    void should_be_reflexive(@ForAll("instances") ProcessInstanceDTO dto) {
        assertThat(dto).isEqualTo(dto);
    }

    @Property
    @DisplayName("should have consistent hashCode")
    void should_have_consistent_hashCode(@ForAll("instances") ProcessInstanceDTO dto) {
        assertThat(dto.hashCode()).isEqualTo(dto.hashCode());
    }

    @Property
    @DisplayName("should handle null optional fields")
    void should_handle_null_optional_fields(@ForAll("positiveIds") Long id) {
        var dto = ProcessInstanceDTO.builder()
            .persistenceId(id)
            .build();

        assertThat(dto.getPersistenceId()).isEqualTo(id);
        assertThat(dto.getProcessName()).isNull();
        assertThat(dto.getProcessStatus()).isNull();
    }

    @Property
    @DisplayName("should generate non-null toString")
    void should_generate_non_null_toString(@ForAll("instances") ProcessInstanceDTO dto) {
        assertThat(dto.toString()).isNotNull();
        assertThat(dto.toString()).contains("ProcessInstanceDTO");
    }

    @Property
    @DisplayName("should have equal objects produce equal hashCodes")
    void should_have_equal_hashCodes_for_equal_objects(
            @ForAll("positiveIds") Long id,
            @ForAll("names") String name) {

        var dto1 = ProcessInstanceDTO.builder()
            .persistenceId(id).processName(name).build();
        var dto2 = ProcessInstanceDTO.builder()
            .persistenceId(id).processName(name).build();

        assertThat(dto1).isEqualTo(dto2);
        assertThat(dto1.hashCode()).isEqualTo(dto2.hashCode());
    }

    // =========================================================================
    // Arbitraries (Providers)
    // =========================================================================

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
            Arbitraries.of("Employee Onboarding", "Purchase Order",
                           "Leave Request", "Invoice Approval")
        );
    }

    @Provide
    Arbitrary<String> statuses() {
        return Arbitraries.of("running", "completed", "cancelled",
                              "aborted", "error", "initializing");
    }

    @Provide
    Arbitrary<Long> userIds() {
        return Arbitraries.longs().between(1L, 10000L);
    }

    @Provide
    Arbitrary<ProcessInstanceDTO> instances() {
        return Combinators.combine(
            positiveIds(),
            idStrings(),
            names(),
            statuses(),
            userIds()
        ).as((id, idStr, name, status, userId) ->
            ProcessInstanceDTO.builder()
                .persistenceId(id)
                .persistenceId_string(idStr)
                .processName(name)
                .processStatus(status)
                .startedByUserId(userId)
                .build());
    }
}
```
