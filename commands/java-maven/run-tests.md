# Run Tests

Run project tests with Maven.

## Arguments
- `$ARGUMENTS`: `unit` (default), `integration`, `property`, `mutation`, `all`, or a specific class name

## Instructions

1. Determine scope:
   - **`unit`**: `mvn clean test`
   - **`integration`**: `mvn clean test -Dtest.type=integration`
   - **`property`**: `mvn clean test -Dtest="*PropertyTest,*Props*"`
   - **`mutation`**: `mvn org.pitest:pitest-maven:mutationCoverage`
   - **`all`**: `mvn clean test -DfailIfNoTests=false`
   - **Class name**: `mvn clean test -Dtest=$ARGUMENTS`

2. Summary: tests run / passed / failed / skipped
3. If failures: show test names and brief error messages
4. For mutation: show mutation score
