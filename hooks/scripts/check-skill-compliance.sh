#!/bin/bash
# =============================================================================
# check-skill-compliance.sh — Skills 2.0 Compliance Validator
#
# PostToolUse hook: runs after Write/Edit on any SKILL.md file.
# Validates that the skill follows Skills 2.0 best practices.
#
# Checks:
#   1. YAML frontmatter exists with required fields (name, description)
#   2. allowed-tools field is present
#   3. Skill is in a directory (not flat .md)
#   4. references/ directory exists
#   5. SKILL.md is under 500 lines
#   6. Has "When activated" section
#   7. Has persona/role description
# =============================================================================

set -euo pipefail

FILE_PATH="${TOOL_INPUT_FILE_PATH:-${1:-}}"

# Only check SKILL.md files
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

case "$FILE_PATH" in
  */SKILL.md) ;;
  *) exit 0 ;;
esac

if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

SKILL_DIR=$(dirname "$FILE_PATH")
SKILL_NAME=$(basename "$SKILL_DIR")
WARNINGS=""
ERRORS=""

# --- Check 1: YAML frontmatter ---
FIRST_LINE=$(head -1 "$FILE_PATH")
if [ "$FIRST_LINE" != "---" ]; then
  ERRORS="${ERRORS}\n  - Missing YAML frontmatter (file must start with ---)"
fi

# --- Check 2: Required frontmatter fields ---
HAS_NAME=$(head -20 "$FILE_PATH" | grep -c "^name:" || true)
HAS_DESC=$(head -20 "$FILE_PATH" | grep -c "^description:" || true)
HAS_TOOLS=$(head -20 "$FILE_PATH" | grep -c "^allowed-tools:" || true)

if [ "$HAS_NAME" -eq 0 ]; then
  ERRORS="${ERRORS}\n  - Missing 'name:' in frontmatter"
fi
if [ "$HAS_DESC" -eq 0 ]; then
  ERRORS="${ERRORS}\n  - Missing 'description:' in frontmatter"
fi
if [ "$HAS_TOOLS" -eq 0 ]; then
  WARNINGS="${WARNINGS}\n  - Missing 'allowed-tools:' (recommended: Read, Grep, Glob)"
fi

# --- Check 3: Directory structure (not flat file) ---
if [ "$SKILL_DIR" = "." ] || [ "$SKILL_DIR" = ".claude/skills" ]; then
  ERRORS="${ERRORS}\n  - SKILL.md must be inside a skill directory (skills/{name}/SKILL.md)"
fi

# --- Check 4: references/ directory ---
if [ ! -d "$SKILL_DIR/references" ]; then
  WARNINGS="${WARNINGS}\n  - No references/ directory (recommended for progressive disclosure)"
fi

# --- Check 5: Line count ---
LINE_COUNT=$(wc -l < "$FILE_PATH")
if [ "$LINE_COUNT" -gt 500 ]; then
  WARNINGS="${WARNINGS}\n  - SKILL.md is $LINE_COUNT lines (max recommended: 500). Move content to references/"
fi

# --- Check 6: "When activated" section ---
HAS_ACTIVATED=$(grep -c "## When activated" "$FILE_PATH" || true)
if [ "$HAS_ACTIVATED" -eq 0 ]; then
  WARNINGS="${WARNINGS}\n  - Missing '## When activated' section (recommended)"
fi

# --- Check 7: Persona/role ---
HAS_PERSONA=$(grep -ciE "(you are|expert in|specializing)" "$FILE_PATH" || true)
if [ "$HAS_PERSONA" -eq 0 ]; then
  WARNINGS="${WARNINGS}\n  - No persona/role found (recommend: 'You are a [Role]...')"
fi

# --- Output ---
if [ -n "$ERRORS" ]; then
  echo "SKILL 2.0 ERRORS in $SKILL_NAME/SKILL.md:"
  echo -e "$ERRORS"
  echo ""
  echo "Fix these before committing."
  exit 1
fi

if [ -n "$WARNINGS" ]; then
  echo "SKILL 2.0 WARNINGS for $SKILL_NAME/SKILL.md:"
  echo -e "$WARNINGS"
  echo ""
  echo "Consider fixing for full Skills 2.0 compliance."
fi

exit 0
