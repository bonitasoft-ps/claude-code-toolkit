#!/bin/bash
# Hook: Pre-Write controller README.md check
# Event: PreToolUse (Write)
# Purpose: When creating a new Java file in a controller directory,
#          warn if README.md is missing in that controller package
# Exit 0 = allow (informational only)

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# Only check Java files in controller directories
if ! echo "$FILE_PATH" | grep -qiE "controller/.*\.java$"; then
    exit 0
fi

# Extract the controller directory
CONTROLLER_DIR=$(dirname "$FILE_PATH")

# Check if README.md exists in the controller directory
if [ ! -f "$CONTROLLER_DIR/README.md" ]; then
    echo "" >&2
    echo "WARNING: Controller directory is missing README.md documentation!" >&2
    echo "  Directory: $CONTROLLER_DIR" >&2
    echo "  Per AGENTS.md section 5, every controller package MUST have a README.md." >&2
    echo "  Use /generate-readme to create one after adding the controller." >&2
    echo "" >&2
fi

exit 0
