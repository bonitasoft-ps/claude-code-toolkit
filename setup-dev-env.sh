#!/usr/bin/env bash
# =============================================================================
# setup-dev-env.sh — Claude Code Developer Environment Setup
# =============================================================================
#
# Non-interactive script that configures a developer's Claude Code environment
# using the claude-code-toolkit resources.
#
# Usage:
#   bash setup-dev-env.sh                      # Configure personal + current project
#   bash setup-dev-env.sh --personal           # Personal scope only (~/.claude/)
#   bash setup-dev-env.sh --project /path/to   # Project scope only
#   bash setup-dev-env.sh --project-type bonita # Bonita BPM project type
#   bash setup-dev-env.sh --project-type library # Java library type
#   bash setup-dev-env.sh --project-type generic # Generic Java type
#   bash setup-dev-env.sh --list               # Show what would be installed
#   bash setup-dev-env.sh --help               # Show help
#
# What it does:
#   - Personal: Installs commands to ~/.claude/commands/ (available everywhere)
#   - Project:  Installs hooks, skills, configs, settings to .claude/ (per-project)
#
# This is a NON-INTERACTIVE alternative to install.sh.
# For interactive installation with prompts, use: bash install.sh
# =============================================================================

set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Defaults
INSTALL_PERSONAL=false
INSTALL_PROJECT=false
PROJECT_DIR=""
PROJECT_TYPE="bonita"
LIST_ONLY=false

# -----------------------------------------------------------------------------
# Parse arguments
# -----------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case $1 in
        --personal)
            INSTALL_PERSONAL=true
            shift
            ;;
        --project)
            INSTALL_PROJECT=true
            if [[ -n "${2:-}" && "${2:-}" != --* ]]; then
                PROJECT_DIR="$2"
                shift
            fi
            shift
            ;;
        --project-type)
            PROJECT_TYPE="${2:-bonita}"
            shift 2
            ;;
        --list)
            LIST_ONLY=true
            shift
            ;;
        --help|-h)
            echo "Usage: bash setup-dev-env.sh [OPTIONS]"
            echo ""
            echo "Non-interactive Claude Code environment setup."
            echo ""
            echo "Options:"
            echo "  --personal              Install commands to ~/.claude/ (all projects)"
            echo "  --project [PATH]        Install hooks/skills/configs to project .claude/"
            echo "  --project-type TYPE     Project type: bonita (default), library, generic"
            echo "  --list                  Show what would be installed without installing"
            echo "  --help                  Show this help"
            echo ""
            echo "If no scope flag is given, both personal and project are installed."
            echo ""
            echo "Examples:"
            echo "  bash setup-dev-env.sh                              # Full setup"
            echo "  bash setup-dev-env.sh --personal                   # Commands only"
            echo "  bash setup-dev-env.sh --project ~/my-bonita-app    # Project only"
            echo "  bash setup-dev-env.sh --project . --project-type library"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Run with --help for usage."
            exit 1
            ;;
    esac
done

# If no scope specified, do both
if [ "$INSTALL_PERSONAL" = false ] && [ "$INSTALL_PROJECT" = false ]; then
    INSTALL_PERSONAL=true
    INSTALL_PROJECT=true
fi

