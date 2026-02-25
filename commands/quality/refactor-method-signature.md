# Refactor Method Signature

Safely refactor a method signature and update ALL call sites across the project.

## Arguments
- `$ARGUMENTS`: method name and description of change

## Instructions

1. **Find the method** definition across all source files
2. **Find ALL usages** in Java, Groovy, Kotlin files and embedded scripts in .proc files
3. **Present change plan**: current vs proposed signature, all affected files
4. **Ask confirmation** before modifying
5. **Apply changes**: definition first, then all call sites, then tests
6. **Verify**: `mvn clean compile`
7. **Report**: list of modified files
