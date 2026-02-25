#!/bin/bash
# check-code-format.sh - Detect formatting issues in Java/Groovy files
# Fires: PostToolUse on Edit/Write
# Behavior: Warns about formatting issues (does not block)

INPUT=$(cat)

# Extract file path from JSON input
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    # Handle both Edit and Write tool inputs
    path = data.get('tool_input', {}).get('file_path', '')
    print(path)
except:
    print('')
" 2>/dev/null)

# Only check Java and Groovy files
if [[ ! "$FILE_PATH" =~ \.(java|groovy)$ ]]; then
    exit 0
fi

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

WARNINGS=""

# Check for tabs (should use spaces)
if grep -Pn '\t' "$FILE_PATH" > /dev/null 2>&1; then
    TAB_LINES=$(grep -Pn '\t' "$FILE_PATH" | head -5 | cut -d: -f1 | tr '\n' ', ' | sed 's/,$//')
    WARNINGS="${WARNINGS}⚠ TABS detected (use spaces): lines ${TAB_LINES}\n"
fi

# Check for trailing whitespace
if grep -Pn '\s+$' "$FILE_PATH" > /dev/null 2>&1; then
    TRAIL_LINES=$(grep -Pn '\s+$' "$FILE_PATH" | head -5 | cut -d: -f1 | tr '\n' ', ' | sed 's/,$//')
    WARNINGS="${WARNINGS}⚠ Trailing whitespace: lines ${TRAIL_LINES}\n"
fi

# Check for lines > 120 characters (warn only)
if awk 'length > 120 {found=1; exit} END {exit !found}' "$FILE_PATH" 2>/dev/null; then
    LONG_LINES=$(awk 'length > 120 {print NR}' "$FILE_PATH" | head -5 | tr '\n' ', ' | sed 's/,$//')
    WARNINGS="${WARNINGS}⚠ Lines > 120 chars: lines ${LONG_LINES}\n"
fi

# Check for wildcard imports
if grep -n 'import .*\.\*;' "$FILE_PATH" > /dev/null 2>&1; then
    WILD_LINES=$(grep -n 'import .*\.\*;' "$FILE_PATH" | head -5 | cut -d: -f1 | tr '\n' ', ' | sed 's/,$//')
    WARNINGS="${WARNINGS}⚠ Wildcard imports detected (use explicit imports): lines ${WILD_LINES}\n"
fi

# Check for multiple consecutive blank lines
if awk '/^$/{blank++; if(blank>1){found=1; exit}} /^.+$/{blank=0} END{exit !found}' "$FILE_PATH" 2>/dev/null; then
    WARNINGS="${WARNINGS}⚠ Multiple consecutive blank lines detected (max 1 allowed)\n"
fi

# Check for missing final newline
if [ -s "$FILE_PATH" ] && [ "$(tail -c 1 "$FILE_PATH" | wc -l)" -eq 0 ]; then
    WARNINGS="${WARNINGS}⚠ File does not end with a newline\n"
fi

# Output warnings if any
if [ -n "$WARNINGS" ]; then
    echo -e "FORMAT CHECK [$FILE_PATH]:\n${WARNINGS}Consider fixing these formatting issues for code consistency." >&2
fi

exit 0
