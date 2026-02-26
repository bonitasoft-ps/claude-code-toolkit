#!/bin/bash
# check-skill-structure.sh - Validate SKILL.md follows Anthropic methodology
# Fires: PostToolUse on Write/Edit
# Behavior: Warns if SKILL.md files don't follow the standard structure
# Scope: ★★★ Enterprise — ensure all skills follow consistent methodology

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

# Only check SKILL.md files
if [[ ! "$FILE_PATH" =~ SKILL\.md$ ]]; then
    exit 0
fi

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

CONTENT=$(cat "$FILE_PATH")
WARNINGS=""

# === FRONTMATTER CHECKS ===

# Check for YAML frontmatter
if ! echo "$CONTENT" | head -1 | grep -q '^---$'; then
    WARNINGS="${WARNINGS}✗ Missing YAML frontmatter (must start with ---)\n"
fi

# Check for 'name' field in frontmatter
if ! echo "$CONTENT" | grep -q '^name:'; then
    WARNINGS="${WARNINGS}✗ Missing required 'name' field in frontmatter\n"
else
    # Check name format (lowercase, numbers, hyphens only)
    SKILL_NAME=$(echo "$CONTENT" | grep '^name:' | head -1 | sed 's/name: *//')
    if echo "$SKILL_NAME" | grep -qP '[^a-z0-9\-]'; then
        WARNINGS="${WARNINGS}⚠ Skill name '${SKILL_NAME}' should only contain lowercase letters, numbers, and hyphens\n"
    fi
    # Check name length
    NAME_LEN=${#SKILL_NAME}
    if [ "$NAME_LEN" -gt 64 ]; then
        WARNINGS="${WARNINGS}⚠ Skill name exceeds 64 characters (current: ${NAME_LEN})\n"
    fi
    # Check for generic names
    if echo "$SKILL_NAME" | grep -qP '^(review|helper|expert|utils|tools|misc)$'; then
        WARNINGS="${WARNINGS}⚠ Skill name '${SKILL_NAME}' is too generic. Use [domain]-[purpose] format (e.g., bonita-review, java-helper)\n"
    fi
fi

# Check for 'description' field
if ! echo "$CONTENT" | grep -q '^description:'; then
    WARNINGS="${WARNINGS}✗ Missing required 'description' field in frontmatter\n"
else
    # Check description length
    DESC=$(echo "$CONTENT" | grep '^description:' | head -1 | sed 's/description: *//')
    DESC_LEN=${#DESC}
    if [ "$DESC_LEN" -gt 1024 ]; then
        WARNINGS="${WARNINGS}⚠ Description exceeds 1024 characters (current: ${DESC_LEN})\n"
    fi
    if [ "$DESC_LEN" -lt 20 ]; then
        WARNINGS="${WARNINGS}⚠ Description is too short (${DESC_LEN} chars). Should answer: What does it do? When should Claude use it?\n"
    fi
    # Check description answers "when" question
    if ! echo "$DESC" | grep -qi 'when\|use.*for\|use.*when\|trigger\|invoke\|asks about'; then
        WARNINGS="${WARNINGS}⚠ Description should explain WHEN to use this skill (e.g., 'Use when the user asks about...')\n"
    fi
fi

# === CONTENT STRUCTURE CHECKS ===

# Check for main heading
if ! echo "$CONTENT" | grep -q '^# '; then
    WARNINGS="${WARNINGS}⚠ Missing main heading (# Title)\n"
fi

# Check for 'When activated' section
if ! echo "$CONTENT" | grep -qi '## When activated\|## When Activated'; then
    WARNINGS="${WARNINGS}⚠ Missing '## When activated' section — should define what Claude reads/checks first\n"
fi

# Check for rules or patterns section
if ! echo "$CONTENT" | grep -qi '## .*[Rr]ules\|## .*[Pp]atterns\|## .*[Ss]tandards\|## Mandatory'; then
    WARNINGS="${WARNINGS}⚠ Missing rules/patterns section — should define mandatory rules or patterns to follow\n"
fi

# Check for workflow section
if ! echo "$CONTENT" | grep -qi '## When the user\|## Workflow\|## How to\|## Usage'; then
    WARNINGS="${WARNINGS}⚠ Missing workflow section — should define step-by-step actions (e.g., '## When the user asks about...')\n"
fi

# === SIZE CHECKS ===

LINE_COUNT=$(echo "$CONTENT" | wc -l)
if [ "$LINE_COUNT" -gt 500 ]; then
    WARNINGS="${WARNINGS}⚠ SKILL.md is ${LINE_COUNT} lines (max recommended: 500). Use references/ directory for detailed docs.\n"
fi

# === OUTPUT ===

if [ -n "$WARNINGS" ]; then
    echo -e "SKILL STRUCTURE CHECK [$FILE_PATH]:\n${WARNINGS}\nSkill methodology: https://github.com/bonitasoft-ps/claude-code-toolkit\nUse the skill-creator skill for guidance: describe what skill you need." >&2
fi

exit 0
