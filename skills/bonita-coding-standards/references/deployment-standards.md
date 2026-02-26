# Deployment Standards

This reference covers all deployment-related standards for Bonita projects, including continuous
delivery, environment management, permission configuration, and application profiles.

---

## 1. Bonita Continuous Delivery (BCD)

### 1.1 Automatic Deployment (MANDATORY)

Use **BCD (Bonita Continuous Delivery)** for all process deployments. Manual deployment through
the Bonita Portal is not acceptable for production environments.

**Benefits:**
- Reproducible deployments across environments.
- Reduced human error during deployment.
- Audit trail of what was deployed, when, and by whom.
- Rollback capability.

### 1.2 BCD Pipeline Structure

A typical BCD deployment pipeline should include:

1. **Build**: Compile the project and run all unit tests.
2. **Package**: Generate the `.bar` file for the target environment.
3. **Deploy to Staging**: Deploy the bar file to the staging environment.
4. **Integration Tests**: Run integration and process-level tests.
5. **Approval Gate**: Manual approval for production deployment.
6. **Deploy to Production**: Deploy the approved bar file to production.

### 1.3 BCD Configuration

Maintain BCD configuration files per environment:

```
bcd/
  scenarios/
    deploy-dev.yml
    deploy-staging.yml
    deploy-production.yml
  inventory/
    dev.ini
    staging.ini
    production.ini
```

---

## 2. Bar File Management

### 2.1 One Bar File Per Environment (MANDATORY)

Each target environment (development, staging, production) MUST have its own bar file generated
from the Studio with environment-specific configuration.

**Why:** Bar files embed environment-specific parameters (database connections, service URLs,
actor mappings) at build time. A bar file built for development will contain development
parameters and cannot be used in production.

### 2.2 Environment-Specific Configuration

The following elements vary per environment and must be configured in the Studio before
exporting the bar file:

| Configuration | Example Dev | Example Production |
|---|---|---|
| Actor Mappings | Dev user group | Production organization groups |
| Process Parameters | `http://localhost:8080` | `https://api.company.com` |
| Connector Configurations | Dev credentials | Production credentials |
| Custom Permissions | Relaxed for testing | Strict for security |

### 2.3 Configuration Checklist Before Export

Before exporting a bar file for any environment:

- [ ] All **actor mappings** are configured for the target environment.
- [ ] All **process parameters** are set with environment-specific values.
- [ ] All **connector configurations** reference the correct target systems.
- [ ] **BDM Access Control** is configured and activated.
- [ ] No development-only settings remain (debug flags, test accounts).
- [ ] Version number is updated in the process definition.

---

## 3. Environment Configuration Management

### 3.1 Parameter Management

Process parameters should be organized by category:

```
Parameters/
  connection/
    database.url
    database.user
    database.password (encrypted)
    external-api.base-url
    external-api.api-key (encrypted)
  business/
    default.page-size
    max.retry-count
    notification.enabled
  technical/
    log.level
    cache.ttl-seconds
    thread-pool.size
```

### 3.2 Secrets Management

- **NEVER** store secrets in plain text in parameter files or source code.
- Use Bonita's parameter encryption for sensitive values.
- For external secrets, integrate with a secrets manager (HashiCorp Vault, AWS Secrets Manager).
- Document which parameters are secrets so they are handled correctly during deployment.

### 3.3 Configuration Validation

Before each deployment, validate that:

- [ ] All required parameters have values (no empty or placeholder values).
- [ ] URLs and endpoints are reachable from the target environment.
- [ ] Database connections can be established.
- [ ] External service credentials are valid.
- [ ] File paths and directories exist on the target server.

---

## 4. Permissions Management

### 4.1 Dynamic Permissions

Dynamic permissions control access to Bonita REST APIs at runtime. They are evaluated per
request based on the authenticated user's profile.

**Configuration steps:**

1. Review the default dynamic permissions provided by Bonita.
2. Identify which APIs each profile (Administrator, User, Manager) needs access to.
3. Create custom permission rules for project-specific REST API extensions.
4. Test each profile's access in a staging environment before production.

