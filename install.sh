#!/bin/bash
# ============================================================================
# Claude Code Toolkit — Installer
# https://github.com/bonitasoft-ps/claude-code-toolkit
#
# Interactive installer that copies resources to the right scope.
# Usage: bash install.sh
# ============================================================================

set -e

TOOLKIT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     Claude Code Toolkit — Bonitasoft Methodology        ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "This installer copies resources from the toolkit to the right location."
echo -e "Resources are organized by ${BOLD}scope${NC} (Enterprise > Personal > Project)."
echo ""

# ─── Step 1: Choose scope ───────────────────────────────────────────────────
echo -e "${CYAN}Step 1: Choose installation scope${NC}"
echo ""
echo -e "  ${BOLD}1) Enterprise${NC} ★★★  — Organization-wide, cannot be overridden"
echo -e "     Installs: hooks, configs, skills to system path"
echo ""
echo -e "  ${BOLD}2) Personal${NC}   ★★☆  — Your home directory, all projects"
echo -e "     Installs: commands to ~/.claude/commands/"
echo ""
echo -e "  ${BOLD}3) Project${NC}    ★☆☆  — This project's .claude/ directory"
echo -e "     Installs: commands, hooks, skills, configs, templates"
echo ""
read -p "Choose scope [1/2/3]: " SCOPE

# ─── Functions ──────────────────────────────────────────────────────────────

install_enterprise() {
    echo ""
    echo -e "${YELLOW}★★★ Enterprise Installation${NC}"
    echo -e "This requires administrator privileges."
    echo ""

    # Detect OS
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        MANAGED_DIR="/c/ProgramData/ClaudeCode"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        MANAGED_DIR="/Library/Application Support/ClaudeCode"
    else
        MANAGED_DIR="/etc/claude-code"
    fi

    echo -e "Managed settings path: ${BOLD}$MANAGED_DIR${NC}"
    echo ""

    echo -e "${BLUE}Enterprise resources to install:${NC}"
    echo "  - configs/checkstyle.xml        (code style rules)"
    echo "  - configs/pmd-ruleset.xml       (static analysis)"
    echo "  - configs/.editorconfig         (editor formatting)"
    echo "  - hooks: pre-commit-compile, check-code-format, check-code-style, check-hardcoded-strings"
    echo "  - skills: bonita-bdm-expert, bonita-rest-api-expert"
    echo ""
    read -p "Continue? [y/N]: " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Aborted."; exit 0
    fi

    echo ""
    echo -e "${GREEN}Creating directory: $MANAGED_DIR${NC}"
    mkdir -p "$MANAGED_DIR" 2>/dev/null || {
        echo -e "${RED}Permission denied. Run with sudo or as Administrator.${NC}"
        exit 1
    }

    # Copy configs
    echo -e "  Copying checkstyle.xml..."
    cp "$TOOLKIT_DIR/configs/checkstyle.xml" "$MANAGED_DIR/"
    echo -e "  Copying pmd-ruleset.xml..."
    cp "$TOOLKIT_DIR/configs/pmd-ruleset.xml" "$MANAGED_DIR/"
    echo -e "  Copying .editorconfig..."
    cp "$TOOLKIT_DIR/configs/.editorconfig" "$MANAGED_DIR/"

    # Copy hook scripts
    mkdir -p "$MANAGED_DIR/hooks"
    for hook in pre-commit-compile.sh check-code-format.sh check-code-style.sh check-hardcoded-strings.sh; do
        echo -e "  Copying hooks/$hook..."
        cp "$TOOLKIT_DIR/hooks/scripts/$hook" "$MANAGED_DIR/hooks/"
    done
    chmod +x "$MANAGED_DIR/hooks/"*.sh 2>/dev/null || true

    # Copy skills
    mkdir -p "$MANAGED_DIR/skills"
    echo -e "  Copying skills/bonita-bdm-expert..."
    cp -r "$TOOLKIT_DIR/skills/bonita-bdm-expert" "$MANAGED_DIR/skills/"
    echo -e "  Copying skills/bonita-rest-api-expert..."
    cp -r "$TOOLKIT_DIR/skills/bonita-rest-api-expert" "$MANAGED_DIR/skills/"

    # Generate managed-settings.json if it doesn't exist
    if [ ! -f "$MANAGED_DIR/managed-settings.json" ]; then
        echo -e "  Creating managed-settings.json..."
        cat > "$MANAGED_DIR/managed-settings.json" << 'SETTINGS_EOF'
{
  "_comment": "Enterprise managed settings for Bonitasoft. Cannot be overridden by users.",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"MANAGED_DIR/hooks/pre-commit-compile.sh\""
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"MANAGED_DIR/hooks/check-code-format.sh\""
          },
          {
            "type": "command",
            "command": "bash \"MANAGED_DIR/hooks/check-code-style.sh\""
          },
          {
            "type": "command",
            "command": "bash \"MANAGED_DIR/hooks/check-hardcoded-strings.sh\""
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"MANAGED_DIR/hooks/check-code-format.sh\""
          },
          {
            "type": "command",
            "command": "bash \"MANAGED_DIR/hooks/check-code-style.sh\""
          }
        ]
      }
    ]
  }
}
SETTINGS_EOF
        # Replace MANAGED_DIR placeholder with actual path
        sed -i "s|MANAGED_DIR|$MANAGED_DIR|g" "$MANAGED_DIR/managed-settings.json" 2>/dev/null || \
        sed -i '' "s|MANAGED_DIR|$MANAGED_DIR|g" "$MANAGED_DIR/managed-settings.json" 2>/dev/null || true
    fi

    echo ""
    echo -e "${GREEN}★★★ Enterprise installation complete!${NC}"
    echo -e "Managed settings: ${BOLD}$MANAGED_DIR/managed-settings.json${NC}"
    echo -e "Restart Claude Code to apply changes."
}

