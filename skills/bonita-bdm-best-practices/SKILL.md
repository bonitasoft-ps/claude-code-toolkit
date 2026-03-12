---
name: bonita-bdm-best-practices
description: |
  BDM best practices — redirects to bonita-bdm-generator-toolkit for complete guidance.
  Keywords: bdm rules, bdm best practices, bom xml, bdm query, bdm index, countFor, bdm naming
allowed-tools: Read, Grep, Glob
user-invocable: true
---

# Bonita BDM Best Practices

For comprehensive BDM best practices, use the **bonita-bdm-generator-toolkit** which contains:

## Knowledge Base
- **bdm-best-practices.md** -- Naming, countFor, indexes, relations, anti-patterns, audit fields, access control
- **bonita-bdm-complete-reference.md** -- XML schema, field types, SQL validation rules
- **bdm-patterns.md** -- Design patterns (master-detail, audit, status, tree, multi-tenant)
- **bdm-access-control.md** -- Profile-based field visibility rules

## Skill
- **bonita-bdm-expert** -- Complete skill for BDM design, generation, and validation

## Quick Reference: Key Rules

1. **countFor**: Every `List` query needs a matching `countFor` query (REST API pagination)
2. **Descriptions**: ALL elements (objects, fields, queries, indexes, constraints) MUST have `<description>`
3. **Indexes**: MANDATORY for every field in WHERE/ORDER BY/JOIN of used queries
4. **Reserved words**: NEVER use `type`, `status`, `order`, `group`, `user` as field names
5. **Relations**: LAZY fetch for collections, EAGER only for always-needed single relations
6. **Audit fields**: `createdBy`, `createdDate`, `modifiedBy`, `modifiedDate`, `processInstanceId`
