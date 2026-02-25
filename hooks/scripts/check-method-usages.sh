#!/bin/bash
# Hook: Post-edit method usage check
# Event: PostToolUse (Edit)
# Purpose: After editing a Java/Groovy file, detect method signature changes
#          and warn about other files that may need updating
# Exit 0 = always allow (informational only)

INPUT=$(cat)

# Extract the edited file path
FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# Only check Java and Groovy source files
if ! echo "$FILE_PATH" | grep -qE "\.(java|groovy|kt)$"; then
    exit 0
fi

# Only check files in extensions directory
if ! echo "$FILE_PATH" | grep -qiE "extensions/"; then
    exit 0
fi

# Extract the old and new strings to detect signature changes
OLD_STRING=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('old_string',''))" 2>/dev/null)
NEW_STRING=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('new_string',''))" 2>/dev/null)

# Detect if this looks like a method signature change
# Check for patterns like: methodName( with different parameters
METHOD_PATTERN='(public|private|protected|static|void|int|long|String|boolean|List|Map|Set|Optional)\s+\w+\s*\('

OLD_HAS_METHOD=$(echo "$OLD_STRING" | grep -cE "$METHOD_PATTERN" 2>/dev/null)
NEW_HAS_METHOD=$(echo "$NEW_STRING" | grep -cE "$METHOD_PATTERN" 2>/dev/null)

if [ "$OLD_HAS_METHOD" -gt 0 ] && [ "$NEW_HAS_METHOD" -gt 0 ]; then
    # Extract method name from old string
    METHOD_NAME=$(echo "$OLD_STRING" | grep -oP '\w+(?=\s*\()' | head -1)

    if [ -n "$METHOD_NAME" ] && [ "$METHOD_NAME" != "if" ] && [ "$METHOD_NAME" != "for" ] && [ "$METHOD_NAME" != "while" ] && [ "$METHOD_NAME" != "switch" ] && [ "$METHOD_NAME" != "catch" ]; then
        PROJECT_DIR="$CLAUDE_PROJECT_DIR"
        if [ -z "$PROJECT_DIR" ]; then
            PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
        fi

        echo "Method signature change detected: $METHOD_NAME" >&2
        echo "Searching for other usages across the project..." >&2

        # Search for usages in extensions
        USAGES=$(grep -rnl "$METHOD_NAME" \
            "$PROJECT_DIR/extensions/" \
            --include="*.java" --include="*.groovy" --include="*.kt" \
            2>/dev/null | grep -v "$(basename "$FILE_PATH")" | head -15)

        # Search in Groovy scripts
        GROOVY_USAGES=$(grep -rnl "$METHOD_NAME" \
            "$PROJECT_DIR/app/src-groovy/" \
            --include="*.groovy" \
            2>/dev/null | head -5)

        # Search in .proc files (embedded scripts)
        PROC_USAGES=$(grep -rl "$METHOD_NAME" \
            "$PROJECT_DIR/app/diagrams/" \
            --include="*.proc" \
            2>/dev/null | head -5)

        if [ -n "$USAGES" ] || [ -n "$GROOVY_USAGES" ] || [ -n "$PROC_USAGES" ]; then
            echo "" >&2
            echo "WARNING: Method '$METHOD_NAME' is also used in these files:" >&2
            if [ -n "$USAGES" ]; then
                echo "  [Extensions]" >&2
                echo "$USAGES" | sed 's/^/    /' >&2
            fi
            if [ -n "$GROOVY_USAGES" ]; then
                echo "  [Groovy Scripts]" >&2
                echo "$GROOVY_USAGES" | sed 's/^/    /' >&2
            fi
            if [ -n "$PROC_USAGES" ]; then
                echo "  [Process Definitions]" >&2
                echo "$PROC_USAGES" | sed 's/^/    /' >&2
            fi
            echo "" >&2
            echo "Consider updating these files to match the new signature. Use /refactor-method-signature for automated updates." >&2
        fi
    fi
fi

exit 0
