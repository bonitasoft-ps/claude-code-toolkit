#!/bin/bash
# check-document-pattern.sh - Detect document generation without corporate branding
# Fires: PostToolUse on Edit/Write
# Behavior: Warns if document generation code doesn't follow corporate pattern
# Scope: ★★★ Enterprise — enforce corporate branding in all documents

INPUT=$(cat)

# Extract file path from JSON input
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    path = data.get('tool_input', {}).get('file_path', '')
    print(path)
except:
    print('')
" 2>/dev/null)

# Only check Java files
if [[ ! "$FILE_PATH" =~ \.java$ ]]; then
    exit 0
fi

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Check if file contains document generation imports
HAS_DOC_IMPORTS=false
DOC_LIBS=""

if grep -q 'import com.lowagie\|import com.github.librepdf\|import org.xhtmlrenderer\|import com.openpdf' "$FILE_PATH" 2>/dev/null; then
    HAS_DOC_IMPORTS=true
    DOC_LIBS="${DOC_LIBS}OpenPDF/Flying Saucer (PDF), "
fi

if grep -q 'import org.apache.poi' "$FILE_PATH" 2>/dev/null; then
    HAS_DOC_IMPORTS=true
    DOC_LIBS="${DOC_LIBS}Apache POI (Word/Excel), "
fi

if grep -q 'import com.itextpdf' "$FILE_PATH" 2>/dev/null; then
    HAS_DOC_IMPORTS=true
    DOC_LIBS="${DOC_LIBS}iText (WARNING: use OpenPDF instead for license reasons), "
fi

if grep -q 'import org.thymeleaf' "$FILE_PATH" 2>/dev/null; then
    # Thymeleaf alone is fine, but check if used for document output
    if grep -q 'pdf\|PDF\|document\|Document\|report\|Report\|export\|Export' "$FILE_PATH" 2>/dev/null; then
        HAS_DOC_IMPORTS=true
        DOC_LIBS="${DOC_LIBS}Thymeleaf (HTML templates), "
    fi
fi

# If no document generation code found, exit silently
if [ "$HAS_DOC_IMPORTS" = false ]; then
    exit 0
fi

# Remove trailing comma
DOC_LIBS=$(echo "$DOC_LIBS" | sed 's/, $//')

WARNINGS=""

# Check for BrandingConfig usage
if ! grep -q 'BrandingConfig' "$FILE_PATH" 2>/dev/null; then
    WARNINGS="${WARNINGS}⚠ Document generation detected (${DOC_LIBS}) but BrandingConfig is not referenced.\n  All documents MUST use BrandingConfig constants for colors, fonts, and logos.\n"
fi

# Check for hardcoded hex colors (common in document generation)
HARDCODED_COLORS=$(grep -n '#[0-9a-fA-F]\{6\}' "$FILE_PATH" 2>/dev/null | grep -v '^\s*//' | grep -v 'BrandingConfig' | grep -v 'static final' | head -5)
if [ -n "$HARDCODED_COLORS" ]; then
    COLOR_LINES=$(echo "$HARDCODED_COLORS" | cut -d: -f1 | tr '\n' ', ' | sed 's/,$//')
    WARNINGS="${WARNINGS}⚠ Hardcoded hex colors found at lines ${COLOR_LINES}.\n  Use BrandingConfig constants (PRIMARY_COLOR, SECONDARY_COLOR, etc.) instead.\n"
fi

# Check for hardcoded font names
if grep -n '"Arial"\|"Helvetica"\|"Times New Roman"\|"Courier"\|"Verdana"' "$FILE_PATH" 2>/dev/null | grep -v 'BrandingConfig\|FONT_FAMILY\|static final' > /dev/null 2>&1; then
    WARNINGS="${WARNINGS}⚠ Hardcoded font names detected. Use BrandingConfig.FONT_FAMILY instead.\n"
fi

# Check for iText usage (license warning)
if grep -q 'import com.itextpdf' "$FILE_PATH" 2>/dev/null; then
    WARNINGS="${WARNINGS}⚠ iText library detected. Use OpenPDF (com.github.librepdf:openpdf) instead to avoid AGPL license issues.\n"
fi

# Check for string concatenation to build HTML (should use Thymeleaf)
if grep -n 'StringBuilder\|StringBuffer\|"<html"\|"<body"\|"<table"\|"<div"' "$FILE_PATH" 2>/dev/null | grep -v 'test\|Test\|spec\|Spec' > /dev/null 2>&1; then
    if grep -q 'pdf\|PDF\|document\|Document\|report\|Report\|export\|Export' "$FILE_PATH" 2>/dev/null; then
        WARNINGS="${WARNINGS}⚠ HTML string concatenation detected in document generation code.\n  Use Thymeleaf templates instead of building HTML with StringBuilder.\n"
    fi
fi

# Output warnings if any
if [ -n "$WARNINGS" ]; then
    echo -e "DOCUMENT BRANDING CHECK [$FILE_PATH]:\n${WARNINGS}\nCorporate standard: All documents must use BrandingConfig + Thymeleaf templates + corporate.css.\nUse /generate-document to scaffold a compliant document service." >&2
fi

exit 0
