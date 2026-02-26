# BDM Access Control — Complete Reference

This document contains the rules and guidance for configuring BDM Access Control in Bonita, ensuring proper security for business data.

---

## 1. The Mandate

**MANDATORY**: BDM Access Control MUST be activated and configured for all business objects that contain personal information or sensitive data. As a security best practice, consider configuring access control for ALL business objects.

---

## 2. What Is BDM Access Control?

BDM Access Control is a Bonita security layer that restricts which users/profiles can read, create, update, or delete BDM records. It complements (but does not replace) process-level security and actor mappings.

- **Without BDM Access Control**: Any authenticated user with access to the REST API can query ANY BDM record via the `/API/bdm/businessData/` endpoints
- **With BDM Access Control**: Only users matching the defined access rules can retrieve or modify records

---

## 3. Where to Configure

BDM Access Control is configured in **Bonita Studio** via the **Security tab** (also called "BDM Access Control" in the Studio menu):

1. Open Bonita Studio
2. Go to **Development > BDM Access Control** (or navigate to the Security tab)
3. Define access rules per business object
4. Deploy the access control configuration along with the BDM

The access control configuration is stored as part of the project and is deployed alongside the BDM definition.

---

## 4. Access Control Concepts

### 4.1 Access Rules

Each business object can have multiple access rules. Each rule defines:
- **Who**: Which profiles or users can access
- **What**: Which attributes/fields are visible
- **When**: Conditions for access (static or dynamic)

### 4.2 Rule Types

| Type | Description | Use Case |
|------|-------------|----------|
| **Static rule** | Always applies based on user profile | Admin sees all, User sees limited fields |
| **Dynamic rule** | Conditional based on data values | User sees only their own records |

### 4.3 Field-Level Security

BDM Access Control supports field-level visibility:
- You can hide sensitive fields from certain profiles
- Example: HR profile sees `salary` field, Manager profile does not

---

## 5. Configuration Best Practices

### 5.1 Default Behavior (No Rules Defined)

When no access control rules are defined for a business object:
- **ALL authenticated users** can access ALL records and ALL fields
- This is the least secure configuration
- Acceptable ONLY for truly public reference data (e.g., country lists, currency codes)

### 5.2 Recommended Approach

For **every** business object, define at minimum:

1. **Administrator rule**: Full access to all fields (for admin/support profiles)
2. **Process participant rule**: Access scoped to process-related data
3. **Default deny**: If no rule matches, access should be denied

### 5.3 Personal Information Objects

Objects containing personal data (names, emails, phone numbers, addresses) MUST have:
- Restricted field visibility (only show necessary fields per profile)
- Dynamic rules to ensure users only see records they are authorized for
- Audit trail considerations (who accessed what data)

### 5.4 Process-Linked Objects

For BDM objects linked to process instances (containing `processInstanceId`):
- Consider rules that restrict access to records from processes the user is involved in
- Use dynamic rules based on process initiator or task assignee
- Ensure REST API consumers only receive records they should see

---

## 6. Security Patterns

### 6.1 Pattern: Owner-Based Access

Users can only read records they created:

**Rule configuration:**
- Condition: `record.creationUser == currentUser.userName`
- Fields: All fields visible
- Profiles: All authenticated users

This pattern is useful for personal data objects (e.g., user preferences, personal tasks).

### 6.2 Pattern: Profile-Based Access

Different profiles see different fields:

**Administrator rule:**
- Profiles: `Administrator`
- Fields: ALL fields visible
- Condition: None (always applies)

**Manager rule:**
- Profiles: `Manager`
- Fields: All except `salary`, `personalId`
- Condition: None

**User rule:**
- Profiles: `User`
- Fields: `fullName`, `currentStatus`, `processInstanceId` only
- Condition: None

### 6.3 Pattern: Process-Scoped Access

Users involved in a process can see related BDM records:

**Rule configuration:**
- Condition: User is initiator or task assignee of the process identified by `processInstanceId`
- Fields: Relevant process data fields
- Profiles: Process participants

---

## 7. Common Mistakes

### 7.1 Forgetting to Deploy Access Control

BDM Access Control must be **deployed separately** from the BDM itself. After configuring rules:
1. Deploy the BDM (Business Data Model)
2. Deploy the BDM Access Control configuration
3. Verify access rules are active by testing REST API calls with different user profiles

### 7.2 Overly Permissive Default Rules

**BAD**: A single rule granting all profiles access to all fields
```
Rule: "AllAccess"
Profiles: Everyone
Fields: All
Condition: None
```

**GOOD**: Layered rules with progressive field visibility
```
Rule: "AdminFull" -> Profiles: Admin -> All fields
Rule: "ManagerLimited" -> Profiles: Manager -> Business fields only
Rule: "UserMinimal" -> Profiles: User -> Name and status only
```

### 7.3 Not Testing with Different Profiles

Always test BDM Access Control by:
1. Logging in as different user profiles (Admin, Manager, User)
2. Calling the same BDM REST API endpoint
3. Verifying that each profile sees only the fields/records they should
4. Confirming unauthorized access is properly denied

---

## 8. Integration with REST API

BDM Access Control is enforced at the REST API layer:

- `/API/bdm/businessData/{qualifiedName}` endpoints respect access rules
- Custom REST API extensions that use DAO calls bypass BDM Access Control (they run with system privileges)
- When building custom REST API extensions, implement your own authorization checks

### 8.1 REST API Extension Authorization

If your REST API extension bypasses BDM Access Control (which all DAO-based extensions do), add manual authorization:

```groovy
// In REST API Extension
def currentUser = apiSession.getUserName()
def userProfiles = profileAPI.getProfilesForUser(apiSession.getUserId())

// Check if user has required profile
if (!userProfiles.any { it.name == "Administrator" }) {
    return buildResponse(responseBuilder, HttpServletResponse.SC_FORBIDDEN,
        '{"error": "Insufficient privileges"}')
}
```

---

## 9. Checklist for New Business Objects

When creating a new BDM object, verify:

- [ ] BDM Access Control rules are defined (or consciously skipped for public data)
- [ ] Personal information fields have restricted visibility
- [ ] Administrator profile has full access rule
- [ ] Process participant rules are scoped appropriately
- [ ] Access control is tested with multiple user profiles
- [ ] Custom REST API extensions include authorization checks if they bypass BDM Access Control
