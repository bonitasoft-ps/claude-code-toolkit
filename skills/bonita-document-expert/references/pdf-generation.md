# PDF Generation with OpenPDF and Flying Saucer

## Overview

This guide covers PDF generation using the HTML-to-PDF approach:
**Thymeleaf HTML template -> Thymeleaf engine -> HTML string -> Flying Saucer -> PDF bytes**

This architecture allows the same corporate CSS and HTML templates to be reused for both HTML reports and PDF documents.

## Technology Stack

| Library | Artifact | Purpose |
|---------|----------|---------|
| OpenPDF | `com.github.librepdf:openpdf:1.3.30` | Open-source PDF library (iText fork) |
| Flying Saucer | `org.xhtmlrenderer:flying-saucer-openpdf:9.1.22` | Renders XHTML+CSS to PDF |
| Thymeleaf | `org.thymeleaf:thymeleaf:3.1.2.RELEASE` | HTML template engine |

## Architecture

```
+-------------------+     +------------------+     +------------------+     +-----------+
| Thymeleaf Template| --> | Thymeleaf Engine | --> | HTML String      | --> | IText     |
| (report.html)     |     | + Data Model     |     | (rendered XHTML) |     | Renderer  |
+-------------------+     +------------------+     +------------------+     +-----------+
                                                                                  |
                                                                                  v
                                                                            +-----------+
                                                                            | PDF bytes |
                                                                            | (output)  |
                                                                            +-----------+
```

## Complete PDF Document Service Example

