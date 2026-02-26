#!/bin/bash
# =============================================================================
# scaffold-skill.sh
# Creates the directory structure and template SKILL.md for a new Claude Code skill.
#
# Usage: bash scaffold-skill.sh <skill-name> [enterprise|personal|project] [description]
#
# Arguments:
#   $1 - Skill name (kebab-case, e.g., "bonita-connector-expert")
#   $2 - Scope: "enterprise", "personal", or "project" (default: "project")
#   $3 - Optional description for the skill
#
# Examples:
#   bash scaffold-skill.sh my-review-prefs personal
#   bash scaffold-skill.sh bonita-connector-expert enterprise "Connector development patterns"
#   bash scaffold-skill.sh loan-api-docs project "Loan Request API documentation"
# =============================================================================

set -euo pipefail

SKILL_NAME="${1:-}"
SCOPE="${2:-project}"
DESCRIPTION="${3:-}"

# --- Validation ---
if [ -z "$SKILL_NAME" ]; then
  echo "ERROR: Skill name is required."
  echo "Usage: bash scaffold-skill.sh <skill-name> [enterprise|personal|project] [description]"
  exit 1
fi

# Validate name format (lowercase, numbers, hyphens only)
if ! echo "$SKILL_NAME" | grep -qE '^[a-z][a-z0-9-]*$'; then
  echo "ERROR: Skill name must be lowercase letters, numbers, and hyphens only."
  echo "  Got: '$SKILL_NAME'"
  echo "  Example: 'bonita-connector-expert', 'my-review-prefs'"
  exit 1
fi

# Check name length
if [ ${#SKILL_NAME} -gt 64 ]; then
  echo "ERROR: Skill name must be 64 characters or less (got ${#SKILL_NAME})."
  exit 1
fi

# --- Determine target directory based on scope ---
case "$SCOPE" in
  enterprise)
    # Enterprise skills go to the toolkit AND the project
    TOOLKIT_DIR="${CLAUDE_PROJECT_DIR:-.}/../../../JavaProjects/claude-code-toolkit/skills/$SKILL_NAME"
    TARGET_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/skills/$SKILL_NAME"
    echo "SCOPE: Enterprise (toolkit + project)"
    ;;
  personal)
    TARGET_DIR="$HOME/.claude/skills/$SKILL_NAME"
    TOOLKIT_DIR=""
    echo "SCOPE: Personal (~/.claude/skills/)"
    ;;
  project)
    TARGET_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/skills/$SKILL_NAME"
    TOOLKIT_DIR=""
    echo "SCOPE: Project (.claude/skills/)"
    ;;
  *)
    echo "ERROR: Invalid scope '$SCOPE'. Use: enterprise, personal, or project"
    exit 1
    ;;
esac

# --- Check if skill already exists ---
if [ -d "$TARGET_DIR" ]; then
  echo "WARNING: Skill directory already exists: $TARGET_DIR"
  echo "  Use Edit tool to modify the existing SKILL.md instead."
  exit 1
fi

# --- Create directory structure ---
echo ""
echo "Creating skill: $SKILL_NAME"
echo "  Target: $TARGET_DIR"

mkdir -p "$TARGET_DIR"
mkdir -p "$TARGET_DIR/references"
mkdir -p "$TARGET_DIR/scripts"
mkdir -p "$TARGET_DIR/assets"

# --- Generate default description if not provided ---
if [ -z "$DESCRIPTION" ]; then
  # Convert kebab-case to readable words
  READABLE_NAME=$(echo "$SKILL_NAME" | sed 's/-/ /g')
  DESCRIPTION="Use when the user asks about $READABLE_NAME. Provides expert guidance and patterns."
fi

# --- Create SKILL.md template ---
cat > "$TARGET_DIR/SKILL.md" << SKILLEOF
---
name: $SKILL_NAME
description: $DESCRIPTION
allowed-tools: Read, Grep, Glob
---

# $(echo "$SKILL_NAME" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g') Expert

Brief description of the expert role. What does this skill do and why does it exist?

## When activated

1. **Read project context**: Check \`AGENTS.md\` or \`CLAUDE.md\` for project-specific information
2. **Scan existing code**: Use Glob and Grep to find relevant files and patterns
3. **Load references**: Read \`references/\` files for detailed guidance when needed

## Mandatory Rules

### Rule Category 1

- Rule with explanation and rationale
- Another rule with code example:

\`\`\`java
// GOOD: Example of the correct pattern
public Record MyDto(String name, int value) {}

// BAD: Anti-pattern to avoid
public class MyDto { /* mutable fields */ }
\`\`\`

### Rule Category 2

- Rule with explanation
- Another rule

## Progressive Disclosure

For detailed patterns, read the appropriate reference file:

- **Detailed rules and examples**: Read \`references/detailed-rules.md\`

## When the user asks about [topic]

1. Check existing patterns in the codebase
2. Apply the mandatory rules above
3. Provide a working code example
4. Verify the result compiles: \`mvn clean compile\`
SKILLEOF

# --- Create placeholder reference file ---
cat > "$TARGET_DIR/references/detailed-rules.md" << REFEOF
# Detailed Rules and Examples

## Section 1: [Topic]

Detailed explanation with code examples...

## Section 2: [Topic]

More detailed patterns...
REFEOF

# --- Summary ---
echo ""
echo "============================================="
echo "  Skill Scaffolded Successfully!"
echo "============================================="
echo ""
echo "  Name:   $SKILL_NAME"
echo "  Scope:  $SCOPE"
echo "  Path:   $TARGET_DIR"
echo ""
echo "  Files created:"
echo "    $TARGET_DIR/SKILL.md                    (template - EDIT THIS)"
echo "    $TARGET_DIR/references/detailed-rules.md (placeholder)"
echo "    $TARGET_DIR/scripts/                     (empty - add scripts)"
echo "    $TARGET_DIR/assets/                      (empty - add templates)"
echo ""
echo "  Next steps:"
echo "    1. Edit SKILL.md with your rules and patterns"
echo "    2. Add detailed docs to references/"
echo "    3. Add validation scripts to scripts/"
echo "    4. Add templates/assets to assets/"
echo "    5. Restart Claude Code and test the skill"

if [ "$SCOPE" = "enterprise" ] && [ -n "$TOOLKIT_DIR" ]; then
  echo ""
  echo "  Enterprise skill: Also copy to toolkit:"
  echo "    cp -r $TARGET_DIR $TOOLKIT_DIR"
  echo "    Then update README.md and push to GitHub"
fi

echo ""
echo "============================================="
