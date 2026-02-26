#!/usr/bin/env bash
# =============================================================================
# check-coverage.sh - JaCoCo coverage checker for the process-builder project
#
# Usage:
#   ./check-coverage.sh              # Run JaCoCo and check thresholds
#   ./check-coverage.sh --report     # Generate report only (skip threshold check)
#   ./check-coverage.sh --verbose    # Show detailed per-class coverage
#
# Thresholds:
#   Line coverage:   minimum 80%  (target 95%+)
#   Branch coverage: minimum 70%  (target 90%+)
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
POM_FILE="extensions/pom.xml"
JACOCO_REPORT_XML="extensions/target/site/jacoco/jacoco.xml"
JACOCO_REPORT_HTML="extensions/target/site/jacoco/index.html"
LINE_THRESHOLD=80
BRANCH_THRESHOLD=70

# Find the project root
find_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/extensions" && -f "$dir/extensions/pom.xml" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    if [[ -f "$POM_FILE" ]]; then
        echo "$PWD"
        return 0
    fi
    echo ""
    return 1
}

# Print a section header
print_header() {
    echo ""
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

# Parse JaCoCo XML report and extract coverage metrics
parse_jacoco_report() {
    local xml_file="$1"

    if [[ ! -f "$xml_file" ]]; then
        echo -e "${RED}ERROR: JaCoCo XML report not found at: ${xml_file}${NC}"
        echo "Run tests first: mvn test -f extensions/pom.xml"
        return 1
    fi

    # Extract overall counters from the report
    # JaCoCo XML has <counter> elements at the report level for totals
    local line_missed line_covered branch_missed branch_covered
    local method_missed method_covered class_missed class_covered

    # Parse LINE counter
    line_missed=$(grep -oP '<counter type="LINE" missed="\K[0-9]+' "$xml_file" | tail -1 || echo "0")
    line_covered=$(grep -oP '<counter type="LINE" missed="[0-9]+" covered="\K[0-9]+' "$xml_file" | tail -1 || echo "0")

    # Parse BRANCH counter
    branch_missed=$(grep -oP '<counter type="BRANCH" missed="\K[0-9]+' "$xml_file" | tail -1 || echo "0")
    branch_covered=$(grep -oP '<counter type="BRANCH" missed="[0-9]+" covered="\K[0-9]+' "$xml_file" | tail -1 || echo "0")

    # Parse METHOD counter
    method_missed=$(grep -oP '<counter type="METHOD" missed="\K[0-9]+' "$xml_file" | tail -1 || echo "0")
    method_covered=$(grep -oP '<counter type="METHOD" missed="[0-9]+" covered="\K[0-9]+' "$xml_file" | tail -1 || echo "0")

    # Parse CLASS counter
    class_missed=$(grep -oP '<counter type="CLASS" missed="\K[0-9]+' "$xml_file" | tail -1 || echo "0")
    class_covered=$(grep -oP '<counter type="CLASS" missed="[0-9]+" covered="\K[0-9]+' "$xml_file" | tail -1 || echo "0")

    # Calculate percentages
    local line_total=$((line_missed + line_covered))
    local branch_total=$((branch_missed + branch_covered))
    local method_total=$((method_missed + method_covered))
    local class_total=$((class_missed + class_covered))

    local line_pct=0 branch_pct=0 method_pct=0 class_pct=0

    if [[ $line_total -gt 0 ]]; then
        line_pct=$((line_covered * 100 / line_total))
    fi
    if [[ $branch_total -gt 0 ]]; then
        branch_pct=$((branch_covered * 100 / branch_total))
    fi
    if [[ $method_total -gt 0 ]]; then
        method_pct=$((method_covered * 100 / method_total))
    fi
    if [[ $class_total -gt 0 ]]; then
        class_pct=$((class_covered * 100 / class_total))
    fi

    # Print summary
    print_header "Coverage Summary"

    echo -e "  ${CYAN}Metric          Covered   Missed    Total     Coverage${NC}"
    echo    "  -------------------------------------------------------"
    printf "  Lines           %-9s %-9s %-9s " "$line_covered" "$line_missed" "$line_total"
    print_coverage_pct "$line_pct" "$LINE_THRESHOLD"

    printf "  Branches        %-9s %-9s %-9s " "$branch_covered" "$branch_missed" "$branch_total"
    print_coverage_pct "$branch_pct" "$BRANCH_THRESHOLD"

    printf "  Methods         %-9s %-9s %-9s " "$method_covered" "$method_missed" "$method_total"
    print_coverage_pct "$method_pct" "0"

    printf "  Classes         %-9s %-9s %-9s " "$class_covered" "$class_missed" "$class_total"
    print_coverage_pct "$class_pct" "0"

    echo ""

    # Check thresholds
    local passed=true

    echo -e "  ${CYAN}Threshold Checks:${NC}"
    if [[ $line_pct -ge $LINE_THRESHOLD ]]; then
        echo -e "    ${GREEN}[PASS]${NC} Line coverage: ${line_pct}% >= ${LINE_THRESHOLD}% threshold"
    else
        echo -e "    ${RED}[FAIL]${NC} Line coverage: ${line_pct}% < ${LINE_THRESHOLD}% threshold"
        passed=false
    fi

    if [[ $branch_pct -ge $BRANCH_THRESHOLD ]]; then
        echo -e "    ${GREEN}[PASS]${NC} Branch coverage: ${branch_pct}% >= ${BRANCH_THRESHOLD}% threshold"
    else
        echo -e "    ${RED}[FAIL]${NC} Branch coverage: ${branch_pct}% < ${BRANCH_THRESHOLD}% threshold"
        passed=false
    fi

    echo ""
    echo -e "  ${YELLOW}HTML Report: ${JACOCO_REPORT_HTML}${NC}"
    echo ""

    # Export variables for use by other functions
    export COVERAGE_LINE_PCT=$line_pct
    export COVERAGE_BRANCH_PCT=$branch_pct
    export COVERAGE_PASSED=$passed
}

# Print coverage percentage with color coding
print_coverage_pct() {
    local pct=$1
    local threshold=$2

    if [[ $threshold -eq 0 ]]; then
        echo -e "${BLUE}${pct}%${NC}"
    elif [[ $pct -ge 95 ]]; then
        echo -e "${GREEN}${pct}% (excellent)${NC}"
    elif [[ $pct -ge $threshold ]]; then
        echo -e "${GREEN}${pct}%${NC}"
    elif [[ $pct -ge $((threshold - 10)) ]]; then
        echo -e "${YELLOW}${pct}% (below target)${NC}"
    else
        echo -e "${RED}${pct}% (BELOW THRESHOLD)${NC}"
    fi
}

# List uncovered classes
list_uncovered_classes() {
    local xml_file="$1"

    if [[ ! -f "$xml_file" ]]; then
        return 0
    fi

    print_header "Uncovered / Low-Coverage Classes"

    # Extract class-level coverage from the XML
    # Find classes where LINE coverage is below threshold
    local found_uncovered=false

    # Parse each package/class combination
    # This uses a simple grep-based approach for portability
    local current_package=""

    while IFS= read -r line; do
        # Track current package
        if echo "$line" | grep -qP '<package name="'; then
            current_package=$(echo "$line" | grep -oP '<package name="\K[^"]+' || echo "")
        fi

        # Find class entries
        if echo "$line" | grep -qP '<class name="'; then
            local class_name
            class_name=$(echo "$line" | grep -oP '<class name="\K[^"]+' || echo "")

            # Look for the LINE counter within the next few lines
            # (This is a simplified parser)
            continue
        fi

        # Find LINE counters at class level
        if echo "$line" | grep -qP '<counter type="LINE"'; then
            local missed covered total pct
            missed=$(echo "$line" | grep -oP 'missed="\K[0-9]+' || echo "0")
            covered=$(echo "$line" | grep -oP 'covered="\K[0-9]+' || echo "0")
            total=$((missed + covered))

            if [[ $total -gt 0 ]]; then
                pct=$((covered * 100 / total))
                if [[ $pct -lt $LINE_THRESHOLD ]]; then
                    if [[ "$found_uncovered" == "false" ]]; then
                        echo -e "  ${CYAN}Classes below ${LINE_THRESHOLD}% line coverage:${NC}"
                        echo ""
                        found_uncovered=true
                    fi
                    printf "    "
                    print_coverage_pct "$pct" "$LINE_THRESHOLD"
                fi
            fi
        fi
    done < "$xml_file"

    if [[ "$found_uncovered" == "false" ]]; then
        echo -e "  ${GREEN}All classes meet the ${LINE_THRESHOLD}% line coverage threshold.${NC}"
    fi

    echo ""
}

# Show detailed per-class coverage
show_verbose_coverage() {
    local xml_file="$1"

    if [[ ! -f "$xml_file" ]]; then
        return 0
    fi

    print_header "Per-Class Coverage Details"

    echo -e "  ${CYAN}Class                                         Lines    Branches${NC}"
    echo    "  -------------------------------------------------------------------"

    # Simple extraction of class-level data
    # In practice, opening the HTML report is more useful
    echo -e "  ${YELLOW}For detailed per-class coverage, open the HTML report:${NC}"
    echo -e "  ${YELLOW}  ${JACOCO_REPORT_HTML}${NC}"
    echo ""
}

# Show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  (none)       Run JaCoCo report and check thresholds"
    echo "  --report     Generate report only (skip threshold check)"
    echo "  --verbose    Show detailed per-class coverage"
    echo "  --help       Show this help message"
    echo ""
    echo "Thresholds:"
    echo "  Line coverage:   ${LINE_THRESHOLD}% minimum"
    echo "  Branch coverage: ${BRANCH_THRESHOLD}% minimum"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local mode="check"

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --report)
                mode="report"
                ;;
            --verbose)
                mode="verbose"
                ;;
            -h|--help|help)
                show_usage
                exit 0
                ;;
            *)
                echo -e "${RED}ERROR: Unknown option: ${arg}${NC}"
                show_usage
                exit 1
                ;;
        esac
    done

    # Find project root
    local project_root
    project_root=$(find_project_root)
    if [[ -z "$project_root" ]]; then
        echo -e "${RED}ERROR: Could not find project root (no extensions/pom.xml found)${NC}"
        exit 1
    fi

    cd "$project_root"
    echo -e "${BLUE}Project root: ${project_root}${NC}"

    # Check Maven
    if ! command -v mvn &>/dev/null; then
        echo -e "${RED}ERROR: Maven (mvn) is not installed or not in PATH${NC}"
        exit 1
    fi

    # Step 1: Run tests and generate JaCoCo report
    print_header "Generating JaCoCo Coverage Report"
    echo -e "${BLUE}Running: mvn test jacoco:report -f ${POM_FILE}${NC}"
    echo ""

    if ! mvn test jacoco:report -f "$POM_FILE" 2>&1; then
        echo -e "${RED}ERROR: Maven test or JaCoCo report generation failed${NC}"
        echo "Fix test failures before checking coverage."
        exit 1
    fi

    # Step 2: Parse and display the report
    parse_jacoco_report "$JACOCO_REPORT_XML"

    # Step 3: Additional output based on mode
    case "$mode" in
        verbose)
            list_uncovered_classes "$JACOCO_REPORT_XML"
            show_verbose_coverage "$JACOCO_REPORT_XML"
            ;;
        report)
            echo -e "${YELLOW}Report generated. Skipping threshold check.${NC}"
            exit 0
            ;;
        check)
            list_uncovered_classes "$JACOCO_REPORT_XML"
            ;;
    esac

    # Step 4: Return exit code based on threshold check
    if [[ "${COVERAGE_PASSED:-true}" == "true" ]]; then
        echo -e "${GREEN}Coverage thresholds met. All checks passed.${NC}"
        exit 0
    else
        echo -e "${RED}Coverage thresholds NOT met. Please add more tests.${NC}"
        echo ""
        echo "Tips to improve coverage:"
        echo "  1. Check the HTML report for uncovered lines"
        echo "  2. Add tests for edge cases and error paths"
        echo "  3. Add property tests for DTOs and validators"
        echo "  4. Run mutation tests to find weak assertions"
        echo ""
        exit 1
    fi
}

main "$@"
