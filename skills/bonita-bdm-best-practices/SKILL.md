---
name: bonita-bdm-best-practices
description: "BDM best practices: naming, queries, indexes, countFor, access control, and common anti-patterns."
user_invocable: true
trigger_keywords: ["bdm rules", "bdm best practices", "bom xml", "bdm query", "bdm index", "countFor", "bdm naming"]
allowed-tools: Read, Grep, Glob, Bash
---

# Bonita BDM Best Practices

You are an expert in Bonita Business Data Model design and optimization.

## Naming Conventions

### Business Objects
- Use a project prefix: `{PX}EntityName` (e.g., PBProcess, CSCustomer)
- PascalCase for object names
- Singular form (not plural)
- Qualified name: `com.{company}.{domain}.{PXEntityName}`

### Fields
- camelCase: `firstName`, `creationDate`, `accountId`
- Relations: object name lowercase, singular/plural by multiplicity
  - Single: `customer`, `environment`
  - Collection: `attachmentsList`, `commentsList`
- NEVER use SQL reserved words: `type`, `status`, `order`, `group`, `user`
  - Instead: `entityType`, `entityStatus`, `sortOrder`, `userGroup`

### Constraints and Indexes
- Unique constraint: max 20 chars, valid SQL identifier
- Index: max 20 chars, pattern `idx{Entity}{Field}` or `idx{E}{F1}{F2}`
- Both MUST have description explaining what they enforce/optimize

## Description Rule (MANDATORY)
Every element MUST have a `<description>` tag:
- businessObject — what it represents and why
- field — purpose, valid values, format
- query — what it retrieves and when to use it
- uniqueConstraint — what business rule it enforces
- index — which queries it optimizes

## Data Integrity Rules

### Mandatory Fields
- Every object must have at least one `nullable="false"` field
- Typically: the primary business identifier (name, code, etc.)

### Unique Constraints
- Add when a field or combination MUST be unique
- Document WHAT business rule and WHY
- Examples: username, email, code+type combination

### String/TEXT Control
- STRING: max 255 chars (standard fields)
- TEXT: unlimited (JSON payloads, large descriptions, HTML content)
- Always set explicit `length` for STRING fields

## Query Rules

### countFor Queries (99% RULE)
For EVERY query returning `java.util.List`, create a matching count query:
```xml
<query name="findByStatus"
       content="SELECT e FROM Entity e WHERE e.status = :status ORDER BY e.createdAt DESC"
       returnType="java.util.List">
    <queryParameters>
        <queryParameter name="status" className="java.lang.String"/>
    </queryParameters>
</query>
<query name="countForFindByStatus"
       content="SELECT COUNT(e) FROM Entity e WHERE e.status = :status"
       returnType="java.lang.Long">
    <queryParameters>
        <queryParameter name="status" className="java.lang.String"/>
    </queryParameters>
</query>
```
This is CRITICAL for REST API pagination.

### Query Naming
- `findBy{Field}` — single field filter
- `findBy{Field1}And{Field2}` — multi-field filter
- `findAll` — no filter (with ORDER BY)
- `countForFindBy...` — matching count
- `findActive{Entity}s` — semantic queries

### JPQL Best Practices
- Always include ORDER BY for deterministic results
- Use named parameters `:paramName` not positional `?1`
- Join relations via `.persistenceId` for lazy-loaded relations:
  ```sql
  WHERE e.parent.persistenceId = :parentId
  ```
- Use `IS NULL` / `IS NOT NULL` for nullable checks
- For boolean checks: `e.isActive = true` or `e.isActive <> true`

## Index Rules

### When to Index (MANDATORY)
Create index for every field used in:
- WHERE clause of USED queries
- ORDER BY clause
- JOIN conditions
- Combined conditions → composite index

### Index Structure
```xml
<index>
    <indexName>idxByStatus</indexName>
    <description>Optimizes findByStatus and countForFindByStatus queries</description>
    <fieldNames>
        <fieldName>status</fieldName>
    </fieldNames>
</index>
<!-- Composite index for multi-field queries -->
<index>
    <indexName>idxByTypeDate</indexName>
    <description>Optimizes findByTypeAndDate query with type filter and date ordering</description>
    <fieldNames>
        <fieldName>entityType</fieldName>
        <fieldName>createdAt</fieldName>
    </fieldNames>
</index>
```

### Usage Verification
Only index queries that are ACTUALLY USED in:
- REST API extensions (via DAO calls)
- Process scripts (via Groovy/BDM API)
- BDM REST endpoints (/API/bdm/businessData/)

## Relation Design

### AGGREGATION vs COMPOSITION
- **AGGREGATION**: Referenced entity exists independently (most common)
  - Example: Order → Customer (customer exists independently)
- **COMPOSITION**: Child entity lifecycle tied to parent
  - Example: Order → OrderLine (lines don't exist without order)
  - Child is deleted when parent is deleted

### Fetch Strategy
- **LAZY** (default, recommended): Load on demand
  - Use for collections and rarely-accessed relations
- **EAGER**: Load immediately with parent
  - Use only for always-needed single relations
  - NEVER use EAGER on collections

## Access Control
- `bdm_access_control.xml` restricts field visibility per profile
- Apply principle of least privilege
- Restrict sensitive fields (financial, personal data)

## Common Anti-Patterns

1. **No countFor queries** — Breaks pagination in REST APIs
2. **Missing indexes** — Causes slow queries at scale
3. **All fields nullable** — No data integrity
4. **No descriptions** — Unmaintainable model
5. **EAGER fetch on collections** — N+1 performance disaster
6. **SQL reserved words as field names** — Portability issues
7. **Missing unique constraints** — Duplicate data
8. **TEXT type for short strings** — Wastes storage, prevents indexing

## MCP Tools
- `generate_bdm` — Generate bom.xml from specification
- `validate_bdm` — Validate BDM against best practices
- `analyze_bdm_queries` — Check countFor coverage and index alignment