install_personal() {
    echo ""
    echo -e "${YELLOW}★★☆ Personal Installation${NC}"
    echo ""

    CLAUDE_HOME="$HOME/.claude"
    echo -e "Installing to: ${BOLD}$CLAUDE_HOME${NC}"
    echo ""

    echo -e "${BLUE}Personal resources to install:${NC}"
    echo "  Commands (available in ALL your projects):"
    echo "    - /compile, /run-tests, /run-mutation-tests"
    echo "    - /generate-tests, /check-coverage"
    echo "    - /check-code-quality, /audit-compliance"
    echo "    - /refactor-method-signature, /create-constants"
    echo ""
    read -p "Continue? [y/N]: " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Aborted."; exit 0
    fi

    echo ""
    mkdir -p "$CLAUDE_HOME/commands"

    # Copy productivity commands
    echo -e "  Copying java-maven commands..."
    cp "$TOOLKIT_DIR/commands/java-maven/"* "$CLAUDE_HOME/commands/"

    echo -e "  Copying quality commands..."
    cp "$TOOLKIT_DIR/commands/quality/"* "$CLAUDE_HOME/commands/"

    echo -e "  Copying testing commands..."
    cp "$TOOLKIT_DIR/commands/testing/"* "$CLAUDE_HOME/commands/"

    echo ""
    echo -e "${GREEN}★★☆ Personal installation complete!${NC}"
    echo -e "Commands installed to: ${BOLD}$CLAUDE_HOME/commands/${NC}"
    echo ""
    echo "Installed commands:"
    ls -1 "$CLAUDE_HOME/commands/"*.md 2>/dev/null | while read f; do
        echo "  /$(basename "$f" .md)"
    done
    echo ""
    echo -e "Restart Claude Code to use them."
}

