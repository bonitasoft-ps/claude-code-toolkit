#!/usr/bin/env bash
#
# check-code-quality.sh
#
# Performs static analysis checks on Java source files for Bonita coding standards.
# Reports findings to stderr with a summary.
#
# Usage:
#   ./check-code-quality.sh <java-source-directory>
#
# Example:
#   ./check-code-quality.sh src/main/java
#
# Checks performed:
#   1. Methods exceeding 30 lines
#   2. System.out.println / System.err.println usage
#   3. Missing Javadoc on public methods
#   4. Hardcoded strings in comparisons
#
# Exit codes:
#   0 - No violations found
#   1 - Violations found
#   2 - Invalid arguments or directory not found

set -euo pipefail

# ============================================================================
# Constants
# ============================================================================
readonly SCRIPT_NAME="$(basename "$0")"
readonly MAX_METHOD_LINES=30
readonly COLOR_RED='\033[0;31m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_RESET='\033[0m'

# Counters
total_long_methods=0
total_sysout=0
total_missing_javadoc=0
total_hardcoded_strings=0
total_files_scanned=0

# ============================================================================
# Functions
# ============================================================================

usage() {
    cat >&2 <<EOF
Usage: $SCRIPT_NAME <java-source-directory>

Checks Java source files for Bonita coding standard violations.

Arguments:
  java-source-directory    Path to the root directory containing .java files

Checks:
  1. Methods exceeding $MAX_METHOD_LINES lines
  2. System.out.println / System.err.println usage
  3. Missing Javadoc on public methods
  4. Hardcoded strings in comparisons (.equals("..."))

EOF
}

log_violation() {
    local level="$1"
    local file="$2"
    local line="$3"
    local message="$4"

    case "$level" in
        ERROR)   echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $file:$line - $message" >&2 ;;
        WARNING) echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET}  $file:$line - $message" >&2 ;;
        INFO)    echo -e "${COLOR_CYAN}[INFO]${COLOR_RESET}  $file:$line - $message" >&2 ;;
    esac
}

# --------------------------------------------------------------------------
# Check 1: Methods exceeding MAX_METHOD_LINES lines
# --------------------------------------------------------------------------
check_long_methods() {
    local file="$1"
    local in_method=false
    local method_name=""
    local method_start_line=0
    local method_lines=0
    local brace_depth=0
    local line_number=0

    while IFS= read -r line; do
        ((line_number++))

        # Detect method declarations (public, protected, private, or package-private)
        # Match lines that look like method signatures (contain parentheses, not class/interface/enum)
        if [[ "$in_method" == false ]] && \
           echo "$line" | grep -qP '^\s*(public|protected|private|static|\s)*(static\s+)?(final\s+)?\S+\s+\w+\s*\(' && \
           ! echo "$line" | grep -qP '^\s*(class|interface|enum|import|package|new |return |if |while |for |switch )' && \
           echo "$line" | grep -qP '\)\s*(\{|throws)'; then

            # Extract method name
            method_name=$(echo "$line" | grep -oP '\w+\s*\(' | head -1 | sed 's/\s*($//')
            method_start_line=$line_number
            method_lines=0
            brace_depth=0
            in_method=true
        fi

        if [[ "$in_method" == true ]]; then
            # Count opening and closing braces
            local open_braces close_braces
            open_braces=$(echo "$line" | tr -cd '{' | wc -c)
            close_braces=$(echo "$line" | tr -cd '}' | wc -c)
            brace_depth=$((brace_depth + open_braces - close_braces))
            ((method_lines++))

            # Method ends when brace depth returns to 0
            if [[ $brace_depth -le 0 && $method_lines -gt 1 ]]; then
                if [[ $method_lines -gt $MAX_METHOD_LINES ]]; then
                    log_violation "ERROR" "$file" "$method_start_line" \
                        "Method '$method_name' is $method_lines lines (max: $MAX_METHOD_LINES). Refactor into smaller methods."
                    ((total_long_methods++))
                fi
                in_method=false
            fi
        fi
    done < "$file"
}

# --------------------------------------------------------------------------
# Check 2: System.out.println / System.err.println usage
# --------------------------------------------------------------------------
check_system_out() {
    local file="$1"
    local line_number=0

    while IFS= read -r line; do
        ((line_number++))

        # Skip comments
        if echo "$line" | grep -qP '^\s*(//|\*|/\*)'; then
            continue
        fi

        if echo "$line" | grep -qP 'System\.(out|err)\.(println|print|printf)'; then
            log_violation "ERROR" "$file" "$line_number" \
                "System.out/err usage detected. Use SLF4J Logger instead."
            ((total_sysout++))
        fi

        if echo "$line" | grep -qP '\.printStackTrace\(\)'; then
            log_violation "ERROR" "$file" "$line_number" \
                "printStackTrace() detected. Use logger.error(\"message\", exception) instead."
            ((total_sysout++))
        fi
    done < "$file"
}

