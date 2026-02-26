# Word and Excel Generation with Apache POI

## Overview

Apache POI (poi-ooxml) is used for generating Word (.docx) and Excel (.xlsx) documents with Bonitasoft corporate branding. All documents must use `BrandingConfig` constants for colors, fonts, and structure.

## Maven Dependency

```xml
<dependency>
    <groupId>org.apache.poi</groupId>
    <artifactId>poi-ooxml</artifactId>
    <version>5.2.5</version>
</dependency>
```

---

## Word Document Generation (.docx)

### Complete Branded Word Document Service

```java
package com.bonitasoft.processbuilder.service;

import com.bonitasoft.processbuilder.document.BrandingConfig;
import org.apache.poi.util.Units;
import org.apache.poi.xwpf.usermodel.*;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.*;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigInteger;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.logging.Logger;

/**
 * Word document generation service with Bonitasoft corporate branding.
 * All documents include branded header, footer, and consistent typography.
 */
public class WordDocumentService {

    private static final Logger LOGGER = Logger.getLogger(WordDocumentService.class.getName());

    // =========================================================================
    // Document Creation
    // =========================================================================

    /**
     * Creates a branded Word document with title, subtitle, and table data.
     *
     * @param title    Document title
     * @param subtitle Document subtitle
     * @param headers  Table column headers
     * @param rows     Table data rows
     * @return DOCX file as byte array
     */
    public byte[] generateReport(String title, String subtitle,
                                  List<String> headers, List<List<String>> rows) {
        try (XWPFDocument document = new XWPFDocument();
             ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {

            // Set page margins
            setPageMargins(document);

            // Add branded header with logo
            addBrandedHeader(document);

            // Add title
            addTitle(document, title);

            // Add subtitle
            addSubtitle(document, subtitle);

            // Add spacing
            addEmptyParagraph(document);

            // Add data table
            if (headers != null && !headers.isEmpty()) {
                addBrandedTable(document, headers, rows);
            }

            // Add footer
            addBrandedFooter(document, title);

            document.write(outputStream);
            LOGGER.info("Word document generated: " + title);
            return outputStream.toByteArray();

        } catch (Exception e) {
            throw new RuntimeException("Failed to generate Word document", e);
        }
    }

    // =========================================================================
    // Page Setup
    // =========================================================================

    /**
     * Sets corporate page margins for the document.
     */
    private void setPageMargins(XWPFDocument document) {
        CTSectPr sectPr = document.getDocument().getBody().addNewSectPr();
        CTPageMar pageMar = sectPr.addNewPgMar();

        // Margins in twips (1 inch = 1440 twips)
        long topMargin = Math.round(BrandingConfig.PAGE_MARGIN_TOP * 20);    // points to twips
        long bottomMargin = Math.round(BrandingConfig.PAGE_MARGIN_BOTTOM * 20);
        long leftMargin = Math.round(BrandingConfig.PAGE_MARGIN_LEFT * 20);
        long rightMargin = Math.round(BrandingConfig.PAGE_MARGIN_RIGHT * 20);

        pageMar.setTop(BigInteger.valueOf(topMargin));
        pageMar.setBottom(BigInteger.valueOf(bottomMargin));
        pageMar.setLeft(BigInteger.valueOf(leftMargin));
        pageMar.setRight(BigInteger.valueOf(rightMargin));
    }

    // =========================================================================
    // Header with Logo
    // =========================================================================

    /**
     * Adds a branded header with the Bonitasoft logo.
     */
    private void addBrandedHeader(XWPFDocument document) {
        try {
            // Create header
            XWPFHeader header = document.createHeader(HeaderFooterType.DEFAULT);
            XWPFParagraph headerParagraph = header.getParagraphArray(0);
            if (headerParagraph == null) {
                headerParagraph = header.createParagraph();
            }
            headerParagraph.setAlignment(ParagraphAlignment.LEFT);

            // Add logo image
            XWPFRun logoRun = headerParagraph.createRun();
            try (InputStream logoStream = getClass().getResourceAsStream(
                    BrandingConfig.LOGO_RESOURCE_PATH)) {
                if (logoStream != null) {
                    logoRun.addPicture(
                            logoStream,
                            XWPFDocument.PICTURE_TYPE_PNG,
                            "bonitasoft-logo.png",
                            Units.toEMU(BrandingConfig.LOGO_WIDTH),
                            Units.toEMU(BrandingConfig.LOGO_HEIGHT)
                    );
                } else {
                    // Fallback: text-based logo
                    logoRun.setText(BrandingConfig.COMPANY_NAME);
                    logoRun.setBold(true);
                    logoRun.setFontSize(BrandingConfig.FONT_SIZE_SUBTITLE);
                    logoRun.setColor(BrandingConfig.PRIMARY_COLOR.replace("#", ""));
                    logoRun.setFontFamily(BrandingConfig.FONT_FAMILY.split(",")[0].replace("'", "").trim());
                }
            }

            // Add a horizontal line under the header
            addHorizontalLine(headerParagraph);

        } catch (Exception e) {
            LOGGER.warning("Could not add header with logo: " + e.getMessage());
        }
    }

    // =========================================================================
    // Footer
    // =========================================================================

    /**
     * Adds a branded footer with generation info and page numbers.
     */
    private void addBrandedFooter(XWPFDocument document, String documentTitle) {
        XWPFFooter footer = document.createFooter(HeaderFooterType.DEFAULT);
        XWPFParagraph footerParagraph = footer.getParagraphArray(0);
        if (footerParagraph == null) {
            footerParagraph = footer.createParagraph();
        }
        footerParagraph.setAlignment(ParagraphAlignment.CENTER);

        // Footer text
        String footerText = String.format(BrandingConfig.FOOTER_TEXT, documentTitle)
                + " | " + LocalDateTime.now().format(
                DateTimeFormatter.ofPattern(BrandingConfig.DATE_FORMAT));

        XWPFRun footerRun = footerParagraph.createRun();
        footerRun.setText(footerText + " | Page ");
        footerRun.setFontSize(BrandingConfig.FONT_SIZE_SMALL);
        footerRun.setColor(BrandingConfig.TEXT_LIGHT_COLOR.replace("#", ""));
        footerRun.setFontFamily(BrandingConfig.FONT_FAMILY.split(",")[0].replace("'", "").trim());

        // Add page number field
        footerParagraph.getCTP().addNewFldSimple().setInstr("PAGE");
        XWPFRun ofRun = footerParagraph.createRun();
        ofRun.setText(" / ");
        ofRun.setFontSize(BrandingConfig.FONT_SIZE_SMALL);
        ofRun.setColor(BrandingConfig.TEXT_LIGHT_COLOR.replace("#", ""));
        footerParagraph.getCTP().addNewFldSimple().setInstr("NUMPAGES");
    }

    // =========================================================================
    // Title and Subtitle
    // =========================================================================

    /**
     * Adds the document title with corporate styling.
     */
    private void addTitle(XWPFDocument document, String title) {
        XWPFParagraph titleParagraph = document.createParagraph();
        titleParagraph.setAlignment(ParagraphAlignment.LEFT);
        titleParagraph.setSpacingAfter(100);

        XWPFRun titleRun = titleParagraph.createRun();
        titleRun.setText(title);
        titleRun.setBold(true);
        titleRun.setFontSize(BrandingConfig.FONT_SIZE_TITLE);
        titleRun.setColor(BrandingConfig.PRIMARY_COLOR.replace("#", ""));
        titleRun.setFontFamily(BrandingConfig.FONT_FAMILY.split(",")[0].replace("'", "").trim());
    }

    /**
     * Adds the document subtitle with corporate styling.
     */
    private void addSubtitle(XWPFDocument document, String subtitle) {
        XWPFParagraph subtitleParagraph = document.createParagraph();
        subtitleParagraph.setAlignment(ParagraphAlignment.LEFT);
        subtitleParagraph.setSpacingAfter(200);

        XWPFRun subtitleRun = subtitleParagraph.createRun();
        subtitleRun.setText(subtitle);
        subtitleRun.setFontSize(BrandingConfig.FONT_SIZE_SUBTITLE);
        subtitleRun.setColor(BrandingConfig.TEXT_LIGHT_COLOR.replace("#", ""));
        subtitleRun.setFontFamily(BrandingConfig.FONT_FAMILY.split(",")[0].replace("'", "").trim());
    }

    // =========================================================================
    // Table with Corporate Styling
    // =========================================================================

    /**
     * Adds a branded data table with header row styling and alternating row colors.
     */
    private void addBrandedTable(XWPFDocument document, List<String> headers,
                                  List<List<String>> rows) {
        XWPFTable table = document.createTable(rows.size() + 1, headers.size());
        table.setWidth("100%");

        String fontName = BrandingConfig.FONT_FAMILY.split(",")[0].replace("'", "").trim();

        // Style header row
        XWPFTableRow headerRow = table.getRow(0);
        for (int i = 0; i < headers.size(); i++) {
            XWPFTableCell cell = headerRow.getCell(i);
            setCellBackground(cell, BrandingConfig.PRIMARY_COLOR);

            XWPFParagraph paragraph = cell.getParagraphArray(0);
            if (paragraph == null) {
                paragraph = cell.addParagraph();
            }
            paragraph.setAlignment(ParagraphAlignment.LEFT);

            XWPFRun run = paragraph.createRun();
            run.setText(headers.get(i));
            run.setBold(true);
            run.setColor("FFFFFF");
            run.setFontSize(BrandingConfig.FONT_SIZE_BODY);
            run.setFontFamily(fontName);
        }

        // Style data rows with alternating colors
        for (int rowIdx = 0; rowIdx < rows.size(); rowIdx++) {
            XWPFTableRow dataRow = table.getRow(rowIdx + 1);
            List<String> rowData = rows.get(rowIdx);

            String bgColor = (rowIdx % 2 == 0)
                    ? BrandingConfig.BACKGROUND_COLOR
                    : BrandingConfig.BACKGROUND_ALT_COLOR;

            for (int colIdx = 0; colIdx < headers.size() && colIdx < rowData.size(); colIdx++) {
                XWPFTableCell cell = dataRow.getCell(colIdx);
                setCellBackground(cell, bgColor);

                XWPFParagraph paragraph = cell.getParagraphArray(0);
                if (paragraph == null) {
                    paragraph = cell.addParagraph();
                }

                XWPFRun run = paragraph.createRun();
                run.setText(rowData.get(colIdx));
                run.setFontSize(BrandingConfig.FONT_SIZE_BODY);
                run.setColor(BrandingConfig.TEXT_COLOR.replace("#", ""));
                run.setFontFamily(fontName);
            }
        }

        // Set table borders
        setTableBorders(table);
    }

    // =========================================================================
    // Utility Methods
    // =========================================================================

    /**
     * Sets the background color of a table cell.
     */
    private void setCellBackground(XWPFTableCell cell, String hexColor) {
        CTTcPr tcPr = cell.getCTTc().addNewTcPr();
        CTShd shd = tcPr.addNewShd();
        shd.setFill(hexColor.replace("#", ""));
        shd.setVal(STShd.CLEAR);
    }

    /**
     * Sets consistent borders for the entire table.
     */
    private void setTableBorders(XWPFTable table) {
        String borderColor = BrandingConfig.BORDER_COLOR.replace("#", "");
        CTTblBorders borders = table.getCTTbl().getTblPr().addNewTblBorders();

        for (CTBorder border : new CTBorder[]{
                borders.addNewTop(), borders.addNewBottom(),
                borders.addNewLeft(), borders.addNewRight(),
                borders.addNewInsideH(), borders.addNewInsideV()}) {
            border.setVal(STBorder.SINGLE);
            border.setSz(BigInteger.valueOf(4));
            border.setColor(borderColor);
        }
    }

    /**
     * Adds a horizontal line (border-bottom) to a paragraph.
     */
    private void addHorizontalLine(XWPFParagraph paragraph) {
        CTPPr ppr = paragraph.getCTP().getPPr();
        if (ppr == null) {
            ppr = paragraph.getCTP().addNewPPr();
        }
        CTPBdr border = ppr.addNewPBdr();
        CTBorder bottomBorder = border.addNewBottom();
        bottomBorder.setVal(STBorder.SINGLE);
        bottomBorder.setSz(BigInteger.valueOf(6));
        bottomBorder.setColor(BrandingConfig.PRIMARY_COLOR.replace("#", ""));
    }

    /**
     * Adds an empty paragraph for spacing.
     */
    private void addEmptyParagraph(XWPFDocument document) {
        XWPFParagraph paragraph = document.createParagraph();
        paragraph.setSpacingAfter(100);
    }

    /**
     * Adds a paragraph with body text styling.
     */
    public void addBodyParagraph(XWPFDocument document, String text) {
        XWPFParagraph paragraph = document.createParagraph();
        paragraph.setAlignment(ParagraphAlignment.LEFT);
        paragraph.setSpacingAfter(100);

        XWPFRun run = paragraph.createRun();
        run.setText(text);
        run.setFontSize(BrandingConfig.FONT_SIZE_BODY);
        run.setColor(BrandingConfig.TEXT_COLOR.replace("#", ""));
        run.setFontFamily(BrandingConfig.FONT_FAMILY.split(",")[0].replace("'", "").trim());
    }

    /**
     * Sets the document to landscape orientation.
     */
    public void setLandscapeOrientation(XWPFDocument document) {
        CTSectPr sectPr = document.getDocument().getBody().getSectPr();
        if (sectPr == null) {
            sectPr = document.getDocument().getBody().addNewSectPr();
        }
        CTPageSz pageSize = sectPr.addNewPgSz();
        pageSize.setOrient(STPageOrientation.LANDSCAPE);
        // A4 landscape dimensions in twips
        pageSize.setW(BigInteger.valueOf(16840));
        pageSize.setH(BigInteger.valueOf(11900));
    }
}
```

