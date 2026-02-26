#!/bin/bash
# =============================================================================
# generate-audit-report.sh
# Converts a Markdown audit report to DOCX and PDF formats using Pandoc.
#
# Usage: bash generate-audit-report.sh [backend|uib|full] [output-dir] [report-file]
#
# Arguments:
#   $1 - Audit type: "backend", "uib", or "full" (default: "backend")
#   $2 - Output directory for generated files (default: "./reports-out")
#   $3 - Path to the Markdown report file (default: auto-detected)
#
# Examples:
#   bash generate-audit-report.sh backend ./output report.md
#   bash generate-audit-report.sh uib context-ia/reports-uib/reports-out
#   bash generate-audit-report.sh full context-ia/reports/reports-out
# =============================================================================

set -euo pipefail

# --- Configuration ---
AUDIT_TYPE="${1:-backend}"
OUTPUT_DIR="${2:-./reports-out}"
REPORT_FILE="${3:-}"
DATE_PREFIX=$(date +"%Y_%m")
CUSTOMER="Customer"

# --- Determine file naming based on audit type ---
case "$AUDIT_TYPE" in
  backend)
    REPORT_NAME="${DATE_PREFIX}_Audit_${CUSTOMER}_v1.0"
    DEFAULT_REPORT_DIR="context-ia/reports/reports-out"
    ;;
  uib)
    REPORT_NAME="${DATE_PREFIX}_Audit_UIB_${CUSTOMER}_v1.0"
    DEFAULT_REPORT_DIR="context-ia/reports-uib/reports-out"
    ;;
  full)
    REPORT_NAME="${DATE_PREFIX}_Audit_Full_${CUSTOMER}_v1.0"
    DEFAULT_REPORT_DIR="context-ia/reports/reports-out"
    ;;
  *)
    echo "ERROR: Invalid audit type '$AUDIT_TYPE'. Use: backend, uib, or full"
    exit 1
    ;;
esac

# Use default output dir if not specified
if [ "$OUTPUT_DIR" = "./reports-out" ]; then
  OUTPUT_DIR="$DEFAULT_REPORT_DIR"
fi

