---
name: test-scaffold-generator
description: "Delegate to this agent to generate integration test scaffolds for Bonita .bar process files. It creates IT classes with proper structure, deploys the process, and generates test methods for expected flows."
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
color: green
skills: bonita-test-toolkit-expert
---

## Task

Generate complete integration test scaffolds for Bonita process .bar files.

## Procedure

### Phase 1: Discover

1. List all `.bar` files in `src/test/resources/processes/`
2. List all existing `*IT.java` files
3. Identify processes without test coverage

### Phase 2: Analyze

For each process that needs a test:
1. Determine the process name from the .bar filename (format: `ProcessName--version.bar`)
2. Check if `AbstractProcessTest` exists and review its API
3. Review existing test classes for project-specific conventions

### Phase 3: Generate

For each new test class, create a file following this pattern:

```java
package [project.package].tests;

import [project.package].tests.AbstractProcessTest;
import com.bonitasoft.test.toolkit.model.ProcessDefinition;
import com.bonitasoft.test.toolkit.model.ProcessInstance;
import org.junit.jupiter.api.*;

import static com.bonitasoft.test.toolkit.assertion.ProcessInstanceAssert.assertThat;

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@DisplayName("[ProcessName] Integration Tests")
public class [ProcessName]IT extends AbstractProcessTest {

    private ProcessDefinition process;

    @BeforeAll
    void setUpProcess() {
        process = deployProcess("[ProcessName--version.bar]");
    }

    @Test
    @DisplayName("Process should complete with valid input")
    void should_complete_when_input_is_valid() {
        // ARRANGE
        // TODO: Set up test data

        // ACT
        ProcessInstance instance = client.start(process)
            .execute();

        // ASSERT
        assertThat(instance).isCompleted();
    }

    @Test
    @DisplayName("Process should fail gracefully with invalid input")
    void should_handle_error_when_input_is_invalid() {
        // TODO: Implement error scenario
    }
}
```

### Phase 4: Verify

1. Run `mvn test-compile` to verify all generated tests compile
2. Fix any compilation errors
3. Report results

## Output Format

```
## Test Scaffold Report

### Created
- ProcessNameIT.java — X test methods

### Existing (skipped)
- ExistingProcessIT.java — already has coverage

### Compilation
✅ All tests compile / ❌ Errors found: [details]
```
