#!/bin/bash
# =============================================================================
# run-audit-checks.sh
# Executes automated audit checks on a Bonita project directory.
#
# Usage: bash run-audit-checks.sh [project-directory]
#
# Arguments:
#   $1 - Path to the Bonita project root directory (default: current directory)
#
# This script runs:
#   1. Maven compilation check
#   2. Checkstyle analysis
#   3. PMD analysis
#   4. JaCoCo code coverage report
#   5. Missing Javadoc check on public methods
#   6. BDM missing descriptions check
#   7. Summary of all findings
#
# Examples:
#   bash run-audit-checks.sh /path/to/bonita-project
#   bash run-audit-checks.sh .
# =============================================================================

set -uo pipefail

PROJECT_DIR="${1:-.}"
FINDINGS_COUNT=0
WARNINGS_COUNT=0
ERRORS_COUNT=0

# --- Output formatting ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; WARNINGS_COUNT=$((WARNINGS_COUNT + 1)); }
log_error()   { echo -e "${RED}[FAIL]${NC} $1"; ERRORS_COUNT=$((ERRORS_COUNT + 1)); }
log_finding() { echo -e "${YELLOW}[FIND]${NC} $1"; FINDINGS_COUNT=$((FINDINGS_COUNT + 1)); }

echo "============================================="
echo "  Bonita Project Audit Checks"
echo "============================================="
echo "  Project Directory: $PROJECT_DIR"
echo "  Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="
echo ""

# --- Validate project directory ---
if [ ! -d "$PROJECT_DIR" ]; then
  log_error "Project directory not found: $PROJECT_DIR"
  exit 1
fi

cd "$PROJECT_DIR"

if [ ! -f "pom.xml" ]; then
  log_error "pom.xml not found in $PROJECT_DIR. Is this a Maven project?"
  exit 1
fi

# =============================================================================
# CHECK 1: Java Version
# =============================================================================
echo "--- Check 1: Java Version ---"
if command -v java &>/dev/null; then
  JAVA_VERSION=$(java -version 2>&1 | head -1)
  log_info "Java: $JAVA_VERSION"
  if echo "$JAVA_VERSION" | grep -q '"17\|" 17\|version "17'; then
    log_success "Java 17 detected"
  else
    log_warning "Java 17 is recommended for Bonita projects. Current: $JAVA_VERSION"
  fi
else
  log_error "Java not found in PATH"
fi
echo ""

# =============================================================================
# CHECK 2: Maven Compilation
# =============================================================================
echo "--- Check 2: Maven Compilation (mvn clean compile) ---"
log_info "Running mvn clean compile..."
MVN_OUTPUT_FILE=$(mktemp)

if mvn clean compile -Dmaven.test.skip=true -q 2>"$MVN_OUTPUT_FILE"; then
  log_success "Project compiles successfully"
else
  log_error "Compilation FAILED. This is a BLOCKING issue."
  log_error "Error output:"
  cat "$MVN_OUTPUT_FILE" | head -50
  echo ""
  log_error "AUDIT CANNOT PROCEED: Fix compilation errors first."
  rm -f "$MVN_OUTPUT_FILE"
  # Continue with other checks but note the failure
fi
rm -f "$MVN_OUTPUT_FILE"
echo ""

# =============================================================================
# CHECK 3: Checkstyle
# =============================================================================
echo "--- Check 3: Checkstyle Analysis ---"
if grep -q "checkstyle" pom.xml 2>/dev/null; then
  log_info "Checkstyle plugin found in pom.xml. Running check..."
  CHECKSTYLE_OUTPUT=$(mktemp)
  if mvn checkstyle:check -q 2>"$CHECKSTYLE_OUTPUT"; then
    log_success "Checkstyle: No violations found"
  else
    VIOLATION_COUNT=$(grep -c "violation" "$CHECKSTYLE_OUTPUT" 2>/dev/null || echo "unknown")
    log_finding "Checkstyle violations detected ($VIOLATION_COUNT violations)"
    cat "$CHECKSTYLE_OUTPUT" | grep -i "violation\|error" | head -20
  fi
  rm -f "$CHECKSTYLE_OUTPUT"
else
  log_warning "Checkstyle plugin NOT configured in pom.xml"
  log_finding "Recommendation: Add maven-checkstyle-plugin to pom.xml"
fi
echo ""

# =============================================================================
# CHECK 4: PMD
# =============================================================================
echo "--- Check 4: PMD Analysis ---"
if grep -q "pmd" pom.xml 2>/dev/null; then
  log_info "PMD plugin found in pom.xml. Running check..."
  PMD_OUTPUT=$(mktemp)
  if mvn pmd:check -q 2>"$PMD_OUTPUT"; then
    log_success "PMD: No violations found"
  else
    VIOLATION_COUNT=$(grep -c "violation" "$PMD_OUTPUT" 2>/dev/null || echo "unknown")
    log_finding "PMD violations detected ($VIOLATION_COUNT violations)"
    cat "$PMD_OUTPUT" | grep -i "violation\|error" | head -20
  fi
  rm -f "$PMD_OUTPUT"