```java
package com.bonitasoft.processbuilder.service;

import com.bonitasoft.processbuilder.document.BrandingConfig;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;
import org.thymeleaf.templatemode.TemplateMode;
import org.thymeleaf.templateresolver.ClassLoaderTemplateResolver;
import org.xhtmlrenderer.pdf.ITextRenderer;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

/**
 * PDF document generation service using Flying Saucer (HTML -> PDF).
 * All documents follow Bonitasoft corporate branding via BrandingConfig.
 */
public class PdfDocumentService {

    private static final Logger LOGGER = Logger.getLogger(PdfDocumentService.class.getName());

    private final TemplateEngine templateEngine;

    public PdfDocumentService() {
        this.templateEngine = createTemplateEngine();
    }

    // =========================================================================
    // Template Engine Setup
    // =========================================================================

    /**
     * Creates and configures the Thymeleaf template engine.
     * Templates are loaded from src/main/resources/templates/
     */
    private TemplateEngine createTemplateEngine() {
        ClassLoaderTemplateResolver resolver = new ClassLoaderTemplateResolver();
        resolver.setPrefix("templates/");
        resolver.setSuffix(".html");
        resolver.setTemplateMode(TemplateMode.HTML);
        resolver.setCharacterEncoding("UTF-8");
        resolver.setCacheable(true);

        TemplateEngine engine = new TemplateEngine();
        engine.setTemplateResolver(resolver);
        return engine;
    }

    // =========================================================================
    // PDF Generation
    // =========================================================================

    /**
     * Generates a PDF document from a Thymeleaf template.
     *
     * @param templateName The template name (without .html extension), e.g., "report-template"
     * @param dataModel    Key-value pairs to populate the template
     * @return PDF file as byte array
     */
    public byte[] generatePdf(String templateName, Map<String, Object> dataModel) {
        // Step 1: Add branding variables to the data model
        enrichWithBrandingData(dataModel);

        // Step 2: Render HTML from Thymeleaf template
        String htmlContent = renderHtml(templateName, dataModel);

        // Step 3: Convert HTML to PDF
        return convertHtmlToPdf(htmlContent);
    }

    /**
     * Adds corporate branding data to the template context.
     */
    private void enrichWithBrandingData(Map<String, Object> dataModel) {
        dataModel.put("primaryColor", BrandingConfig.PRIMARY_COLOR);
        dataModel.put("secondaryColor", BrandingConfig.SECONDARY_COLOR);
        dataModel.put("successColor", BrandingConfig.SUCCESS_COLOR);
        dataModel.put("warningColor", BrandingConfig.WARNING_COLOR);
        dataModel.put("errorColor", BrandingConfig.ERROR_COLOR);
        dataModel.put("textColor", BrandingConfig.TEXT_COLOR);
        dataModel.put("textLightColor", BrandingConfig.TEXT_LIGHT_COLOR);
        dataModel.put("backgroundColor", BrandingConfig.BACKGROUND_COLOR);
        dataModel.put("backgroundAltColor", BrandingConfig.BACKGROUND_ALT_COLOR);
        dataModel.put("borderColor", BrandingConfig.BORDER_COLOR);
        dataModel.put("fontFamily", BrandingConfig.FONT_FAMILY);
        dataModel.put("companyName", BrandingConfig.COMPANY_NAME);
        dataModel.put("generatedDate", LocalDateTime.now().format(
                DateTimeFormatter.ofPattern(BrandingConfig.DATE_FORMAT)));

        // Logo as Base64 for PDF embedding
        dataModel.put("logoBase64", loadLogoAsBase64());
    }

    /**
     * Renders an HTML string from a Thymeleaf template with the given data model.
     */
    private String renderHtml(String templateName, Map<String, Object> dataModel) {
        Context context = new Context();
        context.setVariables(dataModel);
        return templateEngine.process(templateName, context);
    }

    /**
     * Converts an HTML string to PDF bytes using Flying Saucer's ITextRenderer.
     */
    private byte[] convertHtmlToPdf(String htmlContent) {
        try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            ITextRenderer renderer = new ITextRenderer();

            // Configure fonts
            configureFonts(renderer);

            // Set the HTML document
            renderer.setDocumentFromString(htmlContent);
            renderer.layout();

            // Render to PDF
            renderer.createPDF(outputStream);

            LOGGER.info("PDF generated successfully, size: " + outputStream.size() + " bytes");
            return outputStream.toByteArray();

        } catch (Exception e) {
            throw new RuntimeException("Failed to generate PDF document", e);
        }
    }

    // =========================================================================
    // Font Configuration
    // =========================================================================

    /**
     * Configures fonts for the PDF renderer.
     * Flying Saucer uses the ITextFontResolver to manage fonts.
     */
    private void configureFonts(ITextRenderer renderer) {
        try {
            // Register system fonts
            renderer.getFontResolver().addFont(
                    "fonts/Helvetica.ttf",
                    com.lowagie.text.pdf.BaseFont.IDENTITY_H,
                    com.lowagie.text.pdf.BaseFont.EMBEDDED
            );
        } catch (Exception e) {
            // Fall back to built-in fonts if custom fonts are not available
            LOGGER.warning("Custom font not found, using built-in fonts: " + e.getMessage());
        }
    }

    // =========================================================================
    // Logo Handling
    // =========================================================================

    /**
     * Loads the Bonitasoft logo from resources and encodes it as Base64.
     * This approach embeds the logo directly in the HTML for PDF rendering,
     * avoiding file path resolution issues in Flying Saucer.
     */
    private String loadLogoAsBase64() {
        try (InputStream is = getClass().getResourceAsStream(BrandingConfig.LOGO_RESOURCE_PATH)) {
            if (is == null) {
                LOGGER.warning("Logo not found at: " + BrandingConfig.LOGO_RESOURCE_PATH);
                return "";
            }
            byte[] logoBytes = is.readAllBytes();
            return "data:image/png;base64," + Base64.getEncoder().encodeToString(logoBytes);
        } catch (IOException e) {
            LOGGER.warning("Failed to load logo: " + e.getMessage());
            return "";
        }
    }

    // =========================================================================
    // Convenience Methods
    // =========================================================================

    /**
     * Generates a report PDF with a title, subtitle, and data table.
     *
     * @param title       The report title
     * @param subtitle    The report subtitle
     * @param headers     Table column headers
     * @param rows        Table data rows (list of lists)
     * @return PDF as byte array
     */
    public byte[] generateReportPdf(String title, String subtitle,
                                     List<String> headers, List<List<String>> rows) {
        Map<String, Object> dataModel = new java.util.HashMap<>();
        dataModel.put("title", title);
        dataModel.put("subtitle", subtitle);
        dataModel.put("tableHeaders", headers);
        dataModel.put("tableRows", rows);
        dataModel.put("footerText", String.format(BrandingConfig.FOOTER_TEXT, title));

        return generatePdf("report-template", dataModel);
    }

    /**
     * Generates a simple single-page PDF with title and HTML body content.
     */
    public byte[] generateSimplePdf(String title, String bodyHtml) {
        Map<String, Object> dataModel = new java.util.HashMap<>();
        dataModel.put("title", title);
        dataModel.put("bodyContent", bodyHtml);
        dataModel.put("footerText", String.format(BrandingConfig.FOOTER_TEXT, title));

        return generatePdf("simple-template", dataModel);
    }
}
```

