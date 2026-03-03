# Hooks Reference — claude-code-toolkit

15 hooks organized by scope and event type. All hooks are POSIX-compatible and use `PYTHON_CMD` fallback for Windows compatibility.

## Hook Events

| Event | When | Exit codes |
|-------|------|-----------|
| `PreToolUse` | Before Claude uses a tool | `exit 0` = allow, `exit 2` = block |
| `PostToolUse` | After Claude uses a tool | `exit 0` = allow (warnings via stderr) |

## Enterprise Hooks ★★★

These enforce organization-wide standards. Deploy via `managed-settings.json`.

| Hook | Event | Trigger condition | Action |
|------|-------|------------------|--------|
| `safe-git-workflow.sh` | PreToolUse (Bash) | `git commit` or `git push` on main/master/develop | **Blocks** — enforces `claude/{type}/{desc}` branch + PR via `gh` |
| `pre-commit-compile.sh` | PreToolUse (Bash) | `git commit` command | **Blocks** if `mvn clean compile` fails; skip with `SKIP_COMPILE=1` |
| `pre-push-validate.sh` | PreToolUse (Bash) | `git push` command | **Blocks** if compilation fails or sensitive files staged |
| `check-code-format.sh` | PostToolUse (Edit/Write) | Java/Groovy/Kotlin files edited | Warns about tabs, trailing whitespace, lines > 120 chars, wildcard imports, blank lines |
| `check-code-style.sh` | PostToolUse (Edit/Write) | Java/Groovy/Kotlin files edited | Warns about System.out.println, empty catch, methods > 30 lines, missing @Override |
| `check-hardcoded-strings.sh` | PostToolUse (Edit) | Java/Groovy/Kotlin source files | Warns about magic strings in comparisons and switch cases |
| `check-document-pattern.sh` | PostToolUse (Edit/Write) | Java files with document generation | Warns if missing BrandingConfig, hardcoded colors/fonts, or iText usage without corporate pattern |
| `check-skill-structure.sh` | PostToolUse (Write/Edit) | SKILL.md files | Warns if SKILL.md missing YAML frontmatter, name, description, or required sections |
| `check-openapi-annotations.sh` | PostToolUse (Edit/Write) | Java files in controller directories | Warns about missing `@Tag`, `@Operation`, `@ApiResponse` on REST API controllers |

## Project Hooks ★☆☆

These depend on project type. Install in `.claude/` within the specific repository.

| Hook | Event | Project type | Trigger condition | Action |
|------|-------|-------------|------------------|--------|
| `check-bdm-countfor.sh` | PostToolUse (Edit) | Bonita BPM | `bom.xml` edited | Warns about collection queries missing `countFor` companion query |
| `check-controller-readme.sh` | PreToolUse (Write) | Bonita BPM | New Java file in controller directory | Warns if `README.md` is missing in that controller package |
| `check-method-usages.sh` | PostToolUse (Edit) | Multi-module Java | Java/Groovy files edited | Lists other files calling a method when its signature changes |
| `check-test-pair.sh` | PostToolUse (Edit/Write) | Java libraries | Source Java files | Warns if `*Test.java` or `*PropertyTest.java` is missing for the modified class |
| `check-docs-consistency.sh` | PostToolUse (Write/Edit) | Any project | SKILL.md, commands/*.md, hooks/*.sh, agents/*.md | Warns when documented counts drift from actual filesystem counts |
| `knowledge-file-reminder.sh` | PostToolUse (Write/Edit) | Any project | `knowledge/` files modified | Warns when `knowledge/` files change and `claude-project/` may be out of sync |

## Recommended Hook Sets by Project Type

### Bonita BPM Project
```json
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "Bash", "hooks": [
        {"type": "command", "command": "bash safe-git-workflow.sh"},
        {"type": "command", "command": "bash pre-commit-compile.sh"}
      ]}
    ],
    "PostToolUse": [
      {"matcher": "Edit|Write", "hooks": [
        {"type": "command", "command": "bash check-code-format.sh"},
        {"type": "command", "command": "bash check-code-style.sh"},
        {"type": "command", "command": "bash check-hardcoded-strings.sh"},
        {"type": "command", "command": "bash check-openapi-annotations.sh"},
        {"type": "command", "command": "bash check-bdm-countfor.sh"},
        {"type": "command", "command": "bash check-controller-readme.sh"}
      ]}
    ]
  }
}
```

### Java Library Project
```json
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "Bash", "hooks": [
        {"type": "command", "command": "bash safe-git-workflow.sh"},
        {"type": "command", "command": "bash pre-commit-compile.sh"}
      ]}
    ],
    "PostToolUse": [
      {"matcher": "Edit|Write", "hooks": [
        {"type": "command", "command": "bash check-code-format.sh"},
        {"type": "command", "command": "bash check-code-style.sh"},
        {"type": "command", "command": "bash check-test-pair.sh"}
      ]}
    ]
  }
}
```

### Knowledge/Toolkit Project (this repo)
```json
{
  "hooks": {
    "PostToolUse": [
      {"matcher": "Write|Edit", "hooks": [
        {"type": "command", "command": "bash check-skill-structure.sh"},
        {"type": "command", "command": "bash check-docs-consistency.sh"},
        {"type": "command", "command": "bash knowledge-file-reminder.sh"}
      ]}
    ]
  }
}
```

## Hook Configuration File Location

| Scope | Path |
|-------|------|
| Enterprise | `C:\ProgramData\ClaudeCode\managed-settings.json` (Windows) or `/etc/claude-code/managed-settings.json` (Linux) |
| Personal | `~/.claude/settings.json` |
| Project | `.claude/settings.json` (committed to git) |
| Project (personal) | `.claude/settings.local.json` (NOT committed) |

## Templates

Ready-to-use settings templates are available in `templates/`:
- `templates/bonita-project.json` — Bonita BPM project (all enterprise + BDM/controller hooks)
- `templates/java-library.json` — Java library project (enterprise hooks + test-pair check)
