# Thymeleaf HTML Template Patterns

## Overview

Thymeleaf is the template engine used for generating HTML content that can be:
1. Served directly as HTML reports or emails
2. Converted to PDF via Flying Saucer (ITextRenderer)

All templates follow Bonitasoft corporate branding and reference `BrandingConfig` values.

## Setting Up the Thymeleaf Template Engine

### Standalone Setup (no Spring)

```java
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;
import org.thymeleaf.templatemode.TemplateMode;
import org.thymeleaf.templateresolver.ClassLoaderTemplateResolver;

public class TemplateService {

    private final TemplateEngine templateEngine;

    public TemplateService() {
        this.templateEngine = createTemplateEngine();
    }

    private TemplateEngine createTemplateEngine() {
        ClassLoaderTemplateResolver resolver = new ClassLoaderTemplateResolver();
        resolver.setPrefix("templates/");        // src/main/resources/templates/
        resolver.setSuffix(".html");
        resolver.setTemplateMode(TemplateMode.HTML);
        resolver.setCharacterEncoding("UTF-8");
        resolver.setCacheable(true);

        TemplateEngine engine = new TemplateEngine();
        engine.setTemplateResolver(resolver);
        return engine;
    }

    /**
     * Renders a template with the given data model.
     *
     * @param templateName Template name (without .html extension)
     * @param variables    Key-value pairs for template variables
     * @return Rendered HTML string
     */
    public String render(String templateName, java.util.Map<String, Object> variables) {
        Context context = new Context();
        context.setVariables(variables);
        return templateEngine.process(templateName, context);
    }
}
```

### Spring Boot Setup

If the project uses Spring Boot, Thymeleaf auto-configures with `spring-boot-starter-thymeleaf`:

```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

@Service
public class TemplateService {

    @Autowired
    private TemplateEngine templateEngine;

    public String render(String templateName, java.util.Map<String, Object> variables) {
        Context context = new Context();
        context.setVariables(variables);
        return templateEngine.process(templateName, context);
    }
}
```

## Template Location

All templates live in:

```
src/main/resources/
+-- templates/
|   +-- css/
|   |   +-- corporate.css          # Corporate CSS (linked or inlined)
|   +-- images/
|   |   +-- bonitasoft-logo.png    # Bonitasoft logo
|   +-- base-layout.html           # Base layout with header/footer
|   +-- report-template.html       # Report template
|   +-- invoice-template.html      # Invoice template
```

## Corporate HTML Template Structure

### Base Layout Template (base-layout.html)

