#!/bin/bash
# Hook: Post-edit hardcoded strings detection
# Event: PostToolUse (Edit) - triggers when Java/Groovy files are edited
# Purpose: Detect hardcoded magic strings that should be constants
# Exit 0 = always allow (informational)

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
NEW_STRING=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('new_string',''))" 2>/dev/null)

# Only check Java and Groovy source files in extensions
if ! echo "$FILE_PATH" | grep -qiE "\.(java|groovy|kt)$"; then
    exit 0
fi
if ! echo "$FILE_PATH" | grep -qiE "extensions/"; then
    exit 0
fi
# Skip constants files, enums, and test files
if echo "$FILE_PATH" | grep -qiE "(constants/|Constants\.|enums/|Enum|/test/)"; then
    exit 0
fi

# Check the new_string for hardcoded string patterns
# Look for string literals in comparisons or assignments (not in log/exception messages)
python -c "
import re
import sys

new_string = '''$NEW_STRING'''

# Patterns that suggest hardcoded magic strings (not log messages)
# Match: \"word\".equals, .equals(\"word\"), == \"word\", case \"word\"
suspicious_patterns = [
    (r'\"([A-Z_]{3,})\"\.equals', 'status/type comparison'),
    (r'\.equals\(\"([a-zA-Z_]{3,})\"', 'string comparison'),
    (r'case\s+\"([a-zA-Z_]{3,})\"', 'switch case string'),
    (r'==\s*\"([a-zA-Z_]{3,})\"', 'direct string comparison'),
]

found = []
for pattern, desc in suspicious_patterns:
    matches = re.findall(pattern, new_string)
    for m in matches:
        # Skip common acceptable strings
        if m.lower() not in ('null', 'true', 'false', 'utf-8', 'utf8'):
            found.append((m, desc))

if found:
    print('', file=sys.stderr)
    print('NOTICE: Potential hardcoded magic strings detected:', file=sys.stderr)
    for value, desc in found:
        print(f'  - \"{value}\" ({desc})', file=sys.stderr)
    print('', file=sys.stderr)
    print('Consider using constants instead. Existing constant files:', file=sys.stderr)
    print('  - extensions/.../utils/constants/Constants.java', file=sys.stderr)
    print('  - extensions/.../utils/constants/ErrorMessages.java', file=sys.stderr)
    print('  - extensions/.../utils/constants/Messages.java', file=sys.stderr)
    print('  - Or add to process-builder-extension-library for cross-project reuse', file=sys.stderr)
    print('Use /create-constants to auto-extract them.', file=sys.stderr)
    print('', file=sys.stderr)
" 2>&1

exit 0
