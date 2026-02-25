# Contributing to the Claude Code Toolkit

This toolkit defines our **team methodology** for AI-assisted development. Every team member can contribute to make it better.

---

## Our Methodology

### Principles
1. **Consistency first** - All projects should follow the same standards
2. **Automate everything** - If a check can be automated, it should be a hook
3. **Fail fast** - Catch issues during development, not in code review
4. **Document as you go** - Every command, hook, and skill has documentation
5. **Share and reuse** - If it's useful in one project, put it in the toolkit

### Development Workflow with Claude Code
1. **Start a task** - Describe what you need to Claude
2. **Hooks fire automatically** - Pre-commit compilation, format checks, style checks, BDM validation
3. **Use commands** for specific tasks - `/run-tests`, `/check-bdm-queries`, `/generate-tests`
4. **Claude follows project rules** - CLAUDE.md, skills, and context files guide AI behavior
5. **Review and commit** - Hooks ensure code compiles and tests pass before commit

---

## How to Contribute

### Adding a New Command

1. **Choose a category:** `java-maven/`, `bonita/`, `quality/`, or `testing/`. Create a new category if needed.

2. **Create the Markdown file:**
   ```
   commands/<category>/my-command.md
   ```

3. **Follow this template:**
   ```markdown
   # Command Name

   Brief description of what this command does.

   ## Arguments
   - `$ARGUMENTS`: Description of expected arguments (optional)

   ## Instructions
   1. Step 1 - what Claude should do
   2. Step 2 - what Claude should do
   3. Step 3 - what Claude should do

   ## Output
   What the user should expect to see.
   ```

4. **Test it** in a real project before submitting.

5. **Update the README** - Add the command to the appropriate table in README.md.

### Adding a New Hook Script

1. **Create the script:**
   ```
   hooks/scripts/my-hook.sh
   ```

2. **Follow these conventions:**
   - Read JSON from stdin: `INPUT=$(cat)`
   - Extract relevant fields with python3
   - Exit 0 = allow (send feedback via stderr)
   - Exit 2 = block (only for PreToolUse hooks)
   - Keep it fast (< 2 seconds execution time)
   - Only check relevant files (filter by extension)

3. **Use this skeleton:**
   ```bash
   #!/bin/bash
   # my-hook.sh - Brief description
   # Fires: PostToolUse on Edit/Write (or PreToolUse on Bash, etc.)
   # Behavior: Warns about X / Blocks Y

   INPUT=$(cat)

   FILE_PATH=$(echo "$INPUT" | python3 -c "
   import sys, json
   try:
       data = json.load(sys.stdin)
       path = data.get('tool_input', {}).get('file_path', '')
       print(path)
   except:
       print('')
   " 2>/dev/null)

   # Filter: only check relevant files
   if [[ ! "$FILE_PATH" =~ \.(java|groovy)$ ]]; then
       exit 0
   fi

   # Your checks here...

   if [ -n "$WARNINGS" ]; then
       echo "$WARNINGS" >&2
   fi

   exit 0
   ```

4. **Add to templates** - Update `bonita-project.json` and/or `java-library.json` with the hook configuration.

5. **Update the README** - Add the hook to the Available Hooks table.

### Adding a New Skill

1. **Create the skill directory:**
   ```
   skills/my-skill/SKILL.md
   ```

2. **Use YAML frontmatter:**
   ```yaml
   ---
   name: my-skill
   description: When to use this skill. Be specific so Claude knows when to auto-invoke it.
   allowed-tools: Read, Grep, Glob
   user-invocable: true
   ---
   ```

3. **Structure the skill instructions:**
   - "When activated" - What to read/check first
   - "Mandatory Rules" - What patterns to enforce
   - "When the user asks about X" - Step-by-step workflow

4. **Test auto-invocation** - Verify Claude activates the skill when asking about the relevant topic.

### Adding a Configuration File

1. **Place in `configs/`:**
   ```
   configs/my-config.xml
   ```

2. **Add a header comment** explaining:
   - What this config is for
   - How to integrate it (Maven plugin config snippet)
   - Link to the toolkit repo

3. **Update the README** - Add the config to the Toolkit Structure and document its purpose.

### Updating a Settings Template

1. **Edit the appropriate template** in `templates/`:
   - `bonita-project.json` for Bonita BPM projects
   - `java-library.json` for Java libraries

2. **Add your hook** to the correct event (PreToolUse, PostToolUse, Stop, etc.)

3. **Test the full template** in a real project.

---

## Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Commands | `kebab-case.md` | `run-tests.md`, `check-bdm-queries.md` |
| Hook scripts | `kebab-case.sh` | `check-code-format.sh`, `pre-commit-compile.sh` |
| Skills | `kebab-case/SKILL.md` | `bonita-bdm-expert/SKILL.md` |
| Config files | Standard names | `checkstyle.xml`, `pmd-ruleset.xml` |
| Templates | `descriptive-name.json` | `bonita-project.json` |

---

## Quality Checklist

Before submitting a PR, verify:

- [ ] Command/hook/skill works in a real project
- [ ] README.md is updated with the new resource
- [ ] Hook scripts have proper file filtering (don't run on irrelevant files)
- [ ] Hook scripts are fast (< 2 seconds)
- [ ] Hook scripts exit with correct codes (0 = allow, 2 = block)
- [ ] Templates are updated if a new hook was added
- [ ] No hardcoded project-specific paths (use `$CLAUDE_PROJECT_DIR`)

---

## Folder Structure Reference

```
claude-code-toolkit/
├── commands/
│   ├── java-maven/          # Generic Java + Maven commands
│   ├── bonita/              # Bonita BPM specific commands
│   ├── quality/             # Code quality commands
│   └── testing/             # Testing commands
├── hooks/
│   └── scripts/             # Reusable hook scripts
├── skills/                  # Reusable skills (auto-invocable)
├── configs/                 # Standard config files (Checkstyle, PMD, EditorConfig)
├── templates/               # settings.json templates + CLAUDE.md template
├── README.md                # Full documentation (methodology + catalog)
├── CONTRIBUTING.md          # This file
└── ADOPTION_GUIDE.md        # Step-by-step adoption instructions
```

---

## Ideas for Future Contributions

Here are areas where the toolkit can grow:

### New Commands
- `/analyze-dependencies` - Detect unused or conflicting Maven dependencies
- `/security-audit` - Check for known vulnerabilities in dependencies
- `/generate-dto` - Generate DTO records from a specification
- `/document-api` - Generate OpenAPI documentation from controllers
- `/migrate-java` - Help migrate code to newer Java version features

### New Hooks
- `check-dependency-versions.sh` - Warn about outdated dependencies on edit of pom.xml
- `check-sql-injection.sh` - Detect potential SQL injection in JPQL queries
- `check-null-safety.sh` - Detect potential NullPointerException patterns
- `check-logging-level.sh` - Ensure appropriate log levels in production code

### New Skills
- `bonita-process-expert` - Expert guidance on Bonita process modeling
- `bonita-connector-expert` - Expert guidance on Bonita connector development
- `java-migration-expert` - Help migrate Java 11/8 code to Java 17+ idioms
- `testing-expert` - Expert guidance on test strategy and coverage

### New Configs
- `spotbugs-ruleset.xml` - SpotBugs configuration
- `jacoco-rules.xml` - JaCoCo coverage rules
- `pit-config.xml` - PIT mutation testing configuration
- `sonarqube.properties` - SonarQube project configuration
