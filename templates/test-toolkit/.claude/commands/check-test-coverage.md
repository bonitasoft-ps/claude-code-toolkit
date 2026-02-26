# Check Test Coverage

Analyze which Bonita processes have integration test coverage and which are missing.

## Instructions

1. **Find all .bar files** in `src/test/resources/processes/`

2. **Find all IT test classes** in `src/test/java/`

3. **Cross-reference**:
   - For each .bar file, check if there's a corresponding `*IT.java` that deploys it
   - For each IT class, check if it references a .bar file that exists

4. **Report**:

   ```
   ## Process Test Coverage

   | Process (.bar file) | Test Class | Status |
   |---------------------|-----------|--------|
   | Process--1.0.bar    | ProcessIT | ✅ Covered |
   | OtherProcess.bar    | —         | ❌ Missing |

   ## Summary
   - X / Y processes have integration tests (Z% coverage)
   - Missing tests: [list]
   ```

5. **For missing tests**, offer to generate scaffolds using the test-scaffold-generator agent.