install_project() {
    echo ""
    echo -e "${YELLOW}★☆☆ Project Installation${NC}"
    echo ""

    read -p "Project directory path [.]: " PROJECT_DIR
    PROJECT_DIR="${PROJECT_DIR:-.}"
    PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

    echo ""
    echo -e "Installing to: ${BOLD}$PROJECT_DIR/.claude/${NC}"
    echo ""

    # Choose project type
    echo -e "${CYAN}Step 2: Choose project type${NC}"
    echo ""
    echo -e "  ${BOLD}1) Bonita BPM${NC}  — REST API extensions, BDM, processes"
    echo -e "  ${BOLD}2) Java Library${NC} — Shared library with unit + property tests"
    echo -e "  ${BOLD}3) Generic Java${NC} — Standard Java/Maven project"
    echo ""
    read -p "Choose type [1/2/3]: " PROJECT_TYPE

    echo ""
    read -p "Continue? [y/N]: " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Aborted."; exit 0
    fi

    echo ""
    mkdir -p "$PROJECT_DIR/.claude/commands"
    mkdir -p "$PROJECT_DIR/.claude/hooks"
    mkdir -p "$PROJECT_DIR/.claude/skills"

    # ─── Common for all project types ───
    echo -e "  Copying enterprise hook scripts..."
    for hook in pre-commit-compile.sh check-code-format.sh check-code-style.sh check-hardcoded-strings.sh; do
        cp "$TOOLKIT_DIR/hooks/scripts/$hook" "$PROJECT_DIR/.claude/hooks/"
    done

    echo -e "  Copying config files to project root..."
    cp "$TOOLKIT_DIR/configs/checkstyle.xml" "$PROJECT_DIR/"
    cp "$TOOLKIT_DIR/configs/pmd-ruleset.xml" "$PROJECT_DIR/"
    cp "$TOOLKIT_DIR/configs/.editorconfig" "$PROJECT_DIR/"

    echo -e "  Copying skills..."
    cp -r "$TOOLKIT_DIR/skills/bonita-bdm-expert" "$PROJECT_DIR/.claude/skills/"
    cp -r "$TOOLKIT_DIR/skills/bonita-rest-api-expert" "$PROJECT_DIR/.claude/skills/"

    case "$PROJECT_TYPE" in
        1)
            echo -e "  Copying Bonita BPM commands..."
            cp "$TOOLKIT_DIR/commands/bonita/"* "$PROJECT_DIR/.claude/commands/"

            echo -e "  Copying Bonita-specific hooks..."
            cp "$TOOLKIT_DIR/hooks/scripts/check-bdm-countfor.sh" "$PROJECT_DIR/.claude/hooks/"
            cp "$TOOLKIT_DIR/hooks/scripts/check-controller-readme.sh" "$PROJECT_DIR/.claude/hooks/"
            cp "$TOOLKIT_DIR/hooks/scripts/check-method-usages.sh" "$PROJECT_DIR/.claude/hooks/"

            echo -e "  Copying Bonita settings template..."
            cp "$TOOLKIT_DIR/templates/bonita-project.json" "$PROJECT_DIR/.claude/settings.json"
            ;;
        2)
            echo -e "  Copying library-specific hooks..."
            cp "$TOOLKIT_DIR/hooks/scripts/check-test-pair.sh" "$PROJECT_DIR/.claude/hooks/"

            echo -e "  Copying Java library settings template..."
            cp "$TOOLKIT_DIR/templates/java-library.json" "$PROJECT_DIR/.claude/settings.json"
            ;;
        3)
            echo -e "  Copying generic settings..."
            # Create minimal settings.json
            cat > "$PROJECT_DIR/.claude/settings.json" << 'GENERIC_EOF'
{
  "_comment": "Claude Code settings for Java project. Generated by claude-code-toolkit installer.",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/pre-commit-compile.sh\""
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/check-code-format.sh\""
          },
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/check-code-style.sh\""
          },
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/check-hardcoded-strings.sh\""
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/check-code-format.sh\""
          },
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/check-code-style.sh\""
          }
        ]
      }
    ]
  }
}
GENERIC_EOF
            ;;
    esac

    # Make all hooks executable
    chmod +x "$PROJECT_DIR/.claude/hooks/"*.sh 2>/dev/null || true

    # Copy CLAUDE.md template if none exists
    if [ ! -f "$PROJECT_DIR/CLAUDE.md" ]; then
        echo -e "  Creating CLAUDE.md from template..."
        cp "$TOOLKIT_DIR/templates/CLAUDE.md.template" "$PROJECT_DIR/CLAUDE.md"
    else
        echo -e "  CLAUDE.md already exists, skipping."
    fi

    echo ""
    echo -e "${GREEN}★☆☆ Project installation complete!${NC}"
    echo ""
    echo "Installed to $PROJECT_DIR:"
    echo "  .claude/commands/  — $(ls -1 "$PROJECT_DIR/.claude/commands/"*.md 2>/dev/null | wc -l) commands"
    echo "  .claude/hooks/     — $(ls -1 "$PROJECT_DIR/.claude/hooks/"*.sh 2>/dev/null | wc -l) hooks"
    echo "  .claude/skills/    — $(ls -1d "$PROJECT_DIR/.claude/skills/"*/ 2>/dev/null | wc -l) skills"
    echo "  .claude/settings.json"
    echo "  checkstyle.xml, pmd-ruleset.xml, .editorconfig"
    if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
        echo "  CLAUDE.md"
    fi
    echo ""
    echo -e "Next steps:"
    echo -e "  1. ${BOLD}Customize${NC} CLAUDE.md for your project"
    echo -e "  2. ${BOLD}Commit${NC}: git add .claude/ checkstyle.xml pmd-ruleset.xml .editorconfig CLAUDE.md"
    echo -e "  3. ${BOLD}Restart${NC} Claude Code"
}

# ─── Execute the chosen function ────────────────────────────────────────────
# (Functions are defined above, but bash reads the whole file first)
case "$SCOPE" in
    1) install_enterprise ;;
    2) install_personal ;;
    3) install_project ;;
esac
