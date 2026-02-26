# JPQL Query Patterns — Complete Reference

This document contains detailed guidance on JPQL query design, indexing strategies, and the countFor pattern for Bonita BDM.

---

## 1. Index Obligation

### 1.1 The Rule

It is **MANDATORY** to create an index for **every attribute** used in the `WHERE`, `ORDER BY`, or `JOIN` clauses of any BDM query. This applies ONLY to queries that are demonstrably **USED** in the project.

### 1.2 Usage Verification Scope

Before creating an index, verify that the query is actually consumed in at least one of these layers:

- **REST API**: BDM endpoints (e.g., `/API/bdm/businessData/{businessDataType}/findByIds`, custom BDM search REST extensions)
- **Java API/DAO**: Usage requiring the corresponding DAO (e.g., `pBProcessDAO.findByPersistenceId`)
- **Groovy scripts**: BDM query calls within connectors, operations, or script tasks

If a query is NOT used anywhere, its index is unnecessary overhead. However, if you are designing a new query, always include the index -- it will be used.

### 1.3 Index Types

**Single-field index** -- for queries filtering on one attribute:
```xml
<index name="idxProcPId" description="Optimizes findByProcessInstanceId query for case-level lookups">
  <fieldPath>processInstanceId</fieldPath>
</index>
```

**Composite index** -- for queries filtering on multiple attributes together:
```xml
<index name="idxDataNameDate" description="Optimizes findByNameAndDate - composite index on dataName+creationDate for filtered date-range queries">
  <fieldPath>dataName</fieldPath>
  <fieldPath>creationDate</fieldPath>
</index>
```

### 1.4 Index Naming Convention

- Format: `idx_{abbreviatedTable}_{abbreviatedField(s)}`
- **Maximum 20 characters** (hard database constraint)
- Must be a valid SQL identifier (letters, digits, underscores only)
- Abbreviate intelligently when table/field names are long

**Examples:**
| Query WHERE clause | Index Name | Fields |
|-------------------|------------|--------|
| `WHERE p.processInstanceId = :pid` | `idxMyObjProcId` | `processInstanceId` |
| `WHERE p.fullName = :name` | `idxCatFullName` | `fullName` |
| `WHERE p.dataName = :n AND p.creationDate = :d` | `idxDataNameDate` | `dataName`, `creationDate` |
| `ORDER BY p.creationDate DESC` | `idxMyObjCreDate` | `creationDate` |

### 1.5 Index Description Requirement

Every index MUST have a description explaining:
1. Which query/queries it optimizes
2. Why this index exists (performance justification)

```xml
<!-- GOOD -->
<index name="idxProcPId" description="Optimizes findByProcessInstanceId and countForFindByProcessInstanceId - critical for case-level data retrieval in REST API">
  <fieldPath>processInstanceId</fieldPath>
</index>

<!-- BAD -->
<index name="idxProcPId" description="Index on processInstanceId">
  <fieldPath>processInstanceId</fieldPath>
</index>
```

---

## 2. CountFor Rule (99% Rule)

### 2.1 The Rule

For **99% of queries** that return a collection (`returnType="java.util.List"`), you MUST generate a corresponding COUNT query.

### 2.2 Naming Convention

The COUNT query MUST be named: `countFor` + the main query name

| Main Query | CountFor Query |
|------------|---------------|
| `findByProcessInstanceId` | `countForFindByProcessInstanceId` |
| `findByRefSteps` | `countForFindByRefSteps` |
| `findByNameAndStatus` | `countForFindByNameAndStatus` |
| `findAll` | `countForFindAll` |

### 2.3 Why This Is CRITICAL

**REST API Pagination depends on COUNT queries.**

When a REST API consumer calls a BDM query endpoint with pagination parameters (`p=0&c=10`), the Bonita Runtime uses:
1. The main query to fetch the page of results
2. The COUNT query to determine the **total number of results** (returned in the `Content-Range` HTTP header)

Without the COUNT query:
- The REST API cannot report the total number of matching records
- Frontend pagination components (tables, grids) cannot display "Page 1 of N"
- Users have no way to know how many records exist

### 2.4 Exceptions (Do NOT need countFor)

- Queries returning `java.lang.Long` (already a count)
- Queries returning a single object (e.g., `findByPersistenceId`)
- Aggregate queries (`avg`, `min`, `max`, `sum`, `count`)
- OrderBy variants of a query that already has a countFor -- the base countFor can be reused in REST API code

### 2.5 Complete Example

