#!/bin/bash
# Hook: Post-edit - warn about missing OpenAPI/Swagger annotations on controllers
# Event: PostToolUse (Edit|Write)
# Purpose: Ensure REST API controllers have proper API documentation annotations
# Exit 0 = informational only (warnings via stderr)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; fp=json.load(sys.stdin).get('tool_input',{}).get('file_path',''); print(fp)" 2>/dev/null)

# Only check Java files
if ! echo "$FILE_PATH" | grep -qE "\.java$"; then
    exit 0
fi

# Only check files that look like controllers (contain RestApiController or extend Abstract*Controller)
if ! grep -qE "(implements\s+RestApiController|extends\s+Abstract\w*Controller)" "$FILE_PATH" 2>/dev/null; then
    exit 0
fi

# Skip abstract classes themselves
if grep -qE "^\s*public\s+abstract\s+class" "$FILE_PATH" 2>/dev/null; then
    exit 0
fi

# Skip test files
if echo "$FILE_PATH" | grep -qE "src/test/"; then
    exit 0
fi

WARNINGS=""

# Check for @Api or @Tag annotation (Swagger/OpenAPI class-level)
if ! grep -qE "(@Api\b|@Tag\b)" "$FILE_PATH" 2>/dev/null; then
    WARNINGS="$WARNINGS\n  - Missing @Api or @Tag annotation on controller class"
fi

# Check for @Operation or @ApiOperation on methods
if ! grep -qE "(@Operation\b|@ApiOperation\b)" "$FILE_PATH" 2>/dev/null; then
    WARNINGS="$WARNINGS\n  - Missing @Operation annotations on endpoint methods"
fi

# Check for @ApiResponse annotations
if ! grep -qE "@ApiResponse" "$FILE_PATH" 2>/dev/null; then
    WARNINGS="$WARNINGS\n  - Missing @ApiResponse annotations (document status codes: 200, 400, 500)"
fi

if [ -n "$WARNINGS" ]; then
    CLASS_NAME=$(basename "$FILE_PATH" .java)
    echo "" >&2
    echo "WARNING: Controller '$CLASS_NAME' is missing OpenAPI documentation:" >&2
    echo -e "$WARNINGS" >&2
    echo "" >&2
    echo "Per bonita-rest-api-expert standards, all controllers should have:" >&2
    echo "  - @Tag(name = \"...\") on the class" >&2
    echo "  - @Operation(summary = \"...\") on endpoint methods" >&2
    echo "  - @ApiResponse annotations for each HTTP status code" >&2
    echo "" >&2
fi

exit 0
