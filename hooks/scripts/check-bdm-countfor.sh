#!/bin/bash
# Hook: Post-edit BDM countFor validation
# Event: PostToolUse (Edit) - triggers when bom.xml is edited
# Purpose: After editing bom.xml, check for collection queries missing countFor
# Exit 0 = always allow (informational)

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# Only check bom.xml edits
if ! echo "$FILE_PATH" | grep -qiE "bom\.xml$"; then
    exit 0
fi

PROJECT_DIR="$CLAUDE_PROJECT_DIR"
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
fi

BOM_FILE="$PROJECT_DIR/bdm/bom.xml"
if [ ! -f "$BOM_FILE" ]; then
    exit 0
fi

# Use Python to analyze countFor compliance
python -c "
import xml.etree.ElementTree as ET
import sys

tree = ET.parse(r'$BOM_FILE')
root = tree.getroot()

list_queries = []
countfor_names = set()

for elem in root.iter():
    tag = elem.tag.split('}')[-1] if '}' in elem.tag else elem.tag
    if tag in ('query', 'customQuery'):
        qname = elem.get('name', '')
        qreturn = elem.get('returnType', '')
        # Find parent business object
        if qname:
            if qname.startswith('countFor'):
                countfor_names.add(qname)
            elif 'java.util.List' in qreturn:
                list_queries.append(qname)

missing = []
for qname in list_queries:
    expected = 'countFor' + qname[0].upper() + qname[1:]
    # Check exact match or base query match (OrderBy variants can reuse base countFor)
    base_name = qname.split('OrderBy')[0] if 'OrderBy' in qname else qname
    expected_base = 'countFor' + base_name[0].upper() + base_name[1:]
    if expected not in countfor_names and expected_base not in countfor_names:
        # Not even a partial match
        found = any(base_name in cf for cf in countfor_names)
        if not found:
            missing.append(qname)

if missing:
    print('', file=sys.stderr)
    print('BDM WARNING: Collection queries missing countFor counterpart:', file=sys.stderr)
    for q in missing:
        print(f'  - {q} (needs countFor{q[0].upper()}{q[1:]})', file=sys.stderr)
    print('', file=sys.stderr)
    print('Per project rule (02-datamodel.mdc): queries returning java.util.List', file=sys.stderr)
    print('MUST have a corresponding countFor query for REST API pagination.', file=sys.stderr)
    print('Note: OrderBy variants can reuse the base countFor query in code.', file=sys.stderr)
    print('', file=sys.stderr)
" 2>&1

exit 0
