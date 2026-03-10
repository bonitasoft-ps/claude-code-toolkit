---
name: bonita-bdm-generation
description: |
  Generate Bonita BDM (bom.xml) files from entity descriptions.
  Covers field types, relations, JPQL queries, indexes, constraints, and validation.
  Keywords: BDM, bom.xml, entity, field, relation, JPQL, query, generation, Business Data Model
allowed-tools: Read, Write, Grep, Glob, Bash
user-invocable: true
---

# BDM Generation for Bonita

Generate valid `bom.xml` (Business Data Model) files from entity descriptions.

## When activated

1. **Gather required inputs** — package name, entities with fields/relations, custom queries
2. **Generate the XML** following all rules below
3. **Validate** against the checklist before returning

---

## Required inputs

1. **Package name** — Java-style, e.g. `com.bonitasoft.hr`
2. **Entities** — name, fields (name + type), relations to other entities
3. **Custom queries** — any non-standard queries the process needs

---

## bom.xml root structure

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<businessObjectModel xmlns="http://documentation.bonitasoft.com/bdm-xml-schema/1.0">
  <businessObjects>
    <!-- one <businessObject> per entity -->
  </businessObjects>
</businessObjectModel>
```

## Entity structure

```xml
<businessObject qualifiedName="com.bonitasoft.hr.LeaveRequest">
  <fields>
    <simpleField name="startDate"   type="LOCALDATE"  nullable="false"/>
    <simpleField name="endDate"     type="LOCALDATE"  nullable="false"/>
    <simpleField name="reason"      type="TEXT"        nullable="true"/>
    <simpleField name="approved"    type="BOOLEAN"     nullable="false"/>
    <relationField name="employee"
                   type="AGGREGATION"
                   reference="com.bonitasoft.hr.Employee"
                   multiple="false"
                   nullable="false"
                   fetchType="EAGER"/>
  </fields>
  <uniqueConstraints/>
  <indexes>
    <index name="idx_leaveRequest_startDate" fieldNames="startDate"/>
  </indexes>
  <queries>
    <query name="findByEmployee"
           content="SELECT l FROM LeaveRequest l WHERE l.employee.persistenceId = :employeeId"
           returnType="java.util.List">
      <queryParameters>
        <queryParameter name="employeeId" className="java.lang.Long"/>
      </queryParameters>
    </query>
  </queries>
</businessObject>
```

---

## Field types reference

| BDM Type | Java Type | Notes |
|----------|-----------|-------|
| `STRING` | String | Max length configurable, default 255 |
| `TEXT` | String | Unlimited length |
| `INTEGER` | Integer | |
| `LONG` | Long | Use for IDs and large numbers |
| `DOUBLE` | Double | Floating point |
| `FLOAT` | Float | |
| `BOOLEAN` | Boolean | |
| `DATE` | Date | Deprecated — prefer LOCALDATE |
| `DATETIME` | Date | Deprecated — prefer LOCALDATETIME |
| `LOCALDATE` | LocalDate | Date without time (Java 8+) |
| `LOCALDATETIME` | LocalDateTime | Date with time (Java 8+) |
| `BYTE` | Byte[] | Binary data |

---

## Relation types

| Type | Meaning | DB impact |
|------|---------|-----------|
| `COMPOSITION` | Child cannot exist without parent | CASCADE DELETE |
| `AGGREGATION` | Independent objects, optional relation | No cascade |

```xml
<!-- One-to-many composition -->
<relationField name="leaveRequests" type="COMPOSITION"
               reference="com.company.LeaveRequest"
               multiple="true" fetchType="LAZY"/>

<!-- Many-to-one aggregation -->
<relationField name="employee" type="AGGREGATION"
               reference="com.company.Employee"
               multiple="false" fetchType="EAGER"/>
```

---

## JPQL query rules

- Entity alias: lowercase first letter of entity name (`LeaveRequest` -> `l`)
- Parameters prefixed with `:` in content, declared in `<queryParameters>`
- Return type is always full Java class: `java.util.List`, `java.lang.Long`

---

## Naming conventions

| Item | Convention | Example |
|------|-----------|---------|
| Entity | PascalCase | `LeaveRequest` |
| qualifiedName | package + entity | `com.company.LeaveRequest` |
| Field name | camelCase | `startDate`, `isApproved` |
| Query name | camelCase, starts with `find`/`count`/`search` | `findByEmployee` |
| Index name | `idx_{entity}_{field}` | `idx_leaveRequest_startDate` |
| Constraint | `uc_{entity}_{fields}` | `uc_employee_email` |

---

## Validation checklist

- [ ] `qualifiedName` contains full package path
- [ ] All `relationField` `reference` values match existing entity `qualifiedName`
- [ ] JPQL aliases match entity name pattern
- [ ] All query parameters declared in `<queryParameters>`
- [ ] No field named `persistenceId` (reserved by Bonita)
- [ ] No circular COMPOSITION relations
