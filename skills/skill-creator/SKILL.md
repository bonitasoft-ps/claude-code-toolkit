---
name: skill-creator
description: Use when the user asks to create a new Claude Code skill, write a SKILL.md file, design a skill, or wants guidance on skill structure, frontmatter, allowed-tools, or skill best practices. Ensures all skills follow the Anthropic standard and Bonitasoft methodology.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Skill Creator — Meta-Skill for Generating Claude Code Skills

You are an expert in creating Claude Code skills following the Anthropic agent skills standard and Bonitasoft team methodology. Your role is to ensure every skill is well-structured, correctly described, and effective.

## When activated

1. **Read existing skills**: Check `.claude/skills/` and the toolkit at `C:\JavaProjects\claude-code-toolkit\skills\`
2. **Understand the request**: What domain does the user want the skill to cover?
3. **Check for conflicts**: Ensure the new skill name doesn't conflict with existing skills

## Skill Creation Rules (MANDATORY)

### File Structure
Every skill MUST follow this structure:
```
skills/
└── skill-name/              # Directory name = skill name (kebab-case)
    ├── SKILL.md              # Main skill file (MANDATORY)
    ├── references/           # Optional: detailed documentation Claude reads on demand
    │   ├── architecture.md
    │   └── examples.md
    ├── scripts/              # Optional: executable scripts (output-only, saves context)
    │   └── validate.sh
    └── assets/               # Optional: templates, images, data files
        └── template.html
```

### SKILL.md Template (MANDATORY)
```yaml
---
name: my-skill-name
description: Clear description answering TWO questions - (1) What does this skill do? (2) When should Claude use it? Include keywords that match how users actually phrase their requests. Max 1024 characters.
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
- Another rule

### Rule Category 2
- Rule with explanation

## Patterns and Examples

### Pattern Name
```code example```

## When the user asks about [topic]

1. Step-by-step workflow
2. What to check first
3. What to create/modify
4. How to verify
```

### Frontmatter Fields

| Field | Required | Rules |
|-------|----------|-------|
| `name` | YES | Lowercase, numbers, hyphens only. Max 64 chars. MUST match directory name. |
| `description` | YES | Max 1024 chars. Answer: What does it do? When should Claude use it? Include matching keywords. |
| `allowed-tools` | No | Restrict Claude's tools when skill is active. Omit = no restrictions. |
| `model` | No | Specify a Claude model. Omit = use default. |
| `user-invocable` | No | Set to `true` if user can invoke with `/skill-name`. |

### Naming Rules
- Use **descriptive, prefixed names** to avoid conflicts across scopes
- GOOD: `bonita-bdm-expert`, `frontend-pr-review`, `testing-expert`
- BAD: `review`, `helper`, `expert` (too generic, will conflict)
- Convention: `[domain]-[purpose]` (e.g., `bonita-process-expert`, `java-migration-expert`)

### Description Best Practices

A good description MUST answer:
1. **What does this skill do?** — "Provides expert guidance on Bonita BDM design and JPQL queries"
2. **When should Claude use it?** — "Use when the user asks about BDM queries, data model, JPQL, business objects, or database design"

Include **keywords that match how users phrase requests**:
```yaml
# BAD - Too vague
description: Helps with documents.

# GOOD - Specific, keyword-rich
description: Use when the user asks about generating documents (PDF, HTML reports, Word, Excel), corporate branding, document templates, or uses libraries like iText, OpenPDF, Apache POI, Flying Saucer, Thymeleaf for document output. Ensures all documents follow Bonitasoft corporate standards.
```

### Content Best Practices

1. **Keep SKILL.md under 500 lines** — Claude loads the full content into context
2. **Use progressive disclosure** — Link to `references/` files for detailed docs
3. **Scripts over instructions** — For complex validation, put a script in `scripts/` and tell Claude to execute it (only output uses tokens, not the script content)
4. **Structure with clear sections**: "When activated", "Mandatory Rules", "Patterns", "When the user asks about..."
5. **Be explicit, not vague** — "Always use AssertJ for assertions" instead of "use good assertion libraries"
6. **Include code examples** — Show the patterns you want Claude to follow

### Scope Classification
Every new skill MUST have a recommended scope:
- **★★★ Enterprise**: Company-wide domain knowledge (BDM expert, REST API expert, document branding)
- **★★☆ Personal**: Individual productivity (code review preferences, personal workflows)
- **★☆☆ Project**: Project-specific (only relevant to certain project types)

### allowed-tools Guidelines

| Use case | Recommended allowed-tools |
|----------|--------------------------|
| Read-only analysis | `Read, Grep, Glob` |
| Read + run scripts | `Read, Grep, Glob, Bash` |
| Full editing | `Read, Grep, Glob, Edit, Write, Bash` |
| No restriction | Omit the field entirely |

## Skill Creation Workflow

When creating a new skill:

1. **Check for existing skills** with overlapping functionality
2. **Choose a descriptive name** (domain-purpose format)
3. **Write the description** answering "What?" and "When?"
4. **Classify the scope** (Enterprise / Personal / Project)
5. **Decide on allowed-tools** based on what the skill needs
6. **Write SKILL.md** following the template above
7. **Keep under 500 lines** — use references/ for details
8. **Test the skill**:
   - Restart Claude Code
   - Verify it appears in `what skills are available`
   - Test with a matching request
   - Verify it does NOT trigger on unrelated requests
9. **Add to the toolkit**:
   - Copy to `C:\JavaProjects\claude-code-toolkit\skills\`
   - Update README.md with the new skill in the correct scope section
   - Commit and push

## Priority System Reminder

If two skills share the same name across scopes:
```
1. Enterprise  (highest — cannot be overridden)
2. Personal    (~/.claude/skills/)
3. Project     (.claude/skills/ in repo)
4. Plugin      (lowest — namespaced)
```

Use unique, descriptive names to avoid conflicts. Instead of `review`, use `bonita-pr-review`.
