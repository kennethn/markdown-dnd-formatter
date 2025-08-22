#!/bin/bash

# D&D Markdown to PDF converter
# Usage: ./upnote-export.sh input.md

set -euo pipefail

# =========================
# Validation Functions
# =========================

print_usage() {
    echo "Usage: $0 input.md"
    echo "Converts UpNote markdown export to D&D-styled PDF"
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
INPUT="$1"
validate_input "$INPUT"

# Set up file paths
INPUT_PATH="$(realpath "$INPUT")"
INPUT_DIR="$(dirname "$INPUT_PATH")"
INPUT_FILE="$(basename "$INPUT_PATH" .md)"
CLEANED_FILE="${INPUT_DIR}/${INPUT_FILE}_cleaned.md"
OUTPUT_FILE="${INPUT_DIR}/${INPUT_FILE}.pdf"

# Script directory and resources
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILTER_DIR="$SCRIPT_DIR/filters"
TEMPLATE_PATH="$SCRIPT_DIR/dnd-notes.tex"
FIX_SCRIPT="$SCRIPT_DIR/scripts/fix-upnote-markdown.sh"

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

echo "📄 Generating PDF..."
(
    cd "$INPUT_DIR" || exit 1
    pandoc "$(basename "$CLEANED_FILE")" -o "$(basename "$OUTPUT_FILE")" "${PANDOC_OPTS[@]}"
)
STATUS=$?

if [ $STATUS -eq 0 ]; then
    echo "✅ PDF created: $OUTPUT_FILE"
else
    echo "❌ PDF generation failed" >&2
    exit 1
fi
