# Maven Dependencies for Document Generation

## All Dependencies

Add the following dependencies to your `pom.xml` for complete document generation support:

```xml
<!-- ============================================================ -->
<!-- DOCUMENT GENERATION DEPENDENCIES                              -->
<!-- ============================================================ -->

<!-- OpenPDF (PDF generation - open source fork of iText 4)
     License: LGPL/MPL - safe for commercial use
     NOTE: Do NOT use iText 5+ (AGPL license) -->
<dependency>
    <groupId>com.github.librepdf</groupId>
    <artifactId>openpdf</artifactId>
    <version>1.3.30</version>
</dependency>

<!-- Flying Saucer (HTML/CSS to PDF renderer)
     Uses OpenPDF as the PDF backend
     Converts well-formed XHTML + CSS 2.1 into PDF -->
<dependency>
    <groupId>org.xhtmlrenderer</groupId>
    <artifactId>flying-saucer-openpdf</artifactId>
    <version>9.1.22</version>
</dependency>

<!-- Thymeleaf (HTML template engine)
     Used for generating HTML from templates
     Same templates work for both HTML output and PDF (via Flying Saucer) -->
<dependency>
    <groupId>org.thymeleaf</groupId>
    <artifactId>thymeleaf</artifactId>
    <version>3.1.2.RELEASE</version>
</dependency>

<!-- Apache POI (Microsoft Office document generation)
     poi-ooxml includes support for both .docx (Word) and .xlsx (Excel)
     Also includes poi core dependency transitively -->
<dependency>
    <groupId>org.apache.poi</groupId>
    <artifactId>poi-ooxml</artifactId>
    <version>5.2.5</version>
</dependency>
```

## Version Compatibility Matrix

| Library | Version | Java Min | Notes |
|---------|---------|----------|-------|
| OpenPDF | 1.3.30 | Java 8 | LTS version, active maintenance |
| Flying Saucer | 9.1.22 | Java 8 | Must match OpenPDF backend (not iText) |
| Thymeleaf | 3.1.2.RELEASE | Java 8 | Latest 3.x line |
| Apache POI | 5.2.5 | Java 8 | Requires poi-ooxml for .docx/.xlsx |

## Important Notes

### Flying Saucer Backend

Flying Saucer has multiple backend modules. You MUST use the OpenPDF variant:

```xml
<!-- CORRECT: OpenPDF backend (open source, LGPL) -->
<artifactId>flying-saucer-openpdf</artifactId>

<!-- WRONG: iText 5 backend (AGPL license - NOT allowed) -->
<!-- <artifactId>flying-saucer-pdf-itext5</artifactId> -->

<!-- WRONG: Old iText backend (deprecated) -->
<!-- <artifactId>flying-saucer-pdf</artifactId> -->
```

### Apache POI Exclusions

If your project has conflicting XML libraries (common with older Java EE or Spring Boot projects), you may need exclusions:

```xml
<dependency>
    <groupId>org.apache.poi</groupId>
    <artifactId>poi-ooxml</artifactId>
    <version>5.2.5</version>
    <exclusions>
        <!-- Exclude if you already have xml-apis from another dependency -->
        <exclusion>
            <groupId>xml-apis</groupId>
            <artifactId>xml-apis</artifactId>
        </exclusion>
        <!-- Exclude if conflicting with project's stax implementation -->
        <exclusion>
            <groupId>stax</groupId>
            <artifactId>stax-api</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

### Thymeleaf with Spring Boot

If your project uses Spring Boot, you can use the starter instead of the standalone dependency:

```xml
<!-- Spring Boot Thymeleaf starter (includes auto-configuration) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
```

For Bonita projects (non-Spring Boot), use the standalone Thymeleaf dependency.

### OpenPDF vs iText

| Feature | OpenPDF 1.3.x | iText 5.x+ |
|---------|---------------|-------------|
| License | LGPL/MPL | AGPL (copyleft) |
| Commercial use | Free | Requires paid license |
| API compatibility | iText 4.x API | Different API |
| Active maintenance | Yes | Yes (paid) |
| **Recommendation** | **USE THIS** | **DO NOT USE** |

OpenPDF is a community-maintained fork of iText 4 and is fully compatible with Flying Saucer. It is the only PDF library allowed in Bonitasoft projects.

## Dependency Tree Overview

```
project
+-- com.github.librepdf:openpdf:1.3.30
+-- org.xhtmlrenderer:flying-saucer-openpdf:9.1.22
|   +-- org.xhtmlrenderer:flying-saucer-core:9.1.22
|   +-- com.github.librepdf:openpdf:1.3.30
+-- org.thymeleaf:thymeleaf:3.1.2.RELEASE
|   +-- ognl:ognl:3.3.4
|   +-- org.attoparser:attoparser:2.0.7.RELEASE
|   +-- org.unbescape:unbescape:1.1.6.RELEASE
+-- org.apache.poi:poi-ooxml:5.2.5
    +-- org.apache.poi:poi:5.2.5
    +-- org.apache.poi:poi-ooxml-lite:5.2.5
    +-- org.apache.xmlbeans:xmlbeans:5.1.1
    +-- org.apache.commons:commons-compress:1.24.0
    +-- commons-io:commons-io:2.15.0
```

## Checking Existing Dependencies

Before adding these dependencies, check if any are already present in your `pom.xml`:

```bash
# From the project root directory
mvn dependency:tree | grep -E "(openpdf|flying-saucer|thymeleaf|poi)"
```

If an older version exists, update it to the versions listed above. Do not mix versions.
