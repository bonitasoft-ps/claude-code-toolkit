#!/usr/bin/env bash
# =============================================================================
# check-controller.sh
# Validates the structure of a Bonita REST API controller directory.
#
# Usage:
#   ./check-controller.sh <controller-directory-path>
#
# Example:
#   ./check-controller.sh extensions/processBuilderRestAPI/src/main/java/com/bonitasoft/processbuilder/rest/api/controller/processesAccessible
#
# Checks:
#   - Abstract*.java presence
#   - Concrete *.java (non-Abstract) presence
#   - README.md presence
#   - *Field.java (constants) presence
#   - Corresponding test files
#   - Corresponding DTO files (Param*, Result*)
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
WARN=0

# Print functions
pass() {
    echo -e "  ${GREEN}[PASS]${NC} $1"
    ((PASS++))
}

fail() {
    echo -e "  ${RED}[FAIL]${NC} $1"
    ((FAIL++))
}

warn() {
    echo -e "  ${YELLOW}[WARN]${NC} $1"
    ((WARN++))
}

info() {
    echo -e "  ${BLUE}[INFO]${NC} $1"
}

# =============================================================================
# Main
# =============================================================================

if [ $# -lt 1 ]; then
    echo "Usage: $0 <controller-directory-path>"
    echo ""
    echo "Example:"
    echo "  $0 extensions/processBuilderRestAPI/src/main/java/com/bonitasoft/processbuilder/rest/api/controller/processesAccessible"
    exit 1
fi

CONTROLLER_DIR="$1"

if [ ! -d "$CONTROLLER_DIR" ]; then
    echo -e "${RED}Error: Directory does not exist: ${CONTROLLER_DIR}${NC}"
    exit 1
fi

# Extract controller name from directory
CONTROLLER_NAME=$(basename "$CONTROLLER_DIR")
CONTROLLER_NAME_PASCAL=$(echo "$CONTROLLER_NAME" | sed -r 's/(^|_)(\w)/\U\2/g')

echo ""
echo "============================================="
echo " Controller Structure Validator"
echo " Directory: $CONTROLLER_DIR"
echo " Controller: $CONTROLLER_NAME"
echo "============================================="
echo ""

# -----------------------------------------------
# 1. Check Abstract class
# -----------------------------------------------
echo "--- Controller Files ---"

ABSTRACT_FILES=$(find "$CONTROLLER_DIR" -maxdepth 1 -name "Abstract*.java" 2>/dev/null | wc -l)
if [ "$ABSTRACT_FILES" -gt 0 ]; then
    ABSTRACT_FILE=$(find "$CONTROLLER_DIR" -maxdepth 1 -name "Abstract*.java" -print -quit)
    pass "Abstract class found: $(basename "$ABSTRACT_FILE")"
else
    fail "No Abstract*.java found in controller directory"
fi

# -----------------------------------------------
# 2. Check Concrete class (non-Abstract *.java)
# -----------------------------------------------
CONCRETE_FILES=$(find "$CONTROLLER_DIR" -maxdepth 1 -name "*.java" ! -name "Abstract*" ! -name "*Field*" ! -name "*Test*" 2>/dev/null | wc -l)
if [ "$CONCRETE_FILES" -gt 0 ]; then
    CONCRETE_FILE=$(find "$CONTROLLER_DIR" -maxdepth 1 -name "*.java" ! -name "Abstract*" ! -name "*Field*" ! -name "*Test*" -print -quit)
    pass "Concrete class found: $(basename "$CONCRETE_FILE")"
else
    fail "No concrete controller class (non-Abstract *.java) found"
fi

# -----------------------------------------------
# 3. Check README.md
# -----------------------------------------------
if [ -f "$CONTROLLER_DIR/README.md" ]; then
    # Check README has content (more than 10 lines)
    README_LINES=$(wc -l < "$CONTROLLER_DIR/README.md")
    if [ "$README_LINES" -gt 10 ]; then
        pass "README.md found ($README_LINES lines)"
    else
        warn "README.md exists but is very short ($README_LINES lines) - may be incomplete"
    fi

    # Check for required sections
    REQUIRED_SECTIONS=("Overview" "Architecture" "Endpoint" "Request Parameters" "Response Format" "Use Cases" "Business Logic" "Error Handling" "Key Classes" "Dependencies" "Testing")
    MISSING_SECTIONS=()
    for section in "${REQUIRED_SECTIONS[@]}"; do
        if ! grep -qi "$section" "$CONTROLLER_DIR/README.md" 2>/dev/null; then
            MISSING_SECTIONS+=("$section")
        fi
    done

    if [ ${#MISSING_SECTIONS[@]} -eq 0 ]; then
        pass "README.md contains all 11 required sections"
    else
        warn "README.md missing sections: ${MISSING_SECTIONS[*]}"
    fi
else
    fail "README.md not found in controller directory"
fi

# -----------------------------------------------
# 4. Check Field class (constants)
# -----------------------------------------------
FIELD_FILES=$(find "$CONTROLLER_DIR" -maxdepth 1 -name "*Field*.java" 2>/dev/null | wc -l)
if [ "$FIELD_FILES" -gt 0 ]; then
    FIELD_FILE=$(find "$CONTROLLER_DIR" -maxdepth 1 -name "*Field*.java" -print -quit)
    pass "Field constants class found: $(basename "$FIELD_FILE")"
else
    warn "No *Field*.java (constants class) found - OK if no filtering/ordering"
fi

echo ""
echo "--- DTO Files ---"

# -----------------------------------------------
# 5. Check DTO files
# -----------------------------------------------
# Try to find the project root (look for pom.xml going up)
PROJECT_ROOT="$CONTROLLER_DIR"
while [ "$PROJECT_ROOT" != "/" ] && [ ! -f "$PROJECT_ROOT/pom.xml" ]; do
    PROJECT_ROOT=$(dirname "$PROJECT_ROOT")
done

if [ -f "$PROJECT_ROOT/pom.xml" ]; then
    DTO_BASE=$(find "$PROJECT_ROOT/src/main/java" -type d -name "dto" 2>/dev/null | head -1)

    if [ -n "$DTO_BASE" ]; then
        # Check Parameter DTO
        PARAM_FILES=$(find "$DTO_BASE/parameter" -name "Param*${CONTROLLER_NAME_PASCAL}*" -o -name "*${CONTROLLER_NAME_PASCAL}*Param*" 2>/dev/null | wc -l)
        if [ "$PARAM_FILES" -gt 0 ]; then
            PARAM_FILE=$(find "$DTO_BASE/parameter" -name "Param*" 2>/dev/null | grep -i "$CONTROLLER_NAME" | head -1)
            pass "Parameter DTO found: $(basename "$PARAM_FILE" 2>/dev/null || echo "found")"
        else
            # Try a broader search
            PARAM_BROAD=$(find "$DTO_BASE/parameter" -name "*.java" 2>/dev/null | wc -l)
            if [ "$PARAM_BROAD" -gt 0 ]; then
                warn "No Param*${CONTROLLER_NAME_PASCAL}*.java found - check naming convention"
            else
                fail "No parameter DTOs found in dto/parameter/"
            fi
        fi

        # Check Result DTO
        RESULT_FILES=$(find "$DTO_BASE/result" -name "Result*${CONTROLLER_NAME_PASCAL}*" -o -name "*${CONTROLLER_NAME_PASCAL}*Result*" 2>/dev/null | wc -l)
        if [ "$RESULT_FILES" -gt 0 ]; then
            RESULT_FILE=$(find "$DTO_BASE/result" -name "Result*" 2>/dev/null | grep -i "$CONTROLLER_NAME" | head -1)
            pass "Result DTO found: $(basename "$RESULT_FILE" 2>/dev/null || echo "found")"
        else
            RESULT_BROAD=$(find "$DTO_BASE/result" -name "*.java" 2>/dev/null | wc -l)
            if [ "$RESULT_BROAD" -gt 0 ]; then
                warn "No Result*${CONTROLLER_NAME_PASCAL}*.java found - check naming convention"
            else
                fail "No result DTOs found in dto/result/"
            fi
        fi
    else
        warn "Could not locate dto/ directory"
    fi
else
    warn "Could not find project root (pom.xml) - skipping DTO checks"
fi

echo ""
echo "--- Test Files ---"

# -----------------------------------------------
# 6. Check Test files
# -----------------------------------------------
if [ -f "$PROJECT_ROOT/pom.xml" ]; then
    TEST_BASE=$(echo "$CONTROLLER_DIR" | sed 's|/main/|/test/|')

    if [ -d "$TEST_BASE" ]; then
        # Check for Abstract test
        ABSTRACT_TESTS=$(find "$TEST_BASE" -maxdepth 1 -name "Abstract*Test.java" 2>/dev/null | wc -l)
        if [ "$ABSTRACT_TESTS" -gt 0 ]; then
            pass "Abstract test class found"
        else
            fail "No Abstract*Test.java found in test directory"
        fi

        # Check for Concrete test
        CONCRETE_TESTS=$(find "$TEST_BASE" -maxdepth 1 -name "*Test.java" ! -name "Abstract*" ! -name "*PropertyTest*" 2>/dev/null | wc -l)
        if [ "$CONCRETE_TESTS" -gt 0 ]; then
            pass "Concrete test class(es) found ($CONCRETE_TESTS files)"
        else
            fail "No concrete test class (*Test.java) found"
        fi

        # Check for Property tests (optional)
        PROPERTY_TESTS=$(find "$TEST_BASE" -maxdepth 1 -name "*PropertyTest.java" 2>/dev/null | wc -l)
        if [ "$PROPERTY_TESTS" -gt 0 ]; then
            pass "Property-based test class found"
        else
            warn "No *PropertyTest.java found - consider adding jqwik property tests"
        fi
    else
        fail "Test directory not found: $TEST_BASE"
    fi
else
    warn "Could not determine test directory - skipping test checks"
fi

echo ""
echo "--- Code Quality Checks ---"

# -----------------------------------------------
# 7. Check for Javadoc on public methods
# -----------------------------------------------
if [ "$ABSTRACT_FILES" -gt 0 ]; then
    ABSTRACT_FILE=$(find "$CONTROLLER_DIR" -maxdepth 1 -name "Abstract*.java" -print -quit)
    PUBLIC_METHODS=$(grep -c "public " "$ABSTRACT_FILE" 2>/dev/null || echo 0)
    JAVADOC_BLOCKS=$(grep -c "/\*\*" "$ABSTRACT_FILE" 2>/dev/null || echo 0)
    if [ "$JAVADOC_BLOCKS" -ge "$PUBLIC_METHODS" ] 2>/dev/null; then
        pass "Javadoc blocks ($JAVADOC_BLOCKS) >= public members ($PUBLIC_METHODS)"
    else
        warn "Javadoc blocks ($JAVADOC_BLOCKS) < public members ($PUBLIC_METHODS) - may need more docs"
    fi
fi

# -----------------------------------------------
# 8. Check for OpenAPI annotations
# -----------------------------------------------
if [ "$ABSTRACT_FILES" -gt 0 ]; then
    ABSTRACT_FILE=$(find "$CONTROLLER_DIR" -maxdepth 1 -name "Abstract*.java" -print -quit)
    if grep -q "@Operation" "$ABSTRACT_FILE" 2>/dev/null; then
        pass "OpenAPI @Operation annotation found"
    else
        fail "No @Operation annotation found in abstract class"
    fi

    if grep -q "@ApiResponse" "$ABSTRACT_FILE" 2>/dev/null; then
        pass "OpenAPI @ApiResponse annotations found"
    else
        fail "No @ApiResponse annotations found in abstract class"
    fi
fi

# -----------------------------------------------
# 9. Check for LicenseValidator usage
# -----------------------------------------------
if [ "$ABSTRACT_FILES" -gt 0 ]; then
    ABSTRACT_FILE=$(find "$CONTROLLER_DIR" -maxdepth 1 -name "Abstract*.java" -print -quit)
    if grep -q "LicenseValidator" "$ABSTRACT_FILE" 2>/dev/null; then
        pass "LicenseValidator usage found in abstract class"
    else
        fail "No LicenseValidator usage found - license check is MANDATORY"
    fi
fi

# -----------------------------------------------
# 10. Check for magic strings
# -----------------------------------------------
if [ "$CONCRETE_FILES" -gt 0 ]; then
    CONCRETE_FILE=$(find "$CONTROLLER_DIR" -maxdepth 1 -name "*.java" ! -name "Abstract*" ! -name "*Field*" ! -name "*Test*" -print -quit)
    # Look for hardcoded strings in method bodies (rough check)
    HARDCODED=$(grep -n '"[A-Za-z].*"' "$CONCRETE_FILE" 2>/dev/null | grep -v "private static final" | grep -v "Logger" | grep -v "import" | grep -v "//" | grep -v "format(" | grep -v "@" | wc -l)
    if [ "$HARDCODED" -le 2 ]; then
        pass "Few or no hardcoded strings detected"
    else
        warn "Possible hardcoded strings detected ($HARDCODED occurrences) - consider using constants"
    fi
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "============================================="
echo " Summary"
echo "============================================="
echo -e "  ${GREEN}PASS: $PASS${NC}"
echo -e "  ${RED}FAIL: $FAIL${NC}"
echo -e "  ${YELLOW}WARN: $WARN${NC}"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}Controller structure is valid!${NC}"
    exit 0
else
    echo -e "${RED}Controller has $FAIL issue(s) that must be fixed.${NC}"
    exit 1
fi
