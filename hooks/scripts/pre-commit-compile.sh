#!/bin/bash
# Hook: Pre-commit compilation check
# Event: PreToolUse (Bash)
# Purpose: Run mvn clean compile before any git commit to ensure project stability
# Exit 0 = allow, Exit 2 = block

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

# Only intercept git commit commands
if ! echo "$COMMAND" | grep -qE "git\s+commit"; then
    exit 0
fi

PROJECT_DIR="$CLAUDE_PROJECT_DIR"
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
fi

echo "Pre-commit hook: Running mvn clean compile to verify project stability..." >&2

# Run Maven clean compile
MVN_OUTPUT=$(cd "$PROJECT_DIR" && mvn clean compile 2>&1)
MVN_EXIT=$?

if [ $MVN_EXIT -ne 0 ]; then
    echo "BLOCKED: Maven compilation failed. Fix the following errors before committing:" >&2
    echo "" >&2
    # Extract only ERROR lines for a concise summary
    echo "$MVN_OUTPUT" | grep -E "^\[ERROR\]" | head -20 >&2
    echo "" >&2
    echo "Run /compile-project for full details." >&2
    exit 2
fi

echo "Pre-commit hook: Compilation successful. Proceeding with commit." >&2
exit 0