else
  log_warning "PMD plugin NOT configured in pom.xml"
  log_finding "Recommendation: Add maven-pmd-plugin to pom.xml"
fi
echo ""

# =============================================================================
# CHECK 5: JaCoCo Code Coverage
# =============================================================================
echo "--- Check 5: JaCoCo Code Coverage ---"
if grep -q "jacoco" pom.xml 2>/dev/null; then
  log_info "JaCoCo plugin found in pom.xml. Running report..."
  JACOCO_OUTPUT=$(mktemp)
  if mvn test jacoco:report -q 2>"$JACOCO_OUTPUT"; then
    # Try to extract coverage percentage from the report
    JACOCO_REPORT=$(find . -path "*/jacoco/index.html" -type f 2>/dev/null | head -1)
    if [ -n "$JACOCO_REPORT" ]; then
      log_success "JaCoCo report generated: $JACOCO_REPORT"
      # Try to extract total coverage
      COVERAGE=$(grep -oP 'Total.*?(\d+%?)' "$JACOCO_REPORT" 2>/dev/null | head -1 || echo "")
      if [ -n "$COVERAGE" ]; then
        log_info "Coverage: $COVERAGE"
      else
        log_info "Open $JACOCO_REPORT in a browser to view coverage details"
      fi
    else
      log_warning "JaCoCo report file not found after generation"
    fi
  else
    log_warning "JaCoCo report generation failed (tests may have failed)"
    cat "$JACOCO_OUTPUT" | grep -i "error\|fail" | head -10
  fi
  rm -f "$JACOCO_OUTPUT"
else
  log_warning "JaCoCo plugin NOT configured in pom.xml"
  log_finding "Recommendation: Add jacoco-maven-plugin to pom.xml for code coverage"
fi
echo ""

# =============================================================================
# CHECK 6: Missing Javadoc on Public Methods
# =============================================================================
echo "--- Check 6: Missing Javadoc on Public Methods ---"
JAVA_FILES=$(find . -name "*.java" -not -path "*/test/*" -not -path "*/target/*" 2>/dev/null)
if [ -n "$JAVA_FILES" ]; then
  TOTAL_PUBLIC_METHODS=0
  MISSING_JAVADOC=0

  while IFS= read -r java_file; do
    # Count public methods
    PUBLIC_METHODS=$(grep -c "public.*(" "$java_file" 2>/dev/null || echo 0)
    TOTAL_PUBLIC_METHODS=$((TOTAL_PUBLIC_METHODS + PUBLIC_METHODS))

    # Check for public methods without preceding Javadoc (/** ... */)
    # Simple heuristic: look for "public" lines not preceded by "*/" within 5 lines
    while IFS= read -r line_num; do
      if [ -n "$line_num" ]; then
        # Check if there's a Javadoc closing tag within 5 lines before this public method
        START_LINE=$((line_num - 5))
        if [ "$START_LINE" -lt 1 ]; then START_LINE=1; fi
        PRECEDING=$(sed -n "${START_LINE},${line_num}p" "$java_file" 2>/dev/null)
        if ! echo "$PRECEDING" | grep -q '\*/'; then
          MISSING_JAVADOC=$((MISSING_JAVADOC + 1))
        fi
      fi
    done < <(grep -n "public.*(" "$java_file" 2>/dev/null | grep -v "class\|interface\|enum" | cut -d: -f1)
  done <<< "$JAVA_FILES"

  if [ "$TOTAL_PUBLIC_METHODS" -gt 0 ]; then
    JAVADOC_COVERAGE=$(( (TOTAL_PUBLIC_METHODS - MISSING_JAVADOC) * 100 / TOTAL_PUBLIC_METHODS ))
    log_info "Total public methods found: $TOTAL_PUBLIC_METHODS"
    log_info "Methods with Javadoc: $((TOTAL_PUBLIC_METHODS - MISSING_JAVADOC))"
    log_info "Methods WITHOUT Javadoc: $MISSING_JAVADOC"
    log_info "Javadoc coverage: ${JAVADOC_COVERAGE}%"

    if [ "$JAVADOC_COVERAGE" -lt 50 ]; then
      log_finding "Javadoc coverage is LOW (${JAVADOC_COVERAGE}%). Target: >80%"
    elif [ "$JAVADOC_COVERAGE" -lt 80 ]; then
      log_warning "Javadoc coverage is MODERATE (${JAVADOC_COVERAGE}%). Target: >80%"
    else
      log_success "Javadoc coverage is GOOD (${JAVADOC_COVERAGE}%)"
    fi
  else
    log_info "No public methods found in Java source files"
  fi
