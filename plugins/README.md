# Plugins Guide

## What Are Plugins?

Plugins are **packaged Claude Code extensions** distributed through marketplaces (npm, GitHub). They can contain skills, commands, and configurations designed to be shared **beyond your team**.

## Plugin Priority

Plugins have **Priority 4** (lowest):

```
1. Enterprise  (highest — cannot be overridden)
2. Personal    (~/.claude/skills/)
3. Project     (.claude/skills/ in repo)
4. Plugin      (lowest — namespaced)
```

Plugin skills use namespaced names: `plugin-name:skill-name`, so they never conflict with other scopes.

## Candidates for Plugin Publishing

These toolkit resources are generic enough to benefit the broader community:

| Resource | Current Scope | Why Plugin? |
|----------|--------------|-------------|
| `testing-expert` | ★★★ Enterprise | JUnit 5 + Mockito + AssertJ + jqwik patterns are universal |
| `skill-creator` | ★★★ Enterprise | Meta-skill useful for any Claude Code user |
| `prompt-engineering-log` | ★★☆ Personal | Audit trail useful for any AI-assisted work |
| `multi-repo-manager` | ★★☆ Personal | Multi-repo management useful for any team |

### NOT candidates (too Bonita-specific)

- `bonita-bdm-expert` — Bonita BDM knowledge
- `bonita-rest-api-expert` — Bonita extension patterns
- `bonita-process-expert` — Bonita process modeling
- `bonita-uib-expert` — Bonita UI Builder
- All `bonita-*` skills — company-specific domain knowledge

## How to Publish a Plugin

### Step 1: Create Plugin Structure

```
my-plugin/
├── package.json          # npm package metadata
├── README.md             # Plugin documentation
├── skills/
│   └── my-skill/
│       ├── SKILL.md      # Standard skill file
│       ├── references/
│       └── scripts/
└── commands/
    └── my-command.md     # Optional commands
```

### Step 2: Define package.json

```json
{
  "name": "@bonitasoft/claude-testing-expert",
  "version": "1.0.0",
  "description": "Comprehensive testing patterns for Java projects with JUnit 5, Mockito, AssertJ, and jqwik",
  "claude-code-plugin": {
    "skills": ["skills/testing-expert"],
    "commands": []
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/bonitasoft-ps/claude-testing-expert-plugin"
  },
  "keywords": ["claude-code", "testing", "junit5", "java"],
  "license": "MIT"
}
```

### Step 3: Publish

```bash
# npm
npm publish --access public

# GitHub (alternative)
# Create a release in the plugin repository
```

### Step 4: Install in Claude Code

Users install via:
```
claude plugins install @bonitasoft/claude-testing-expert
```

## Enterprise Control: strictKnownMarketplaces

Administrators can restrict which plugins can be installed using `managed-settings.json`:

```json
{
  "strictKnownMarketplaces": [
    {
      "source": "github",
      "repo": "bonitasoft-ps/approved-plugins"
    },
    {
      "source": "npm",
      "package": "@bonitasoft/*"
    }
  ]
}
```

This ensures only approved plugins are used across the organization.

## Dual Publishing Strategy

For generic skills, we recommend **dual publishing**:

1. **Keep in toolkit** as Enterprise skill (Priority 1) — team always has it
2. **Publish as plugin** (Priority 4) — community can benefit

Since Enterprise > Plugin, there's no conflict. If the Enterprise version exists, it wins. If someone outside the company installs only the plugin, they get the community version.
