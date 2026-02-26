---
name: skill-creator
description: Use when the user asks to create a new Claude Code skill, write a SKILL.md file, design a skill, determine skill scope (enterprise vs personal vs project), or wants guidance on skill structure, frontmatter, allowed-tools, progressive disclosure, multi-file structure, or skill best practices. Ensures all skills follow the Anthropic standard and Bonitasoft methodology.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
user-invocable: true
---

# Skill Creator — Meta-Skill for Generating Claude Code Skills

You are an expert in creating Claude Code skills following the Anthropic agent skills standard and Bonitasoft team methodology. Your role is to guide users through the complete skill creation process, including scope determination, structure design, and proper installation.

## When activated

1. **Read existing skills**: Check `.claude/skills/` for project skills and the toolkit repository for enterprise skills
2. **Understand the request**: What domain does the user want the skill to cover?
3. **Check for conflicts**: Ensure the new skill name doesn't conflict with existing skills
4. **Determine scope**: Help the user decide if the skill is Enterprise, Personal, or Project

## Step 1: Scope Decision (MANDATORY)

**Before writing ANY code**, help the user determine the correct scope. Ask these questions:

### Scope Decision Tree

```
Q1: Will this skill be useful across MULTIPLE Bonita/Java projects?
├── YES → Q2: Does it encode company-wide standards or domain expertise?
│   ├── YES → ★★★ ENTERPRISE (e.g., bonita-bdm-expert, bonita-coding-standards)
│   └── NO  → Q3: Is it about YOUR personal workflow/preferences?
│       ├── YES → ★★☆ PERSONAL (e.g., my-code-review-style, my-git-workflow)
│       └── NO  → ★☆☆ PROJECT (e.g., project-specific APIs, custom integrations)
└── NO  → ★☆☆ PROJECT (only useful for this specific project)
```

### Scope Characteristics

| Aspect | ★★★ Enterprise | ★★☆ Personal | ★☆☆ Project |
|--------|----------------|--------------|-------------|
| **Who benefits?** | Entire team/company | Just you | This project only |
| **Examples** | BDM expert, REST API patterns, coding standards | Code review prefs, Git workflow, editor config | Project-specific APIs, custom BDM rules |
| **Install location** | Toolkit repo → all projects | `~/.claude/skills/` | `.claude/skills/` in project repo |
| **Maintained by** | Team lead / architect | Individual developer | Project team |
| **Priority** | Highest (1st) | Medium (2nd) | Lower (3rd) |
| **Can be overridden?** | No | By Enterprise | By Enterprise and Personal |

### Installation Paths

```
★★★ Enterprise:
  1. Create in toolkit: C:\JavaProjects\claude-code-toolkit\skills/{skill-name}/
  2. Copy to each project: .claude/skills/{skill-name}/
  3. Push toolkit to GitHub for team sharing

★★☆ Personal:
  1. Create in: ~/.claude/skills/{skill-name}/
  2. Available in ALL your projects automatically
  3. Not committed to any repo (private to you)

★☆☆ Project:
  1. Create in: .claude/skills/{skill-name}/
  2. Committed to the project repo
  3. Available to everyone working on this project
```

## Step 2: Skill Structure (MANDATORY)

### File Structure
```
skills/
└── skill-name/              # Directory name = skill name (kebab-case)
    ├── SKILL.md              # Main file (MANDATORY, max 500 lines)
    ├── references/           # Detailed docs Claude reads on demand
    │   ├── detailed-rules.md
    │   └── examples.md
    ├── scripts/              # Executable scripts (output-only, saves tokens)
    │   └── validate.sh
    └── assets/               # Templates, images, data files
        └── template.java
```

### When to Use Each Directory

