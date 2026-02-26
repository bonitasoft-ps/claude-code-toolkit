# BDM Data Model Rules — Complete Reference

This document contains the complete, detailed rules for Bonita Business Data Model (BDM) naming conventions, data integrity, and structural requirements. These rules apply exclusively to the `bom.xml` file and the resulting BDM definition.

---

## 1. Naming Conventions

### 1.1 Business Objects (BDM Objects)

- **MANDATORY prefix**: Use the project-specific prefix `PB` (e.g., `PBProcessInstance`, `PBCategory`, `PBAction`, `PBGenericEntry`)
- The prefix indicates the object's origin project and prevents naming collisions across applications
- Object names use **PascalCase** after the prefix

**Examples:**
| Good | Bad | Why |
|------|-----|-----|
| `PBProcessInstance` | `ProcessInstance` | Missing PB prefix |
| `PBCategory` | `PB_Category` | No underscores, use PascalCase |
| `PBStepProcessInstance` | `pbStepProcessInstance` | Prefix must be uppercase PB |

### 1.2 Attributes (Fields)

- Use **`camelCase`** convention
- Name must clearly indicate what the field stores
- First letter lowercase, subsequent words capitalized

**Examples:**
| Good | Bad | Why |
|------|-----|-----|
| `firstName` | `firstname` | Missing camelCase separation |
| `creationDate` | `creation_date` | No underscores in BDM fields |
| `processInstanceId` | `ProcessInstanceId` | First letter must be lowercase |
| `refEntityType` | `ref_entity_type` | Use camelCase, not snake_case |

### 1.3 Relations (Referenced Objects)

- Use the **object name without the PB prefix**, in **lowercase**
- Use **singular** for single references (many-to-one, one-to-one)
- Use **plural** (or `List` suffix) for collection references (one-to-many, many-to-many)

**Examples:**
| Relation Type | Good | Bad | Why |
|--------------|------|-----|-----|
| Single (many-to-one) | `customer` | `PBCustomer` | Remove prefix, use lowercase |
| Single (one-to-one) | `category` | `Category` | Must be lowercase |
| Collection (one-to-many) | `stepsList` | `steps` | Use List suffix for clarity |
| Collection (many-to-many) | `tagsList` | `PBTagsList` | Remove prefix |

### 1.4 Reserved Keywords — AVOID

**NEVER** use these as attribute names — they are SQL reserved keywords and cause portability issues across database vendors:

- `type` -- use `entityType`, `refType`, `categoryType` instead
- `status` -- use `currentStatus`, `processStatus`, `stepStatus` instead
- `order` -- use `sortOrder`, `displayOrder` instead
- `group` -- use `groupName`, `userGroup` instead
- `key` -- use `configKey`, `lookupKey` instead
- `value` -- use `configValue`, `entryValue` instead
- `name` -- generally safe but prefer more descriptive names like `fullName`, `displayName`
- `date` -- use `creationDate`, `dueDate`, etc.

Even if these work today, they generate warnings and may break on different database engines.

### 1.5 Index Names

- Format: `idx_{table}_{field}` or `idx_{table}_{f1}_{f2}` for composites
- **Maximum 20 characters** (database constraint)
- Must be a **valid SQL identifier** (letters, numbers, underscores; no spaces or special chars)
- Abbreviate intelligently when needed for length

**Examples:**
| Good | Bad | Why |
|------|-----|-----|
| `idxCatFullName` | `index_for_category_full_name` | Too long (>20 chars) |
| `idxProcInstPId` | `idx ProcInst PId` | Spaces not allowed |
| `idxEntryTypeRef` | `IDX_ENTRY_TYPE_REF` | Prefer lowercase for consistency |

### 1.6 Unique Constraint Names

- **Maximum 20 characters**
- Must be a **valid SQL identifier**
- Name should hint at what uniqueness is being enforced
- Description must state the business rule

**Examples:**
| Good | Description |
|------|-------------|
| `ucCatFullName` | "Prevents duplicate category names" |
| `ucEntryNameType` | "Ensures unique combination of fullName and refEntityType" |

---

## 2. Description Fields (Documentation)

### 2.1 The Rule

**EVERY** element in `bom.xml` that supports a `<description>` tag MUST have a non-empty, meaningful description. This applies to:

- `<businessObject>` -- describe what this object represents and its role in the process
- `<field>` -- describe what data it stores, valid values, and why it exists
- `<index>` -- describe which queries it optimizes
- `<query>` -- describe what it retrieves, when/where it is used, and by which consumers
- `<uniqueConstraint>` -- describe WHAT business rule is enforced and WHY

### 2.2 Quality Standards

**BAD descriptions** (just restating the name):
```xml
<field name="firstName">
  <description>The first name</description>  <!-- USELESS -->
</field>
```

**GOOD descriptions** (explaining purpose, usage, and context):
```xml
<field name="firstName">
  <description>First name of the contact person, displayed in the task list and used for search filters. Mandatory for process initiation.</description>
</field>
```

### 2.3 Index Description Pattern

Always state which queries the index optimizes:
```xml
<index name="idxProcInstPId">
  <description>Optimizes findByProcessInstanceId and countForFindByProcessInstanceId queries for fast process-instance-based lookups</description>
  <fieldPath>processInstanceId</fieldPath>
</index>
```

---

## 3. Data Integrity and Structure

### 3.1 Mandatory Attributes

