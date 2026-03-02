#!/bin/bash
# check-docs-consistency.sh — PostToolUse hook for claude-code-toolkit
#
# Warns when documentation counts are stale.
# Detects drift between actual skill/command/hook/agent counts and documented numbers in README.md
#
# Triggered by: PostToolUse[Write|Edit] on SKILL.md, commands/*.md, hooks/scripts/*.sh, agents/*.md

PYTHON_CMD="${PYTHON_CMD:-$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "python3")}"

INPUT=$(cat)

# Extract file path from JSON input
FILE_PATH=$(echo "$INPUT" | $PYTHON_CMD -c "
import sys, json
try:
    data = json.load(sys.stdin)
    path = data.get('tool_input', {}).get('file_path', '')
    print(path)
except:
    print('')
" 2>/dev/null)

# Only trigger on relevant files
case "$FILE_PATH" in
  */skills/*/SKILL.md|*/commands/*.md|*/hooks/scripts/*.sh|*/agents/*.md) ;;
  *) exit 0 ;;
esac

# Locate repo root
REPO_DIR="${CLAUDE_PROJECT_DIR:-}"
if [[ -z "$REPO_DIR" ]] || [[ ! -f "$REPO_DIR/README.md" ]]; then
  dir="$FILE_PATH"
  while [[ "$dir" != "/" && "$dir" != "." ]]; do
    dir=$(dirname "$dir")
    if [[ -f "$dir/README.md" ]] && [[ -d "$dir/skills" ]]; then
      REPO_DIR="$dir"
      break
    fi
  done
fi

if [[ -z "$REPO_DIR" ]] || [[ ! -f "$REPO_DIR/README.md" ]]; then
  exit 0
fi

README="$REPO_DIR/README.md"
WARNINGS=""

# --- Count actual skills ---
ACTUAL_SKILLS=$(ls -d "$REPO_DIR/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')
README_SKILLS=$(grep -oE '\*\*Skills\*\*.*\| [0-9]+' "$README" | grep -oE '[0-9]+$' | head -1)

if [[ -n "$README_SKILLS" && "$ACTUAL_SKILLS" != "$README_SKILLS" ]]; then
  WARNINGS="${WARNINGS}\n  Skills: README says $README_SKILLS but skills/ has $ACTUAL_SKILLS"
fi

# --- Count actual commands (recursive, all .md files) ---
ACTUAL_COMMANDS=$(find "$REPO_DIR/commands" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
README_COMMANDS=$(grep -oE '\*\*Commands\*\*.*\| [0-9]+' "$README" | grep -oE '[0-9]+$' | head -1)

if [[ -n "$README_COMMANDS" && "$ACTUAL_COMMANDS" != "$README_COMMANDS" ]]; then
  WARNINGS="${WARNINGS}\n  Commands: README says $README_COMMANDS but commands/ has $ACTUAL_COMMANDS"
fi

# --- Count actual hooks ---
ACTUAL_HOOKS=$(ls "$REPO_DIR/hooks/scripts"/*.sh 2>/dev/null | wc -l | tr -d ' ')
README_HOOKS=$(grep -oE '\*\*Hooks\*\*.*\| [0-9]+' "$README" | grep -oE '[0-9]+$' | head -1)

if [[ -n "$README_HOOKS" && "$ACTUAL_HOOKS" != "$README_HOOKS" ]]; then
  WARNINGS="${WARNINGS}\n  Hooks: README says $README_HOOKS but hooks/scripts/ has $ACTUAL_HOOKS"
fi

# --- Count actual agents (excluding README.md) ---
ACTUAL_AGENTS=$(ls "$REPO_DIR/agents"/*.md 2>/dev/null | grep -v README | wc -l | tr -d ' ')
README_AGENTS=$(grep -oE '\*\*Agents\*\*.*\| [0-9]+' "$README" | grep -oE '[0-9]+$' | head -1)

if [[ -n "$README_AGENTS" && "$ACTUAL_AGENTS" != "$README_AGENTS" ]]; then
  WARNINGS="${WARNINGS}\n  Agents: README says $README_AGENTS but agents/ has $ACTUAL_AGENTS"
fi

# --- Report ---
if [[ -n "$WARNINGS" ]]; then
  echo ""
  echo "DOCS CONSISTENCY CHECK — Documentation Drift Detected (claude-code-toolkit)"
  echo -e "$WARNINGS"
  echo ""
  echo "  Please update README.md 'How many' column to reflect current counts."
  echo ""
fi

exit 0
