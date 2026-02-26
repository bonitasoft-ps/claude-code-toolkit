#!/bin/bash
# =============================================================================
# validate-bdm.sh - BDM Compliance Checker for Bonita Business Data Model
# =============================================================================
# Checks bom.xml for compliance with Bonita BDM best practices:
#   - Missing <description> tags
#   - List-returning queries without countFor counterparts
#   - Missing indexes for query WHERE attributes
#   - Missing mandatory audit fields
#   - Naming conventions (PB prefix, camelCase)
#
# Usage: bash scripts/validate-bdm.sh [path/to/bom.xml]
# Default: bdm/bom.xml
#
# Exit code: Always 0 (informational report)
# =============================================================================

BOM_FILE="${1:-bdm/bom.xml}"

# Colors for output (disable if not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    GREEN='\033[0;32m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    YELLOW=''
    GREEN=''
    CYAN=''
    BOLD=''
    NC=''
fi

# Counters
ERRORS=0
WARNINGS=0
PASS=0

echo ""
echo -e "${BOLD}=========================================${NC}"
echo -e "${BOLD}  BDM Compliance Report${NC}"
echo -e "${BOLD}=========================================${NC}"
echo -e "  File: ${CYAN}${BOM_FILE}${NC}"
echo -e "  Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${BOLD}=========================================${NC}"
echo ""

# Check if file exists
if [ ! -f "$BOM_FILE" ]; then
    echo -e "${RED}[ERROR] File not found: ${BOM_FILE}${NC}"
    echo "  Ensure the BDM file exists at the specified path."
    echo "  Usage: bash scripts/validate-bdm.sh [path/to/bom.xml]"
    exit 0
fi

# =============================================================================
# 1. CHECK MISSING DESCRIPTIONS
# =============================================================================
echo -e "${BOLD}--- 1. Description Tags ---${NC}"
echo ""

# Check businessObject descriptions
OBJECTS_WITHOUT_DESC=0
while IFS= read -r line; do
    # Extract object name
    obj_name=$(echo "$line" | sed -n 's/.*qualifiedName="\([^"]*\)".*/\1/p')
    if [ -z "$obj_name" ]; then
        continue
    fi

    # Check if next non-empty line contains a description with content
    # We look for <description> immediately following the businessObject tag
    # This is a simplified check - we look for empty descriptions
    short_name=$(echo "$obj_name" | sed 's/.*\.//')

    # Count empty or missing descriptions for this object
    # Using grep to find the pattern of businessObject followed by empty description
    if grep -Pzo "qualifiedName=\"${obj_name}\"[^>]*>\s*\n\s*<description>\s*</description>" "$BOM_FILE" > /dev/null 2>&1; then
        echo -e "  ${RED}[FAIL]${NC} Business object '${short_name}' has empty <description>"
        OBJECTS_WITHOUT_DESC=$((OBJECTS_WITHOUT_DESC + 1))
        ERRORS=$((ERRORS + 1))
    elif grep -Pzo "qualifiedName=\"${obj_name}\"[^>]*>\s*\n\s*<description/>" "$BOM_FILE" > /dev/null 2>&1; then
        echo -e "  ${RED}[FAIL]${NC} Business object '${short_name}' has empty <description/>"
        OBJECTS_WITHOUT_DESC=$((OBJECTS_WITHOUT_DESC + 1))
        ERRORS=$((ERRORS + 1))
    fi
done < <(grep 'qualifiedName=' "$BOM_FILE")

# Check field descriptions (empty <description></description> or <description/>)
FIELDS_WITHOUT_DESC=0
while IFS= read -r line; do
    field_name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
    if [ -n "$field_name" ]; then
        FIELDS_WITHOUT_DESC=$((FIELDS_WITHOUT_DESC + 1))
    fi
done < <(grep -B1 '<description>\s*</description>\|<description/>' "$BOM_FILE" | grep '<field\|<relationField')

if [ "$FIELDS_WITHOUT_DESC" -gt 0 ]; then
    echo -e "  ${RED}[FAIL]${NC} ${FIELDS_WITHOUT_DESC} field(s) with empty <description>"
    ERRORS=$((ERRORS + FIELDS_WITHOUT_DESC))
else
    echo -e "  ${GREEN}[PASS]${NC} All fields have descriptions"
    PASS=$((PASS + 1))
fi

# Check query descriptions
QUERIES_WITHOUT_DESC=0
while IFS= read -r line; do
    q_name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
    if [ -n "$q_name" ]; then
        echo -e "  ${RED}[FAIL]${NC} Query '${q_name}' has empty <description>"
        QUERIES_WITHOUT_DESC=$((QUERIES_WITHOUT_DESC + 1))
        ERRORS=$((ERRORS + 1))
    fi
