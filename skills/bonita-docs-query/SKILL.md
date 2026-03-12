---
name: bonita-docs-query
description: |
  Query official Bonita documentation using RAG-powered search. Answers questions about
  Bonita features, configuration, REST API, BDM, processes, UI, connectors, and administration.
  Supports version-specific queries and cross-version comparisons.
  Trigger: "bonita docs", "how does bonita", "bonita documentation", "search docs", "bonita help", "REST API bonita"
allowed-tools: Read, Grep, Glob, mcp__Bonita-AI-Agent__search_bonita_docs, mcp__Bonita-AI-Agent__get_bonita_doc_page, mcp__Bonita-AI-Agent__list_doc_versions, mcp__Bonita-AI-Agent__bonita_rest_api_lookup, mcp__Bonita-AI-Agent__bonita_rest_api_schema, mcp__Bonita-AI-Agent__check_doc_updates, mcp__Bonita-AI-Agent__compare_doc_versions
user_invocable: true
---

# Bonita Documentation Query

## When to Use
- User asks "how does X work in Bonita?"
- Need to look up REST API endpoints
- Check configuration options
- Verify behavior differences between versions
- Find official documentation for a feature

## Query Workflow

### Step 1: Understand the Question
Identify:
- Topic area (process, BDM, connector, REST API, admin, UI, etc.)
- Bonita version (if version-specific)
- Level of detail needed

### Step 2: Search Documentation
Use MCP tools in this order:
1. `search_bonita_docs` — RAG hybrid search (vector + full-text)
2. `get_bonita_doc_page` — get specific page if you know the topic
3. `bonita_rest_api_lookup` — for REST API endpoint queries
4. `bonita_rest_api_schema` — for API request/response schemas

### Step 3: Version-Specific Queries
- `list_doc_versions` — see all indexed versions (21 versions)
- `compare_doc_versions` — compare feature between versions
- `check_doc_updates` — see what changed in a version

## Common Query Patterns

### REST API
"How do I start a process via REST API?"
→ `bonita_rest_api_lookup` with topic "process instantiation"

"What's the endpoint for BDM queries?"
→ `bonita_rest_api_lookup` with topic "BDM query"

### Configuration
"How do I configure LDAP?"
→ `search_bonita_docs` with query "LDAP configuration"

"How to set up SSO?"
→ `search_bonita_docs` with query "SSO SAML configuration"

### Migration
"What changed between 7.11 and 2021.1?"
→ `compare_doc_versions` with source and target

### Features
"How do timers work?"
→ `search_bonita_docs` with query "timer events BPMN"

## Version Coverage
21 indexed versions from 7.3 to 2024.3, covering:
- Installation and configuration
- Process design and deployment
- BDM and data management
- REST API reference
- UI Designer and UI Builder
- Connectors and extensions
- Administration and monitoring

## Tips
- Be specific in queries: "BDM JPQL query syntax" > "BDM"
- Specify version when relevant: "REST API authentication 2024.1"
- Use `bonita_rest_api_schema` for exact request/response formats
- Cross-reference multiple versions for migration planning
