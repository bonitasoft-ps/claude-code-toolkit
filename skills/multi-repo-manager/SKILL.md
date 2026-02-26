---
name: multi-repo-manager
description: Manage git operations across multiple related repositories (status, pull, push).
disable-model-invocation: true
argument-hint: status | pull | push
allowed-tools: Bash(git *)
user-invocable: true
---

# Multi-Repo Manager

Perform git operations across multiple related repositories in a single command.

## Scope

**Personal** (useful for any developer managing multiple related repos).

## Configuration

Define your repos by reading a `repos.json` file in the workspace root, or configure them directly in this skill. The expected format:

```json
{
  "repos": [
    { "name": "repo-1", "path": "/path/to/repo-1" },
    { "name": "repo-2", "path": "/path/to/repo-2" }
  ]
}
```

If no `repos.json` exists, scan the workspace root for directories containing `.git/`.

## Arguments

`$ARGUMENTS`: One of:
- `status` (default) — Show git status of all repos
- `pull` — Pull latest from remote for all repos
- `push` — Push local commits to remote for all repos

## Operations

### `status`

For each repo, run `git status --porcelain --branch` and present:

| Repo | Branch | Ahead/Behind | Modified | Untracked | Clean? |
|------|--------|-------------|----------|-----------|--------|

If all repos are clean: "All repos are clean and up to date."

### `pull`

1. Run `git pull --rebase` in each repo (in parallel)
2. Show summary:

| Repo | Files Changed | New Commits | Conflicts |
|------|--------------|-------------|-----------|

3. If conflicts, show details and ask how to resolve.

### `push`

1. Show pending commits per repo: `git log --oneline @{upstream}..HEAD`
2. Present summary:

| Repo | Commits to Push | Summary |
|------|----------------|---------|

3. **Ask user to confirm** before pushing
4. Push all repos: `git push`
5. Show final status

## Safety

- **Never force push** — use `git push` only (no `--force`)
- **Always show what will happen** before push
- **Ask for confirmation** before any write operation
- **Report conflicts** clearly and ask for resolution strategy