```xml
<!-- Main query: returns a List -->
<query name="findByProcessInstanceId"
       content="SELECT p FROM PBMyObject p WHERE p.processInstanceId = :processInstanceId ORDER BY p.creationDate DESC"
       returnType="java.util.List">
  <description>Retrieves all records for a specific process instance, ordered by creation date descending. Used by the case detail REST API to display associated data.</description>
  <queryParameter name="processInstanceId" className="java.lang.Long"/>
</query>

<!-- CountFor query: returns Long -->
<query name="countForFindByProcessInstanceId"
       content="SELECT COUNT(p) FROM PBMyObject p WHERE p.processInstanceId = :processInstanceId"
       returnType="java.lang.Long">
  <description>Count query for findByProcessInstanceId. Required for REST API pagination to determine total number of matching records.</description>
  <queryParameter name="processInstanceId" className="java.lang.Long"/>
</query>

<!-- Index for the WHERE clause attribute -->
<index name="idxMyObjProcId" description="Optimizes findByProcessInstanceId and countForFindByProcessInstanceId for process-instance-based lookups">
  <fieldPath>processInstanceId</fieldPath>
</index>
```

### 2.6 OrderBy Variants

When you create an OrderBy variant of an existing query, you do NOT need a separate countFor -- the count is the same regardless of ordering.

```xml
<!-- Base query -->
<query name="findByStatus"
       content="SELECT p FROM PBTask p WHERE p.currentStatus = :status ORDER BY p.creationDate DESC"
       returnType="java.util.List">
  <description>Find tasks by status, default ordering by creation date</description>
  <queryParameter name="status" className="java.lang.String"/>
</query>

<!-- OrderBy variant -- shares countForFindByStatus -->
<query name="findByStatusOrderByName"
       content="SELECT p FROM PBTask p WHERE p.currentStatus = :status ORDER BY p.fullName ASC"
       returnType="java.util.List">
  <description>Find tasks by status, ordered by name. Uses countForFindByStatus for pagination.</description>
  <queryParameter name="status" className="java.lang.String"/>
</query>

<!-- Single countFor serves both queries -->
<query name="countForFindByStatus"
       content="SELECT COUNT(p) FROM PBTask p WHERE p.currentStatus = :status"
       returnType="java.lang.Long">
  <description>Count query for findByStatus and findByStatusOrderByName. Used for REST API pagination.</description>
  <queryParameter name="status" className="java.lang.String"/>
</query>
```

---

## 3. Multi-Table Queries

### 3.1 The Rule

JPQL queries in Bonita BDM are scoped to a **single business object**. If you need to query across multiple BDM objects (JOIN across tables), **do NOT create a multi-object JPQL query in bom.xml**.

### 3.2 Recommended Approach

Use a **REST API Extension** instead:
1. Create a REST API extension with direct SQL or multiple BDM DAO calls
2. Aggregate the results in Java/Groovy code
3. Return a unified JSON response

**Why?**
- Bonita BDM queries are designed for single-object JPQL
- Cross-object joins are fragile and hard to maintain in BDM
- REST API extensions give full control over query logic and response structure
- Performance tuning is easier with explicit SQL or DAO calls

### 3.3 Example: When to Use REST API Extension

**Scenario**: You need a report showing process instances with their steps and categories.

**BAD** (multi-object JPQL in bom.xml):
```xml
<!-- DO NOT DO THIS -->
<query name="findWithStepsAndCategory"
       content="SELECT p FROM PBProcessInstance p JOIN p.stepsList s JOIN s.category c WHERE ...">
```

**GOOD** (REST API Extension):
```groovy
// In REST API Extension controller
def processInstances = pBProcessInstanceDAO.findByStatus("ACTIVE", 0, 100)
def result = processInstances.collect { pi ->
    def steps = pBStepProcessInstanceDAO.findByProcessInstanceId(pi.processInstanceId, 0, 1000)
    [
        processInstance: pi,
        steps: steps,
        stepCount: steps.size()
    ]
}
return buildResponse(responseBuilder, HttpServletResponse.SC_OK, new JsonBuilder(result).toString())
```

---

## 4. Single Object Retrieval

### 4.1 processInstanceId Constraint

When retrieving records for a specific process case, ALWAYS filter by `processInstanceId`:

```xml
<!-- GOOD: Scoped to process instance -->
<query name="findByProcessInstanceId"
       content="SELECT p FROM PBMyObject p WHERE p.processInstanceId = :processInstanceId"
       returnType="java.util.List">
  <description>Find all records for a specific process case</description>
  <queryParameter name="processInstanceId" className="java.lang.Long"/>
</query>

<!-- BAD: Unscoped query returning ALL records -->
<query name="findAll"
       content="SELECT p FROM PBMyObject p"
       returnType="java.util.List">
  <description>Returns all records without filtering</description>
  <!-- This returns ALL records across ALL process instances - very expensive -->
</query>
```

### 4.2 Finding a Single Record

For queries designed to return exactly one record, use appropriate constraints and do NOT set `returnType="java.util.List"`:

