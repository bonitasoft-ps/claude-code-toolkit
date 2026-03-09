#!/bin/bash
# rag-index-reminder.sh - Remind to re-index RAG when knowledge files change
# Fires: PostToolUse on Write/Edit
# Behavior: Warns when knowledge/standards/templates files are created or modified,
#           reminding that the RAG vectordb in bonita-docs-toolkit may need updating.
#           The GitHub Action handles this automatically on push, but for local
#           development it's useful to run npm run index:knowledge manually.
# Scope: ★★☆ Personal — for PS toolkit repos with RAG-indexed knowledge

PYTHON_CMD="${PYTHON_CMD:-$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "python3")}"

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | $PYTHON_CMD -c "
import sys, json
try:
    data = json.load(sys.stdin)
    path = data.get('tool_input', {}).get('file_path', '')
    print(path)
except:
    print('')
" 2>/dev/null)

# Only trigger for knowledge-related directories
if ! echo "$FILE_PATH" | grep -qiE "(knowledge|standards|templates|guides)/.*\.md$"; then
    exit 0
fi

# Skip bonita-docs-toolkit's own files (it IS the RAG)
if echo "$FILE_PATH" | grep -qiE "bonita-docs-toolkit/"; then
    exit 0
fi

# Skip claude-project/ mirrors (not source knowledge)
if echo "$FILE_PATH" | grep -qiE "claude-project/"; then
    exit 0
fi

# Detect which source was modified
SOURCE="unknown"
if echo "$FILE_PATH" | grep -qiE "upgrade-toolkit"; then
    SOURCE="upgrade"
elif echo "$FILE_PATH" | grep -qiE "audit-toolkit"; then
    SOURCE="audit"
elif echo "$FILE_PATH" | grep -qiE "connectors.*toolkit"; then
    SOURCE="connectors"
else
    # Try to extract from path
    SOURCE=$(echo "$FILE_PATH" | $PYTHON_CMD -c "
import sys
path = sys.stdin.read().strip().replace('\\\\', '/')
parts = path.split('/')
for p in parts:
    if p.startswith('bonita-') and 'toolkit' in p:
        name = p.replace('bonita-', '').replace('-toolkit', '').replace('-generator', '')
        print(name)
        sys.exit(0)
print('unknown')
" 2>/dev/null)
fi

FILENAME=$(basename "$FILE_PATH")
echo "" >&2
echo "RAG: Knowledge file modified: $FILENAME (source: $SOURCE)" >&2
echo "The RAG vectordb will auto-update on push via GitHub Action." >&2
echo "For local testing: cd bonita-docs-toolkit && npm run index:knowledge -- --source $SOURCE" >&2
echo "" >&2

exit 0
