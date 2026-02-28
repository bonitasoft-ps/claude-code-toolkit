#!/bin/bash
# Hook: Safe git workflow — prevent direct commits/pushes to protected branches
# Event: PreToolUse (Bash)
# Purpose: Enforce branch-based PR workflow for all Claude Code sessions.
#          All changes must go through a claude/{type}/{description} branch + PR.
# Exit 0 = allow, Exit 2 = block
# Scope: Enterprise (★★★) — applies to all repos

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

# Only intercept git commit and git push commands
if ! echo "$COMMAND" | grep -qE "git\s+(commit|push)"; then
    exit 0
fi

# Extract working directory
CWD=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('cwd', ''))
except:
    print('')
" 2>/dev/null)

if [ -z "$CWD" ]; then
    CWD="$CLAUDE_PROJECT_DIR"
fi

# Not a git repo — allow
if ! cd "$CWD" 2>/dev/null || ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

# Get current branch (empty on detached HEAD — allow)
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
if [ -z "$CURRENT_BRANCH" ]; then
    exit 0
fi

# Check if on a protected branch
PROTECTED_BRANCHES="main master develop"
IS_PROTECTED=false
for branch in $PROTECTED_BRANCHES; do
    if [ "$CURRENT_BRANCH" = "$branch" ]; then
        IS_PROTECTED=true
        break
    fi
done

# If not on a protected branch, allow
if [ "$IS_PROTECTED" = false ]; then
    exit 0
fi

# Determine command type for a more specific error message
IS_COMMIT=false
IS_PUSH=false
echo "$COMMAND" | grep -qE "git\s+commit" && IS_COMMIT=true
echo "$COMMAND" | grep -qE "git\s+push" && IS_PUSH=true

if [ "$IS_COMMIT" = true ]; then
    echo "" >&2
    echo "BLOCKED: Direct commit to '$CURRENT_BRANCH' is not allowed." >&2
    echo "" >&2
    echo "You MUST create a feature branch first. Follow the safe-git-workflow:" >&2
    echo "  1. git checkout -b claude/{type}/{short-description}" >&2
    echo "     Types: feat, fix, docs, refactor, test, chore" >&2
    echo "  2. Stage and commit on the new branch" >&2
    echo "  3. git push -u origin claude/{type}/{short-description}" >&2
    echo "  4. gh pr create --base $CURRENT_BRANCH --title \"...\" --body \"...\"" >&2
    echo "" >&2
    exit 2
fi

if [ "$IS_PUSH" = true ]; then
    echo "" >&2
    echo "BLOCKED: Direct push to '$CURRENT_BRANCH' is not allowed." >&2
    echo "" >&2
    echo "You are on a protected branch. Create a feature branch first:" >&2
    echo "  git checkout -b claude/{type}/{short-description}" >&2
    echo "Then commit, push the branch, and create a PR." >&2
    echo "" >&2
    exit 2
fi

exit 0
