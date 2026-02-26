# Contributing to the Claude Code Toolkit

This toolkit defines our **team methodology** for AI-assisted development. Every team member can contribute to make it better.

---

## Our Methodology

### Principles
1. **Consistency first** - All projects follow the same standards
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

### Step 1: Choose the right scope

Every resource you add must have a **recommended scope**. Ask yourself:

| Question | Scope | Symbol |
|----------|-------|--------|
| Should this apply to ALL developers on ALL projects? | **Enterprise** | ★★★ |
| Is this a developer productivity tool? | **Personal** | ★★☆ |
| Does this depend on the project type (Bonita, Library)? | **Project** | ★☆☆ |

**Examples:**
- Code formatting hook → ★★★ Enterprise (everyone must format the same way)
- `/compile` command → ★★☆ Personal (developer convenience, not enforcement)
- BDM countFor validation → ★☆☆ Project (only Bonita BDM projects need this)

### Step 2: Add the resource

#### Adding a New Command

1. **Choose a category:** `java-maven/`, `bonita/`, `quality/`, or `testing/`. Create a new one if needed.

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

#### Adding a New Hook Script

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
   # Scope: ★★★ Enterprise / ★★☆ Personal / ★☆☆ Project

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

4. **Add to templates** - Update `bonita-project.json` and/or `java-library.json` with the hook config.

#### Adding a New Skill

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

4. **Use descriptive names** to avoid conflicts across scopes. Instead of `review`, use `bonita-pr-review`.

5. **Test auto-invocation** - Verify Claude activates the skill when asking about the relevant topic.

#### Adding a New Agent

Agents are isolated Claude instances for delegated tasks. They get their own context window and must explicitly list which skills to load.

1. **Create the agent file:**
   ```
   agents/my-agent.md
   ```

2. **Use YAML frontmatter:**
   ```yaml
   ---
   name: my-agent-name
   description: "When to delegate to this agent. Be specific."
   tools: Read, Grep, Glob, Bash, Edit, Write
   model: sonnet
   color: blue
   skills: skill-one, skill-two
   ---
   ```

3. **Structure the agent instructions:**
   - `## Task` — What the agent must accomplish
   - `## Procedure` — Step-by-step workflow
   - `## Output Format` — How to structure results

4. **Key facts about agents:**
   - Agents do NOT see your skills automatically — you must list them in `skills:`
   - Each agent gets its own context window (isolated from your conversation)
   - Skills listed are loaded at startup (not on demand)
   - Use `model: sonnet` for cost-effective agents, `model: opus` for complex ones

5. **Test delegation** - Verify `delegate to my-agent: [task]` works correctly.

#### Adding an MCP Skill

MCP skills teach Claude how to use external MCP tools following team conventions. They pair an MCP server (which provides tools) with a skill (which teaches conventions).

1. **Create the skill directory:**
   ```
   skills/my-mcp-skill/SKILL.md
   ```

2. **Include MCP tools in `allowed-tools`:**
   ```yaml
   ---
   name: my-mcp-skill
   description: "Use when the user asks about [topic] using [MCP tool]."
   allowed-tools: Read, Grep, Glob, mcp__my-mcp-server__*
   ---
   ```

3. **Document your team's conventions** for using that tool (templates, naming, labels, workflows).

4. **Use progressive disclosure** — put detailed templates in `references/` subdirectory.

#### Adding a Configuration File

1. **Place in `configs/`:**
   ```
   configs/my-config.xml
   ```

2. **Add a header comment** explaining:
   - What this config is for
   - How to integrate it (Maven plugin config snippet)
   - Link to the toolkit repo

### Step 3: Update documentation

1. **README.md** - Add the resource to the correct scope section (Enterprise / Personal / Project)
2. **Scope symbol** - Mark with ★★★, ★★☆, or ★☆☆ in the repository structure
3. **Templates** - If it's a hook, update `bonita-project.json` and/or `java-library.json`
4. **install.sh** - If it's a new hook or config, update the installer script

---

## Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Commands | `kebab-case.md` | `run-tests.md`, `check-bdm-queries.md` |
| Hook scripts | `kebab-case.sh` | `check-code-format.sh`, `pre-commit-compile.sh` |
| Skills | `kebab-case/SKILL.md` | `bonita-bdm-expert/SKILL.md` |
| Agents | `kebab-case.md` | `code-reviewer.md`, `bonita-auditor.md` |
| Config files | Standard names | `checkstyle.xml`, `pmd-ruleset.xml` |
| Templates | `descriptive-name.json` | `bonita-project.json` |

