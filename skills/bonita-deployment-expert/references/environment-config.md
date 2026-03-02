# Environment Configuration Management

## Configuration Hierarchy

```
1. bonita-platform-community-custom.properties  → Database, platform-level
2. bonita-tenant-community-custom.properties     → Tenant-level (work service, schedulers)
3. Bonita Portal > Configuration                 → Runtime parameters (SMTP, auth)
4. Process Parameters                            → Per-process variables
5. Environment variables                         → Container/OS level overrides
```

## Per-Environment Properties

### Development (local)

```properties
# bonita-platform-community-custom.properties
db.vendor=h2
db.url=jdbc:h2:file:./database/bonita;DB_CLOSE_ON_EXIT=FALSE
platform.tenant.default.username=install
platform.tenant.default.password=install
```

### Staging

```properties
# bonita-platform-community-custom.properties
db.vendor=postgres
db.url=jdbc:postgresql://staging-db:5432/bonita
db.user=${BONITA_DB_USER}
db.password=${BONITA_DB_PASSWORD}
```

### Production

```properties
# bonita-platform-community-custom.properties
db.vendor=postgres
db.url=jdbc:postgresql://prod-db-cluster:5432/bonita?ssl=true
db.user=${BONITA_DB_USER}
db.password=${BONITA_DB_PASSWORD}

# Connection pool tuning
db.pool.initial=10
db.pool.max=200
```

## Docker Compose Example

```yaml
services:
  bonita:
    image: bonita:2025.1
    ports:
      - "8080:8080"
    environment:
      DB_VENDOR: postgres
      DB_HOST: db
      DB_PORT: 5432
      DB_NAME: bonita
      DB_USER: bonita
      DB_PASS: ${BONITA_DB_PASSWORD}
      TENANT_LOGIN: install
      TENANT_PASSWORD: ${BONITA_TENANT_PASSWORD}
    volumes:
      - bonita-data:/opt/bonita
    depends_on:
      - db

  db:
    image: postgres:16
    environment:
      POSTGRES_DB: bonita
      POSTGRES_USER: bonita
      POSTGRES_PASSWORD: ${BONITA_DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
```

## Secret Management

| Approach | When to use |
|----------|-------------|
| Environment variables | Simple deployments, Docker |
| HashiCorp Vault | Enterprise, multi-environment |
| AWS Secrets Manager | AWS-hosted Bonita |
| GitHub Secrets | CI/CD pipelines |

**Never store in:**
- `application.properties` committed to git
- Process variable default values
- Bonita connector configurations (visible in Portal)
