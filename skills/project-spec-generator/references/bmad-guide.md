# BMAD Method Integration Guide

Reference for integrating BMAD (Breakthrough Method for Agile AI-Driven Development) concepts into Claude Code projects.

## What is BMAD?

BMAD is a methodology that orchestrates **specialized AI agents** for each stage of the software development cycle. Instead of using one generalist AI assistant, it assigns roles to focused agents with specific expertise.

**Key concept**: Agent As Code — each agent is defined as a declarative Markdown file with personality, skills, commands, and dependencies.

## BMAD Phases mapped to Claude Code

| BMAD Phase | Claude Code Equivalent | What to do |
|-----------|----------------------|------------|
| **Analysis** | Plan Mode (`Shift+Tab` x2) | Explore codebase, understand requirements |
| **Planning** | `/project-spec-generator PRD` | Generate PRD and requirements |
| **Solutioning** | `/project-spec-generator architecture` | Design architecture and tech decisions |
| **Implementation** | Story-by-story development | Implement one story at a time with AC validation |

## BMAD Roles → Claude Code Skills

| BMAD Agent | Our Equivalent | How to achieve it |
|-----------|---------------|-------------------|
| **Analyst** | Plan Mode + prompting | Ask Claude to explore and analyze in Plan Mode |
| **Project Manager** | `project-spec-generator` skill | Generate PRDs and requirements |
| **Architect** | `project-spec-generator` skill | Generate architecture docs |
| **Scrum Master** | `project-spec-generator` skill | Generate and manage user stories |
| **Developer** | Claude Code default mode | Implement stories following specs |
| **QA** | `testing-expert` skill | Generate and run tests |

## Document Sharding (BMAD Concept)

BMAD's "document sharding" fragments complex documentation into digestible atomic pieces for the AI. In Claude Code, this maps to:

```
BMAD concept          → Claude Code equivalent
──────────────────────────────────────────────
Agent .md files       → .claude/skills/*/SKILL.md
Shared knowledge      → docs/ folder + CLAUDE.md
User stories          → stories/ folder (one file per story)
Config                → .claude/settings.json + rules/
Progressive loading   → references/ (loaded on demand)
```

### Why Sharding Matters

- **Context window**: Large monolithic docs waste tokens and can cause hallucinations
- **Focus**: Smaller docs keep Claude focused on the current task
- **Reusability**: Atomic docs can be referenced from multiple places
- **Versioning**: Easier to track changes in small, focused files

## Workflow: BMAD-Style Project Setup

### Step 1: Discovery Session

```
User: "I want to build [project idea]"
Claude (in Plan Mode): Asks discovery questions, explores constraints
Output: docs/DISCOVERY.md with findings
```

### Step 2: PRD Generation

```
User: "/project-spec-generator PRD"
Claude: Generates docs/PRD.md from discovery findings
Output: Complete PRD with requirements, personas, scope
```

### Step 3: Architecture

```
User: "/project-spec-generator architecture"
Claude: Reads PRD, proposes tech stack and component design
Output: docs/ARCHITECTURE.md with ADRs
```

### Step 4: Story Mapping

```
User: "/project-spec-generator stories"
Claude: Reads PRD + Architecture, generates epics and stories
Output: stories/ folder with organized user stories
```

### Step 5: Sprint Planning

```
User: "Plan sprint 1"
Claude: Reads stories, identifies MVP scope, creates sprint plan
Output: stories/SPRINT-01.md with committed stories
```

### Step 6: Implementation (Story by Story)

```
User: "Implement story S-001"
Claude:
  1. Reads stories/epic-01/story-001.md
  2. Reads docs/ARCHITECTURE.md for context
  3. Implements following acceptance criteria
  4. Marks AC as complete: [x]
  5. Runs tests
  6. Moves to next story
```

## CLAUDE.md Template for BMAD Projects

```markdown
# [Project Name]

## Overview
[Project description from PRD]

## Development Workflow (Spec-Driven)

**IMPORTANT: Always follow this workflow:**

1. Before implementing, read the relevant story in `stories/`
2. Check acceptance criteria — they define "done"
3. Reference `docs/ARCHITECTURE.md` for technical decisions
4. After implementing, mark acceptance criteria as [x] complete
5. Run tests before moving to the next story
6. If architecture decisions change, update `docs/ARCHITECTURE.md`

## Project Docs
- Requirements: `docs/PRD.md`
- Architecture: `docs/ARCHITECTURE.md`
- Current Sprint: `stories/SPRINT-XX.md`

## Tech Stack
[From ARCHITECTURE.md]

## Coding Standards
[Project-specific rules]
```

## Tips for BMAD-Style Development with Claude Code

### 1. Invest in Design Phase
Don't rush to code. A solid PRD + Architecture = much better AI-generated code.

### 2. One Story at a Time
Implement and validate one story before starting the next. This prevents context drift and catches issues early.

### 3. Keep Context Fresh
When starting a new story, explicitly tell Claude:
```
"Read stories/epic-01/story-003.md and docs/ARCHITECTURE.md.
Implement this story following the acceptance criteria."
```

### 4. Use Plan Mode for Analysis
Before coding complex stories, use Plan Mode to analyze the codebase and plan the approach.

### 5. Validate with Tests
After each story, ask Claude to generate tests that verify the acceptance criteria.

### 6. Update Docs
If implementation reveals new insights or changes architecture decisions, update the docs immediately. Living documentation > stale documentation.

## BMAD Resources

- **Official site**: [bmadcodes.com](https://bmadcodes.com)
- **GitHub**: [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)
- **Claude Code port**: [BMAD-AT-CLAUDE](https://github.com/24601/BMAD-AT-CLAUDE)
- **Claude Code skills**: [claude-code-bmad-skills](https://github.com/aj-geddes/claude-code-bmad-skills)
- **Spec workflow**: [claude-code-spec-workflow](https://github.com/Pimzino/claude-code-spec-workflow)