This template defines the corporate document structure used by all other templates:

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org" lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title th:text="${title}">Document Title</title>

    <!--
        For HTML output: link to external CSS
        For PDF output: CSS is injected inline (Flying Saucer needs it)
    -->
    <style th:inline="text">
        /* === BRAND COLORS (injected from BrandingConfig) === */
        :root {
            --primary-color: [[${primaryColor}]];
            --secondary-color: [[${secondaryColor}]];
            --success-color: [[${successColor}]];
            --warning-color: [[${warningColor}]];
            --error-color: [[${errorColor}]];
            --text-color: [[${textColor}]];
            --text-light: [[${textLightColor}]];
            --bg-color: [[${backgroundColor}]];
            --bg-alt: [[${backgroundAltColor}]];
            --border-color: [[${borderColor}]];
            --font-family: [[${fontFamily}]];
        }

        /* === PAGE SETUP FOR PDF === */
        @page {
            size: A4;
            margin: 2.5cm 2cm 3cm 2cm;

            @bottom-right {
                content: "Page " counter(page) " / " counter(pages);
                font-size: 9pt;
                color: #666666;
            }
        }

        /* === BASE STYLES === */
        body {
            font-family: 'Helvetica Neue', Arial, Helvetica, sans-serif;
            font-size: 11pt;
            line-height: 1.5;
            color: #333333;
            margin: 0;
            padding: 0;
        }

        /* === HEADER === */
        .document-header {
            display: table;
            width: 100%;
            border-bottom: 3px solid [[${primaryColor}]];
            padding-bottom: 12px;
            margin-bottom: 24px;
        }

        .header-logo {
            display: table-cell;
            vertical-align: middle;
            width: 30%;
        }

        .header-logo img {
            height: 40px;
        }

        .header-title {
            display: table-cell;
            vertical-align: middle;
            text-align: center;
            width: 40%;
        }

        .header-title h1 {
            margin: 0;
            font-size: 24pt;
            color: [[${primaryColor}]];
        }

        .header-title p {
            margin: 4px 0 0 0;
            font-size: 12pt;
            color: #666666;
        }

        .header-client {
            display: table-cell;
            vertical-align: middle;
            text-align: right;
            width: 30%;
        }

        /* === CONTENT === */
        .document-body {
            min-height: 600px;
        }

        h2 {
            font-size: 18pt;
            color: [[${primaryColor}]];
            border-bottom: 1px solid [[${borderColor}]];
            padding-bottom: 6px;
            margin-top: 24px;
        }

        h3 {
            font-size: 14pt;
            color: [[${primaryColor}]];
            margin-top: 18px;
        }

        /* === TABLES === */
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 16px 0;
        }

        thead th {
            background-color: [[${primaryColor}]];
            color: #FFFFFF;
            padding: 8px 12px;
            text-align: left;
            font-weight: bold;
            font-size: 10pt;
        }

        tbody td {
            padding: 6px 12px;
            border: 1px solid [[${borderColor}]];
            font-size: 10pt;
        }

        tbody tr:nth-child(even) {
            background-color: [[${backgroundAltColor}]];
        }

        /* === FOOTER === */
        .document-footer {
            border-top: 2px solid [[${primaryColor}]];
            padding-top: 8px;
            margin-top: 32px;
            font-size: 9pt;
            color: #666666;
            text-align: center;
        }

        /* === STATUS BADGES === */
        .badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 3px;
            font-size: 9pt;
            font-weight: bold;
            color: #FFFFFF;
        }

        .badge-success { background-color: [[${successColor}]]; }
        .badge-warning { background-color: [[${warningColor}]]; }
        .badge-error { background-color: [[${errorColor}]]; }
        .badge-info { background-color: [[${primaryColor}]]; }
    </style>
</head>
<body>

    <!-- ============ HEADER ============ -->
    <div class="document-header">
        <div class="header-logo">
            <img th:src="${logoBase64}" alt="Bonitasoft" />
        </div>
        <div class="header-title">
            <h1 th:text="${title}">Document Title</h1>
            <p th:text="${subtitle}" th:if="${subtitle}">Subtitle</p>
        </div>
        <div class="header-client">
            <img th:src="${clientLogoBase64}" th:if="${clientLogoBase64}"
                 alt="Client" style="height: 35px;" />
        </div>
    </div>

    <!-- ============ BODY ============ -->
    <div class="document-body">
        <!-- Content is inserted here by child templates -->
        <div th:replace="${contentFragment}">
            <p>Default content placeholder</p>
        </div>
    </div>

    <!-- ============ FOOTER ============ -->
    <div class="document-footer">
        <span th:text="${footerText}">Generated by Report - Bonitasoft</span>
        <span> | </span>
        <span th:text="${generatedDate}">01/01/2024 12:00</span>
    </div>

</body>
</html>
```

## Thymeleaf Syntax Reference

### Text Output

```html
<!-- Escaped text (safe for user input) -->
<span th:text="${variable}">default text</span>

<!-- Unescaped HTML (use only for trusted content) -->
<div th:utext="${htmlContent}">default content</div>

<!-- Inline text within attributes -->
<div th:attr="data-id=${item.id}">Content</div>
```

### Iteration (th:each)

```html
<!-- Iterate over a list -->
<tr th:each="row : ${tableRows}">
    <td th:each="cell : ${row}" th:text="${cell}">Cell value</td>
</tr>

