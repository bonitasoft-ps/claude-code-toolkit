#!/bin/bash
# check-test-structure.sh - Validates Bonita test structure conventions
# Fires: PostToolUse on Edit/Write
# Behavior: Warns about missing patterns in integration tests
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

# Only check Java IT test files
if [[ ! "$FILE_PATH" =~ /src/test/java/.*IT\.java$ ]]; then
    exit 0
fi

WARNINGS=""
BASENAME=$(basename "$FILE_PATH")

# Must extend AbstractProcessTest
if ! grep -q "extends AbstractProcessTest" "$FILE_PATH" 2>/dev/null; then
    WARNINGS+="⚠️  $BASENAME: Integration tests must extend AbstractProcessTest\n"
fi

# Should use AssertJ (not JUnit assertions)
if grep -q "import org.junit.jupiter.api.Assertions" "$FILE_PATH" 2>/dev/null; then
    WARNINGS+="⚠️  $BASENAME: Use AssertJ assertions instead of JUnit Assertions\n"
fi

# Check for Thread.sleep (should use Awaitility)
if grep -q "Thread.sleep" "$FILE_PATH" 2>/dev/null; then
    WARNINGS+="⚠️  $BASENAME: Use Awaitility instead of Thread.sleep() for async waiting\n"
fi

# Check for JUnit 4 annotations
if grep -q "import org.junit.Before\b\|import org.junit.After\b\|import org.junit.Test\b" "$FILE_PATH" 2>/dev/null; then
    WARNINGS+="⚠️  $BASENAME: Use JUnit 5 annotations (@BeforeEach, @AfterEach, @Test from jupiter)\n"
fi

# Test methods should follow naming convention
METHODS=$(grep -E '^\s+(void|public void)\s+\w+\(' "$FILE_PATH" 2>/dev/null | grep -v 'setUp\|tearDown\|deploy\|initialize' || true)
if [ -n "$METHODS" ]; then
    BAD_NAMES=$(echo "$METHODS" | grep -v 'should_.*_when_\|should_.*_for_\|should_' || true)
    if [ -n "$BAD_NAMES" ]; then
        WARNINGS+="⚠️  $BASENAME: Test methods should follow should_XXX_when_YYY() naming\n"
    fi
fi

if [ -n "$WARNINGS" ]; then
    echo -e "$WARNINGS" >&2
fi

exit 0