else
  log_info "No Java source files found (excluding tests and target)"
fi
echo ""

# =============================================================================
# CHECK 7: BDM Missing Descriptions
# =============================================================================
echo "--- Check 7: BDM Missing Descriptions ---"
BOM_FILE=$(find . -name "bom.xml" -not -path "*/target/*" 2>/dev/null | head -1)
if [ -n "$BOM_FILE" ] && [ -f "$BOM_FILE" ]; then
  log_info "BDM file found: $BOM_FILE"

  # Count business objects
  BO_COUNT=$(grep -c "<businessObject" "$BOM_FILE" 2>/dev/null || echo 0)
  log_info "Business objects found: $BO_COUNT"

  # Check for empty descriptions on business objects
  EMPTY_BO_DESC=$(grep -A1 "<businessObject" "$BOM_FILE" 2>/dev/null | grep "<description></description>\|<description/>" | wc -l)
  MISSING_BO_DESC=$(grep "<businessObject" "$BOM_FILE" 2>/dev/null | grep -v "description" | wc -l)
  TOTAL_MISSING_BO=$((EMPTY_BO_DESC + MISSING_BO_DESC))

  if [ "$TOTAL_MISSING_BO" -gt 0 ]; then
    log_finding "Business objects with empty/missing descriptions: $TOTAL_MISSING_BO"
  else
    log_success "All business objects have descriptions"
  fi

  # Check for empty field descriptions
  EMPTY_FIELD_DESC=$(grep -c "<description></description>\|<description/>" "$BOM_FILE" 2>/dev/null || echo 0)
  if [ "$EMPTY_FIELD_DESC" -gt 0 ]; then
    log_finding "Empty <description> tags found in BDM: $EMPTY_FIELD_DESC"
  else
    log_success "No empty description tags found"
  fi

  # Check for missing indexes
  INDEX_COUNT=$(grep -c "<index " "$BOM_FILE" 2>/dev/null || echo 0)
  QUERY_COUNT=$(grep -c "<query " "$BOM_FILE" 2>/dev/null || echo 0)
  log_info "Indexes defined: $INDEX_COUNT"
  log_info "Custom queries defined: $QUERY_COUNT"

  if [ "$QUERY_COUNT" -gt 0 ] && [ "$INDEX_COUNT" -eq 0 ]; then
    log_finding "Custom queries exist ($QUERY_COUNT) but NO indexes are defined"
  elif [ "$QUERY_COUNT" -gt "$INDEX_COUNT" ]; then
    log_warning "More queries ($QUERY_COUNT) than indexes ($INDEX_COUNT). Some queries may lack indexes."
  fi

  # Check for countFor queries
  LIST_QUERIES=$(grep -c 'returnType="java.util.List"' "$BOM_FILE" 2>/dev/null || echo 0)
  COUNT_FOR_QUERIES=$(grep -c "countFor" "$BOM_FILE" 2>/dev/null || echo 0)
  log_info "List-returning queries: $LIST_QUERIES"
  log_info "CountFor queries: $COUNT_FOR_QUERIES"

  if [ "$LIST_QUERIES" -gt "$COUNT_FOR_QUERIES" ]; then
    MISSING_COUNTFOR=$((LIST_QUERIES - COUNT_FOR_QUERIES))
    log_finding "Missing countFor queries: $MISSING_COUNTFOR (every List query needs a countFor)"
  else
    log_success "CountFor queries appear complete"
  fi

  # Check for STRING fields that might be dates
  DATE_STRINGS=$(grep -B5 'type="STRING"' "$BOM_FILE" 2>/dev/null | grep -ic "date\|fecha\|time\|hora" || echo 0)
  if [ "$DATE_STRINGS" -gt 0 ]; then
    log_finding "Potential date fields using STRING type: $DATE_STRINGS (should use DATE ONLY or DATE-TIME)"
  fi

  # Check for deprecated DATE type
  DEPRECATED_DATE=$(grep -c 'type="DATE"' "$BOM_FILE" 2>/dev/null || echo 0)
  if [ "$DEPRECATED_DATE" -gt 0 ]; then
    log_finding "Deprecated DATE (java.util.Date) type used: $DEPRECATED_DATE times. Use DATE ONLY or DATE-TIME."
  fi

  # Check for audit fields
  AUDIT_FIELDS_PATTERN="auFechaCreacion\|auUsuarioCreacion\|auFechaModificacion\|auUsuarioModificacion"
  AUDIT_FIELDS_FOUND=$(grep -c "$AUDIT_FIELDS_PATTERN" "$BOM_FILE" 2>/dev/null || echo 0)
  if [ "$BO_COUNT" -gt 0 ]; then
    EXPECTED_AUDIT_FIELDS=$((BO_COUNT * 4))
    if [ "$AUDIT_FIELDS_FOUND" -lt "$EXPECTED_AUDIT_FIELDS" ]; then
      log_finding "Audit fields incomplete: found $AUDIT_FIELDS_FOUND, expected $EXPECTED_AUDIT_FIELDS (4 per business object)"
    else
      log_success "Audit fields appear complete"
    fi
  fi