<!-- With iteration status (index, count, size, even/odd) -->
<tr th:each="item, iter : ${items}"
    th:class="${iter.even ? 'row-even' : 'row-odd'}">
    <td th:text="${iter.count}">1</td>
    <td th:text="${item.name}">Name</td>
    <td th:text="${item.status}">Status</td>
</tr>
```

### Conditional Rendering (th:if, th:unless, th:switch)

```html
<!-- Show/hide based on condition -->
<span th:if="${status == 'Completed'}" class="badge badge-success">Completed</span>
<span th:if="${status == 'In Progress'}" class="badge badge-warning">In Progress</span>
<span th:if="${status == 'Error'}" class="badge badge-error">Error</span>

<!-- Inverse condition -->
<p th:unless="${items.empty}">Found items:</p>

<!-- Switch/case -->
<div th:switch="${item.type}">
    <span th:case="'success'" class="badge badge-success" th:text="${item.label}">OK</span>
    <span th:case="'warning'" class="badge badge-warning" th:text="${item.label}">Warn</span>
    <span th:case="*" class="badge badge-info" th:text="${item.label}">Info</span>
</div>
```

### Images (th:src)

```html
<!-- From Base64 data (for PDF) -->
<img th:src="${logoBase64}" alt="Logo" style="height: 40px;" />

<!-- From resource path (for HTML) -->
<img th:src="@{/images/bonitasoft-logo.png}" alt="Logo" style="height: 40px;" />
```

### String Operations

```html
<!-- String concatenation -->
<span th:text="'Total: ' + ${count} + ' items'">Total: 0 items</span>

<!-- String formatting -->
<span th:text="${#strings.toUpperCase(status)}">STATUS</span>

<!-- Date formatting -->
<span th:text="${#temporals.format(date, 'dd/MM/yyyy HH:mm')}">01/01/2024</span>

<!-- Number formatting -->
<span th:text="${#numbers.formatDecimal(amount, 1, 2)}">0.00</span>
```

## Passing Data Model to Templates

```java
import java.util.*;
import java.time.LocalDateTime;

// Build the data model
Map<String, Object> model = new HashMap<>();

// Document metadata
model.put("title", "Monthly Process Report");
model.put("subtitle", "January 2024 Activity Summary");
model.put("footerText", String.format(BrandingConfig.FOOTER_TEXT, "Process Report"));
model.put("generatedDate", LocalDateTime.now().format(
    DateTimeFormatter.ofPattern(BrandingConfig.DATE_FORMAT)));

// Branding data (colors, fonts, logo)
model.put("primaryColor", BrandingConfig.PRIMARY_COLOR);
model.put("secondaryColor", BrandingConfig.SECONDARY_COLOR);
model.put("successColor", BrandingConfig.SUCCESS_COLOR);
model.put("warningColor", BrandingConfig.WARNING_COLOR);
model.put("errorColor", BrandingConfig.ERROR_COLOR);
model.put("textColor", BrandingConfig.TEXT_COLOR);
model.put("textLightColor", BrandingConfig.TEXT_LIGHT_COLOR);
model.put("backgroundColor", BrandingConfig.BACKGROUND_COLOR);
model.put("backgroundAltColor", BrandingConfig.BACKGROUND_ALT_COLOR);
model.put("borderColor", BrandingConfig.BORDER_COLOR);
model.put("fontFamily", BrandingConfig.FONT_FAMILY);
model.put("logoBase64", loadLogoAsBase64());

// Business data
model.put("tableHeaders", Arrays.asList("Process", "Status", "Started", "Duration"));
model.put("tableRows", Arrays.asList(
    Arrays.asList("Order Processing", "Completed", "2024-01-15", "2h 15m"),
    Arrays.asList("Invoice Review", "In Progress", "2024-01-16", "1h 30m")
));

// Summary statistics
model.put("totalProcesses", 42);
model.put("completedCount", 35);
model.put("inProgressCount", 5);
model.put("errorCount", 2);

