# Version Migration Checklist

## 7.x → 2021.1 (a.k.a. 7.12)

- [ ] Update Maven parent POM version
- [ ] Check REST API extension compatibility (page API changes)
- [ ] Verify BDM access patterns (DAO changes)
- [ ] Update Living Application descriptors
- [ ] Test all connectors against new runtime
- [ ] Update test dependencies

## 2021.x → 2022.x

- [ ] Check UI Designer page compatibility
- [ ] Verify Living Application navigation
- [ ] Update REST API extension permissions
- [ ] Test multi-tenancy configuration

## 2022.x → 2023.1 (Jakarta Migration)

**This is the most impactful migration.**

- [ ] **javax → jakarta**: Replace ALL javax imports
  - `javax.servlet` → `jakarta.servlet`
  - `javax.persistence` → `jakarta.persistence`
  - `javax.validation` → `jakarta.validation`
  - `javax.xml.bind` → `jakarta.xml.bind`
- [ ] **Groovy 3 → 4**: Check Groovy script compatibility
  - Test all `.groovy` scripts
  - Check `@CompileStatic` compatibility
- [ ] **Hibernate 5 → 6**: Update HQL queries
  - Implicit joins may behave differently
  - Check criteria API usage
- [ ] **Tomcat 9 → 10.1**: Update servlet filters and listeners
- [ ] Update all Maven dependencies to Jakarta-compatible versions
- [ ] Run full regression test suite

## 2023.x → 2024.1

- [ ] Verify Java 17 is the runtime (mandatory)
- [ ] Replace Java 11 patterns with Java 17 features (records, sealed classes)
- [ ] Verify Groovy 4 compatibility (mandatory)
- [ ] Check for removed/deprecated APIs

## 2024.x → 2025.x

- [ ] **UI Designer → UI Builder**: Plan frontend migration
  - Export existing pages
  - Recreate in UI Builder (Appsmith-based)
  - Test all form validations
  - Verify data bindings
- [ ] Update REST API extensions for new frontend API
- [ ] Test process forms in new UI Builder

## General Pre-Migration Checklist

- [ ] Full backup of Bonita database
- [ ] Export all BDM data via REST API
- [ ] Document current process versions and active instances
- [ ] Run all tests on current version (baseline)
- [ ] Review Bonita release notes for target version
- [ ] Check third-party connector compatibility
- [ ] Plan rollback strategy
- [ ] Schedule maintenance window
