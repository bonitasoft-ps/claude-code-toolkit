# Run Integration Tests

Run Bonita process integration tests using Maven Failsafe.

## Arguments
- `$ARGUMENTS`: Optional test class name (e.g., `PaymentRequestIT`), test method pattern, or empty for all tests

## Instructions

1. If `$ARGUMENTS` is empty, run all integration tests:
   ```bash
   mvn clean verify
   ```

2. If `$ARGUMENTS` specifies a class name, run that specific test:
   ```bash
   mvn verify -Dit.test=$ARGUMENTS
   ```

3. If `$ARGUMENTS` contains a method pattern (e.g., `PaymentRequestIT#should_complete*`), run matching methods:
   ```bash
   mvn verify -Dit.test=$ARGUMENTS
   ```

4. Show a summary of:
   - Tests run / passed / failed / skipped
   - Any failed test details with error messages
   - Total execution time

## Important Notes

- Integration tests (`*IT.java`) run via `maven-failsafe-plugin`
- Unit tests (`*Test.java`) run via `maven-surefire-plugin`
- Bonita Runtime must be accessible at the configured URL
- Use `-Dbonita.url=...` to override the Bonita URL