// Render
String html = templateService.render("report-template", model);
```

## Complete Example: Report Template (report-template.html)

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org" lang="en">
<head>
    <meta charset="UTF-8" />
    <title th:text="${title}">Report</title>

    <style th:inline="text">
        @page {
            size: A4;
            margin: 2.5cm 2cm 3cm 2cm;
            @bottom-right {
                content: "Page " counter(page) " / " counter(pages);
                font-size: 9pt;
                color: #666666;
            }
        }

        body {
            font-family: [[${fontFamily}]];
            font-size: 11pt;
            line-height: 1.5;
            color: [[${textColor}]];
            margin: 0;
            padding: 0;
        }

        .header {
            display: table;
            width: 100%;
            border-bottom: 3px solid [[${primaryColor}]];
            padding-bottom: 12px;
            margin-bottom: 20px;
        }

        .header-left {
            display: table-cell;
            vertical-align: middle;
            width: 30%;
        }

        .header-center {
            display: table-cell;
            vertical-align: middle;
            text-align: center;
            width: 40%;
        }

        .header-right {
            display: table-cell;
            vertical-align: middle;
            text-align: right;
            width: 30%;
        }

        .header-left img { height: 40px; }

        h1 {
            margin: 0;
            font-size: 24pt;
            color: [[${primaryColor}]];
        }

        .subtitle {
            margin: 4px 0 0 0;
            font-size: 12pt;
            color: [[${textLightColor}]];
        }

        h2 {
            font-size: 18pt;
            color: [[${primaryColor}]];
            border-bottom: 1px solid [[${borderColor}]];
            padding-bottom: 6px;
            margin-top: 24px;
        }

        /* Summary cards */
        .summary {
            display: table;
            width: 100%;
            margin: 16px 0;
        }

        .summary-card {
            display: table-cell;
            text-align: center;
            padding: 12px;
            border: 1px solid [[${borderColor}]];
            width: 25%;
        }

        .summary-value {
            font-size: 28pt;
            font-weight: bold;
        }

        .summary-label {
            font-size: 9pt;
            color: [[${textLightColor}]];
            text-transform: uppercase;
        }

        .color-primary { color: [[${primaryColor}]]; }
        .color-success { color: [[${successColor}]]; }
        .color-warning { color: [[${warningColor}]]; }
        .color-error { color: [[${errorColor}]]; }

        /* Data table */
        table.data-table {
            width: 100%;
            border-collapse: collapse;
            margin: 16px 0;
        }

        table.data-table thead th {
            background-color: [[${primaryColor}]];
            color: #FFFFFF;
            padding: 8px 12px;
            text-align: left;
            font-weight: bold;
            font-size: 10pt;
        }

        table.data-table tbody td {
            padding: 6px 12px;
            border: 1px solid [[${borderColor}]];
            font-size: 10pt;
        }

        table.data-table tbody tr:nth-child(even) {
            background-color: [[${backgroundAltColor}]];
        }

        table.data-table tr {
            page-break-inside: avoid;
        }

        /* Status badges */
        .badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 3px;
            font-size: 9pt;
            font-weight: bold;
            color: #FFFFFF;
        }

        .badge-success { background-color: [[${successColor}]]; }
        .badge-warning { background-color: [[${warningColor}]]; }
        .badge-error { background-color: [[${errorColor}]]; }

        /* Footer */
        .footer {
            border-top: 2px solid [[${primaryColor}]];
            padding-top: 8px;
            margin-top: 32px;
            font-size: 9pt;
            color: [[${textLightColor}]];
            text-align: center;
        }

        .page-break { page-break-before: always; }
    </style>
</head>
<body>

    <!-- ============ HEADER ============ -->
    <div class="header">
        <div class="header-left">
            <img th:src="${logoBase64}" alt="Bonitasoft" />
        </div>
        <div class="header-center">
            <h1 th:text="${title}">Report Title</h1>
            <p class="subtitle" th:text="${subtitle}" th:if="${subtitle}">Subtitle</p>
        </div>
        <div class="header-right">
            <span th:text="${generatedDate}" style="font-size: 9pt; color: #666666;">
                01/01/2024
            </span>
        </div>
    </div>

    <!-- ============ SUMMARY SECTION ============ -->
    <h2>Summary</h2>
    <div class="summary">
        <div class="summary-card">
            <div class="summary-value color-primary" th:text="${totalProcesses}">42</div>
            <div class="summary-label">Total Processes</div>
        </div>
        <div class="summary-card">
            <div class="summary-value color-success" th:text="${completedCount}">35</div>
            <div class="summary-label">Completed</div>
        </div>
        <div class="summary-card">
            <div class="summary-value color-warning" th:text="${inProgressCount}">5</div>
            <div class="summary-label">In Progress</div>
        </div>
        <div class="summary-card">
            <div class="summary-value color-error" th:text="${errorCount}">2</div>
            <div class="summary-label">Errors</div>
        </div>
    </div>

    <!-- ============ DATA TABLE ============ -->
    <h2>Process Details</h2>
    <table class="data-table">
        <thead>
            <tr>
                <th th:each="header : ${tableHeaders}" th:text="${header}">Header</th>
            </tr>
        </thead>
        <tbody>
            <tr th:each="row, iter : ${tableRows}">
                <td th:each="cell, cellIter : ${row}">
                    <!-- Apply status badge styling for the Status column (index 1) -->
                    <span th:if="${cellIter.index == 1 and cell == 'Completed'}"
                          class="badge badge-success" th:text="${cell}">Status</span>
                    <span th:if="${cellIter.index == 1 and cell == 'In Progress'}"
                          class="badge badge-warning" th:text="${cell}">Status</span>
                    <span th:if="${cellIter.index == 1 and cell == 'Error'}"
                          class="badge badge-error" th:text="${cell}">Status</span>
                    <span th:if="${cellIter.index != 1 or (cell != 'Completed' and cell != 'In Progress' and cell != 'Error')}"
                          th:text="${cell}">Value</span>
                </td>
            </tr>
        </tbody>
    </table>

    <!-- ============ FOOTER ============ -->
    <div class="footer">
        <span th:text="${footerText}">Generated by Report - Bonitasoft</span>
        <span> | </span>
        <span th:text="${generatedDate}">01/01/2024 12:00</span>
    </div>

</body>
</html>
```

