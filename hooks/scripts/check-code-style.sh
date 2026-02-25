#!/bin/bash
# check-code-style.sh - Detect code style issues (Checkstyle/PMD-like rules)
# Fires: PostToolUse on Edit/Write
# Behavior: Warns about style issues (does not block)

INPUT=$(cat)

# Extract file path from JSON input
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    path = data.get('tool_input', {}).get('file_path', '')
    print(path)
except:
    print('')
" 2>/dev/null)

# Only check Java files
if [[ ! "$FILE_PATH" =~ \.java$ ]]; then
    exit 0
fi

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

WARNINGS=""

# Check for System.out.println / System.err.println (should use logger)
if grep -n 'System\.\(out\|err\)\.print' "$FILE_PATH" > /dev/null 2>&1; then
    SYSOUT_LINES=$(grep -n 'System\.\(out\|err\)\.print' "$FILE_PATH" | head -5 | cut -d: -f1 | tr '\n' ', ' | sed 's/,$//')
    WARNINGS="${WARNINGS}⚠ System.out/err.print detected (use Logger): lines ${SYSOUT_LINES}\n"
fi

# Check for empty catch blocks
if grep -Pzn 'catch\s*\([^)]*\)\s*\{\s*\}' "$FILE_PATH" > /dev/null 2>&1; then
    WARNINGS="${WARNINGS}⚠ Empty catch block detected - add proper error handling or logging\n"
fi

# Check for wildcard imports (Checkstyle AvoidStarImport)
if grep -n 'import .*\.\*;' "$FILE_PATH" > /dev/null 2>&1; then
    WILD=$(grep -n 'import .*\.\*;' "$FILE_PATH" | head -3 | sed 's/^/  /')
    WARNINGS="${WARNINGS}⚠ Wildcard imports (Checkstyle: AvoidStarImport):\n${WILD}\n"
fi

# Check for methods > 30 lines (SRP violation)
# Count lines between method signature and closing brace
LONG_METHODS=$(awk '
/^\s*(public|protected|private)\s+.*\(/ && !/;/ {
    method_start = NR
    method_name = $0
    brace_count = 0
    gsub(/.*\s+/, "", method_name)
    gsub(/\(.*/, "", method_name)
}
/{/ { brace_count++ }
/}/ {
    brace_count--
    if (brace_count == 1 && method_start > 0) {
        lines = NR - method_start
        if (lines > 30) {
            printf "  Line %d: %d lines (method around: %s)\n", method_start, lines, method_name
        }
        method_start = 0
    }
}
' "$FILE_PATH" 2>/dev/null)

if [ -n "$LONG_METHODS" ]; then
    WARNINGS="${WARNINGS}⚠ Methods exceeding 30 lines (SRP - Single Responsibility):\n${LONG_METHODS}\n"
fi

# Check for TODO/FIXME/HACK comments
if grep -n '//\s*\(TODO\|FIXME\|HACK\|XXX\)' "$FILE_PATH" > /dev/null 2>&1; then
    TODO_LINES=$(grep -n '//\s*\(TODO\|FIXME\|HACK\|XXX\)' "$FILE_PATH" | head -3 | sed 's/^/  /')
    WARNINGS="${WARNINGS}ℹ Technical debt markers found:\n${TODO_LINES}\n"
fi

# Check for missing @Override on common overridden methods
for method in "toString" "equals" "hashCode" "compareTo"; do
    LINE_NUM=$(grep -n "public.*${method}\s*(" "$FILE_PATH" | head -1 | cut -d: -f1)
    if [ -n "$LINE_NUM" ]; then
        PREV_LINE=$((LINE_NUM - 1))
        if ! sed -n "${PREV_LINE}p" "$FILE_PATH" | grep -q '@Override'; then
            WARNINGS="${WARNINGS}⚠ Missing @Override on ${method}() at line ${LINE_NUM}\n"
        fi
    fi
done

# Output warnings if any
if [ -n "$WARNINGS" ]; then
    echo -e "STYLE CHECK [$FILE_PATH]:\n${WARNINGS}These issues should be addressed to maintain code quality standards." >&2
fi

exit 0
