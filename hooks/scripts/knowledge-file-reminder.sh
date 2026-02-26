#!/bin/bash
# knowledge-file-reminder.sh - Remind to sync claude-project when knowledge files change
# Fires: PostToolUse on Write/Edit
# Behavior: Warns when knowledge/ files are modified but claude-project/ may be out of sync
# Scope: ★★☆ Personal — for projects maintaining claude-project/ mirrors

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

# Only trigger for knowledge/ directory files
if ! echo "$FILE_PATH" | grep -qiE "knowledge/.*\.(md|json)$"; then
    exit 0
fi

# Skip if the change is already in claude-project/
if echo "$FILE_PATH" | grep -qiE "claude-project/"; then
    exit 0
fi

# Check if claude-project/ directory exists in the repo
CWD=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('cwd', ''))
except:
    print('')
" 2>/dev/null)

if [ -d "$CWD/claude-project" ]; then
    FILENAME=$(basename "$FILE_PATH")
    echo "" >&2
    echo "REMINDER: Knowledge file modified: $FILENAME" >&2
    echo "The claude-project/ folder may need syncing." >&2
    echo "Run /sync-claude-project to check and update." >&2
    echo "" >&2
fi

exit 0
