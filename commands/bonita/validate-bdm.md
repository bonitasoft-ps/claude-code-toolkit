# Validate BDM Compliance

Validate bom.xml against Bonita project standards.

## Instructions

1. **CountFor queries**: collection queries (java.util.List) MUST have countFor. Queries returning Long, single objects, or aggregates (avg, min, max, sum, count) do NOT need countFor.
2. **Descriptions**: all business objects, fields, queries, indexes must have non-empty descriptions
3. **Naming**: PB prefix for objects, camelCase for fields
4. **Indexes**: attributes in WHERE/ORDER BY/JOIN should have indexes
