---
name: safe-git-workflow
description: |
  Use when about to commit, push, or create a pull request. Enforces branch-based
  workflow: all changes go through claude/{type}/{description} branches with PRs
  via gh CLI. Never commit directly to main/master/develop.
  Keywords: commit, push, PR, pull request, branch, git, save changes.
user-invocable: false
---

# Safe Git Workflow

All changes made by Claude Code MUST go through a feature branch and Pull Request.
Direct commits or pushes to main, master, or develop are **forbidden**.

## When activated

1. Detect the current branch: `git branch --show-current`
2. If on main/master/develop: create a new branch BEFORE committing
3. If already on a `claude/*` branch: proceed normally

## Branch Naming Convention

Format: `claude/{type}/{short-description}`

| Type | When to use | Example |
|------|-------------|---------|
| `feat` | New feature or capability | `claude/feat/add-test-tools` |
| `fix` | Bug fix | `claude/fix/audit-category-map` |
| `docs` | Documentation only | `claude/docs/update-readme-ecosystem` |
| `refactor` | Code restructuring | `claude/refactor/extract-helpers` |
| `test` | Adding or fixing tests | `claude/test/add-connector-tests` |
| `chore` | Maintenance, config, deps | `claude/chore/update-dependencies` |

Rules:
- Lowercase only
- Hyphens to separate words
- 2-4 words in the description
- Must reflect the actual changes

## Complete Workflow

### Step 1: Detect base branch

```bash
CURRENT=$(git branch --show-current)
# If on main/master/develop, this is the base branch for the PR
```

### Step 2: Create feature branch (if on protected branch)

```bash
git checkout -b claude/{type}/{short-description}
```

### Step 3: Stage specific files and commit

```bash
git add {specific-files}  # NEVER use git add -A or git add .
git commit -m "$(cat <<'EOF'
{concise commit message}

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

### Step 4: Push the branch

```bash
git push -u origin claude/{type}/{short-description}
```

### Step 5: Create Pull Request

```bash
gh pr create --base {base-branch} --title "{short title}" --body "$(cat <<'EOF'
## Summary
{1-3 bullet points describing what changed and why}

## Test plan
{how to verify the changes}

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Step 6: Report to user

Always tell the user:
- The branch name created
- The PR URL
- A summary of what was committed

## When already on a claude/* branch

If already on a `claude/*` branch (e.g., resuming previous work):
1. Commit normally (the hook allows this)
2. Push to the existing branch
3. If no PR exists yet, create one
4. If PR already exists, just push (PR auto-updates)

## Mandatory Rules

1. **NEVER** commit directly to main, master, or develop
2. **NEVER** use `git add -A` or `git add .` — stage specific files
3. **ALWAYS** include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` in commits
4. **ALWAYS** create a PR after pushing a branch
5. **ALWAYS** use `--base` flag with `gh pr create` to target the correct branch
