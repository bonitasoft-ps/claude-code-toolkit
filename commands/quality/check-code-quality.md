# Check Code Quality

Analyze source files for code quality issues.

## Arguments
- `$ARGUMENTS`: file path, class name, or directory. Default: scan all source files.

## Instructions

Check the following for each file in scope:

### 1. Javadoc Coverage
- Public classes MUST have class-level Javadoc
- Public methods MUST have Javadoc with @param, @return, @throws

### 2. Method Length
- Methods MUST NOT exceed 25-30 lines of executable code
- Report methods exceeding limit with line count

### 3. Hardcoded Magic Strings
- String literals in comparisons/switch cases should be constants
- Exceptions: log messages, exception messages, test assertions

### 4. Code Smells
- Double semicolons `;;`
- Empty catch blocks
- Unused imports
- Raw types (List instead of List<Type>)
- System.out.println (should use Logger)

### 5. Pattern Compliance
- DTOs should use Lombok (@Data, @Builder)
- Services should use constructor injection
- Enums should implement meaningful toString()

### Report Format
```
## Code Quality Report
| Check              | Issues | Severity |
|-------------------|--------|----------|
| Javadoc            | N      | HIGH     |
| Method Length       | N      | HIGH     |
| Magic Strings      | N      | MEDIUM   |
| Code Smells        | N      | MEDIUM   |
```