done < <(grep -A2 '<query ' "$BOM_FILE" | grep -B1 '<description>\s*</description>\|<description/>' | grep '<query ')

if [ "$QUERIES_WITHOUT_DESC" -eq 0 ]; then
    echo -e "  ${GREEN}[PASS]${NC} All queries have descriptions"
    PASS=$((PASS + 1))
fi

# Check index descriptions
INDEXES_WITHOUT_DESC=0
while IFS= read -r line; do
    idx_name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
    # Check if description attribute is empty or missing
    idx_desc=$(echo "$line" | sed -n 's/.*description="\([^"]*\)".*/\1/p')
    if [ -z "$idx_desc" ]; then
        echo -e "  ${RED}[FAIL]${NC} Index '${idx_name}' has empty or missing description"
        INDEXES_WITHOUT_DESC=$((INDEXES_WITHOUT_DESC + 1))
        ERRORS=$((ERRORS + 1))
    fi
done < <(grep '<index ' "$BOM_FILE")

if [ "$INDEXES_WITHOUT_DESC" -eq 0 ]; then
    echo -e "  ${GREEN}[PASS]${NC} All indexes have descriptions"
    PASS=$((PASS + 1))
fi

# Check uniqueConstraint descriptions
UC_WITHOUT_DESC=0
while IFS= read -r line; do
    uc_name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
    uc_desc=$(echo "$line" | sed -n 's/.*description="\([^"]*\)".*/\1/p')
    if [ -z "$uc_desc" ]; then
        echo -e "  ${RED}[FAIL]${NC} Unique constraint '${uc_name}' has empty or missing description"
        UC_WITHOUT_DESC=$((UC_WITHOUT_DESC + 1))
        ERRORS=$((ERRORS + 1))
    fi
done < <(grep '<uniqueConstraint ' "$BOM_FILE")

if [ "$UC_WITHOUT_DESC" -eq 0 ]; then
    echo -e "  ${GREEN}[PASS]${NC} All unique constraints have descriptions"
    PASS=$((PASS + 1))
fi

echo ""

# =============================================================================
# 2. CHECK COUNTFOR QUERIES
# =============================================================================
echo -e "${BOLD}--- 2. CountFor Queries (99% Rule) ---${NC}"
echo ""

MISSING_COUNTFOR=0

# Find all queries returning java.util.List
while IFS= read -r line; do
    query_name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')

    # Skip countFor queries themselves
    if echo "$query_name" | grep -q "^countFor"; then
        continue
    fi

    # Skip if already a count/aggregate query
    if echo "$query_name" | grep -qi "^count"; then
        continue
    fi

    # Check if returnType is java.util.List
    if echo "$line" | grep -q 'returnType="java.util.List"'; then
        # Look for corresponding countFor query
        expected_countfor="countFor$(echo "$query_name" | sed 's/^./\U&/')"
        # Also check with original case
        expected_countfor2="countFor${query_name}"

        if ! grep -q "name=\"${expected_countfor}\"" "$BOM_FILE" && ! grep -q "name=\"${expected_countfor2}\"" "$BOM_FILE"; then
            echo -e "  ${RED}[FAIL]${NC} Query '${query_name}' returns List but has no countFor counterpart"
            echo -e "         Expected: '${expected_countfor2}'"
            MISSING_COUNTFOR=$((MISSING_COUNTFOR + 1))
            ERRORS=$((ERRORS + 1))
        fi
    fi
done < <(grep '<query ' "$BOM_FILE")

if [ "$MISSING_COUNTFOR" -eq 0 ]; then
    echo -e "  ${GREEN}[PASS]${NC} All List-returning queries have countFor counterparts"
    PASS=$((PASS + 1))
fi

echo ""

# =============================================================================
# 3. CHECK INDEXES FOR QUERY WHERE ATTRIBUTES
# =============================================================================
echo -e "${BOLD}--- 3. Index Coverage for Query Attributes ---${NC}"
echo ""

# Collect all indexed fields
INDEXED_FIELDS=""
while IFS= read -r line; do
    field=$(echo "$line" | sed -n 's/.*<fieldPath>\(.*\)<\/fieldPath>.*/\1/p')
    if [ -n "$field" ]; then
        INDEXED_FIELDS="${INDEXED_FIELDS} ${field}"
    fi
done < <(grep '<fieldPath>' "$BOM_FILE")