- **RULE**: Each BDM Object MUST have **at least one mandatory attribute** (`nullable="false"`)
- This ensures basic data integrity -- objects cannot be created as completely empty shells
- Choose the most essential business field(s) as mandatory

**Example:**
```xml
<field name="fullName" type="STRING" length="255" nullable="false" collection="false">
  <description>Display name of the category. Mandatory because categories must always have a name for identification.</description>
</field>
```

### 3.2 Unique Constraints

- Add `<uniqueConstraint>` whenever a combination of attributes **must be unique** in the business domain
- The constraint's description MUST state:
  1. **WHAT** business rule is being enforced
  2. **WHY** duplicates would be problematic

**Example — single field uniqueness:**
```xml
<uniqueConstraint name="ucCatFullName" description="Prevents duplicate category names. Each category must have a unique fullName to avoid confusion in dropdowns and selections.">
  <fieldPath>fullName</fieldPath>
</uniqueConstraint>
```

**Example — composite uniqueness:**
```xml
<uniqueConstraint name="ucEntryNameType" description="Ensures unique combination of fullName and refEntityType. A generic entry name must be unique within its entity type to prevent data ambiguity.">
  <fieldPath>fullName</fieldPath>
  <fieldPath>refEntityType</fieldPath>
</uniqueConstraint>
```

### 3.3 String and TEXT Control

| Type | When to Use | Length |
|------|-------------|--------|
| `STRING` | Standard text fields (names, labels, references) | `length="255"` (default) |
| `STRING` | Short codes, identifiers | `length="50"` or `length="100"` |
| `TEXT` | JSON payloads, extended descriptions, rich content | No length limit |

**RULE**: Use `TEXT` **only** for content that might exceed 255 characters. Overusing TEXT degrades database performance and prevents indexing.

**Example:**
```xml
<!-- STRING for normal fields -->
<field name="fullName" type="STRING" length="255" nullable="false" collection="false">
  <description>Display name, max 255 characters</description>
</field>

<!-- TEXT only for large content -->
<field name="documents" type="TEXT" nullable="true" collection="false">
  <description>JSON payload containing document references for this step. Uses TEXT because JSON structure can exceed 255 characters.</description>
</field>
```

---

## 4. MANDATORY Audit Fields

Every BDM object that is linked to a Bonita process instance MUST include the following audit fields. These are essential for traceability, debugging, and data governance.

### 4.1 Required Fields

| Field | Type | Nullable | Purpose |
|-------|------|----------|---------|
| `creationDate` (or `auCreationDate`) | `DATE` | `false` | Timestamp when the record was created |
| `creationUser` | `STRING` (255) | `false` | Username/ID of the user who created the record |
| `modificationDate` | `DATE` | `true` | Timestamp of the last modification (null if never modified) |
| `modificationUser` | `STRING` (255) | `true` | Username/ID of the user who last modified the record |
| `processInstanceId` | `LONG` | `false` | **CRUCIAL** -- Links this record to its Bonita process instance |

### 4.2 Why processInstanceId Is CRUCIAL

- Every BDM object created by a process MUST be traceable back to its process instance
- Without `processInstanceId`, you cannot:
  - Query records for a specific process instance
  - Clean up data when a process is cancelled/deleted
  - Debug data issues tied to a specific case
  - Build efficient REST API queries filtered by case

### 4.3 Example Audit Fields in bom.xml

```xml
<field name="processInstanceId" type="LONG" nullable="false" collection="false">
  <description>ID of the Bonita process instance that created/owns this record. Used for case-level queries and data traceability.</description>
</field>
<field name="creationDate" type="DATE" nullable="false" collection="false">
  <description>Timestamp when this record was created by the process. Set automatically at creation time.</description>
</field>
<field name="creationUser" type="STRING" length="255" nullable="false" collection="false">
  <description>Username of the person who created this record. Captured from the Bonita session context.</description>
</field>
<field name="modificationDate" type="DATE" nullable="true" collection="false">
  <description>Timestamp of the last modification. Null if the record has never been modified after creation.</description>
</field>
<field name="modificationUser" type="STRING" length="255" nullable="true" collection="false">
  <description>Username of the person who last modified this record. Null if never modified.</description>
</field>
```

---

## 5. BDM Packaging

- Use **packages** to organize related BDM objects (e.g., `com.company.model.process`, `com.company.model.reference`)
- Group objects by functional domain, not by technical layer
- Package names follow standard Java package naming conventions (lowercase, dot-separated)

---

## 6. Relationship Rules

### 6.1 Loading Strategy

- **ALWAYS prefer LAZY loading** over EAGER, especially for `find*` queries returning lists
- EAGER loading on collections causes the N+1 query problem, severely degrading performance
- Only use EAGER when:
  - The related object is ALWAYS needed (very rare)
  - The relation is a single object (not a collection)
  - You are certain the query will only return a small number of results

### 6.2 Relationship Configuration

```xml
<!-- GOOD: LAZY loading for collection relations -->
<relationField name="stepsList"
               reference="PBStepProcessInstance"
               type="COMPOSITION"
               fetchType="LAZY"
               nullable="true"
               collection="true">
  <description>Steps linked to this process instance. LAZY-loaded to avoid performance issues on list queries.</description>
</relationField>

<!-- ACCEPTABLE: EAGER only for single mandatory relations -->
<relationField name="category"
               reference="PBCategory"
               type="AGGREGATION"
               fetchType="EAGER"
               nullable="false"
               collection="false">
  <description>Category of this entry. EAGER-loaded because it is always needed and is a single object.</description>
</relationField>
```
