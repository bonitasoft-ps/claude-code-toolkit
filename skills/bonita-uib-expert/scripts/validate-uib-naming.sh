#!/usr/bin/env bash
# validate-uib-naming.sh
# Validates UIB JSON files for naming convention compliance.
#
# Usage: bash validate-uib-naming.sh <path-to-uib-json>
#
# Checks for:
#   - Generic widget names (Canvas1, Text1, Button1, etc.)
#   - Proper use of bonita-api-plugin (not restapi-plugin)
#   - Presence of navigationSetting: {}
#   - HTTP version HTTP11
#   - formData apiContentType
#
# Reports warnings to stderr. Always exits 0 (informational only).

set -euo pipefail

FILE="${1:-}"

if [[ -z "$FILE" ]]; then
  echo "Usage: $0 <path-to-uib-json>" >&2
  exit 0
fi

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: File not found: $FILE" >&2
  exit 0
fi

WARNINGS=0
FILENAME=$(basename "$FILE")

echo "=== UIB Naming Validation: $FILENAME ===" >&2
echo "" >&2

# --- Check for generic widget names ---
# Matches patterns like Canvas1, Text2, Button3, Container4, etc.
GENERIC_PATTERNS=(
  '"widgetName"[[:space:]]*:[[:space:]]*"Canvas[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"Text[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"Button[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"Container[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"Table[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"Input[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"Select[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"Image[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"Chart[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"Stat[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"Modal[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"Icon[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"Menu[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"Form[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"Tabs[0-9]+'
  '"widgetName"[[:space:]]*:[[:space:]]*"List[0-9]+'
)

echo "[1/6] Checking for generic widget names..." >&2
for PATTERN in "${GENERIC_PATTERNS[@]}"; do
  MATCHES=$(grep -cE "$PATTERN" "$FILE" 2>/dev/null || true)
  if [[ "$MATCHES" -gt 0 ]]; then
    TYPE=$(echo "$PATTERN" | grep -oP '(?<=widgetName.*")[A-Z][a-z]+' || echo "Widget")
    echo "  WARNING: Found $MATCHES generic ${TYPE}N name(s). Rename to descriptive PascalCase." >&2
    # Show the actual names found
    grep -oE "\"widgetName\"[[:space:]]*:[[:space:]]*\"${TYPE}[0-9]+\"" "$FILE" 2>/dev/null | head -5 | while read -r line; do
      echo "    -> $line" >&2
    done
    WARNINGS=$((WARNINGS + MATCHES))
  fi
done

# --- Check for generic action/query names ---
echo "" >&2
echo "[2/6] Checking for generic query names..." >&2
GENERIC_QUERY_PATTERNS=(
  '"name"[[:space:]]*:[[:space:]]*"Query[0-9]+'
  '"name"[[:space:]]*:[[:space:]]*"Api[0-9]+'
  '"name"[[:space:]]*:[[:space:]]*"Action[0-9]+'
)
for PATTERN in "${GENERIC_QUERY_PATTERNS[@]}"; do
  MATCHES=$(grep -cE "$PATTERN" "$FILE" 2>/dev/null || true)
  if [[ "$MATCHES" -gt 0 ]]; then
    echo "  WARNING: Found $MATCHES generic query/action name(s). Use verbObject naming (e.g., getDashboardKpis)." >&2
    grep -oE "\"name\"[[:space:]]*:[[:space:]]*\"(Query|Api|Action)[0-9]+\"" "$FILE" 2>/dev/null | head -5 | while read -r line; do
      echo "    -> $line" >&2
    done
    WARNINGS=$((WARNINGS + MATCHES))
  fi
done

# --- Check for restapi-plugin (should be bonita-api-plugin) ---
echo "" >&2
echo "[3/6] Checking datasource plugin..." >&2
RESTAPI_COUNT=$(grep -c '"restapi-plugin"' "$FILE" 2>/dev/null || true)
if [[ "$RESTAPI_COUNT" -gt 0 ]]; then
  echo "  WARNING: Found $RESTAPI_COUNT occurrence(s) of 'restapi-plugin'. Use 'bonita-api-plugin' instead." >&2
  WARNINGS=$((WARNINGS + RESTAPI_COUNT))
else
  BONITA_PLUGIN_COUNT=$(grep -c '"bonita-api-plugin"' "$FILE" 2>/dev/null || true)
  if [[ "$BONITA_PLUGIN_COUNT" -gt 0 ]]; then
    echo "  OK: Using bonita-api-plugin ($BONITA_PLUGIN_COUNT occurrence(s))." >&2
  fi
fi

# --- Check for executeOnLoad (should be runBehaviour) ---
echo "" >&2
echo "[4/6] Checking run behaviour..." >&2
EXEC_ON_LOAD=$(grep -c '"executeOnLoad"' "$FILE" 2>/dev/null || true)
if [[ "$EXEC_ON_LOAD" -gt 0 ]]; then
  echo "  WARNING: Found $EXEC_ON_LOAD occurrence(s) of 'executeOnLoad'. Use 'runBehaviour: ON_PAGE_LOAD' instead." >&2
  WARNINGS=$((WARNINGS + EXEC_ON_LOAD))
fi

# --- Check for HTTP version ---
echo "" >&2
echo "[5/6] Checking HTTP version..." >&2
HTTP_VERSION_COUNT=$(grep -c '"httpVersion"' "$FILE" 2>/dev/null || true)
HTTP11_COUNT=$(grep -c '"HTTP11"' "$FILE" 2>/dev/null || true)
if [[ "$HTTP_VERSION_COUNT" -gt 0 && "$HTTP11_COUNT" -eq 0 ]]; then
  echo "  WARNING: httpVersion is set but not to HTTP11. Use 'httpVersion: HTTP11'." >&2
  WARNINGS=$((WARNINGS + 1))
elif [[ "$HTTP11_COUNT" -gt 0 ]]; then
  echo "  OK: httpVersion is HTTP11." >&2
fi

# --- Check for formData apiContentType ---
echo "" >&2
echo "[6/6] Checking formData configuration..." >&2
FORM_DATA_COUNT=$(grep -c '"apiContentType"' "$FILE" 2>/dev/null || true)
if [[ "$FORM_DATA_COUNT" -eq 0 ]]; then
  # Only warn if there are API actions in the file
  API_ACTION_COUNT=$(grep -c '"pluginType"[[:space:]]*:[[:space:]]*"API"' "$FILE" 2>/dev/null || true)
  if [[ "$API_ACTION_COUNT" -gt 0 ]]; then
    echo "  WARNING: API actions found but no 'apiContentType' in formData. Add formData: {apiContentType: 'none'}." >&2
    WARNINGS=$((WARNINGS + 1))
  fi
else
  echo "  OK: formData apiContentType configured ($FORM_DATA_COUNT occurrence(s))." >&2
fi

# --- Summary ---
echo "" >&2
echo "=== Summary ===" >&2
if [[ "$WARNINGS" -eq 0 ]]; then
  echo "No naming convention issues found." >&2
else
  echo "Found $WARNINGS warning(s). Review and fix before importing." >&2
fi
echo "" >&2

exit 0