# Check query WHERE clauses for unindexed fields
MISSING_INDEXES=0
while IFS= read -r line; do
    query_name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
    query_content=$(echo "$line" | sed -n 's/.*content="\([^"]*\)".*/\1/p')

    if [ -z "$query_content" ]; then
        continue
    fi

    # Extract field references from WHERE clause (pattern: p.fieldName or t.fieldName etc)
    where_clause=$(echo "$query_content" | sed -n 's/.*WHERE \(.*\)/\1/p' | sed 's/ORDER BY.*//')

    if [ -z "$where_clause" ]; then
        continue
    fi

    # Extract field names (pattern: alias.fieldName)
    where_fields=$(echo "$where_clause" | grep -oP '\w+\.(\w+)' | sed 's/.*\.//' | sort -u)

    for field in $where_fields; do
        # Skip parameters (start with :)
        if echo "$field" | grep -q "^:"; then
            continue
        fi

        # Skip common JPQL keywords
        if echo "$field" | grep -qiE "^(persistenceId|persistenceVersion)$"; then
            continue
        fi

        # Check if field has an index
        if ! echo "$INDEXED_FIELDS" | grep -qw "$field"; then
            echo -e "  ${YELLOW}[WARN]${NC} Field '${field}' used in WHERE of '${query_name}' may not have an index"
            MISSING_INDEXES=$((MISSING_INDEXES + 1))
            WARNINGS=$((WARNINGS + 1))
        fi
    done
done < <(grep '<query ' "$BOM_FILE")

if [ "$MISSING_INDEXES" -eq 0 ]; then
    echo -e "  ${GREEN}[PASS]${NC} All WHERE clause attributes appear to have indexes"
    PASS=$((PASS + 1))
fi

echo ""

# =============================================================================
# 4. CHECK MANDATORY AUDIT FIELDS
# =============================================================================
echo -e "${BOLD}--- 4. Mandatory Audit Fields ---${NC}"
echo ""

AUDIT_FIELDS=("processInstanceId" "creationDate" "creationUser" "modificationDate" "modificationUser")
MISSING_AUDIT=0

# Get all business object names
while IFS= read -r line; do
    obj_qualified=$(echo "$line" | sed -n 's/.*qualifiedName="\([^"]*\)".*/\1/p')
    obj_short=$(echo "$obj_qualified" | sed 's/.*\.//')

    if [ -z "$obj_short" ]; then
        continue
    fi

    # Extract the block for this business object (simplified: check if fields exist anywhere after the object declaration)
    obj_section=$(sed -n "/qualifiedName=\"${obj_qualified}\"/,/<\/businessObject>/p" "$BOM_FILE" 2>/dev/null)

    if [ -z "$obj_section" ]; then
        continue
    fi

    missing_for_obj=""
    for audit_field in "${AUDIT_FIELDS[@]}"; do
        if ! echo "$obj_section" | grep -q "name=\"${audit_field}\""; then
            # Special case: check for auCreationDate as alternative to creationDate
            if [ "$audit_field" = "creationDate" ] && echo "$obj_section" | grep -q "name=\"auCreationDate\""; then
                continue
            fi
            missing_for_obj="${missing_for_obj} ${audit_field}"
        fi
    done

    if [ -n "$missing_for_obj" ]; then
        echo -e "  ${YELLOW}[WARN]${NC} Object '${obj_short}' is missing audit fields:${missing_for_obj}"
        MISSING_AUDIT=$((MISSING_AUDIT + 1))
        WARNINGS=$((WARNINGS + 1))
    fi
done < <(grep 'qualifiedName=' "$BOM_FILE" | grep '<businessObject')

if [ "$MISSING_AUDIT" -eq 0 ]; then
    echo -e "  ${GREEN}[PASS]${NC} All business objects have mandatory audit fields"
    PASS=$((PASS + 1))
fi

echo ""

# =============================================================================
# 5. CHECK NAMING CONVENTIONS
# =============================================================================
echo -e "${BOLD}--- 5. Naming Conventions ---${NC}"
echo ""

# Check PB prefix on business objects
MISSING_PREFIX=0
while IFS= read -r line; do
    obj_qualified=$(echo "$line" | sed -n 's/.*qualifiedName="\([^"]*\)".*/\1/p')
    obj_short=$(echo "$obj_qualified" | sed 's/.*\.//')

    if [ -z "$obj_short" ]; then
        continue
    fi

    if ! echo "$obj_short" | grep -q "^PB"; then
        echo -e "  ${RED}[FAIL]${NC} Object '${obj_short}' does not use the PB prefix"
        MISSING_PREFIX=$((MISSING_PREFIX + 1))
        ERRORS=$((ERRORS + 1))
    fi
