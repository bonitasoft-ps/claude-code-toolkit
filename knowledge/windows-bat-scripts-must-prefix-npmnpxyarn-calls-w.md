# Windows .bat scripts must prefix npm/npx/yarn calls with 'call'

> Auto-generated from learning proposal PROP-1782468909045-4dada0

## Context
PS tooling setup script (setup-ps-tools.bat) on Windows 11

## Description
On Windows, npm/npx/yarn/pnpm are batch scripts (npm.cmd), not real .exe binaries. When a .bat invokes another .cmd WITHOUT the 'call' keyword, cmd.exe transfers control permanently and never returns to the parent script. The parent .bat just ends silently. This makes installer/setup scripts abort mid-flow with no error message. Real .exe tools (git, node) are unaffected, which makes the bug confusing to diagnose since the failure appears right after an unrelated check. Any .bat helper/installer in the toolkits is exposed to this.

## Problem
setup-ps-tools.bat stopped silently right after the Node.js check and never reached the npm verification on Windows. No error, no output, parent script just terminated.

## Solution
Prefix every direct invocation of a .cmd-backed CLI with 'call': 'call npm --version', 'call npm install'. Note: invocations inside a 'for /f (...)' command-substitution block run in a subshell and are NOT affected, so they don't need 'call'. Rule of thumb: any bare npm/npx/yarn/pnpm on its own line in a .bat must start with 'call'.

## Action Items
- [ ] Add a Windows scripting guideline to claude-code-toolkit: in .bat files, prefix npm/npx/yarn/pnpm (and any .cmd) with 'call'
- [ ] Add a lint/grep check in CI or a pre-commit hook: flag lines matching ^\s*(npm|npx|yarn|pnpm)\s in any .bat file
- [ ] Audit all existing .bat installer/helper scripts across the 14 toolkits for bare .cmd invocations

## References
- Proposal: PROP-1782468909045-4dada0
- Category: pattern
- Priority: high
