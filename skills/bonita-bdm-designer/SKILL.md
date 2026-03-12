---
name: bonita-bdm-designer
description: |
  BDM design and generation — redirects to bonita-bdm-generator-toolkit for complete guidance.
  Keywords: bdm, business data model, bom.xml, data model, entities, business object
allowed-tools: Read, Grep, Glob
user-invocable: true
---

# Bonita BDM Designer

For comprehensive BDM design and generation, use the **bonita-bdm-generator-toolkit** which contains:

## Knowledge Base
- **bonita-bdm-complete-reference.md** -- XML schema, all field types with Java/SQL mappings, relation types, query syntax
- **bdm-patterns.md** -- Design patterns (master-detail, reference data, audit trail, status, tree, multi-tenant, document storage)
- **bdm-to-contract-mapping.md** -- BDM-to-contract type mapping, Groovy scripts, form widget mapping
- **bdm-best-practices.md** -- Naming conventions, data integrity, anti-patterns

## Skill
- **bonita-bdm-expert** -- Complete skill for BDM design, generation, and validation

## Quick Reference: Field Types

| BDM Type | Java Type | Use Case |
|----------|-----------|----------|
| STRING | String | Short text (max 255) |
| TEXT | String | Long text (unlimited) |
| INTEGER | Integer | Whole numbers |
| LONG | Long | Large numbers, IDs |
| DOUBLE | Double | Decimals |
| BOOLEAN | Boolean | True/false |
| LOCALDATE | LocalDate | Date without time |
| LOCALDATETIME | LocalDateTime | Date with time |
| OFFSETDATETIME | OffsetDateTime | Date + time + timezone |
| BYTE | byte[] | Binary data |