## Complete Example: Invoice Template (invoice-template.html)

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org" lang="en">
<head>
    <meta charset="UTF-8" />
    <title th:text="'Invoice ' + ${invoiceNumber}">Invoice</title>

    <style th:inline="text">
        @page {
            size: A4;
            margin: 2cm;
            @bottom-center {
                content: "Page " counter(page) " / " counter(pages);
                font-size: 8pt;
                color: #666666;
            }
        }

        body {
            font-family: [[${fontFamily}]];
            font-size: 11pt;
            color: [[${textColor}]];
            margin: 0;
            padding: 0;
        }

        .invoice-header {
            display: table;
            width: 100%;
            margin-bottom: 30px;
        }

        .invoice-header-left {
            display: table-cell;
            vertical-align: top;
            width: 50%;
        }

        .invoice-header-right {
            display: table-cell;
            vertical-align: top;
            text-align: right;
            width: 50%;
        }

        .invoice-number {
            font-size: 28pt;
            font-weight: bold;
            color: [[${primaryColor}]];
            margin: 0;
        }

        .invoice-date {
            font-size: 10pt;
            color: [[${textLightColor}]];
        }

        .address-block {
            margin: 16px 0;
            padding: 12px;
            background-color: [[${backgroundAltColor}]];
            border-left: 3px solid [[${primaryColor}]];
        }

        .address-block h3 {
            margin: 0 0 6px 0;
            font-size: 10pt;
            color: [[${primaryColor}]];
            text-transform: uppercase;
        }

        .address-block p {
            margin: 2px 0;
            font-size: 10pt;
        }

        table.invoice-items {
            width: 100%;
            border-collapse: collapse;
            margin: 24px 0;
        }

        table.invoice-items thead th {
            background-color: [[${primaryColor}]];
            color: #FFFFFF;
            padding: 10px 12px;
            text-align: left;
            font-size: 10pt;
        }

        table.invoice-items thead th:last-child,
        table.invoice-items tbody td:last-child {
            text-align: right;
        }

        table.invoice-items tbody td {
            padding: 8px 12px;
            border-bottom: 1px solid [[${borderColor}]];
            font-size: 10pt;
        }

        table.invoice-items tbody tr:nth-child(even) {
            background-color: [[${backgroundAltColor}]];
        }

        .totals {
            width: 300px;
            margin-left: auto;
            margin-top: 16px;
        }

        .totals table {
            width: 100%;
            border-collapse: collapse;
        }

        .totals td {
            padding: 6px 12px;
            font-size: 11pt;
        }

        .totals .total-row {
            font-weight: bold;
            font-size: 14pt;
            color: [[${primaryColor}]];
            border-top: 2px solid [[${primaryColor}]];
        }

        .footer {
            border-top: 2px solid [[${primaryColor}]];
            padding-top: 10px;
            margin-top: 40px;
            text-align: center;
            font-size: 9pt;
            color: [[${textLightColor}]];
        }
    </style>