done < <(grep 'qualifiedName=' "$BOM_FILE" | grep '<businessObject')

if [ "$MISSING_PREFIX" -eq 0 ]; then
    echo -e "  ${GREEN}[PASS]${NC} All business objects use PB prefix"
    PASS=$((PASS + 1))
fi

# Check camelCase on fields (first letter should be lowercase)
BAD_CASE=0
while IFS= read -r line; do
    field_name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')

    if [ -z "$field_name" ]; then
        continue
    fi

    # Check if first character is uppercase (bad for camelCase)
    first_char=$(echo "$field_name" | cut -c1)
    if echo "$first_char" | grep -q '[A-Z]'; then
        echo -e "  ${YELLOW}[WARN]${NC} Field '${field_name}' does not start with lowercase (camelCase violation)"
        BAD_CASE=$((BAD_CASE + 1))
        WARNINGS=$((WARNINGS + 1))
    fi
done < <(grep '<field ' "$BOM_FILE")

if [ "$BAD_CASE" -eq 0 ]; then
    echo -e "  ${GREEN}[PASS]${NC} All field names follow camelCase convention"
    PASS=$((PASS + 1))
fi

# Check for reserved keywords
RESERVED_KEYWORDS=("\"type\"" "\"status\"" "\"order\"" "\"group\"" "\"key\"" "\"value\"")
RESERVED_FOUND=0
for keyword in "${RESERVED_KEYWORDS[@]}"; do
    clean_keyword=$(echo "$keyword" | tr -d '"')
    if grep '<field ' "$BOM_FILE" | grep -q "name=${keyword}"; then
        echo -e "  ${RED}[FAIL]${NC} Field uses SQL reserved keyword: '${clean_keyword}'"
        RESERVED_FOUND=$((RESERVED_FOUND + 1))
        ERRORS=$((ERRORS + 1))
    fi
done

if [ "$RESERVED_FOUND" -eq 0 ]; then
    echo -e "  ${GREEN}[PASS]${NC} No SQL reserved keywords used as field names"
    PASS=$((PASS + 1))
fi

# Check index name length (max 20 chars)
LONG_INDEX_NAMES=0
while IFS= read -r line; do
    idx_name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
    if [ -n "$idx_name" ] && [ ${#idx_name} -gt 20 ]; then
        echo -e "  ${RED}[FAIL]${NC} Index name '${idx_name}' exceeds 20 characters (${#idx_name} chars)"
        LONG_INDEX_NAMES=$((LONG_INDEX_NAMES + 1))
        ERRORS=$((ERRORS + 1))
    fi
done < <(grep '<index ' "$BOM_FILE")

if [ "$LONG_INDEX_NAMES" -eq 0 ]; then
    echo -e "  ${GREEN}[PASS]${NC} All index names are within 20 character limit"
    PASS=$((PASS + 1))
fi

# Check unique constraint name length (max 20 chars)
LONG_UC_NAMES=0
while IFS= read -r line; do
    uc_name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
    if [ -n "$uc_name" ] && [ ${#uc_name} -gt 20 ]; then
        echo -e "  ${RED}[FAIL]${NC} Unique constraint name '${uc_name}' exceeds 20 characters (${#uc_name} chars)"
        LONG_UC_NAMES=$((LONG_UC_NAMES + 1))
        ERRORS=$((ERRORS + 1))
    fi
done < <(grep '<uniqueConstraint ' "$BOM_FILE")

if [ "$LONG_UC_NAMES" -eq 0 ]; then
    echo -e "  ${GREEN}[PASS]${NC} All unique constraint names are within 20 character limit"
    PASS=$((PASS + 1))
fi

echo ""

# =============================================================================
# 6. SUMMARY
# =============================================================================
echo -e "${BOLD}=========================================${NC}"
echo -e "${BOLD}  Summary${NC}"
echo -e "${BOLD}=========================================${NC}"
echo -e "  ${GREEN}Passed:   ${PASS}${NC}"
echo -e "  ${YELLOW}Warnings: ${WARNINGS}${NC}"
echo -e "  ${RED}Errors:   ${ERRORS}${NC}"
echo -e "${BOLD}=========================================${NC}"
echo ""

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}BDM is fully compliant!${NC}"
elif [ "$ERRORS" -eq 0 ]; then
    echo -e "  ${YELLOW}BDM has warnings to review but no critical errors.${NC}"
else
    echo -e "  ${RED}BDM has compliance errors that should be fixed.${NC}"
fi

echo ""

# Always exit 0 (informational)
exit 0
