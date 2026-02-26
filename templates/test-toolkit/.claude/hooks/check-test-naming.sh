#!/bin/bash
# check-test-naming.sh - Validates test class naming conventions
# Fires: PostToolUse on Edit/Write
# Behavior: Warns if test class doesn't follow naming conventions
# Scope: ★☆☆ Project — Test Toolkit projects only

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    path = data.get('tool_input', {}).get('file_path', '')
    print(path)
except:
    print('')
" 2>/dev/null)

# Only check Java files in test directory
if [[ ! "$FILE_PATH" =~ /src/test/java/.*\.java$ ]]; then
    exit 0
fi

WARNINGS=""

BASENAME=$(basename "$FILE_PATH")
CLASS_NAME="${BASENAME%.java}"

# Integration test classes must end with IT
if grep -q "extends AbstractProcessTest" "$FILE_PATH" 2>/dev/null; then
    if [[ ! "$CLASS_NAME" =~ IT$ ]]; then
        WARNINGS+="⚠️  Test Naming: $CLASS_NAME extends AbstractProcessTest but doesn't end with 'IT'. Rename to ${CLASS_NAME}IT.java\n"
    fi
fi

# Check for @TestInstance annotation on IT classes
if [[ "$CLASS_NAME" =~ IT$ ]]; then
    if ! grep -q "@TestInstance" "$FILE_PATH" 2>/dev/null; then
        WARNINGS+="⚠️  Missing @TestInstance(TestInstance.Lifecycle.PER_CLASS) on $CLASS_NAME\n"
    fi
fi

# Check for @DisplayName on test classes
if [[ "$CLASS_NAME" =~ (IT|Test)$ ]]; then
    if ! grep -q "@DisplayName" "$FILE_PATH" 2>/dev/null; then
        WARNINGS+="⚠️  Missing @DisplayName on $CLASS_NAME\n"
    fi
fi

if [ -n "$WARNINGS" ]; then
    echo -e "$WARNINGS" >&2
fi

exit 0