## ITextRenderer Configuration Details

### Setting Base URL for Relative Resources

When your HTML references external CSS or images via relative paths, you must set a base URL:

```java
// Option 1: Use classpath resource URL
String baseUrl = getClass().getResource("/templates/").toExternalForm();
renderer.setDocumentFromString(htmlContent, baseUrl);

// Option 2: Use file system path
String baseUrl = new File("src/main/resources/templates/").toURI().toURL().toExternalForm();
renderer.setDocumentFromString(htmlContent, baseUrl);
```

### Using Embedded CSS Instead of External Files

For maximum portability in PDF generation, embed CSS directly in the HTML:

```java
private String injectCssIntoHtml(String htmlContent) {
    try (InputStream cssStream = getClass().getResourceAsStream("/templates/css/corporate.css")) {
        if (cssStream != null) {
            String css = new String(cssStream.readAllBytes(), java.nio.charset.StandardCharsets.UTF_8);
            return htmlContent.replace("</head>",
                    "<style>" + css + "</style></head>");
        }
    } catch (IOException e) {
        LOGGER.warning("Could not inject CSS: " + e.getMessage());
    }
    return htmlContent;
}
```

## Page Headers and Footers with Page Numbers

Flying Saucer supports CSS-based headers and footers using the `@page` rule and `running()` elements:

```css
@page {
    size: A4;
    margin: 2.5cm 2cm 3cm 2cm;

    @top-left {
        content: element(header-left);
    }

    @top-right {
        content: element(header-right);
    }

    @bottom-center {
        content: element(footer-center);
    }

    @bottom-right {
        content: "Page " counter(page) " / " counter(pages);
        font-size: 9pt;
        color: #666666;
        font-family: 'Helvetica Neue', Arial, sans-serif;
    }
}

/* Elements that become running headers/footers */
#header-left {
    position: running(header-left);
}

#header-right {
    position: running(header-right);
}

#footer-center {
    position: running(footer-center);
}
```

Corresponding HTML elements:

```html
<!-- These elements are removed from flow and placed in page margins -->
<div id="header-left">
    <img th:src="${logoBase64}" style="height: 30pt;" alt="Bonitasoft" />
</div>
<div id="header-right">
    <span th:text="${title}" style="font-size: 12pt; color: #2C3E7A;">Report Title</span>
</div>
<div id="footer-center">
    <span th:text="${footerText}" style="font-size: 9pt; color: #666666;">Generated by Report - Bonitasoft</span>
</div>
```

## Multi-Page Document Handling

### Forcing Page Breaks

```css
/* Force a page break before this element */
.page-break-before {
    page-break-before: always;
}

/* Force a page break after this element */
.page-break-after {
    page-break-after: always;
}

/* Avoid breaking inside this element */
.no-break {
    page-break-inside: avoid;
}
```

Usage in Thymeleaf templates:

```html
<!-- Each section starts on a new page -->
<div th:each="section, iter : ${sections}">
    <div th:class="${iter.index > 0 ? 'page-break-before' : ''}">
        <h2 th:text="${section.title}">Section Title</h2>
        <div th:utext="${section.content}">Content</div>
    </div>
</div>
```

## Table Rendering in PDF

Tables in Flying Saucer require explicit styling for proper PDF rendering:

```css
table {
    width: 100%;
    border-collapse: collapse;
    margin: 16px 0;
    font-size: 10pt;
}

table thead th {
    background-color: #2C3E7A;
    color: #FFFFFF;
    padding: 8px 12px;
    text-align: left;
    font-weight: bold;
    font-size: 10pt;
    border: 1px solid #2C3E7A;
}

table tbody td {
    padding: 6px 12px;
    border: 1px solid #E0E0E0;
    font-size: 10pt;
    color: #333333;
}

table tbody tr:nth-child(even) {
    background-color: #F5F7FA;
}

table tbody tr:hover {
    background-color: #EEF1F7;
}

/* Prevent table rows from being split across pages */
table tr {
    page-break-inside: avoid;
}
```