else
  log_warning "BDM file (bom.xml) not found in project"
fi
echo ""

# =============================================================================
# CHECK 8: REST API Extension READMEs
# =============================================================================
echo "--- Check 8: REST API Extension Documentation ---"
CONTROLLER_DIRS=$(find . -path "*/controller/*" -name "*.java" -not -path "*/target/*" 2>/dev/null | xargs -I{} dirname {} | sort -u)
if [ -n "$CONTROLLER_DIRS" ]; then
  TOTAL_CONTROLLERS=0
  MISSING_README=0
  while IFS= read -r ctrl_dir; do
    TOTAL_CONTROLLERS=$((TOTAL_CONTROLLERS + 1))
    if [ ! -f "$ctrl_dir/README.md" ]; then
      MISSING_README=$((MISSING_README + 1))
      log_finding "Missing README.md in controller: $ctrl_dir"
    fi
  done <<< "$CONTROLLER_DIRS"

  log_info "Controller packages found: $TOTAL_CONTROLLERS"
  if [ "$MISSING_README" -eq 0 ]; then
    log_success "All controller packages have README.md"
  else
    log_finding "$MISSING_README controller packages missing README.md"
  fi
else
  log_info "No REST API Extension controllers found"
fi
echo ""

# =============================================================================
# CHECK 9: EditorConfig
# =============================================================================
echo "--- Check 9: EditorConfig ---"
if [ -f ".editorconfig" ]; then
  log_success ".editorconfig file present"
else
  log_finding ".editorconfig file NOT found. Recommended for consistent formatting."
fi
echo ""

# =============================================================================
# CHECK 10: Process Variable Count (quick heuristic)
# =============================================================================
echo "--- Check 10: Process Variables (heuristic) ---"
PROC_FILES=$(find . -name "*.proc" -not -path "*/target/*" 2>/dev/null)
if [ -n "$PROC_FILES" ]; then
  while IFS= read -r proc_file; do
    VAR_COUNT=$(grep -c "<data " "$proc_file" 2>/dev/null || echo 0)
    PROC_NAME=$(basename "$proc_file" .proc)
    if [ "$VAR_COUNT" -gt 40 ]; then
      log_finding "Process '$PROC_NAME' has $VAR_COUNT variables (>40 threshold)"
    elif [ "$VAR_COUNT" -gt 20 ]; then
      log_warning "Process '$PROC_NAME' has $VAR_COUNT variables (consider reducing)"
    else
      log_info "Process '$PROC_NAME': $VAR_COUNT variables"
    fi
  done <<< "$PROC_FILES"
else
  log_info "No .proc files found"
fi
echo ""

# =============================================================================
# SUMMARY
# =============================================================================
echo "============================================="
echo "  AUDIT CHECK SUMMARY"
echo "============================================="
echo -e "  Findings:  ${YELLOW}${FINDINGS_COUNT}${NC}"
echo -e "  Warnings:  ${YELLOW}${WARNINGS_COUNT}${NC}"
echo -e "  Errors:    ${RED}${ERRORS_COUNT}${NC}"
echo ""

TOTAL_ISSUES=$((FINDINGS_COUNT + WARNINGS_COUNT + ERRORS_COUNT))
if [ "$ERRORS_COUNT" -gt 0 ]; then
  echo -e "  ${RED}RESULT: CRITICAL ISSUES FOUND${NC}"
  echo "  The project has blocking errors that must be resolved before a full audit."
elif [ "$FINDINGS_COUNT" -gt 10 ]; then
  echo -e "  ${YELLOW}RESULT: SIGNIFICANT FINDINGS${NC}"
  echo "  The project has multiple areas requiring attention."
elif [ "$TOTAL_ISSUES" -gt 0 ]; then
  echo -e "  ${YELLOW}RESULT: MINOR FINDINGS${NC}"
  echo "  The project has some areas for improvement."
else
  echo -e "  ${GREEN}RESULT: PROJECT LOOKS HEALTHY${NC}"
  echo "  No significant issues detected in automated checks."
fi

echo ""
echo "  NOTE: These are automated checks only. A manual code review"
echo "  is required for a comprehensive audit."
echo "============================================="
