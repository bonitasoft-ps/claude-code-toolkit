# Audit Project Compliance

Run a comprehensive compliance audit against project standards. Enhanced version with security checks, connector validation, and scoring.

## Arguments
- `$ARGUMENTS`: scope - `extensions`, `bdm`, `connectors`, `security`, `all` (default: `all`)

## Instructions

### 1. Test Coverage
- For each source `.java` file, verify a `*Test.java` exists
- List files WITHOUT test counterparts
- Check test naming convention: `should_do_X_when_condition_Y`
- Verify AssertJ usage (not native JUnit assertions)

### 2. Documentation
- Check all controller/service directories have README.md (if applicable)
- Check public methods have Javadoc with @param, @return, @throws
- Check class-level Javadoc exists on all public classes

### 3. BDM Compliance (if bom.xml exists)
- Collection queries (java.util.List) must have countFor queries
- All elements must have description tags
- Indexes exist for all WHERE/ORDER BY fields
- Business objects follow PB prefix naming convention

### 4. Code Quality
- Method length <= 30 lines
- No hardcoded magic strings (use constants)
- No double semicolons
- No System.out.println (use Logger)
- No unused imports
- Constructor injection preferred over field injection

### 5. Security
- No credentials in source code (passwords, API keys, tokens)
- No SQL injection vulnerabilities (string concatenation in queries)
- Input validation on all controller endpoints
- Proper error handling (no stack traces in responses)

### 6. Connector Compliance (if connectors exist)
- All 4 lifecycle methods present: validate, connect, execute, disconnect
- Configuration class uses @Data @Builder
- Exception hierarchy extends ConnectorException
- Credentials use Password widget type

### Report
```
## Compliance Audit Report

| Category           | Status    | Issues | Score  |
|-------------------|-----------|--------|--------|
| Test Coverage      | PASS/FAIL | N      | X/100  |
| Documentation      | PASS/FAIL | N      | X/100  |
| BDM Queries        | PASS/FAIL | N      | X/100  |
| Code Quality       | PASS/FAIL | N      | X/100  |
| Security           | PASS/FAIL | N      | X/100  |
| Connectors         | PASS/FAIL | N      | X/100  |

**Overall Score: X/100**
**Grade: A/B/C/D/F** (A=90+, B=80+, C=70+, D=60+, F=<60)
```

### Remediation Priority
List the top 5 issues to fix first, ordered by:
1. CRITICAL security issues
2. HIGH code quality issues
3. MEDIUM documentation gaps
4. LOW style issues
