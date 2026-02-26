#!/bin/bash
# pre-push-validate.sh - Validate project state before git push
# Fires: PreToolUse on Bash (intercepts git push)
# Behavior: Blocks push if critical issues detected
# Scope: ★★★ Enterprise — prevents pushing broken code
# Exit 0 = allow, Exit 2 = block

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

# Only intercept git push commands
if ! echo "$COMMAND" | grep -qE "git\s+push"; then
    exit 0
fi

CWD=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('cwd', ''))
except:
    print('')
" 2>/dev/null)

ISSUES=0
WARNINGS=""

# Check 1: Uncommitted changes
UNCOMMITTED=$(cd "$CWD" && git status --porcelain 2>/dev/null | wc -l)
if [ "$UNCOMMITTED" -gt 0 ]; then
    WARNINGS="$WARNINGS\n  - $UNCOMMITTED uncommitted file(s) detected"
    # This is a warning, not a blocker
fi

# Check 2: Maven project compiles (if pom.xml exists)
if [ -f "$CWD/pom.xml" ]; then
    MVN_OUTPUT=$(cd "$CWD" && mvn compile -q -Dmaven.test.skip=true 2>&1)
    if [ $? -ne 0 ]; then
        echo "" >&2
        echo "BLOCKED: Project does not compile. Fix before pushing:" >&2
        echo "$MVN_OUTPUT" | grep -E "^\[ERROR\]" | head -10 >&2
        echo "" >&2
        exit 2
    fi
fi

# Check 3: No TODO/FIXME in staged files (warning only)
TODOS=$(cd "$CWD" && git diff --cached --name-only 2>/dev/null | xargs grep -l "TODO\|FIXME\|HACK\|XXX" 2>/dev/null | wc -l)
if [ "$TODOS" -gt 0 ]; then
    WARNINGS="$WARNINGS\n  - $TODOS file(s) contain TODO/FIXME markers"
fi

# Check 4: No .env or credentials files staged
SENSITIVE=$(cd "$CWD" && git diff --cached --name-only 2>/dev/null | grep -iE "(\.env|credentials|secret|password|token)" | head -5)
if [ -n "$SENSITIVE" ]; then
    echo "" >&2
    echo "BLOCKED: Sensitive files detected in commit:" >&2
    echo "$SENSITIVE" >&2
    echo "Remove these files from staging before pushing." >&2
    echo "" >&2
    exit 2
fi

# Report warnings (non-blocking)
if [ -n "$WARNINGS" ]; then
    echo "" >&2
    echo "Pre-push warnings:" >&2
    echo -e "$WARNINGS" >&2
    echo "Proceeding with push..." >&2
    echo "" >&2
fi

exit 0
