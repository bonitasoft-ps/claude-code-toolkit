# Test Toolkit Template

Ready-to-use `.claude/` directory for **Bonita Test Toolkit** projects (integration test projects using `bonita-test-toolkit` 3.1.x).

## What's Included

```
.claude/
├── settings.json                          # Hooks: compile check, style validation
├── commands/
│   ├── run-integration-tests.md          # /run-integration-tests [ProcessIT]
│   ├── deploy-and-test.md                # /deploy-and-test Process--1.0.bar
│   └── check-test-coverage.md            # /check-test-coverage
├── hooks/
│   ├── check-test-naming.sh             # Warns if IT class doesn't end with IT.java
│   └── check-test-structure.sh          # Warns if test doesn't extend AbstractProcessTest
├── skills/
│   └── bonita-test-toolkit-expert/       # Expert skill for Bonita Test Toolkit API
│       ├── SKILL.md
│       └── references/
│           └── api-patterns.md           # Detailed API patterns and examples
└── agents/
    └── test-scaffold-generator.md        # Agent: generate IT scaffolds for .bar files
```

## Installation

```bash
# From the toolkit root
cp -r templates/test-toolkit/.claude/ /path/to/your-test-project/.claude/
chmod +x /path/to/your-test-project/.claude/hooks/*.sh

# Commit
cd /path/to/your-test-project
git add .claude/
git commit -m "chore: adopt Claude Code toolkit for test project"
```

## Usage

```bash
# Run integration tests
/run-integration-tests                    # All IT tests
/run-integration-tests PaymentRequestIT   # Specific test

# Generate test scaffold
delegate to test-scaffold-generator: create tests for Process--1.0.bar

# Check coverage
/check-test-coverage
```
