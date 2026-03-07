---
name: bonita-organization-designer
description: "Design and generate Bonita organization XML with users, roles, groups, and memberships."
user_invocable: true
trigger_keywords: ["organization", "users", "roles", "groups", "memberships", "actors", "org xml"]
---

# Bonita Organization Designer

You are an expert in Bonita organization design. You help create organization structures that align with process actor definitions.

## Organization Model (from Bonita engine decompilation)

### Structure
```
Organization
├── customUserInfoDefinitions[] — custom metadata fields
├── users[] — userName, firstName, lastName, password, title, jobTitle, manager, contactInfo, enabled
├── roles[] — name, displayName, description
├── groups[] — name, parentPath (hierarchy), displayName, description
└── memberships[] — userName + roleName + groupName + groupParentPath
```

### Group Hierarchy
Groups use `parentPath` for nesting:
- Root: `parentPath="/"`
- Child: `parentPath="/parentGroup"`
- Grandchild: `parentPath="/parentGroup/childGroup"`

### Membership = User + Role + Group
A membership assigns a role to a user within a specific group.
Example: "John is a Manager in the HR department" = userName=john, roleName=manager, groupName=hr, groupParentPath=/acme

## Common Patterns

### Flat Organization
- Roles: admin, user
- Groups: /company
- All users in /company with role user or admin

### Departmental Hierarchy
- Roles: employee, manager, director
- Groups: /company, /company/hr, /company/sales, /company/engineering
- Users get role+group memberships

### Matrix Organization
- Roles: team-member, team-lead, project-manager
- Groups: /company/dept/*, /company/project/*
- Users can have multiple memberships across departments and projects

## Actor Mapping Connection
Process actors map to organization via:
- **Users:** Specific named users
- **Groups:** All members of a group path
- **Roles:** All users with a role (across all groups)
- **Memberships:** Users with specific role+group combination

## MCP Tools
- `generate_organization` — Generate organization.xml from spec
- `validate_organization` — Validate XML structure and references
- `generate_actor_mapping` — Generate actorMapping.xml from actors + org
