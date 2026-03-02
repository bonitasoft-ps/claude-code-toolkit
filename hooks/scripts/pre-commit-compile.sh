#!/bin/bash
# Hook: Pre-commit compilation check
# Event: PreToolUse (Bash)
# Purpose: Run mvn compile before git commit to ensure project stability
# Exit 0 = allow, Exit 2 = block
# Skip: set SKIP_COMPILE=1 to bypass

PYTHON_CMD="${PYTHON_CMD:-$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "python3")}"

# Allow skipping compilation
if [ "${SKIP_COMPILE:-0}" = "1" ]; then
    exit 0
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | "$PYTHON_CMD" -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

# Only intercept git commit commands
if ! echo "$COMMAND" | grep -qE "git\s+commit"; then
    exit 0
fi

PROJECT_DIR="$CLAUDE_PROJECT_DIR"
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
fi

# Only compile if pom.xml exists
if [ ! -f "$PROJECT_DIR/pom.xml" ]; then
    exit 0
fi

# Only compile if .java files are staged
if ! (cd "$PROJECT_DIR" && git diff --cached --name-only 2>/dev/null | grep -qE '\.java$'); then
    exit 0
fi

echo "Pre-commit hook: Running mvn compile (Java files staged)..." >&2

# Run Maven compile (without clean for speed)
MVN_OUTPUT=$(cd "$PROJECT_DIR" && mvn compile -q 2>&1)
MVN_EXIT=$?

if [ $MVN_EXIT -ne 0 ]; then
    echo "BLOCKED: Maven compilation failed. Fix the following errors before committing:" >&2
    echo "" >&2
    echo "$MVN_OUTPUT" | grep -E "^\[ERROR\]" | head -20 >&2
    echo "" >&2
    echo "Run /compile-project for full details. Set SKIP_COMPILE=1 to bypass." >&2
    exit 2
fi

echo "Pre-commit hook: Compilation successful. Proceeding with commit." >&2
exit 0