# --------------------------------------------------------------------------
# Check 3: Missing Javadoc on public methods
# --------------------------------------------------------------------------
check_missing_javadoc() {
    local file="$1"
    local prev_line=""
    local prev_prev_line=""
    local line_number=0
    local in_javadoc=false
    local javadoc_ended_at=0

    while IFS= read -r line; do
        ((line_number++))

        # Track Javadoc blocks
        if echo "$line" | grep -qP '^\s*/\*\*'; then
            in_javadoc=true
        fi
        if [[ "$in_javadoc" == true ]] && echo "$line" | grep -qP '\*/'; then
            in_javadoc=false
            javadoc_ended_at=$line_number
        fi

        # Check public method declarations
        if echo "$line" | grep -qP '^\s*public\s+(?!class\s|interface\s|enum\s|static\s+final\s)' && \
           echo "$line" | grep -qP '\w+\s*\('; then

            # Check if the line immediately before (allowing for annotations) has a Javadoc end
            local has_javadoc=false
            local check_line=$((line_number - 1))

            # Walk backwards through annotations and blank lines to find Javadoc
            while [[ $check_line -gt 0 ]]; do
                local check_content
                check_content=$(sed -n "${check_line}p" "$file")

                if echo "$check_content" | grep -qP '^\s*@\w+'; then
                    # Annotation, keep looking
                    ((check_line--))
                    continue
                elif echo "$check_content" | grep -qP '^\s*\*/'; then
                    has_javadoc=true
                    break
                elif echo "$check_content" | grep -qP '^\s*$'; then
                    # Empty line, keep looking (but limit search)
                    if [[ $((line_number - check_line)) -gt 5 ]]; then
                        break
                    fi
                    ((check_line--))
                    continue
                else
                    break
                fi
            done

            if [[ "$has_javadoc" == false ]]; then
                local method_name
                method_name=$(echo "$line" | grep -oP '\w+\s*\(' | head -1 | sed 's/\s*($//')
                log_violation "ERROR" "$file" "$line_number" \
                    "Missing Javadoc on public method '$method_name'. All public methods MUST have Javadoc (BLOCKER)."
                ((total_missing_javadoc++))
            fi
        fi
    done < "$file"
}

# --------------------------------------------------------------------------
# Check 4: Hardcoded strings in comparisons
# --------------------------------------------------------------------------
check_hardcoded_strings() {
    local file="$1"
    local line_number=0

    while IFS= read -r line; do
        ((line_number++))

        # Skip comments
        if echo "$line" | grep -qP '^\s*(//|\*|/\*)'; then
            continue
        fi

        # Skip constant definitions (static final)
        if echo "$line" | grep -qP 'static\s+final'; then
            continue
        fi

        # Skip import statements
        if echo "$line" | grep -qP '^\s*import\s'; then
            continue
        fi

        # Check for .equals("literal") pattern
        if echo "$line" | grep -qP '\.equals\s*\(\s*"[^"]+"\s*\)'; then
            log_violation "WARNING" "$file" "$line_number" \
                "Hardcoded string in .equals() comparison. Use a constant instead."
            ((total_hardcoded_strings++))
        fi

        # Check for == "literal" pattern (string reference comparison)
        if echo "$line" | grep -qP '==\s*"[^"]*"'; then
            log_violation "WARNING" "$file" "$line_number" \
                "String comparison using '==' with literal. Use .equals() with a constant."
            ((total_hardcoded_strings++))
        fi

        # Check for "literal".equals() pattern
        if echo "$line" | grep -qP '"[^"]+"\s*\.equals\s*\('; then
            log_violation "WARNING" "$file" "$line_number" \
                "Hardcoded string in comparison (\"literal\".equals(...)). Use a constant."
            ((total_hardcoded_strings++))
        fi

    done < "$file"
}

# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------
print_summary() {
    echo "" >&2
    echo -e "${COLOR_CYAN}========================================${COLOR_RESET}" >&2
    echo -e "${COLOR_CYAN}  Code Quality Check Summary${COLOR_RESET}" >&2
    echo -e "${COLOR_CYAN}========================================${COLOR_RESET}" >&2
    echo -e "  Files scanned:            $total_files_scanned" >&2
    echo -e "  Long methods (>$MAX_METHOD_LINES lines): $total_long_methods" >&2
    echo -e "  System.out/err usage:     $total_sysout" >&2
    echo -e "  Missing Javadoc:          $total_missing_javadoc" >&2
    echo -e "  Hardcoded strings:        $total_hardcoded_strings" >&2

    local total_violations=$((total_long_methods + total_sysout + total_missing_javadoc + total_hardcoded_strings))
    echo -e "  ---" >&2
    echo -e "  Total violations:         $total_violations" >&2
    echo -e "${COLOR_CYAN}========================================${COLOR_RESET}" >&2

    if [[ $total_violations -eq 0 ]]; then
        echo -e "${COLOR_GREEN}  All checks passed!${COLOR_RESET}" >&2
        return 0
    else
        echo -e "${COLOR_RED}  $total_violations violation(s) found.${COLOR_RESET}" >&2
        return 1
    fi
}

main() {
    if [[ $# -ne 1 ]]; then
        usage
        exit 2
    fi

    local source_dir="$1"

    if [[ ! -d "$source_dir" ]]; then
        echo -e "${COLOR_RED}Error: Directory '$source_dir' does not exist.${COLOR_RESET}" >&2
        exit 2
    fi

    echo -e "${COLOR_CYAN}Scanning Java files in: $source_dir${COLOR_RESET}" >&2
    echo "" >&2

    # Find all Java files
    local java_files
    java_files=$(find "$source_dir" -name "*.java" -type f | sort)

    if [[ -z "$java_files" ]]; then
        echo -e "${COLOR_YELLOW}No Java files found in '$source_dir'.${COLOR_RESET}" >&2
        exit 0
    fi

    while IFS= read -r file; do
        ((total_files_scanned++))

        # Skip test files for some checks (still check system.out)
        local is_test=false
        if echo "$file" | grep -qP '(Test|Tests|IT)\.java$'; then
            is_test=true
        fi

        check_system_out "$file"
        check_hardcoded_strings "$file"

        if [[ "$is_test" == false ]]; then
            check_long_methods "$file"
            check_missing_javadoc "$file"
        fi

    done <<< "$java_files"

    print_summary
}

main "$@"
