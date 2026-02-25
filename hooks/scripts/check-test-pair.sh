#!/bin/bash
# Hook: Post-edit - verify test pair exists for every source file
# Event: PostToolUse (Edit|Write)
# The library requires *Test.java AND *PropertyTest.java for every source class
# Exit 0 = informational only

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; fp=json.load(sys.stdin).get('tool_input',{}).get('file_path',''); print(fp)" 2>/dev/null)

# Only check main source Java files
if ! echo "$FILE_PATH" | grep -qE "src/main/java/.*\.java$"; then
    exit 0
fi

# Derive expected test paths
CLASS_NAME=$(basename "$FILE_PATH" .java)
RELATIVE=$(echo "$FILE_PATH" | sed 's|.*src/main/java/|src/test/java/|')
TEST_DIR=$(dirname "$RELATIVE")
UNIT_TEST="$TEST_DIR/${CLASS_NAME}Test.java"
PROP_TEST="$TEST_DIR/${CLASS_NAME}PropertyTest.java"

PROJECT_DIR="$CLAUDE_PROJECT_DIR"
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
fi

MISSING=""
if [ ! -f "$PROJECT_DIR/$UNIT_TEST" ]; then
    MISSING="$MISSING\n  - MISSING: $UNIT_TEST"
fi
if [ ! -f "$PROJECT_DIR/$PROP_TEST" ]; then
    MISSING="$MISSING\n  - MISSING: $PROP_TEST"
fi

if [ -n "$MISSING" ]; then
    echo "" >&2
    echo "WARNING: Test files required for $CLASS_NAME (per AGENTS.md):" >&2
    echo -e "$MISSING" >&2
    echo "" >&2
    echo "Every class MUST have both *Test.java and *PropertyTest.java." >&2
    echo "Use /generate-tests $CLASS_NAME to create them." >&2
    echo "" >&2
fi

exit 0
