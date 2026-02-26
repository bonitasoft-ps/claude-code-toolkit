#!/usr/bin/env bash
# =============================================================================
# run-tests.sh - Test runner for the process-builder project
#
# Usage:
#   ./run-tests.sh [unit|integration|property|mutation|all] [ClassName]
#
# Examples:
#   ./run-tests.sh                          # Run unit tests (default)
#   ./run-tests.sh unit                     # Run unit tests
#   ./run-tests.sh integration              # Run integration tests
#   ./run-tests.sh property                 # Run property-based tests
#   ./run-tests.sh mutation                 # Run mutation tests (PIT)
#   ./run-tests.sh all                      # Run unit + property tests
#   ./run-tests.sh unit MyClassTest         # Run specific test class
#   ./run-tests.sh mutation MyClass         # Run mutation tests for class
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
POM_FILE="extensions/pom.xml"
REPORT_DIR="extensions/target"

# Find the project root (look for the extensions directory)
find_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/extensions" && -f "$dir/extensions/pom.xml" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done

    # Fallback: check if we are already in the project root
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

# Print result summary
print_result() {
    local exit_code=$1
    local test_type=$2

    echo ""
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}[PASS] ${test_type} tests completed successfully${NC}"
    else
        echo -e "${RED}[FAIL] ${test_type} tests failed (exit code: ${exit_code})${NC}"
    fi
    echo ""
}

# Run unit tests
run_unit_tests() {
    local class_name="${1:-}"

    if [[ -n "$class_name" ]]; then
        print_header "Running unit test: ${class_name}"
        mvn test -f "$POM_FILE" -Dtest="$class_name" 2>&1
    else
        print_header "Running all unit tests"
        mvn test -f "$POM_FILE" 2>&1
    fi

    local exit_code=$?
    print_result $exit_code "Unit"

    # Show test report location
    if [[ -d "${REPORT_DIR}/surefire-reports" ]]; then
        local total passed failed errors
        total=$(grep -l "testsuite" "${REPORT_DIR}/surefire-reports/"*.xml 2>/dev/null | wc -l || echo "0")
        echo -e "${YELLOW}Surefire reports: ${REPORT_DIR}/surefire-reports/ (${total} test suites)${NC}"
    fi

    return $exit_code
}

# Run integration tests
run_integration_tests() {
    local class_name="${1:-}"

    if [[ -n "$class_name" ]]; then
        print_header "Running integration test: ${class_name}"
        mvn verify -f "$POM_FILE" -Pintegration-tests -Dtest="$class_name" 2>&1
    else
        print_header "Running all integration tests"
        mvn verify -f "$POM_FILE" -Pintegration-tests 2>&1
    fi

    local exit_code=$?
    print_result $exit_code "Integration"

    # Show test report location
    if [[ -d "${REPORT_DIR}/failsafe-reports" ]]; then
        echo -e "${YELLOW}Failsafe reports: ${REPORT_DIR}/failsafe-reports/${NC}"
    fi

    return $exit_code
}

# Run property-based tests (jqwik)
run_property_tests() {
    local class_name="${1:-}"

    if [[ -n "$class_name" ]]; then
        print_header "Running property test: ${class_name}"
        mvn test -f "$POM_FILE" -Dtest="$class_name" 2>&1
    else
        print_header "Running all property-based tests (*PropertyTest)"
        mvn test -f "$POM_FILE" -Dtest="*PropertyTest" 2>&1
    fi

    local exit_code=$?
    print_result $exit_code "Property"
    return $exit_code
}

# Run mutation tests (PIT)
run_mutation_tests() {
    local class_name="${1:-}"

    if [[ -n "$class_name" ]]; then
        print_header "Running mutation tests for: ${class_name}"
        mvn org.pitest:pitest-maven:mutationCoverage \
            -f "$POM_FILE" \
            -DtargetClasses="**.$class_name" 2>&1
    else
        print_header "Running all mutation tests (PIT)"
        mvn org.pitest:pitest-maven:mutationCoverage -f "$POM_FILE" 2>&1
    fi

    local exit_code=$?
    print_result $exit_code "Mutation"

    # Show PIT report location
    local pit_report_dir
    pit_report_dir=$(find "${REPORT_DIR}" -name "index.html" -path "*/pit-reports/*" 2>/dev/null | head -1 || echo "")
    if [[ -n "$pit_report_dir" ]]; then
        echo -e "${YELLOW}PIT report: ${pit_report_dir}${NC}"
    fi

    return $exit_code
}

# Run all tests (unit + property)
run_all_tests() {
    local exit_code=0

    print_header "Running ALL tests (unit + property)"

    echo -e "${BLUE}--- Phase 1: Unit Tests ---${NC}"
    run_unit_tests || exit_code=$?

    echo -e "${BLUE}--- Phase 2: Property Tests ---${NC}"
    run_property_tests || exit_code=$?

    echo ""
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}[PASS] All test phases completed successfully${NC}"
    else
        echo -e "${RED}[FAIL] One or more test phases failed${NC}"
    fi

    return $exit_code
}

# Show usage
show_usage() {
    echo "Usage: $0 [unit|integration|property|mutation|all] [ClassName]"
    echo ""
    echo "Test types:"
    echo "  unit         Run unit tests (default)"
    echo "  integration  Run integration tests"
    echo "  property     Run property-based tests (*PropertyTest)"
    echo "  mutation     Run mutation tests (PIT)"
    echo "  all          Run unit + property tests"
    echo ""
    echo "Options:"
    echo "  ClassName    Run tests for a specific class only"
    echo ""
    echo "Examples:"
    echo "  $0                                  # Run unit tests"
    echo "  $0 unit MyEntityTest                # Run specific unit test"
    echo "  $0 property PBCategoryDTOPropertyTest  # Run specific property test"
    echo "  $0 mutation MyEntity                # Run PIT for specific class"
    echo "  $0 all                              # Run unit + property tests"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local test_type="${1:-unit}"
    local class_name="${2:-}"

    # Find project root
    local project_root
    project_root=$(find_project_root)
    if [[ -z "$project_root" ]]; then
        echo -e "${RED}ERROR: Could not find project root (no extensions/pom.xml found)${NC}"
        echo "Run this script from the project root or a subdirectory."
        exit 1
    fi

    # Change to project root
    cd "$project_root"
    echo -e "${BLUE}Project root: ${project_root}${NC}"

    # Check that Maven is available
    if ! command -v mvn &>/dev/null; then
        echo -e "${RED}ERROR: Maven (mvn) is not installed or not in PATH${NC}"
        exit 1
    fi

    # Check that pom.xml exists
    if [[ ! -f "$POM_FILE" ]]; then
        echo -e "${RED}ERROR: ${POM_FILE} not found${NC}"
        exit 1
    fi

    # Dispatch to the appropriate test runner
    case "$test_type" in
        unit)
            run_unit_tests "$class_name"
            ;;
        integration)
            run_integration_tests "$class_name"
            ;;
        property)
            run_property_tests "$class_name"
            ;;
        mutation)
            run_mutation_tests "$class_name"
            ;;
        all)
            run_all_tests
            ;;
        -h|--help|help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}ERROR: Unknown test type: ${test_type}${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
