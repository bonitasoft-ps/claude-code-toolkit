# Multi-Repo Configuration Examples

## Environment Variables (recommended)

```bash
# In ~/.bashrc or ~/.zshrc
export BONITA_PS_ROOT="/home/user/PSProjects"
export BONITA_TOOLKIT_PATH="$BONITA_PS_ROOT/bonita-upgrade-toolkit"
export BONITA_AUDIT_PATH="$BONITA_PS_ROOT/bonita-audit-toolkit"
export BONITA_CONNECTORS_PATH="$BONITA_PS_ROOT/bonita-connectors-generator-toolkit"
export BONITA_TEST_TOOLKIT_PATH="$BONITA_PS_ROOT/template-test-toolkit"
export BONITA_DOCS_PATH="$BONITA_PS_ROOT/bonita-docs-toolkit"
```

## Batch Operations

```bash
# Status check across all repos
for repo in bonita-upgrade-toolkit bonita-audit-toolkit bonita-connectors-generator-toolkit \
            template-test-toolkit bonita-docs-toolkit bonita-ai-agent-mcp claude-code-toolkit; do
  echo "=== $repo ==="
  (cd "$BONITA_PS_ROOT/$repo" && git status -sb)
done

# Pull all repos
for repo in bonita-*-toolkit template-test-toolkit bonita-ai-agent-mcp claude-code-toolkit; do
  (cd "$BONITA_PS_ROOT/$repo" && git pull --rebase)
done
```

## Claude Desktop MCP Config

```json
{
  "mcpServers": {
    "bonita-ps": {
      "command": "node",
      "args": ["bonita-ai-agent-mcp/src/index.js"],
      "env": {
        "BONITA_TOOLKIT_PATH": "/path/to/bonita-upgrade-toolkit",
        "BONITA_AUDIT_PATH": "/path/to/bonita-audit-toolkit",
        "BONITA_CONNECTORS_PATH": "/path/to/bonita-connectors-generator-toolkit",
        "BONITA_TEST_TOOLKIT_PATH": "/path/to/template-test-toolkit",
        "BONITA_DOCS_PATH": "/path/to/bonita-docs-toolkit"
      }
    }
  }
}
```
