# Compile Project

Compile the project using Maven.

## Arguments
- `$ARGUMENTS`: `compile` (default), `extensions`, `quick`

## Instructions

1. Determine scope:
   - **No argument or `compile`**: `mvn clean compile`
   - **`extensions`**: `mvn clean compile -f extensions/pom.xml` (if extensions module exists)
   - **`quick`**: `mvn clean compile -Dmaven.test.skip=true`

2. Report:
   - **Success**: confirm all modules compiled
   - **Failure**: show errors with file paths and line numbers, suggest fixes
   - **Lombok issues**: if "cannot access *Builder" errors, run `mvn clean compile -Dmaven.test.skip=true`
