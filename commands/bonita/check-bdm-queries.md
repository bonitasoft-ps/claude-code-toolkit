# Check BDM for Existing Queries

Before implementing a new BDM query, check if it already exists.

## Arguments
- `$ARGUMENTS`: business object name or query description

## Instructions

1. Read `bdm/bom.xml`
2. Search for queries matching the request
3. List ALL existing queries for the matched business object
4. Validate countFor compliance: collection queries (java.util.List) MUST have countFor counterpart. Queries returning Long, single objects, or aggregates do NOT need countFor.
5. Recommend: reuse existing, modify existing, or create new
