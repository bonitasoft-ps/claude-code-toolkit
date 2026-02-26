# Sync Claude Project Files

Synchronize knowledge files and instructions to the `claude-project/` folder for claude.ai compatibility.

## Arguments
- `$ARGUMENTS`: `check` (default — dry run), `sync` (execute copy), `diff` (show differences)

## Instructions

Many projects maintain a `claude-project/` folder containing copies of key files for use with claude.ai Projects (web interface). This command keeps that folder in sync.

### 1. Find Source Files
Locate knowledge files from:
- `knowledge/` directory (all .md files)
- `.claude/skills/` directory (all skill definitions)
- `CLAUDE.md` (project instructions)
- Any other files listed in `claude-project/INSTRUCTIONS.md` metadata

### 2. Find Target Folder
Look for `claude-project/` in the repo root. If it doesn't exist and mode is `sync`, create it.

### 3. Compare Files

For each source file, check if a copy exists in `claude-project/knowledge/` or `claude-project/`:
- Compare file contents (ignore whitespace differences)
- Track: identical, modified (source newer), missing (not in target), extra (only in target)

### 4. Report

```
## Claude Project Sync Status

| File | Status | Action Needed |
|------|--------|---------------|
| knowledge/file.md | In Sync | None |
| knowledge/new-file.md | Missing | Copy to claude-project/ |
| knowledge/old-file.md | Modified | Update in claude-project/ |
```

### 5. Execute (if mode is `sync`)
- Copy new/modified files to `claude-project/knowledge/`
- Update `claude-project/INSTRUCTIONS.md` version comment: `<!-- Version: X.Y.Z -->`
- Update `claude-project/CHANGELOG.md` with sync entry
- Report what was changed

### Pattern Details
This follows the **claude-project sync pattern** used across Bonitasoft PS toolkits:
- `claude-project/INSTRUCTIONS.md` — Main instructions (paste into claude.ai)
- `claude-project/CHANGELOG.md` — Version history
- `claude-project/knowledge/` — Copies of knowledge files
- Version tracked via HTML comment: `<!-- Version: X.Y.Z -->`

**Scope:** ★★☆ Personal — Useful for any project that maintains a claude.ai Project mirror.
