---
name: bonita-bdm-expert
description: |
  BDM expert guidance — redirects to bonita-bdm-generator-toolkit for complete knowledge.
  Keywords: BDM, bom.xml, JPQL, business objects, database design, indexes, unique constraints, countFor, access control
allowed-tools: Read, Grep, Glob
user-invocable: true
---

# Bonita BDM Expert

For comprehensive BDM expertise, use the **bonita-bdm-generator-toolkit** which contains:

## Knowledge Base
- **bonita-bdm-complete-reference.md** -- XML schema, field types, relations, queries, auto-generated queries, SQL validation
- **bdm-best-practices.md** -- Naming, countFor rule, indexes, audit fields, access control, anti-patterns
- **bdm-patterns.md** -- Design patterns with XML fragments (master-detail, audit, status, tree, multi-tenant)
- **bdm-to-contract-mapping.md** -- Contract mapping, Groovy scripts for create/update
- **bdm-rest-api-queries.md** -- REST API endpoints, pagination, BTT DAO access
- **bdm-access-control.md** -- Profile-based field visibility configuration

## Skill
- **bonita-bdm-expert** -- Complete skill for design, generation, validation, and optimization

## Quick Reference: Mandatory Rules

1. **Descriptions**: ALL elements MUST have `<description>` tags
2. **countFor**: Every `List` query needs matching `countFor` (REST API pagination)
3. **Indexes**: For every field in WHERE/ORDER BY/JOIN of used queries
4. **Audit fields**: `createdBy`, `createdDate`, `modifiedBy`, `modifiedDate`, `processInstanceId`
5. **Reserved words**: Never use `type`, `status`, `order`, `group`, `user` as field names
6. **Relations**: LAZY for collections, COMPOSITION only when child lifecycle is tied to parent