</head>
<body>

    <!-- ============ HEADER ============ -->
    <div class="invoice-header">
        <div class="invoice-header-left">
            <img th:src="${logoBase64}" alt="Bonitasoft" style="height: 40px;" />
            <p class="invoice-number" th:text="'Invoice ' + ${invoiceNumber}">Invoice #001</p>
            <p class="invoice-date" th:text="'Date: ' + ${invoiceDate}">Date: 01/01/2024</p>
        </div>
        <div class="invoice-header-right">
            <div class="address-block">
                <h3>Bill To</h3>
                <p th:text="${clientName}">Client Name</p>
                <p th:text="${clientAddress}">123 Client Street</p>
                <p th:text="${clientCity}">City, Country</p>
            </div>
        </div>
    </div>

    <!-- ============ ITEMS TABLE ============ -->
    <table class="invoice-items">
        <thead>
            <tr>
                <th>Description</th>
                <th>Quantity</th>
                <th>Unit Price</th>
                <th>Total</th>
            </tr>
        </thead>
        <tbody>
            <tr th:each="item : ${items}">
                <td th:text="${item.description}">Service description</td>
                <td th:text="${item.quantity}">1</td>
                <td th:text="${#numbers.formatDecimal(item.unitPrice, 1, 2) + ' EUR'}">0.00 EUR</td>
                <td th:text="${#numbers.formatDecimal(item.total, 1, 2) + ' EUR'}">0.00 EUR</td>
            </tr>
        </tbody>
    </table>

    <!-- ============ TOTALS ============ -->
    <div class="totals">
        <table>
            <tr>
                <td>Subtotal</td>
                <td style="text-align: right;"
                    th:text="${#numbers.formatDecimal(subtotal, 1, 2) + ' EUR'}">0.00 EUR</td>
            </tr>
            <tr>
                <td>Tax (20%)</td>
                <td style="text-align: right;"
                    th:text="${#numbers.formatDecimal(tax, 1, 2) + ' EUR'}">0.00 EUR</td>
            </tr>
            <tr class="total-row">
                <td>TOTAL</td>
                <td style="text-align: right;"
                    th:text="${#numbers.formatDecimal(grandTotal, 1, 2) + ' EUR'}">0.00 EUR</td>
            </tr>
        </table>
    </div>

    <!-- ============ FOOTER ============ -->
    <div class="footer">
        <p th:text="${footerText}">Generated by Invoice System - Bonitasoft</p>
        <p th:text="${generatedDate}">01/01/2024 12:00</p>
    </div>

</body>
</html>
```
