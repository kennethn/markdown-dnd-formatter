#!/bin/bash

# D&D Markdown to PDF converter
# Usage: ./md-to-pdf.sh input.md

set -euo pipefail

# =========================
# Validation Functions
# =========================

print_usage() {
    echo "Usage: $0 [options] input.md"
    echo "Converts D&D markdown notes to styled PDF"
    echo ""
    echo "Options:"
    echo "  --one-column           Use single column layout instead of two columns"
    echo "  --output-dir DIR       Specify output directory for PDF (default: same as input)"
    echo "  -h, --help             Show this help message"
}

validate_input() {
    local input="$1"
    
    if [ -z "$input" ]; then
        print_usage
        exit 1
    fi
    
    if [[ "$input" != *.md ]]; then
        echo "❌ Input file must be a .md file" >&2
        exit 1
    fi
    
    if [ ! -f "$input" ]; then
        echo "❌ Input file not found: $input" >&2
        exit 1
    fi
}

# =========================
# Main Script
# =========================

# Parse command line arguments
ONE_COLUMN=false
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --one-column)
            ONE_COLUMN=true
            shift
            ;;
        --output-dir)
            if [[ -z "$2" ]]; then
                echo "❌ --output-dir requires a directory path" >&2
                print_usage
                exit 1
            fi
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        -*)
            echo "❌ Unknown option: $1" >&2
            print_usage
            exit 1
            ;;
        *)
            INPUT="$1"
            shift
            break
            ;;
    esac
done

validate_input "$INPUT"

# Validate output directory if specified
if [[ -n "$OUTPUT_DIR" ]]; then
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        echo "❌ Output directory does not exist: $OUTPUT_DIR" >&2
        exit 1
    fi
    if [[ ! -w "$OUTPUT_DIR" ]]; then
        echo "❌ Output directory is not writable: $OUTPUT_DIR" >&2
        exit 1
    fi
fi

# Set up file paths
INPUT_PATH="$(realpath "$INPUT")"
INPUT_DIR="$(dirname "$INPUT_PATH")"
INPUT_FILE="$(basename "$INPUT_PATH" .md)"
CLEANED_FILE="${INPUT_DIR}/${INPUT_FILE}_cleaned.md"

# Determine output directory
if [[ -n "$OUTPUT_DIR" ]]; then
    OUTPUT_DIR="$(realpath "$OUTPUT_DIR")"
    OUTPUT_FILE="${OUTPUT_DIR}/${INPUT_FILE}.pdf"
    echo "🎯 Using custom output directory: $OUTPUT_DIR"
else
    OUTPUT_FILE="${INPUT_DIR}/${INPUT_FILE}.pdf"
    echo "📂 Using default output directory: $INPUT_DIR"
fi

# Script directory and resources
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILTER_DIR="$SCRIPT_DIR/filters"
TEMPLATE_PATH="$SCRIPT_DIR/dnd-notes.tex"
FIX_SCRIPT="$SCRIPT_DIR/scripts/fix-markdown.sh"

# =========================
# Processing Steps
# =========================

echo "🧼 Cleaning Markdown..."
"$FIX_SCRIPT" "$INPUT_PATH" "$CLEANED_FILE"

if [ $? -ne 0 ]; then
    echo "❌ Markdown cleanup failed" >&2
    exit 1
fi

# Configure Pandoc options
PANDOC_OPTS=(
    --standalone
    --from="markdown+smart+backtick_code_blocks+task_lists"
    --pdf-engine=lualatex
    --template="$TEMPLATE_PATH"
    --lua-filter="$FILTER_DIR/first-h1-big.lua"
    --lua-filter="$FILTER_DIR/sticky-headings.lua"
    --lua-filter="$FILTER_DIR/highlight-boxes.lua"
    --lua-filter="$FILTER_DIR/highlight-keywords.lua"
    --lua-filter="$FILTER_DIR/fix-heading-list-spacing.lua"
    -V tables=false
    --number-sections=false
    --resource-path="."
)

# Add onecolumn variable only if true
if [ "$ONE_COLUMN" = true ]; then
    PANDOC_OPTS+=(-V onecolumn=true)
fi

echo "📄 Generating PDF..."
(
    cd "$INPUT_DIR" || exit 1
    if [[ -n "$OUTPUT_DIR" ]]; then
        pandoc "$(basename "$CLEANED_FILE")" -o "$OUTPUT_FILE" "${PANDOC_OPTS[@]}"
    else
        pandoc "$(basename "$CLEANED_FILE")" -o "$(basename "$OUTPUT_FILE")" "${PANDOC_OPTS[@]}"
    fi
)
STATUS=$?

if [ $STATUS -eq 0 ]; then
    echo "✅ PDF created: $OUTPUT_FILE"
    # Clean up temporary file
    rm -f "$CLEANED_FILE"
else
    echo "❌ PDF generation failed" >&2
    exit 1
fi