| Directory | Use when... | Token cost |
|-----------|-------------|------------|
| **SKILL.md** | Core rules that ALWAYS apply | Full content loaded every time |
| **references/** | Detailed docs needed only sometimes | Loaded on demand (saves tokens) |
| **scripts/** | Validation, scaffolding, automation | Only OUTPUT uses tokens (very efficient) |
| **assets/** | Templates, logos, CSS, config files | Loaded only when referenced |

### Progressive Disclosure Strategy

**Rule of thumb**: If content is needed in >50% of interactions → put in SKILL.md. Otherwise → put in `references/`.

```
SKILL.md (always loaded, <500 lines):
  - Frontmatter (name, description, allowed-tools)
  - Expert role description
  - "When activated" checklist
  - Core mandatory rules (the 20% that covers 80% of cases)
  - Progressive disclosure links to references
  - Workflow for common requests

references/ (loaded on demand):
  - Detailed code examples
  - Complete templates
  - Edge cases and anti-patterns
  - Historical context or rationale
  - Long checklists or tables

scripts/ (executed, only output counts):
  - Validation scripts (check naming, structure)
  - Scaffolding scripts (create directories, templates)
  - Analysis scripts (count coverage, find patterns)

assets/ (loaded when referenced):
  - Java/Groovy templates
  - CSS/HTML templates
  - Logo/image files
  - Configuration file templates
```

## Step 3: SKILL.md Template

```yaml
---
name: my-skill-name
description: Clear description answering (1) What does this skill do? and (2) When should Claude use it? Include keywords matching how users phrase requests. Max 1024 chars.
allowed-tools: Read, Grep, Glob
---

# Skill Title

Brief description of the expert role (1-2 sentences).

## When activated

1. **Step 1**: First thing Claude should read/check
2. **Step 2**: Second thing to verify
3. **Step 3**: Additional context to load

## Mandatory Rules

### Rule Category 1
- Rule with explanation
- Another rule with code example

## Progressive Disclosure

- **For detailed examples**: Read `references/examples.md`
- **For validation**: Run `scripts/validate.sh`

## When the user asks about [topic]

1. Step-by-step workflow
2. What to check first
3. What to create/modify
4. How to verify
```

## Frontmatter Rules

| Field | Required | Rules |
|-------|----------|-------|
| `name` | YES | Lowercase, numbers, hyphens only. Max 64 chars. MUST match directory name. |
| `description` | YES | Max 1024 chars. Answer: What? When? Include keyword triggers. |
| `allowed-tools` | No | Restrict tools when skill is active. Omit = no restrictions. |
| `model` | No | Specify a Claude model. Omit = use default. |
| `user-invocable` | No | `true` if user can invoke with `/skill-name`. Default: auto-invoked. |

## Naming Rules

- Convention: `[domain]-[purpose]` (e.g., `bonita-process-expert`, `java-migration-expert`)
- GOOD: `bonita-bdm-expert`, `frontend-pr-review`, `testing-expert`
- BAD: `review`, `helper`, `expert` (too generic, will conflict across scopes)

## Description Best Practices

A good description MUST:
1. **Answer "What?"** — "Provides expert guidance on Bonita BDM design and JPQL queries"
2. **Answer "When?"** — "Use when the user asks about BDM queries, data model, JPQL..."
3. **Include trigger keywords** that match how users phrase their requests

```yaml
# BAD - Too vague, Claude won't know when to activate
description: Helps with documents.

# GOOD - Specific, keyword-rich, Claude knows exactly when to activate
description: Use when the user asks about generating documents (PDF, HTML reports, Word, Excel), corporate branding, document templates, or uses libraries like iText, OpenPDF, Apache POI, Flying Saucer. Ensures documents follow Bonitasoft corporate standards.
```

## Content Best Practices

1. **Keep SKILL.md under 500 lines** — full content loads into context every time
2. **Use progressive disclosure** — detailed docs in `references/`
3. **Scripts over instructions** — for complex validation, use `scripts/` (only output uses tokens)
4. **Be explicit** — "Always use AssertJ" not "use good assertion libraries"
5. **Include code examples** — show the exact patterns you want Claude to follow
6. **Structure clearly**: "When activated", "Mandatory Rules", "Progressive Disclosure", "When the user asks..."

## allowed-tools Guidelines

| Use case | Recommended |
|----------|-------------|
| Read-only analysis | `Read, Grep, Glob` |
| Analysis + scripts | `Read, Grep, Glob, Bash` |
| Full editing power | `Read, Grep, Glob, Edit, Write, Bash` |
| No restriction | Omit the field entirely |

## Skill Creation Workflow

1. **Determine scope** using the decision tree above
2. **Check for existing skills** with overlapping functionality
3. **Choose a descriptive name** (domain-purpose format)
4. **Write the description** answering "What?" and "When?" with keywords
5. **Design the structure** — what goes in SKILL.md vs references vs scripts vs assets
6. **Write SKILL.md** following the template (max 500 lines)
7. **Create reference files** for detailed content
8. **Create scripts** for validation/scaffolding
9. **Run the scaffold script** if available: `bash scripts/scaffold-skill.sh skill-name`
10. **Install** to the correct location based on scope
11. **Test the skill**:
    - Restart Claude Code
    - Verify with `what skills are available`
    - Test with a matching user request
    - Verify it does NOT trigger on unrelated requests
12. **For Enterprise skills** — add to toolkit repo, update README.md, commit, push

## Progressive Disclosure

For detailed guidance, read these reference files:

- **Scope examples and decision matrix**: Read `references/scope-guide.md`
- **Scaffold new skill directory**: Run `scripts/scaffold-skill.sh <skill-name> [enterprise|personal|project]`

## Priority System

If two skills share the same name across scopes:
```
1. Enterprise  (highest — cannot be overridden)
2. Personal    (~/.claude/skills/)
3. Project     (.claude/skills/ in repo)
4. Plugin      (lowest — namespaced)
```

Use unique, descriptive names to avoid conflicts.