# --- Auto-detect report file if not specified ---
if [ -z "$REPORT_FILE" ]; then
  # Look for the most recent .md file in the output directory or current directory
  if [ -d "$OUTPUT_DIR" ]; then
    REPORT_FILE=$(find "$OUTPUT_DIR" -maxdepth 1 -name "*.md" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  fi
  if [ -z "$REPORT_FILE" ]; then
    REPORT_FILE=$(find . -maxdepth 2 -name "*audit*report*.md" -o -name "*report*.md" -type f 2>/dev/null | head -1)
  fi
  if [ -z "$REPORT_FILE" ]; then
    echo "ERROR: No Markdown report file found. Please specify the report file as the third argument."
    echo "Usage: bash generate-audit-report.sh [backend|uib|full] [output-dir] [report-file.md]"
    exit 1
  fi
fi

echo "============================================="
echo "  Bonita Audit Report Generator"
echo "============================================="
echo "  Audit Type:  $AUDIT_TYPE"
echo "  Report File: $REPORT_FILE"
echo "  Output Dir:  $OUTPUT_DIR"
echo "  Output Name: $REPORT_NAME"
echo "============================================="

# --- Step 0: Check if Pandoc is installed ---
echo ""
echo "[Step 0] Checking for Pandoc installation..."
if command -v pandoc &>/dev/null; then
  PANDOC_VERSION=$(pandoc --version | head -1)
  echo "  Pandoc found: $PANDOC_VERSION"
else
  echo "  Pandoc NOT found. Attempting installation..."

  # Try Chocolatey (Windows)
  if command -v choco &>/dev/null; then
    echo "  Installing via Chocolatey..."
    choco install pandoc -y
    # Refresh PATH
    export PATH="$PATH:/c/Program Files/Pandoc"
  # Try winget (Windows)
  elif command -v winget &>/dev/null; then
    echo "  Installing via winget..."
    winget install --id JohnMacFarlane.Pandoc --accept-source-agreements --accept-package-agreements
  # Try apt (Linux/WSL)
  elif command -v apt-get &>/dev/null; then
    echo "  Installing via apt..."
    sudo apt-get update && sudo apt-get install -y pandoc
  # Try brew (macOS)
  elif command -v brew &>/dev/null; then
    echo "  Installing via brew..."
    brew install pandoc
  else
    echo "  ERROR: Cannot install Pandoc automatically."
    echo "  Please install manually from: https://pandoc.org/installing.html"
    echo "  Windows: choco install pandoc -y"
    echo "  macOS:   brew install pandoc"
    echo "  Linux:   sudo apt install pandoc"
    exit 1
  fi

  # Verify installation
  if command -v pandoc &>/dev/null; then
    echo "  Pandoc installed successfully: $(pandoc --version | head -1)"
  else
    echo "  ERROR: Pandoc installation failed. Please install manually."
    exit 1
  fi
fi

# --- Step 1: Create output directory ---
echo ""
echo "[Step 1] Creating output directory..."
mkdir -p "$OUTPUT_DIR"
echo "  Directory ready: $OUTPUT_DIR"

# --- Step 2: Verify report file exists ---
echo ""
echo "[Step 2] Verifying report file..."
if [ ! -f "$REPORT_FILE" ]; then
  echo "  ERROR: Report file not found: $REPORT_FILE"
  exit 1
fi
echo "  Report file found: $REPORT_FILE ($(wc -l < "$REPORT_FILE") lines)"

# --- Step 3: Generate DOCX ---
echo ""
echo "[Step 3] Generating DOCX..."
DOCX_OUTPUT="$OUTPUT_DIR/${REPORT_NAME}.docx"
if pandoc "$REPORT_FILE" -o "$DOCX_OUTPUT" --toc --number-sections 2>/dev/null; then
  echo "  DOCX generated: $DOCX_OUTPUT"
else
  echo "  WARNING: DOCX generation failed. Trying without TOC..."
  if pandoc "$REPORT_FILE" -o "$DOCX_OUTPUT" 2>/dev/null; then
    echo "  DOCX generated (without TOC): $DOCX_OUTPUT"
  else
    echo "  ERROR: DOCX generation failed completely."
  fi
fi

# --- Step 4: Generate HTML (intermediate for PDF) ---
echo ""
echo "[Step 4] Generating HTML..."
HTML_OUTPUT="$OUTPUT_DIR/${REPORT_NAME}.html"
if pandoc "$REPORT_FILE" -o "$HTML_OUTPUT" --standalone --toc --number-sections \
  --metadata title="Bonita Audit Report - ${AUDIT_TYPE^}" \
  --css="https://cdn.jsdelivr.net/npm/github-markdown-css@5/github-markdown.min.css" 2>/dev/null; then
  echo "  HTML generated: $HTML_OUTPUT"
else
  echo "  WARNING: HTML generation with TOC failed. Trying basic conversion..."
  if pandoc "$REPORT_FILE" -o "$HTML_OUTPUT" --standalone 2>/dev/null; then
    echo "  HTML generated (basic): $HTML_OUTPUT"
  else
    echo "  ERROR: HTML generation failed."
    HTML_OUTPUT=""
  fi
fi

# --- Step 5: Generate PDF ---
echo ""
echo "[Step 5] Generating PDF..."
PDF_OUTPUT="$OUTPUT_DIR/${REPORT_NAME}.pdf"
PDF_GENERATED=false

# Method 1: Try wkhtmltopdf
if command -v wkhtmltopdf &>/dev/null && [ -n "$HTML_OUTPUT" ] && [ -f "$HTML_OUTPUT" ]; then
  echo "  Trying wkhtmltopdf..."
  if wkhtmltopdf --enable-local-file-access \
    --margin-top 25mm --margin-bottom 25mm \
    --margin-left 20mm --margin-right 20mm \
    "$HTML_OUTPUT" "$PDF_OUTPUT" 2>/dev/null; then
    echo "  PDF generated via wkhtmltopdf: $PDF_OUTPUT"
    PDF_GENERATED=true
  else
    echo "  WARNING: wkhtmltopdf failed. Trying alternative..."
  fi
fi

# Method 2: Try Pandoc with LaTeX (xelatex)
if [ "$PDF_GENERATED" = false ] && command -v xelatex &>/dev/null; then
  echo "  Trying Pandoc + xelatex..."
  if pandoc "$REPORT_FILE" -o "$PDF_OUTPUT" --pdf-engine=xelatex \
    -V geometry:margin=1in --toc --number-sections 2>/dev/null; then
    echo "  PDF generated via xelatex: $PDF_OUTPUT"
    PDF_GENERATED=true
  else
    echo "  WARNING: xelatex conversion failed."
  fi
fi

# Method 3: Try Pandoc with pdflatex
if [ "$PDF_GENERATED" = false ] && command -v pdflatex &>/dev/null; then
  echo "  Trying Pandoc + pdflatex..."
  if pandoc "$REPORT_FILE" -o "$PDF_OUTPUT" --pdf-engine=pdflatex \
    -V geometry:margin=1in --toc --number-sections 2>/dev/null; then
    echo "  PDF generated via pdflatex: $PDF_OUTPUT"
    PDF_GENERATED=true
  else
    echo "  WARNING: pdflatex conversion failed."
  fi
fi

# Fallback: HTML is the deliverable
if [ "$PDF_GENERATED" = false ]; then
  echo "  PDF generation not available. HTML file can be used as fallback."
  echo "  To generate PDF manually:"
  echo "    1. Open $HTML_OUTPUT in Chrome/Edge"
  echo "    2. Press Ctrl+P"
  echo "    3. Select 'Save as PDF'"
  echo "    4. Save to: $PDF_OUTPUT"
  echo ""
  echo "  Or install wkhtmltopdf:"
  echo "    Windows: choco install wkhtmltopdf -y"
  echo "    macOS:   brew install wkhtmltopdf"
  echo "    Linux:   sudo apt install wkhtmltopdf"
fi

# --- Summary ---
echo ""
echo "============================================="
echo "  Generation Summary"
echo "============================================="
echo "  Audit Type: $AUDIT_TYPE"

if [ -f "$DOCX_OUTPUT" ]; then
  DOCX_SIZE=$(du -h "$DOCX_OUTPUT" 2>/dev/null | cut -f1 || echo "unknown")
  echo "  DOCX: $DOCX_OUTPUT ($DOCX_SIZE)"
else
  echo "  DOCX: NOT generated"
fi

if [ -n "$HTML_OUTPUT" ] && [ -f "$HTML_OUTPUT" ]; then
  HTML_SIZE=$(du -h "$HTML_OUTPUT" 2>/dev/null | cut -f1 || echo "unknown")
  echo "  HTML: $HTML_OUTPUT ($HTML_SIZE)"
else
  echo "  HTML: NOT generated"
fi

if [ "$PDF_GENERATED" = true ] && [ -f "$PDF_OUTPUT" ]; then
  PDF_SIZE=$(du -h "$PDF_OUTPUT" 2>/dev/null | cut -f1 || echo "unknown")
  echo "  PDF:  $PDF_OUTPUT ($PDF_SIZE)"
else
  echo "  PDF:  NOT generated (use HTML fallback)"
fi

echo "============================================="
echo "  Done!"
echo "============================================="
