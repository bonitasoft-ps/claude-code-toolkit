#!/usr/bin/env bash
# =============================================================================
# setup-claude-code-user.sh — Configure Claude Code user-level settings
# =============================================================================
#
# What it does:
#   1. Creates ~/.claude/settings.json with smart permissions (read/test/git without prompts)
#   2. Creates ~/.claude/CLAUDE.md with global user instructions for Bonitasoft PS
#   3. Enables experimental Agent Teams feature
#   4. Installs Playwright MCP server for browser automation
#
# Why:
#   Claude Code asks permission for every file read, git status, and test run by default.
#   This script pre-approves safe, read-only operations so you can work fluidly without
#   constant interruptions. Write/commit/push operations still require approval.
#
# Usage:
#   bash setup-claude-code-user.sh
#
# Safe to re-run: backs up existing files before overwriting.
# =============================================================================

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
INSTRUCTIONS_FILE="$CLAUDE_DIR/CLAUDE.md"

echo "============================================"
echo "  Claude Code — User Settings Setup"
echo "============================================"
echo ""

# Create .claude directory if needed
mkdir -p "$CLAUDE_DIR"

# --- 1. settings.json ---
if [ -f "$SETTINGS_FILE" ]; then
  BACKUP="$SETTINGS_FILE.backup.$(date +%s)"
  cp "$SETTINGS_FILE" "$BACKUP"
  echo "[backup] Existing settings.json backed up to: $BACKUP"
fi

cat > "$SETTINGS_FILE" << 'SETTINGS_EOF'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(ls *)",
      "Bash(find *)",
      "Bash(cat *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(wc *)",
      "Bash(du *)",
      "Bash(git status*)",
      "Bash(git log*)",
      "Bash(git diff*)",
      "Bash(git branch*)",
      "Bash(git remote*)",
      "Bash(git show*)",
      "Bash(npm test*)",
      "Bash(npm run test*)",
      "Bash(node --test*)",
      "Bash(mvn test*)",
      "Bash(mvn compile*)",
      "Bash(mvn verify*)",
      "Bash(npm run check*)",
      "Bash(npm run lint*)",
      "Bash(npm run build*)"
    ],
    "deny": []
  },
  "autoUpdatesChannel": "latest"
}
SETTINGS_EOF

echo "[ok] settings.json created with smart permissions"

# --- 2. CLAUDE.md (global user instructions) ---
if [ -f "$INSTRUCTIONS_FILE" ]; then
  BACKUP="$INSTRUCTIONS_FILE.backup.$(date +%s)"
  cp "$INSTRUCTIONS_FILE" "$BACKUP"
  echo "[backup] Existing CLAUDE.md backed up to: $BACKUP"
fi

cat > "$INSTRUCTIONS_FILE" << 'INSTRUCTIONS_EOF'
# Claude Code — Global User Instructions (Bonitasoft PS)

## Language and communication

- Default conversation language: user's preference (Spanish/English/French)
- Technical documentation always in English
- Concise and direct responses
- No emojis unless explicitly requested

## Permissions and autonomy

- **Read files without asking**: Any text file, source code, config, logs, or docs
- **Search without asking**: Glob, Grep, and codebase searches are always allowed
- **Run tests without asking**: npm test, mvn test, node --test
- **Git read-only without asking**: git status, git log, git diff, git branch
- **Ask permission for**: git commit, git push, create/delete files, install deps, destructive scripts

## Work style

- **Parallel execution**: Launch agents and tasks in parallel whenever possible
- **Be proactive**: Fix issues directly within allowed permissions
- **No over-engineering**: Simple, direct solutions with minimal code
- **Java 17**: Records, Sealed Classes, Pattern Matching
- **Node.js**: ES Modules, async/await, node --test
- **Tests**: JUnit 5 (Java), node --test (Node.js), naming: should_X_when_Y()

## Bonitasoft PS context

- Professional Services team: upgrades, audits, connectors, tests, training
- 7-repo ecosystem with MCP server (57 tools)
- Bonita versions: 7.x legacy, 2021+ modern (year.release format)
- Connector lifecycle: VALIDATE → CONNECT → EXECUTE → DISCONNECT

## Sensitive files

- NEVER commit: .env, credentials.json, *.pem, *.key
- Proposals/pricing: LOCAL only, never in remote repos
- Customer data: Never expose in commits or logs
INSTRUCTIONS_EOF

echo "[ok] CLAUDE.md created with global instructions"

# --- 3. Install Playwright MCP ---
echo ""
echo "Installing Playwright MCP server for browser automation..."
if command -v claude &> /dev/null; then
  claude mcp add playwright -- npx @playwright/mcp@latest 2>/dev/null && \
    echo "[ok] Playwright MCP installed for Claude Code" || \
    echo "[warn] Could not install Playwright MCP via CLI. Add manually to Claude Desktop config."
else
  echo "[skip] Claude Code CLI not found. Install Playwright MCP manually:"
  echo "       claude mcp add playwright -- npx @playwright/mcp@latest"
fi

# --- Summary ---
echo ""
echo "============================================"
echo "  Setup Complete"
echo "============================================"
echo ""
echo "  Settings:     $SETTINGS_FILE"
echo "  Instructions: $INSTRUCTIONS_FILE"
echo ""
echo "  What's enabled:"
echo "    - Read/search files without prompts"
echo "    - Run tests without prompts"
echo "    - Git read-only without prompts"
echo "    - Agent Teams experimental feature"
echo "    - Playwright MCP (browser automation)"
echo ""
echo "  What still requires approval:"
echo "    - git commit, git push"
echo "    - Creating/deleting files"
echo "    - Installing dependencies"
echo "    - Running unknown scripts"
echo ""
echo "  Restart Claude Code or VS Code for changes to take effect."