## Flying Saucer CSS Support Notes

### Supported CSS Properties
- Box model: `margin`, `padding`, `border`, `width`, `height`
- Typography: `font-family`, `font-size`, `font-weight`, `font-style`, `color`, `text-align`, `text-decoration`, `line-height`, `letter-spacing`
- Background: `background-color`, `background-image` (limited)
- Tables: `border-collapse`, `border-spacing`, `table-layout`
- Page: `@page`, `page-break-before`, `page-break-after`, `page-break-inside`
- Positioning: `position: running()` for headers/footers
- Counters: `counter(page)`, `counter(pages)`
- Lists: `list-style-type`, `list-style-position`

### NOT Supported or Limited
- **Flexbox** (`display: flex`) -- NOT supported
- **CSS Grid** (`display: grid`) -- NOT supported
- **CSS Variables** (`var(--name)`) -- NOT supported in Flying Saucer; use direct values
- **box-shadow** -- NOT supported
- **border-radius** -- Partial support (may not render)
- **opacity** -- Limited support
- **transform** -- NOT supported
- **transition / animation** -- NOT supported
- **calc()** -- NOT supported
- **@import** -- Use inline styles or `<link>` with base URL instead
- **Media queries** -- Only `@media print` is partially supported
- **Gradients** -- NOT supported

### Important: CSS Variables and PDF
Since Flying Saucer does NOT support CSS variables (`var(--primary-color)`), the PDF templates must use direct hex values or inject them via Thymeleaf:

```html
<!-- Option 1: Direct hex values in PDF-specific CSS -->
<style>
    .header { background-color: #2C3E7A; }
</style>

<!-- Option 2: Inject from BrandingConfig via Thymeleaf (recommended) -->
<style th:inline="text">
    .header { background-color: [[${primaryColor}]]; }
    .accent { color: [[${secondaryColor}]]; }
    body { font-family: [[${fontFamily}]]; color: [[${textColor}]]; }
</style>
```

## Font Handling

### Embedding Custom Fonts

```java
// Register a TrueType font for use in PDF
ITextRenderer renderer = new ITextRenderer();
renderer.getFontResolver().addFont(
    "fonts/CustomFont.ttf",                    // Path in classpath
    com.lowagie.text.pdf.BaseFont.IDENTITY_H,  // Encoding (Unicode)
    com.lowagie.text.pdf.BaseFont.EMBEDDED      // Embed font in PDF
);
```

### Using System Fonts

```java
// Register all system fonts (useful for development)
renderer.getFontResolver().addFont(
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    com.lowagie.text.pdf.BaseFont.IDENTITY_H,
    com.lowagie.text.pdf.BaseFont.EMBEDDED
);
```

### Font CSS for PDF

```css
/* Always specify fallback fonts for PDF rendering */
body {
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
    font-size: 11pt;
}

/* Use pt units (not px or rem) for PDF */
h1 { font-size: 24pt; }
h2 { font-size: 18pt; }
h3 { font-size: 14pt; }
p  { font-size: 11pt; }
small { font-size: 9pt; }
```

## Complete Example: Generating a Report PDF

```java
// In a Bonita REST API Extension or Connector
PdfDocumentService pdfService = new PdfDocumentService();

List<String> headers = Arrays.asList("Process", "Status", "Started", "Duration");
List<List<String>> rows = Arrays.asList(
    Arrays.asList("Order Processing", "Completed", "2024-01-15", "2h 15m"),
    Arrays.asList("Invoice Review", "In Progress", "2024-01-16", "1h 30m"),
    Arrays.asList("Approval Flow", "Pending", "2024-01-16", "-")
);

byte[] pdfBytes = pdfService.generateReportPdf(
    "Process Monitoring Report",
    "Monthly Activity Summary - January 2024",
    headers,
    rows
);

// Return as Bonita document or HTTP response
// For REST API: set response content type to "application/pdf"
```
