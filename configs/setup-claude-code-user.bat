@echo off
REM =============================================================================
REM setup-claude-code-user.bat — Configure Claude Code user-level settings
REM =============================================================================
REM
REM What it does:
REM   1. Creates %USERPROFILE%\.claude\settings.json with smart permissions
REM   2. Creates %USERPROFILE%\.claude\CLAUDE.md with global user instructions
REM   3. Enables experimental Agent Teams feature
REM   4. Installs Playwright MCP server for browser automation
REM
REM Why:
REM   Claude Code asks permission for every file read, git status, and test run
REM   by default. This script pre-approves safe, read-only operations so you can
REM   work fluidly without constant interruptions.
REM
REM Usage:
REM   setup-claude-code-user.bat
REM
REM Safe to re-run: backs up existing files before overwriting.
REM =============================================================================

setlocal enabledelayedexpansion

set CLAUDE_DIR=%USERPROFILE%\.claude
set SETTINGS_FILE=%CLAUDE_DIR%\settings.json
set INSTRUCTIONS_FILE=%CLAUDE_DIR%\CLAUDE.md

echo ============================================
echo   Claude Code — User Settings Setup
echo ============================================
echo.

REM Create .claude directory if needed
if not exist "%CLAUDE_DIR%" mkdir "%CLAUDE_DIR%"

REM --- 1. Backup and create settings.json ---
if exist "%SETTINGS_FILE%" (
    set BACKUP=%SETTINGS_FILE%.backup.%DATE:~-4%%DATE:~-7,2%%DATE:~-10,2%
    copy "%SETTINGS_FILE%" "!BACKUP!" >nul
    echo [backup] Existing settings.json backed up
)

(
echo {
echo   "env": {
echo     "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
echo   },
echo   "permissions": {
echo     "allow": [
echo       "Read",
echo       "Glob",
echo       "Grep",
echo       "Bash(ls *)",
echo       "Bash(find *)",
echo       "Bash(cat *)",
echo       "Bash(head *)",
echo       "Bash(tail *)",
echo       "Bash(wc *)",
echo       "Bash(du *)",
echo       "Bash(git status*)",
echo       "Bash(git log*)",
echo       "Bash(git diff*)",
echo       "Bash(git branch*)",
echo       "Bash(git remote*)",
echo       "Bash(git show*)",
echo       "Bash(npm test*)",
echo       "Bash(npm run test*)",
echo       "Bash(node --test*)",
echo       "Bash(mvn test*)",
echo       "Bash(mvn compile*)",
echo       "Bash(mvn verify*)",
echo       "Bash(npm run check*)",
echo       "Bash(npm run lint*)",
echo       "Bash(npm run build*)"
echo     ],
echo     "deny": []
echo   },
echo   "autoUpdatesChannel": "latest"
echo }
) > "%SETTINGS_FILE%"

echo [ok] settings.json created with smart permissions

REM --- 2. Backup and create CLAUDE.md ---
if exist "%INSTRUCTIONS_FILE%" (
    set BACKUP2=%INSTRUCTIONS_FILE%.backup.%DATE:~-4%%DATE:~-7,2%%DATE:~-10,2%
    copy "%INSTRUCTIONS_FILE%" "!BACKUP2!" >nul
    echo [backup] Existing CLAUDE.md backed up
)

(
echo # Claude Code — Global User Instructions ^(Bonitasoft PS^)
echo.
echo ## Language and communication
echo.
echo - Default conversation language: user's preference
echo - Technical documentation always in English
echo - Concise and direct responses
echo - No emojis unless explicitly requested
echo.
echo ## Permissions and autonomy
echo.
echo - Read files without asking: Any text file, source code, config, logs
echo - Search without asking: Glob, Grep, and codebase searches
echo - Run tests without asking: npm test, mvn test, node --test
echo - Git read-only without asking: git status, git log, git diff
echo - Ask permission for: git commit, git push, create/delete files
echo.
echo ## Work style
echo.
echo - Parallel execution: Launch agents and tasks in parallel
echo - Be proactive: Fix issues directly within allowed permissions
echo - No over-engineering: Simple, direct solutions
echo - Java 17: Records, Sealed Classes, Pattern Matching
echo - Node.js: ES Modules, async/await, node --test
echo.
echo ## Bonitasoft PS context
echo.
echo - Professional Services: upgrades, audits, connectors, tests, training
echo - 7-repo ecosystem with MCP server ^(57 tools^)
echo - Connector lifecycle: VALIDATE, CONNECT, EXECUTE, DISCONNECT
echo.
echo ## Sensitive files
echo.
echo - NEVER commit: .env, credentials.json, *.pem, *.key
echo - Proposals/pricing: LOCAL only
) > "%INSTRUCTIONS_FILE%"

echo [ok] CLAUDE.md created with global instructions

REM --- 3. Install Playwright MCP ---
echo.
echo Installing Playwright MCP server for browser automation...
where claude >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    claude mcp add playwright -- npx @playwright/mcp@latest >nul 2>&1
    echo [ok] Playwright MCP installed for Claude Code
) else (
    echo [skip] Claude Code CLI not found. Install Playwright MCP manually:
    echo        claude mcp add playwright -- npx @playwright/mcp@latest
)

REM --- Summary ---
echo.
echo ============================================
echo   Setup Complete
echo ============================================
echo.
echo   Settings:     %SETTINGS_FILE%
echo   Instructions: %INSTRUCTIONS_FILE%
echo.
echo   Restart Claude Code or VS Code for changes to take effect.

endlocal
