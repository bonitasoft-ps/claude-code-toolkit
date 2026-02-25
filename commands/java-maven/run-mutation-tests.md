# Run Mutation Tests (PIT)

Run PIT mutation testing to evaluate test quality.

## Arguments
- `$ARGUMENTS`: optional module path or target class pattern

## Instructions

1. Execute PIT:
   - **No argument**: `mvn org.pitest:pitest-maven:mutationCoverage`
   - **Module**: `mvn org.pitest:pitest-maven:mutationCoverage -f $ARGUMENTS/pom.xml`
   - **Class**: `mvn org.pitest:pitest-maven:mutationCoverage -DtargetClasses="**.$ARGUMENTS"`

2. Summary: mutation score (killed / survived / total)
3. List surviving mutants by class
4. HTML report at: `target/pit-reports/`
