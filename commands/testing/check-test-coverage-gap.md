# Check Test Coverage Gaps

Scan the project to find source classes missing test pairs and report a prioritized gap analysis.

## Arguments
- `$ARGUMENTS`: optional module path (e.g., `extensions/developerIntegrationRestAPI`) or `all` (default)

## Instructions

1. **Find all source files** under `src/main/java/` in the target module(s)
2. **For each source file**, check if the following exist under `src/test/java/` with the same package:
   - `*Test.java` — unit test
   - `*PropertyTest.java` — property-based test (jqwik)
3. **For controller classes** (files extending `RestApiController` or `Abstract*Controller`), also check:
   - Does the controller package have a `README.md`?
   - Are there integration-style tests covering `doHandle()`?
4. **Check JaCoCo reports** if available at `target/site/jacoco/index.html`:
   - Parse overall line/branch coverage percentages
   - Identify classes with coverage below 80%
5. **Generate a gap report** in this format:

```
## Test Coverage Gap Report

### Summary
- Total source classes: X
- Classes with unit tests: Y (Z%)
- Classes with property tests: W (V%)
- Controllers without README: N

### Critical Gaps (Controllers)
| Controller | Unit Test | Property Test | README | Integration Test |
|-----------|-----------|---------------|--------|-----------------|
| MyController | ❌ MISSING | ❌ MISSING | ✅ | ❌ MISSING |

### Missing Unit Tests
1. com.company.MyClass → create MyClassTest.java
2. com.company.dto.MyDTO → create MyDTOTest.java

### Missing Property Tests
1. com.company.dto.MyDTO → create MyDTOPropertyTest.java

### Recommended Priority
1. [HIGH] Controllers without any tests
2. [MEDIUM] DTOs/Records without property tests
3. [LOW] Utility classes without tests
```

6. **Suggest next steps**: which `/generate-tests` or `/generate-integration-tests` commands to run