### Adding Images to Word Documents

```java
/**
 * Adds an image to the document body.
 *
 * @param document  The Word document
 * @param imagePath Resource path to the image
 * @param width     Width in pixels
 * @param height    Height in pixels
 */
public void addImage(XWPFDocument document, String imagePath, int width, int height) {
    try (InputStream imageStream = getClass().getResourceAsStream(imagePath)) {
        if (imageStream == null) {
            LOGGER.warning("Image not found: " + imagePath);
            return;
        }

        XWPFParagraph imageParagraph = document.createParagraph();
        imageParagraph.setAlignment(ParagraphAlignment.CENTER);

        XWPFRun imageRun = imageParagraph.createRun();
        imageRun.addPicture(
                imageStream,
                XWPFDocument.PICTURE_TYPE_PNG,
                imagePath,
                Units.toEMU(width),
                Units.toEMU(height)
        );
    } catch (Exception e) {
        LOGGER.warning("Failed to add image: " + e.getMessage());
    }
}
```

---

## Excel Document Generation (.xlsx)

### Complete Branded Excel Report Service

```java
package com.bonitasoft.processbuilder.service;

import com.bonitasoft.processbuilder.document.BrandingConfig;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.*;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.logging.Logger;

/**
 * Excel report generation service with Bonitasoft corporate branding.
 * Produces .xlsx files with branded header styles, alternating row colors,
 * and corporate footer information.
 */
public class ExcelDocumentService {

    private static final Logger LOGGER = Logger.getLogger(ExcelDocumentService.class.getName());

    // =========================================================================
    // Report Generation
    // =========================================================================

    /**
     * Generates a branded Excel report with header row and data.
     *
     * @param title    Report title (used as sheet name and header)
     * @param headers  Column headers
     * @param rows     Data rows (list of lists)
     * @return XLSX file as byte array
     */
    public byte[] generateReport(String title, List<String> headers,
                                  List<List<String>> rows) {
        try (XSSFWorkbook workbook = new XSSFWorkbook();
             ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {

            // Sanitize sheet name (max 31 chars, no special characters)
            String sheetName = sanitizeSheetName(title);
            XSSFSheet sheet = workbook.createSheet(sheetName);

            // Create cell styles
            CellStyle headerStyle = createHeaderStyle(workbook);
            CellStyle dataStyle = createDataStyle(workbook);
            CellStyle altDataStyle = createAltDataStyle(workbook);
            CellStyle totalStyle = createTotalStyle(workbook);

            int currentRow = 0;

            // Add logo to header area
            currentRow = addLogoHeader(workbook, sheet, currentRow);

            // Add report title
            currentRow = addReportTitle(workbook, sheet, currentRow, title, headers.size());

            // Add empty row for spacing
            currentRow++;

            // Add header row
            Row headerRow = sheet.createRow(currentRow);
            for (int i = 0; i < headers.size(); i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers.get(i));
                cell.setCellStyle(headerStyle);
            }
            currentRow++;

            // Add data rows with alternating colors
            for (int rowIdx = 0; rowIdx < rows.size(); rowIdx++) {
                Row dataRow = sheet.createRow(currentRow);
                List<String> rowData = rows.get(rowIdx);
                CellStyle style = (rowIdx % 2 == 0) ? dataStyle : altDataStyle;

                for (int colIdx = 0; colIdx < headers.size() && colIdx < rowData.size(); colIdx++) {
                    Cell cell = dataRow.createCell(colIdx);
                    cell.setCellValue(rowData.get(colIdx));
                    cell.setCellStyle(style);
                }
                currentRow++;
            }

            // Auto-size columns
            for (int i = 0; i < headers.size(); i++) {
                sheet.autoSizeColumn(i);
                // Add extra padding (256 units = 1 character width)
                int currentWidth = sheet.getColumnWidth(i);
                sheet.setColumnWidth(i, Math.min(currentWidth + 1024, 20000));
            }

            // Add footer row
            addFooterRow(workbook, sheet, currentRow + 1, title, headers.size());

            // Set print area and header/footer for printing
            configurePrintSetup(workbook, sheet, title, headers.size(), currentRow);

            workbook.write(outputStream);
            LOGGER.info("Excel report generated: " + title);
            return outputStream.toByteArray();

        } catch (Exception e) {
            throw new RuntimeException("Failed to generate Excel report", e);
        }
    }

    // =========================================================================
    // Cell Styles
    // =========================================================================

    /**
     * Creates the corporate header row cell style.
     * Primary color background with white bold text.
     */
    private CellStyle createHeaderStyle(XSSFWorkbook workbook) {
        XSSFCellStyle style = workbook.createCellStyle();

        // Background color: Primary
        XSSFColor primaryColor = new XSSFColor(hexToRgb(BrandingConfig.PRIMARY_COLOR), null);
        style.setFillForegroundColor(primaryColor);
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);

        // Font: White, bold
        XSSFFont font = workbook.createFont();
        font.setFontName(BrandingConfig.FONT_FAMILY.split(",")[0].replace("'", "").trim());
        font.setFontHeightInPoints((short) BrandingConfig.FONT_SIZE_BODY);
        font.setBold(true);
        font.setColor(new XSSFColor(new byte[]{(byte) 255, (byte) 255, (byte) 255}, null));
        style.setFont(font);

        // Borders
        setBorders(style, BrandingConfig.PRIMARY_COLOR);

        // Alignment
        style.setAlignment(HorizontalAlignment.LEFT);
        style.setVerticalAlignment(VerticalAlignment.CENTER);

        return style;
    }

    /**
     * Creates the standard data row cell style.
     * White background with dark text.
     */
    private CellStyle createDataStyle(XSSFWorkbook workbook) {
        XSSFCellStyle style = workbook.createCellStyle();

        // Font
        XSSFFont font = workbook.createFont();
        font.setFontName(BrandingConfig.FONT_FAMILY.split(",")[0].replace("'", "").trim());
        font.setFontHeightInPoints((short) BrandingConfig.FONT_SIZE_BODY);
        font.setColor(new XSSFColor(hexToRgb(BrandingConfig.TEXT_COLOR), null));
        style.setFont(font);

        // Borders
        setBorders(style, BrandingConfig.BORDER_COLOR);

        style.setAlignment(HorizontalAlignment.LEFT);
        style.setVerticalAlignment(VerticalAlignment.CENTER);

        return style;
    }

    /**
     * Creates the alternating row cell style.
     * Light gray background with dark text.
     */
    private CellStyle createAltDataStyle(XSSFWorkbook workbook) {
        XSSFCellStyle style = (XSSFCellStyle) createDataStyle(workbook);

        XSSFColor altBg = new XSSFColor(hexToRgb(BrandingConfig.BACKGROUND_ALT_COLOR), null);
        style.setFillForegroundColor(altBg);
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);

        return style;
    }

    /**
     * Creates a total/summary row cell style.
     * Secondary color accented with bold text.
     */
    private CellStyle createTotalStyle(XSSFWorkbook workbook) {
        XSSFCellStyle style = workbook.createCellStyle();

        XSSFColor secondaryColor = new XSSFColor(hexToRgb(BrandingConfig.SECONDARY_COLOR), null);
        style.setFillForegroundColor(secondaryColor);
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);

        XSSFFont font = workbook.createFont();
        font.setFontName(BrandingConfig.FONT_FAMILY.split(",")[0].replace("'", "").trim());
        font.setFontHeightInPoints((short) BrandingConfig.FONT_SIZE_BODY);
        font.setBold(true);
        font.setColor(new XSSFColor(new byte[]{(byte) 255, (byte) 255, (byte) 255}, null));
        style.setFont(font);

        setBorders(style, BrandingConfig.SECONDARY_COLOR);

        style.setAlignment(HorizontalAlignment.LEFT);
        style.setVerticalAlignment(VerticalAlignment.CENTER);

        return style;
    }

    // =========================================================================
    // Header and Footer
    // =========================================================================

    /**
     * Adds the Bonitasoft logo to the top of the sheet.
     * Returns the next available row number.
     */
    private int addLogoHeader(XSSFWorkbook workbook, XSSFSheet sheet, int startRow) {
        try (InputStream logoStream = getClass().getResourceAsStream(
                BrandingConfig.LOGO_RESOURCE_PATH)) {
            if (logoStream != null) {
                byte[] logoBytes = logoStream.readAllBytes();
                int pictureIdx = workbook.addPicture(logoBytes, Workbook.PICTURE_TYPE_PNG);

                CreationHelper helper = workbook.getCreationHelper();
                Drawing<?> drawing = sheet.createDrawingPatriarch();
                ClientAnchor anchor = helper.createClientAnchor();
                anchor.setCol1(0);
                anchor.setRow1(startRow);
                anchor.setCol2(2);
                anchor.setRow2(startRow + 3);

                drawing.createPicture(anchor, pictureIdx);
                return startRow + 4;
            }
        } catch (IOException e) {
            LOGGER.warning("Could not add logo to Excel: " + e.getMessage());
        }

        // Fallback: text header
        Row headerRow = sheet.createRow(startRow);
        Cell cell = headerRow.createCell(0);
        cell.setCellValue(BrandingConfig.COMPANY_NAME);

        XSSFCellStyle style = workbook.createCellStyle();
        XSSFFont font = workbook.createFont();
        font.setFontName(BrandingConfig.FONT_FAMILY.split(",")[0].replace("'", "").trim());
        font.setFontHeightInPoints((short) BrandingConfig.FONT_SIZE_SUBTITLE);
        font.setBold(true);
        font.setColor(new XSSFColor(hexToRgb(BrandingConfig.PRIMARY_COLOR), null));
        style.setFont(font);
        cell.setCellStyle(style);

        return startRow + 2;
    }

    /**
     * Adds a report title row spanning all columns.
     */
    private int addReportTitle(XSSFWorkbook workbook, XSSFSheet sheet,
                                int rowNum, String title, int numColumns) {
        Row titleRow = sheet.createRow(rowNum);
        Cell titleCell = titleRow.createCell(0);
        titleCell.setCellValue(title);

        XSSFCellStyle style = workbook.createCellStyle();
        XSSFFont font = workbook.createFont();
        font.setFontName(BrandingConfig.FONT_FAMILY.split(",")[0].replace("'", "").trim());
        font.setFontHeightInPoints((short) BrandingConfig.FONT_SIZE_TITLE);
        font.setBold(true);
        font.setColor(new XSSFColor(hexToRgb(BrandingConfig.PRIMARY_COLOR), null));
        style.setFont(font);
        titleCell.setCellStyle(style);

        // Merge cells for title
        if (numColumns > 1) {
            sheet.addMergedRegion(new CellRangeAddress(rowNum, rowNum, 0, numColumns - 1));
        }

        return rowNum + 1;
    }

    /**
     * Adds a footer row with generation info.
     */
    private void addFooterRow(XSSFWorkbook workbook, XSSFSheet sheet,
                               int rowNum, String title, int numColumns) {
        Row footerRow = sheet.createRow(rowNum);
        Cell footerCell = footerRow.createCell(0);
        String timestamp = LocalDateTime.now().format(
                DateTimeFormatter.ofPattern(BrandingConfig.DATE_FORMAT));
        footerCell.setCellValue(
                String.format(BrandingConfig.FOOTER_TEXT, title) + " | " + timestamp);

        XSSFCellStyle style = workbook.createCellStyle();
        XSSFFont font = workbook.createFont();
        font.setFontName(BrandingConfig.FONT_FAMILY.split(",")[0].replace("'", "").trim());
        font.setFontHeightInPoints((short) BrandingConfig.FONT_SIZE_SMALL);
        font.setItalic(true);
        font.setColor(new XSSFColor(hexToRgb(BrandingConfig.TEXT_LIGHT_COLOR), null));
        style.setFont(font);
        footerCell.setCellStyle(style);

        if (numColumns > 1) {
            sheet.addMergedRegion(new CellRangeAddress(rowNum, rowNum, 0, numColumns - 1));
        }
    }

    /**
     * Configures print setup with headers and footers.
     */
    private void configurePrintSetup(XSSFWorkbook workbook, XSSFSheet sheet,
                                      String title, int numColumns, int lastRow) {
        PrintSetup printSetup = sheet.getPrintSetup();
        printSetup.setLandscape(numColumns > 5);
        printSetup.setPaperSize(PrintSetup.A4_PAPERSIZE);
        printSetup.setFitWidth((short) 1);
        printSetup.setFitHeight((short) 0);

        // Print header and footer
        Header printHeader = sheet.getHeader();
        printHeader.setLeft(BrandingConfig.COMPANY_NAME);
        printHeader.setCenter(title);
        printHeader.setRight("&D &T");

        Footer printFooter = sheet.getFooter();
        printFooter.setLeft(String.format(BrandingConfig.FOOTER_TEXT, title));
        printFooter.setRight("Page &P / &N");

        // Set print area
        workbook.setPrintArea(
                workbook.getSheetIndex(sheet),
                0, numColumns - 1,
                0, lastRow
        );
    }

    // =========================================================================
    // Utility Methods
    // =========================================================================

    /**
     * Sets thin borders on all sides of a cell style.
     */
    private void setBorders(XSSFCellStyle style, String hexColor) {
        XSSFColor borderColor = new XSSFColor(hexToRgb(hexColor), null);
        style.setBorderTop(BorderStyle.THIN);
        style.setBorderBottom(BorderStyle.THIN);
        style.setBorderLeft(BorderStyle.THIN);
        style.setBorderRight(BorderStyle.THIN);
        style.setTopBorderColor(borderColor);
        style.setBottomBorderColor(borderColor);
        style.setLeftBorderColor(borderColor);
        style.setRightBorderColor(borderColor);
    }

    /**
     * Converts a hex color string (e.g., "#2C3E7A") to an RGB byte array.
     */
    private byte[] hexToRgb(String hex) {
        hex = hex.replace("#", "");
        return new byte[]{
                (byte) Integer.parseInt(hex.substring(0, 2), 16),
                (byte) Integer.parseInt(hex.substring(2, 4), 16),
                (byte) Integer.parseInt(hex.substring(4, 6), 16)
        };
    }

    /**
     * Sanitizes a string for use as an Excel sheet name.
     * Sheet names cannot exceed 31 characters or contain special characters.
     */
    private String sanitizeSheetName(String name) {
        String sanitized = name.replaceAll("[\\[\\]\\*\\?/\\\\:]", "");
        return sanitized.length() > 31 ? sanitized.substring(0, 31) : sanitized;
    }
}
```

### Usage Example

```java
// Generate a branded Excel report
ExcelDocumentService excelService = new ExcelDocumentService();

List<String> headers = Arrays.asList("Process", "Status", "Started", "Duration", "Assignee");
List<List<String>> rows = Arrays.asList(
    Arrays.asList("Order Processing", "Completed", "2024-01-15", "2h 15m", "John"),
    Arrays.asList("Invoice Review", "In Progress", "2024-01-16", "1h 30m", "Jane"),
    Arrays.asList("Approval Flow", "Pending", "2024-01-16", "-", "Unassigned")
);

byte[] excelBytes = excelService.generateReport(
    "Process Monitoring Report",
    headers,
    rows
);

// Write to file or return as HTTP response
```
