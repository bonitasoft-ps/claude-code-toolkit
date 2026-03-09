#!/bin/bash
# sync-claude-project.sh — Sync claude-project/ folders using .claude-project-sync.json manifests
# Usage: sync-claude-project.sh [--all | <repo-path>]
# Dependencies: node (for JSON parsing, no jq needed)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPOS=(
  "/c/PSProjects/bonita-upgrade-toolkit"
  "/c/PSProjects/bonita-audit-toolkit"
  "/c/PSProjects/bonita-connectors-generator-toolkit"
  "/c/PSProjects/bonita-docs-toolkit"
  "/c/PSProjects/template-test-toolkit"
  "/c/PSProjects/bonita-ai-agent-mcp"
  "/c/PSProjects/claude-code-toolkit"
)

# Convert Git Bash path (/c/...) to Windows path (c:/...) for Node.js
to_node_path() {
  echo "$1" | sed 's|^/\([a-zA-Z]\)/|\1:/|'
}

sync_repo() {
  local REPO_PATH="$1"
  local MANIFEST="$REPO_PATH/.claude-project-sync.json"

  if [ ! -f "$MANIFEST" ]; then
    echo -e "${YELLOW}SKIP${NC} $(basename "$REPO_PATH"): no .claude-project-sync.json"
    return 0
  fi

  # Parse entire manifest in one node call — outputs pipe-separated lines
  local NODE_PATH
  NODE_PATH=$(to_node_path "$MANIFEST")
  local PARSED
  PARSED=$(node -e "
    const d=JSON.parse(require('fs').readFileSync('$NODE_PATH','utf8'));
    console.log('META|'+d.repo+'|'+d.label);
    (d.mappings||[]).forEach(m=>console.log('MAP|'+(m.source||'')+'|'+(m.target||'')+'|'+(m.glob||'')+'|'+(m.type||'directory')));
  " 2>/dev/null)

  local REPO_NAME LABEL
  REPO_NAME=$(echo "$PARSED" | grep "^META" | cut -d'|' -f2)
  LABEL=$(echo "$PARSED" | grep "^META" | cut -d'|' -f3)

  local TOTAL=0 MODIFIED=0 NEW=0 UNCHANGED=0

  while IFS='|' read -r TAG SOURCE TARGET GLOB TYPE; do
    [ "$TAG" = "MAP" ] || continue

    if [ "$TYPE" = "file" ]; then
      local SRC_FILE="$REPO_PATH/$SOURCE"
      local DST_FILE="$REPO_PATH/$TARGET"
      TOTAL=$((TOTAL + 1))

      if [ ! -f "$SRC_FILE" ]; then
        continue
      fi
      if [ ! -f "$DST_FILE" ]; then
        mkdir -p "$(dirname "$DST_FILE")"
        cp "$SRC_FILE" "$DST_FILE"
        NEW=$((NEW + 1))
      elif ! diff -q "$SRC_FILE" "$DST_FILE" > /dev/null 2>&1; then
        cp "$SRC_FILE" "$DST_FILE"
        MODIFIED=$((MODIFIED + 1))
      else
        UNCHANGED=$((UNCHANGED + 1))
      fi
    else
      local SRC_DIR="$REPO_PATH/$SOURCE"
      local DST_DIR="$REPO_PATH/$TARGET"

      if [ ! -d "$SRC_DIR" ]; then
        continue
      fi

      mkdir -p "$DST_DIR"

      for SRC_FILE in "$SRC_DIR"$GLOB; do
        [ -f "$SRC_FILE" ] || continue
        local FILENAME
        FILENAME=$(basename "$SRC_FILE")
        local DST_FILE="$DST_DIR$FILENAME"
        TOTAL=$((TOTAL + 1))

        if [ ! -f "$DST_FILE" ]; then
          cp "$SRC_FILE" "$DST_FILE"
          NEW=$((NEW + 1))
        elif ! diff -q "$SRC_FILE" "$DST_FILE" > /dev/null 2>&1; then
          cp "$SRC_FILE" "$DST_FILE"
          MODIFIED=$((MODIFIED + 1))
        else
          UNCHANGED=$((UNCHANGED + 1))
        fi
      done
    fi
  done <<< "$PARSED"

  if [ $NEW -eq 0 ] && [ $MODIFIED -eq 0 ]; then
    echo -e "${GREEN}OK${NC}   [$LABEL] $REPO_NAME: $TOTAL files checked, all in sync"
  else
    echo -e "${YELLOW}SYNC${NC} [$LABEL] $REPO_NAME: $NEW new, $MODIFIED modified, $UNCHANGED unchanged (of $TOTAL total)"
    echo -e "     Remember to update claude-project/CHANGELOG.md"
  fi

  return $((NEW + MODIFIED))
}

# Main
if [ "$1" = "--all" ] || [ -z "$1" ]; then
  echo "=== Claude Project Sync ==="
  echo ""
  TOTAL_CHANGES=0
  for REPO in "${REPOS[@]}"; do
    sync_repo "$REPO" || TOTAL_CHANGES=$((TOTAL_CHANGES + $?))
  done
  echo ""
  if [ $TOTAL_CHANGES -eq 0 ]; then
    echo -e "${GREEN}All repos in sync!${NC}"
  else
    echo -e "${YELLOW}$TOTAL_CHANGES files need attention across repos${NC}"
  fi
else
  sync_repo "$1"
fi
