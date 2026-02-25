# Generate Tests for a Class

Generate comprehensive tests for a Java/Groovy/Kotlin class.

## Arguments
- `$ARGUMENTS`: class name or file path

## Instructions

1. **Find and read** the source class
2. **Read existing test patterns** in the project for conventions
3. **Generate Unit Tests** (JUnit 5 + Mockito + AssertJ):
   - `@ExtendWith(MockitoExtension.class)` if needed
   - `@DisplayName` annotations
   - `should_do_X_when_condition_Y` naming
   - AssertJ assertions only
   - Cover: happy path, edge cases, null handling, errors
4. **Generate Property Tests** (jqwik, if project uses it):
   - `@Property` and `@ForAll` annotations
   - Test invariants, consistency, idempotency
5. **Place tests** in mirror directory under `src/test/java/`
6. **Run tests** to verify they pass
