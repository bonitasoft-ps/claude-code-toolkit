---
name: bonita-bdm-generation
description: |
  BDM generation — redirects to bonita-bdm-generator-toolkit for complete generation capability.
  Keywords: BDM, bom.xml, entity, field, relation, JPQL, query, generation, Business Data Model
allowed-tools: Read, Grep, Glob
user-invocable: true
---

# BDM Generation for Bonita

For complete BDM generation, use the **bonita-bdm-generator-toolkit** which contains:

## Knowledge Base
- **bonita-bdm-complete-reference.md** -- Full XML schema, all field types, relation semantics, query syntax, validation rules
- **bdm-best-practices.md** -- Naming conventions, data integrity, countFor, indexes
- **bdm-patterns.md** -- Proven patterns with complete XML fragments
- **bdm-to-contract-mapping.md** -- How BDM maps to contracts and Groovy scripts

## Skill
- **bonita-bdm-expert** -- Complete skill for BDM generation and validation

## Quick Reference: bom.xml Root Structure

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<businessObjectModel xmlns="http://documentation.bonitasoft.com/bdm-xml-schema/1.0"
                     modelVersion="1.0" productVersion="10.2.0">
  <businessObjects>
    <businessObject qualifiedName="com.company.model.EntityName">
      <fields>...</fields>
      <uniqueConstraints>...</uniqueConstraints>
      <indexes>...</indexes>
      <queries>...</queries>
    </businessObject>
  </businessObjects>
</businessObjectModel>
```

## Validation Essentials
- No `persistenceId` field (auto-generated)
- No circular COMPOSITION chains
- All relation `reference` values match existing `qualifiedName`
- JPQL uses valid field names and `:paramName` syntax
- Custom query names don't clash with auto-generated ones
