#!/bin/bash
# sync-claude-project.sh — Sync claude-project/ folders using .claude-project-sync.json manifests
# Usage: sync-claude-project.sh [--all | <repo-path>]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REPOS=(
  "/c/PSProjects/bonita-upgrade-toolkit"
  "/c/PSProjects/bonita-audit-toolkit"
  "/c/PSProjects/bonita-connectors-generator-toolkit"
  "/c/PSProjects/bonita-docs-toolkit"
  "/c/PSProjects/template-test-toolkit"
  "/c/PSProjects/bonita-ps-mcp"
  "/c/PSProjects/claude-code-toolkit"
)

sync_repo() {
  local REPO_PATH="$1"
  local MANIFEST="$REPO_PATH/.claude-project-sync.json"

  if [ ! -f "$MANIFEST" ]; then
    echo -e "${YELLOW}SKIP${NC} $(basename "$REPO_PATH"): no .claude-project-sync.json"
    return 0
  fi

  local REPO_NAME
  REPO_NAME=$(jq -r '.repo' "$MANIFEST")
  local LABEL
  LABEL=$(jq -r '.label' "$MANIFEST")

  local TOTAL=0
  local MODIFIED=0
  local NEW=0
  local UNCHANGED=0

  # Process direct file mappings
  local MAPPING_COUNT
  MAPPING_COUNT=$(jq '.mappings | length' "$MANIFEST")

  for i in $(seq 0 $((MAPPING_COUNT - 1))); do
    local SOURCE TARGET GLOB TYPE
    SOURCE=$(jq -r ".mappings[$i].source" "$MANIFEST")
    TARGET=$(jq -r ".mappings[$i].target" "$MANIFEST")
    GLOB=$(jq -r ".mappings[$i].glob // empty" "$MANIFEST")
    TYPE=$(jq -r ".mappings[$i].type // \"directory\"" "$MANIFEST")

    if [ "$TYPE" = "file" ]; then
      # Single file mapping
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
      # Directory mapping with glob
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
  done

  # Summary
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
