# Document Status Workflow

## States

### DRAFT
- **Entry**: Document just generated
- **Actions**: Edit content, review internally
- **Exit**: Share with stakeholders
- **Label**: `status:draft`

### UNDER_REVIEW
- **Entry**: Document shared for review
- **Actions**: Collect feedback, make changes
- **Exit**: Stakeholder approves or requests changes
- **Label**: `status:under-review`

### APPROVED
- **Entry**: Stakeholder explicitly validates
- **Actions**: Proceed to implementation
- **Exit**: Implementation begins
- **Label**: `status:approved`
- **GATE**: This is the validation gate. Implementation CANNOT start without this status.

### IMPLEMENTED
- **Entry**: Code complete, tests passing
- **Actions**: Update doc with results (coverage, mutation score, artifacts)
- **Exit**: Generate deliverables
- **Label**: `status:implemented`

### DELIVERED
- **Entry**: PDF generated, sent to stakeholders
- **Actions**: Archive, close
- **Exit**: Terminal state
- **Label**: `status:delivered`

## Transitions

```
DRAFT ──────────→ UNDER_REVIEW ──────→ APPROVED ──────→ IMPLEMENTED ──────→ DELIVERED
  ↑                    │                   │                  │
  └────────────────────┘                   │                  │
  (changes requested)                      │                  │
                                           ↓                  │
                                      REJECTED                │
                                      (rare, restart)         │
                                                              ↓
                                                         DELIVERED
```

## Rules
1. NEVER skip APPROVED → go directly to IMPLEMENTED
2. Changes after APPROVED require re-validation
3. DELIVERED is terminal — create new document for changes
4. Each transition should be logged (who, when, why)

## Destination-Specific Status Tracking

### Confluence
- Use page labels: `status:draft`, `status:under-review`, etc.
- Update label on each transition
- Page version history tracks changes

### Local Files
- Add status in YAML frontmatter: `status: draft`
- Update frontmatter on each transition
- Git history tracks changes

### PDF
- Status in filename: `spec-draft.pdf`, `spec-approved.pdf`, `spec-delivered.pdf`
- Or single file regenerated at each stage

### Other (Jira, email)
- Track status in Jira issue field
- Email subject prefix: [DRAFT], [APPROVED], [DELIVERED]