**Example dynamic permission mapping:**

```properties
# custom-permissions-mapping.properties

# Allow managers to access the task reassignment API
POST|extension/processBuilderRestAPI/reassignTask=[profile|Manager]

# Allow all authenticated users to access read-only endpoints
GET|extension/processBuilderRestAPI/tasks=[profile|User, profile|Manager, profile|Administrator]

# Restrict administrative operations
POST|extension/processBuilderRestAPI/admin/purge=[profile|Administrator]
DELETE|extension/processBuilderRestAPI/admin/cache=[profile|Administrator]
```

### 4.2 Static Permissions

Static permissions are defined at deployment time and do not change at runtime. They control
access to pages, forms, and application sections.

**Configuration steps:**

1. Define which pages each profile can access.
2. Configure living application navigation per profile.
3. Ensure that REST API endpoints called by a page are accessible to the same profiles.

### 4.3 Permission Audit Checklist

- [ ] All REST API extension endpoints have explicit permission rules.
- [ ] Each profile has a documented list of accessible APIs and pages.
- [ ] No endpoint is accessible without authentication (unless explicitly required).
- [ ] Administrative endpoints are restricted to the Administrator profile.
- [ ] Permission changes are reviewed during code review.
- [ ] Permissions are tested in staging with real user accounts per profile.

---

## 5. Application Profiles

### 5.1 Profile Organization

Define and document all application profiles with their associated permissions:

| Profile | Description | Applications | Key Permissions |
|---|---|---|---|
| Administrator | System administration | Admin Console, Process Manager | Full access to all APIs |
| Manager | Team management | Task Manager, Reports | Task reassignment, report generation |
| User | Standard user | Task Portal, Self-Service | Own task access, profile management |
| Viewer | Read-only access | Dashboard | Read-only endpoints |

### 5.2 Profile-to-Application Mapping

Each application should document which profiles have access:

```
Application: Process Builder
  - Administrator: Full access (all pages, all APIs)
  - Manager: Task management, reports, team overview
  - User: Own tasks, self-service forms

Application: Admin Console
  - Administrator: Full access
  - Manager: No access
  - User: No access

Application: Reports Dashboard
  - Administrator: Full access
  - Manager: Department reports
  - User: Personal reports
  - Viewer: Aggregated dashboards only
```

### 5.3 Profile Testing Matrix

Before each deployment, test access for each profile:

| Action | Admin | Manager | User | Viewer | Expected |
|---|---|---|---|---|---|
| View task list | Pass | Pass | Pass | Deny | Per design |
| Reassign task | Pass | Pass | Deny | Deny | Per design |
| Access admin panel | Pass | Deny | Deny | Deny | Per design |
| Generate report | Pass | Pass | Deny | Deny | Per design |
| View dashboard | Pass | Pass | Pass | Pass | Per design |

---

## 6. Deployment Verification Checklist

After each deployment, verify:

- [ ] All processes are deployed and enabled.
- [ ] Process versions match the expected release.
- [ ] BDM is updated and Access Control is active.
- [ ] REST API extensions are deployed and accessible.
- [ ] Dynamic permissions are loaded correctly.
- [ ] Application pages render without errors.
- [ ] A smoke test passes for each critical business flow.
- [ ] Monitoring and alerting are active.
- [ ] Deployment is documented (version, date, deployer, changes).

---

## 7. Rollback Procedure

If a deployment fails or introduces critical issues:

1. **Identify**: Confirm the issue is deployment-related (not pre-existing).
2. **Communicate**: Notify stakeholders that a rollback is in progress.
3. **Rollback**: Deploy the previous known-good bar file using BCD.
4. **Verify**: Run the smoke test suite against the rolled-back version.
5. **Investigate**: Analyze the failed deployment in a non-production environment.
6. **Fix and Re-deploy**: Address the root cause and re-deploy through the standard pipeline.
7. **Document**: Record the incident, root cause, and corrective actions.
