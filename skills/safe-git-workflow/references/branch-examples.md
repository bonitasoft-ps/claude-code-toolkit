# Branch & PR Examples — PS Ecosystem

## Branch Name Examples

| Change | Branch Name |
|--------|-------------|
| Add 5 test tools to MCP server | `claude/feat/add-test-tools` |
| Fix audit category mapping | `claude/fix/audit-category-map` |
| Update all READMEs with ecosystem table | `claude/docs/update-readme-ecosystem` |
| Refactor helpers into separate module | `claude/refactor/extract-helpers` |
| Add setup-tools.test.js assertions | `claude/test/setup-tools-assertions` |
| Bump version to v2.5.0 | `claude/chore/bump-v2.5.0` |
| Add safe-git-workflow hook | `claude/feat/safe-git-workflow` |
| Fix GETTING-STARTED.md env vars | `claude/fix/getting-started-env-vars` |
| Add scaffold-toolkit skill | `claude/feat/scaffold-toolkit` |
| Update CHANGELOG for v2.5 | `claude/docs/changelog-v2.5` |

## PR Title Examples

| Branch | PR Title |
|--------|----------|
| `claude/feat/add-test-tools` | feat: add 5 integration test tools (test-tools.js) |
| `claude/fix/audit-category-map` | fix: correct audit category mapping for BDM standards |
| `claude/docs/update-readme-ecosystem` | docs: update README with 6-repo ecosystem table |
| `claude/feat/safe-git-workflow` | feat: add safe-git-workflow hook and skill |

## PR Body Template

```markdown
## Summary
- {What changed}
- {Why it changed}
- {What it enables}

## Test plan
- [ ] Run `npm test` — all tests pass
- [ ] Verify {specific behavior}
- [ ] Check {integration point}

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```