**Naming tips:**
- **Skills:** Use descriptive, prefixed names to avoid conflicts across scopes. Example: `bonita-bdm-expert` instead of just `bdm`.
- **Agents:** Use task-oriented names. Example: `code-reviewer`, `test-generator`, `bonita-auditor`.
- **MCP Skills:** Name them `[tool]-workflow-expert` or `[tool]-docs-expert`. Example: `jira-workflow-expert`.

---

## Quality Checklist

Before submitting a PR, verify:

- [ ] Resource has a recommended scope (★★★ / ★★☆ / ★☆☆)
- [ ] Resource works in a real project
- [ ] README.md is updated with the resource in the correct scope section
- [ ] Hook scripts have proper file filtering (don't run on irrelevant files)
- [ ] Hook scripts are fast (< 2 seconds)
- [ ] Hook scripts exit with correct codes (0 = allow, 2 = block)
- [ ] Agent frontmatter includes all required fields (name, description, tools, skills)
- [ ] MCP skills include MCP tool patterns in `allowed-tools` (e.g., `mcp__jira__*`)
- [ ] Templates are updated if a new hook was added
- [ ] install.sh is updated if applicable
- [ ] No hardcoded project-specific paths (use `$CLAUDE_PROJECT_DIR`)

---

## Folder Structure Reference

```
claude-code-toolkit/
├── agents/                  # ★☆☆ Project — delegated task agents
├── commands/
│   ├── java-maven/          # ★★☆ Personal — developer productivity
│   ├── bonita/              # ★☆☆ Project — Bonita BPM specific
│   ├── quality/             # ★★☆ Personal — quality tools
│   └── testing/             # ★★☆ Personal — testing tools
├── hooks/
│   └── scripts/             # ★★★ Enterprise + ★☆☆ Project hooks
├── skills/                  # ★★★ Enterprise — domain expertise + MCP skills
├── configs/                 # ★★★ Enterprise — standard rules
├── templates/               # ★☆☆ Project — settings + CLAUDE.md
├── plugins/                 # Guide for publishing skills as plugins
├── install.sh               # Automated installer
├── WHEN_TO_USE_WHAT.md      # Decision guide for resource types
├── README.md                # Full documentation
├── CONTRIBUTING.md          # This file
└── ADOPTION_GUIDE.md        # Step-by-step adoption guide
```

---

## Ideas for Future Contributions

### New Commands
- `/analyze-dependencies` - Detect unused or conflicting Maven dependencies ★★☆
- `/security-audit` - Check for known vulnerabilities in dependencies ★★☆
- `/generate-dto` - Generate DTO records from a specification ★★☆
- `/document-api` - Generate OpenAPI documentation from controllers ★☆☆
- `/migrate-java` - Help migrate code to newer Java version features ★★☆

### New Hooks
- `check-dependency-versions.sh` - Warn about outdated dependencies on pom.xml edit ★★★
- `check-sql-injection.sh` - Detect potential SQL injection in JPQL queries ★★★
- `check-null-safety.sh` - Detect potential NullPointerException patterns ★★★
- `check-logging-level.sh` - Ensure appropriate log levels in production code ★★★

### New Skills / MCP Skills
- `java-migration-expert` - Help migrate Java 11/8 code to Java 17+ idioms ★★★
- `sonarqube-workflow-expert` - MCP skill for SonarQube conventions ★★★
- `github-pr-expert` - MCP skill for PR review conventions ★★★
- `slack-notification-expert` - MCP skill for Slack messaging conventions ★★★

### New Agents
- `security-auditor` - Audit for OWASP vulnerabilities, SQL injection, XSS ★☆☆
- `dependency-updater` - Check and update outdated Maven dependencies ★☆☆
- `migration-agent` - Migrate Java 11/8 code to Java 17+ idioms ★☆☆

### New Configs
- `spotbugs-ruleset.xml` - SpotBugs configuration ★★★
- `jacoco-rules.xml` - JaCoCo coverage rules ★★★
- `pit-config.xml` - PIT mutation testing configuration ★★★
- `sonarqube.properties` - SonarQube project configuration ★★★

### Plugins to Publish
- `testing-expert` - JUnit 5 + Mockito + AssertJ + jqwik patterns (universal)
- `skill-creator` - Meta-skill for creating Claude Code skills (universal)
