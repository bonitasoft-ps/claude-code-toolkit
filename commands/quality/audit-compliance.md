# Audit Project Compliance

Run a full compliance audit against project standards.

## Arguments
- `$ARGUMENTS`: scope - `extensions`, `bdm`, `all` (default: `all`)

## Instructions

### 1. Test Coverage
- For each source `.java` file, verify a `*Test.java` exists
- List files WITHOUT test counterparts

### 2. Documentation
- Check all controller/service directories have README.md (if applicable)
- Check public methods have Javadoc

### 3. BDM Compliance (if bom.xml exists)
- Collection queries (java.util.List) must have countFor queries
- All elements must have description tags

### 4. Code Quality
- Method length <= 30 lines
- No hardcoded magic strings
- No double semicolons

### Report
```
## Compliance Audit Report
| Category           | Status | Issues |
|-------------------|--------|--------|
| Test Coverage      | PASS/FAIL | N     |
| Documentation      | PASS/FAIL | N     |
| BDM Queries        | PASS/FAIL | N     |
| Code Quality       | PASS/FAIL | N     |
```
