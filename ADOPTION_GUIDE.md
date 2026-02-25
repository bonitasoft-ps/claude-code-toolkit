# Adoption Guide: Claude Code Toolkit for Bonita Teams

## Quick Start (5 minutes)

### Step 1: Clone this toolkit
```bash
git clone https://github.com/bonitasoft-presales/claude-code-toolkit.git
# Or if local:
# Located at C:\JavaProjects\claude-code-toolkit
```

### Step 2: Set up your Bonita project
```bash
cd your-bonita-project

# Create Claude directories
mkdir -p .claude/commands .claude/hooks

# Copy template settings
cp /path/to/claude-code-toolkit/templates/bonita-project.json .claude/settings.json

# Copy commands (pick what you need)
cp /path/to/claude-code-toolkit/commands/java-maven/* .claude/commands/
cp /path/to/claude-code-toolkit/commands/bonita/* .claude/commands/
cp /path/to/claude-code-toolkit/commands/quality/* .claude/commands/
cp /path/to/claude-code-toolkit/commands/testing/* .claude/commands/

# Copy hook scripts
cp /path/to/claude-code-toolkit/hooks/scripts/* .claude/hooks/
chmod +x .claude/hooks/*.sh

# Commit so teammates get it automatically
git add .claude/
git commit -m "chore: add Claude Code commands and hooks from toolkit"
```

### Step 3: Restart Claude Code
Close and reopen Claude Code (or your IDE with Claude extension) to load the new hooks.

---

## What You Get

### Automatic Hooks (run without user action)

| When | What happens | Why |
|------|-------------|-----|
| You edit a Java file | Checks if method signatures changed, lists affected files | Prevents broken call sites |
| You edit a Java file | Detects hardcoded magic strings | Enforces constants usage |
| You edit bom.xml | Checks for missing countFor queries | Ensures pagination compliance |
| You create a controller file | Warns if README.md is missing | Enforces documentation |
| Claude finishes responding | Auto-creates/updates tests for modified files, then runs them | Ensures test coverage |
| You commit code | Runs `mvn clean compile` first, blocks if it fails | Prevents broken commits |

### Slash Commands (type `/command` in Claude Code)

| Command | What it does |
|---------|-------------|
| `/compile` | Compile project |
| `/run-tests` | Run unit/integration/property tests |
| `/run-mutation-tests` | Run PIT mutation testing |
| `/generate-tests ClassName` | Generate unit + property tests for a class |
| `/check-code-quality` | Check Javadoc, method length, code smells |
| `/audit-compliance` | Full project compliance audit |
| `/check-bdm-queries PBProcess` | Search existing BDM queries |
| `/validate-bdm` | Validate BDM countFor, descriptions, indexes |
| `/check-existing-extensions` | Search for existing functionality in extensions |
| `/check-existing-processes` | Search for existing process/subprocess logic |
| `/refactor-method-signature` | Refactor method + update all call sites |
| `/create-constants` | Extract hardcoded strings to constants |
| `/generate-readme` | Generate README.md for a controller |
| `/check-coverage` | Run JaCoCo and check coverage thresholds |

---

## For Java Library Projects

Use the library template instead:
```bash
cp /path/to/claude-code-toolkit/templates/java-library.json .claude/settings.json
```

Library-specific differences:
- Pre-commit runs `mvn test` (not just compile)
- Checks for test PAIRS: `*Test.java` + `*PropertyTest.java`
- Auto-generates both unit and property tests

---

## Customizing

### Add project-specific commands
Create `.claude/commands/my-command.md` in your project. It's just a Markdown file:

```markdown
# My Custom Command

Do something specific to this project.

## Arguments
- `$ARGUMENTS`: what the user passes after the command

## Instructions
1. Step one
2. Step two
```

### Disable a hook temporarily
Edit `.claude/settings.json` and remove the hook entry, or set:
```json
{ "disableAllHooks": true }
```

### Personal commands (not shared)
Put them in `~/.claude/commands/` - they'll be available in all your projects but won't affect teammates.

---

## Scope Reference

| Location | Shared with team? | Available where? |
|----------|------------------|-----------------|
| `.claude/commands/` (project) | Yes (via git) | This project only |
| `.claude/settings.json` (project) | Yes (via git) | This project only |
| `.claude/settings.local.json` (project) | No (gitignored) | This project, you only |
| `~/.claude/commands/` (user) | No | All your projects |
| `~/.claude/settings.json` (user) | No | All your projects |

### Recommended setup per role:

**Developer:**
- Use project-level commands/hooks from git (automatic via this toolkit)
- Add personal shortcuts to `~/.claude/commands/`

**Tech Lead:**
- Set up the toolkit in each project repo
- Customize hooks per project needs
- Review and update shared toolkit periodically

**New team member:**
- `git clone` the project → commands/hooks are already there
- Nothing extra to install or configure