```xml
<query name="findByPersistenceId"
       content="SELECT p FROM PBMyObject p WHERE p.persistenceId = :persistenceId"
       returnType="com.company.model.PBMyObject">
  <description>Find a single record by its persistence ID</description>
  <queryParameter name="persistenceId" className="java.lang.Long"/>
</query>
```

---

## 5. Good vs Bad Query Examples

### 5.1 Complete Good Example

A well-designed BDM query set with proper indexes, countFor, and descriptions:

```xml
<businessObject qualifiedName="com.company.model.PBTask">
  <description>Represents a task within a process instance. Contains task details, assignee, and status information.</description>

  <fields>
    <field name="fullName" type="STRING" length="255" nullable="false" collection="false">
      <description>Display name of the task, shown in the task list UI</description>
    </field>
    <field name="currentStatus" type="STRING" length="50" nullable="false" collection="false">
      <description>Current status of the task (e.g., PENDING, IN_PROGRESS, COMPLETED). Used for filtering and dashboards.</description>
    </field>
    <field name="processInstanceId" type="LONG" nullable="false" collection="false">
      <description>Bonita process instance ID that owns this task</description>
    </field>
    <field name="creationDate" type="DATE" nullable="false" collection="false">
      <description>When this task was created</description>
    </field>
    <!-- ... other audit fields ... -->
  </fields>

  <queries>
    <query name="findByProcessInstanceId"
           content="SELECT t FROM PBTask t WHERE t.processInstanceId = :processInstanceId ORDER BY t.creationDate DESC"
           returnType="java.util.List">
      <description>Find all tasks for a process case, newest first. Used by case detail page REST API.</description>
      <queryParameter name="processInstanceId" className="java.lang.Long"/>
    </query>
    <query name="countForFindByProcessInstanceId"
           content="SELECT COUNT(t) FROM PBTask t WHERE t.processInstanceId = :processInstanceId"
           returnType="java.lang.Long">
      <description>Count for findByProcessInstanceId - pagination support</description>
      <queryParameter name="processInstanceId" className="java.lang.Long"/>
    </query>
    <query name="findByStatus"
           content="SELECT t FROM PBTask t WHERE t.currentStatus = :currentStatus ORDER BY t.creationDate DESC"
           returnType="java.util.List">
      <description>Find all tasks with a given status across all processes. Used by the admin dashboard.</description>
      <queryParameter name="currentStatus" className="java.lang.String"/>
    </query>
    <query name="countForFindByStatus"
           content="SELECT COUNT(t) FROM PBTask t WHERE t.currentStatus = :currentStatus"
           returnType="java.lang.Long">
      <description>Count for findByStatus - pagination support for admin dashboard</description>
      <queryParameter name="currentStatus" className="java.lang.String"/>
    </query>
  </queries>

  <indexes>
    <index name="idxTaskProcId" description="Optimizes findByProcessInstanceId and its countFor query">
      <fieldPath>processInstanceId</fieldPath>
    </index>
    <index name="idxTaskStatus" description="Optimizes findByStatus and its countFor query">
      <fieldPath>currentStatus</fieldPath>
    </index>
    <index name="idxTaskCreDate" description="Optimizes ORDER BY creationDate in findByProcessInstanceId and findByStatus">
      <fieldPath>creationDate</fieldPath>
    </index>
  </indexes>
</businessObject>
```

### 5.2 Common Bad Patterns

**Missing countFor:**
```xml
<!-- BAD: List query without countFor -->
<query name="findByStatus" returnType="java.util.List" .../>
<!-- Where is countForFindByStatus? REST API pagination will break! -->
```

**Missing index:**
```xml
<!-- BAD: WHERE clause on currentStatus but no index -->
<query name="findByStatus"
       content="SELECT t FROM PBTask t WHERE t.currentStatus = :status"/>
<!-- No index on currentStatus = full table scan -->
```

**Missing description:**
```xml
<!-- BAD: No description -->
<query name="findByProcessInstanceId" content="...">
  <description></description>  <!-- EMPTY! -->
</query>
```

**Reserved keyword as field name:**
```xml
<!-- BAD: 'status' is a SQL reserved keyword -->
<field name="status" type="STRING" .../>
<!-- Use 'currentStatus' instead -->

<!-- BAD: 'type' is a SQL reserved keyword -->
<field name="type" type="STRING" .../>
<!-- Use 'entityType' or 'refType' instead -->
```

**TEXT type for short fields:**
```xml
<!-- BAD: TEXT for a name field that will never exceed 255 chars -->
<field name="firstName" type="TEXT" .../>
<!-- Use STRING with length="255" instead - TEXT prevents indexing -->
```

**Unscoped findAll without process filter:**
```xml
<!-- BAD: Returns ALL records from ALL process instances -->
<query name="findAll" content="SELECT p FROM PBTask p" returnType="java.util.List"/>
<!-- This will cause performance issues as data grows. Filter by processInstanceId when possible. -->
```
