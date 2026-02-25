# Create Constants from Hardcoded Strings

Detect hardcoded magic strings and extract to appropriate constants classes.

## Arguments
- `$ARGUMENTS`: file path, class name, or `all`

## Instructions

1. **Scan** for string literals in comparisons, switch cases, and assignments
2. **Check existing constants** - avoid duplicates
3. **Decide placement**:
   - Status/state values → check enums first, then constants
   - Error message templates → ErrorMessages class
   - Log messages → Messages class
   - Parameter names → Parameters class
   - Cross-project values → shared library
4. **Create/update** constants with UPPER_SNAKE_CASE and Javadoc
5. **Replace** all usages
6. **Compile** to verify
