# Deploy and Test

Deploy a Bonita process .bar file and run its integration tests.

## Arguments
- `$ARGUMENTS`: The .bar file name (e.g., `PaymentRequest--1.0.bar`) or process name

## Instructions

1. **Find the .bar file** in `src/test/resources/processes/`:
   - Search for `$ARGUMENTS` in the processes directory
   - If not found, list available .bar files and ask

2. **Find the corresponding test class**:
   - Search for `*IT.java` files that reference this process
   - If no test exists, offer to create one using the test scaffold pattern

3. **Run the specific test**:
   ```bash
   mvn verify -Dit.test=<TestClassName>
   ```

4. **Report results**:
   - Deployment success/failure
   - Test execution results
   - Any errors with suggested fixes