# Default project dir
if [ "$INSTALL_PROJECT" = true ] && [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="."
fi

# -----------------------------------------------------------------------------
# List mode
# -----------------------------------------------------------------------------

if [ "$LIST_ONLY" = true ]; then
    echo -e "${BOLD}Claude Code Toolkit — Available Resources${NC}"
    echo ""

    echo -e "${CYAN}Personal Commands (~/.claude/commands/):${NC}"
    for dir in "$TOOLKIT_DIR/commands/"*/; do
        category=$(basename "$dir")
        echo -e "  ${BOLD}$category:${NC}"
        for f in "$dir"*.md; do
            [ -f "$f" ] && echo "    /$(basename "$f" .md)"
        done
    done

    echo ""
    echo -e "${CYAN}Hook Scripts (.claude/hooks/):${NC}"
    for f in "$TOOLKIT_DIR/hooks/scripts/"*.sh; do
        echo "  $(basename "$f")"
    done

    echo ""
    echo -e "${CYAN}Skills (.claude/skills/):${NC}"
    for d in "$TOOLKIT_DIR/skills/"*/; do
        [ -d "$d" ] && echo "  $(basename "$d")/"
    done

    echo ""
    echo -e "${CYAN}Configs (project root):${NC}"
    for f in "$TOOLKIT_DIR/configs/"*; do
        echo "  $(basename "$f")"
    done

    echo ""
    echo -e "${CYAN}Templates (.claude/):${NC}"
    for f in "$TOOLKIT_DIR/templates/"*; do
        echo "  $(basename "$f")"
    done
    exit 0
fi

# -----------------------------------------------------------------------------
# Header
# -----------------------------------------------------------------------------

echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║   Claude Code Toolkit — Developer Environment Setup     ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# -----------------------------------------------------------------------------
# Personal installation
# -----------------------------------------------------------------------------

if [ "$INSTALL_PERSONAL" = true ]; then
    CLAUDE_HOME="$HOME/.claude"
    echo -e "${CYAN}[Personal]${NC} Installing commands to ${BOLD}$CLAUDE_HOME/commands/${NC}"

    mkdir -p "$CLAUDE_HOME/commands"

    count=0
    for dir in "$TOOLKIT_DIR/commands/"*/; do
        if [ -d "$dir" ]; then
            for f in "$dir"*.md; do
                if [ -f "$f" ]; then
                    cp "$f" "$CLAUDE_HOME/commands/"
                    count=$((count + 1))
                fi
            done
        fi
    done

    echo -e "  ${GREEN}✓${NC} $count commands installed"
    echo ""
fi

# -----------------------------------------------------------------------------
# Project installation
# -----------------------------------------------------------------------------

if [ "$INSTALL_PROJECT" = true ]; then
    PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
    echo -e "${CYAN}[Project]${NC} Installing to ${BOLD}$PROJECT_DIR/.claude/${NC} (type: $PROJECT_TYPE)"

    mkdir -p "$PROJECT_DIR/.claude/hooks"
    mkdir -p "$PROJECT_DIR/.claude/skills"

    # --- Common hooks (all project types) ---
    common_hooks=(
        "check-code-format.sh"
        "check-code-style.sh"
        "check-hardcoded-strings.sh"
        "check-skill-structure.sh"
        "pre-commit-compile.sh"
    )
    hook_count=0
    for hook in "${common_hooks[@]}"; do
        if [ -f "$TOOLKIT_DIR/hooks/scripts/$hook" ]; then
            cp "$TOOLKIT_DIR/hooks/scripts/$hook" "$PROJECT_DIR/.claude/hooks/"
            hook_count=$((hook_count + 1))
        fi
    done

    # --- Project-type specific hooks ---
    case "$PROJECT_TYPE" in
        bonita)
            bonita_hooks=(
                "check-bdm-countfor.sh"
                "check-controller-readme.sh"
                "check-method-usages.sh"
                "check-openapi-annotations.sh"
            )
            for hook in "${bonita_hooks[@]}"; do
                if [ -f "$TOOLKIT_DIR/hooks/scripts/$hook" ]; then
                    cp "$TOOLKIT_DIR/hooks/scripts/$hook" "$PROJECT_DIR/.claude/hooks/"
                    hook_count=$((hook_count + 1))
                fi
            done
            ;;
        library)
            if [ -f "$TOOLKIT_DIR/hooks/scripts/check-test-pair.sh" ]; then
                cp "$TOOLKIT_DIR/hooks/scripts/check-test-pair.sh" "$PROJECT_DIR/.claude/hooks/"
                hook_count=$((hook_count + 1))
            fi
            ;;
    esac

    chmod +x "$PROJECT_DIR/.claude/hooks/"*.sh 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} $hook_count hooks installed"

    # --- Skills ---
    skill_count=0
    for skill_dir in "$TOOLKIT_DIR/skills/"*/; do
        if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
            skill_name=$(basename "$skill_dir")
            cp -r "$skill_dir" "$PROJECT_DIR/.claude/skills/"
            skill_count=$((skill_count + 1))
        fi
    done
    echo -e "  ${GREEN}✓${NC} $skill_count skills installed"

    # --- Configs ---
    config_count=0
    # .editorconfig always
    if [ -f "$TOOLKIT_DIR/configs/.editorconfig" ]; then
        cp "$TOOLKIT_DIR/configs/.editorconfig" "$PROJECT_DIR/"
        config_count=$((config_count + 1))
    fi
    # checkstyle + pmd for Java projects
    if [ -f "$TOOLKIT_DIR/configs/checkstyle.xml" ]; then
        cp "$TOOLKIT_DIR/configs/checkstyle.xml" "$PROJECT_DIR/"
        config_count=$((config_count + 1))
    fi
    if [ -f "$TOOLKIT_DIR/configs/pmd-ruleset.xml" ]; then
        cp "$TOOLKIT_DIR/configs/pmd-ruleset.xml" "$PROJECT_DIR/"
        config_count=$((config_count + 1))
    fi
    echo -e "  ${GREEN}✓${NC} $config_count config files installed"

    # --- Settings.json (only if doesn't exist) ---
    if [ ! -f "$PROJECT_DIR/.claude/settings.json" ]; then
        case "$PROJECT_TYPE" in
            bonita)
                if [ -f "$TOOLKIT_DIR/templates/bonita-project.json" ]; then
                    cp "$TOOLKIT_DIR/templates/bonita-project.json" "$PROJECT_DIR/.claude/settings.json"
                fi
                ;;
            library)
                if [ -f "$TOOLKIT_DIR/templates/java-library.json" ]; then
                    cp "$TOOLKIT_DIR/templates/java-library.json" "$PROJECT_DIR/.claude/settings.json"
                fi
                ;;
            *)
                cat > "$PROJECT_DIR/.claude/settings.json" << 'SETTINGS_EOF'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/check-code-format.sh\"",
            "timeout": 5000
          },
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/check-code-style.sh\"",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
SETTINGS_EOF
                ;;
        esac
        echo -e "  ${GREEN}✓${NC} settings.json created"
    else
        echo -e "  ${YELLOW}⚠${NC} settings.json already exists (not overwritten)"
    fi

    # --- CLAUDE.md (only if doesn't exist) ---
    if [ ! -f "$PROJECT_DIR/CLAUDE.md" ]; then
        if [ -f "$TOOLKIT_DIR/templates/CLAUDE.md.template" ]; then
            cp "$TOOLKIT_DIR/templates/CLAUDE.md.template" "$PROJECT_DIR/CLAUDE.md"
            echo -e "  ${GREEN}✓${NC} CLAUDE.md created from template"
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} CLAUDE.md already exists (not overwritten)"
    fi

    echo ""
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo -e "${BOLD}${GREEN}Setup complete!${NC}"
echo ""

if [ "$INSTALL_PERSONAL" = true ]; then
    echo -e "  ${BOLD}Personal:${NC} ~/.claude/commands/ — available in all projects"
fi
if [ "$INSTALL_PROJECT" = true ]; then
    echo -e "  ${BOLD}Project:${NC}  $PROJECT_DIR/.claude/ — hooks, skills, settings"
    echo ""
    echo -e "  ${BOLD}Next steps:${NC}"
    echo "    1. Customize CLAUDE.md for your project"
    echo "    2. git add .claude/ .editorconfig checkstyle.xml pmd-ruleset.xml CLAUDE.md"
    echo "    3. Restart Claude Code / VS Code"
fi
echo ""
