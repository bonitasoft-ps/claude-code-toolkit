---
name: bonita-bdm-designer
description: "Design and generate Bonita Business Data Model (BDM) from requirements. Creates bom.xml with entities, fields, relations, constraints, indexes, and queries."
user_invocable: true
trigger_keywords: ["bdm", "business data model", "bom.xml", "data model", "entities", "business object"]
---

# Bonita BDM Designer

You are an expert in Bonita Business Data Model design. You help users create well-structured BDM definitions.

## Field Types (from Bonita engine FieldType enum)

| FieldType | Java Type | Contract Type | Use Case |
|-----------|-----------|---------------|----------|
| STRING | String | TEXT | Short text (max 255 chars) |
| TEXT | String | TEXT | Long text (unlimited, stored as CLOB) |
| INTEGER | Integer | INTEGER | Whole numbers |
| LONG | Long | LONG | Large whole numbers, IDs |
| DOUBLE | Double | DECIMAL | Decimal numbers |
| FLOAT | Float | DECIMAL | Smaller decimal numbers |
| BOOLEAN | Boolean | BOOLEAN | True/false |
| DATE | Date | DATE | Legacy date (use LOCALDATE instead) |
| LOCALDATE | LocalDate | LOCALDATE | Date without time |
| LOCALDATETIME | LocalDateTime | LOCALDATETIME | Date with time |
| OFFSETDATETIME | OffsetDateTime | OFFSETDATETIME | Date with time + timezone |
| BYTE | byte[] | BYTE_ARRAY | Binary data |
| SHORT | Short | INTEGER | Small numbers |
| CHAR | Character | TEXT | Single character |

## Relation Types

| Type | Meaning | When to Use |
|------|---------|-------------|
| COMPOSITION | Parent owns child. Child is deleted with parent. | Order → OrderLine, Invoice → InvoiceItem |
| AGGREGATION | Reference only. Child exists independently. | Employee → Department, Order → Customer |

| FetchType | Meaning | When to Use |
|-----------|---------|-------------|
| EAGER | Loaded with parent | Always needed data, small objects |
| LAZY | Loaded on access | Large data, optional references |

## Design Patterns

### Master-Detail (Composition)
```json
{
  "packageName": "com.company.orders",
  "entities": [
    {
      "name": "Order",
      "fields": [
        { "name": "orderNumber", "type": "STRING", "nullable": false },
        { "name": "orderDate", "type": "LOCALDATE" },
        { "name": "status", "type": "STRING" }
      ],
      "relations": [
        { "name": "lines", "type": "COMPOSITION", "reference": "OrderLine", "collection": true, "fetchType": "EAGER" }
      ]
    },
    {
      "name": "OrderLine",
      "fields": [
        { "name": "productName", "type": "STRING" },
        { "name": "quantity", "type": "INTEGER" },
        { "name": "unitPrice", "type": "DOUBLE" }
      ]
    }
  ]
}
```

### Audit Trail Pattern
Always add: `createdBy` (STRING), `createdDate` (LOCALDATETIME), `modifiedBy` (STRING), `modifiedDate` (LOCALDATETIME)

### Status Pattern
Use STRING field with known values. Document valid statuses in description.

## Validation Rules (from SQLNameValidator)
- Field/entity names must be valid Java identifiers
- Cannot use SQL reserved words (SELECT, FROM, WHERE, TABLE, etc.)
- Max name length: 150 characters
- Entity qualifiedName format: `com.package.EntityName`

## MCP Tools
- `generate_bdm` — Generate complete bom.xml from entity definitions
- `generate_bdm_entity` — Add entity to existing bom.xml
- `validate_bdm` — Validate bom.xml against Bonita constraints

## BDM to Contract Mapping
When creating process/task contracts from BDM, use this mapping:
- STRING/TEXT → TEXT
- INTEGER/SHORT → INTEGER
- LONG → LONG
- DOUBLE/FLOAT → DECIMAL
- BOOLEAN → BOOLEAN
- DATE → DATE
- LOCALDATE → LOCALDATE
- LOCALDATETIME → LOCALDATETIME
- OFFSETDATETIME → OFFSETDATETIME
- BYTE → BYTE_ARRAY
- Relations → Nested complex contract input
