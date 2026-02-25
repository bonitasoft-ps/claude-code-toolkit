# Check Test Coverage

Run tests with JaCoCo and verify against project thresholds.

## Instructions

1. Run: `mvn clean test jacoco:report -DfailIfNoTests=false`
2. Parse coverage report at `target/site/jacoco/`
3. Report per-class coverage vs project thresholds
4. List classes below threshold with uncovered lines
5. Suggest which test methods to add
