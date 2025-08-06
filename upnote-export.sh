#!/bin/bash

# Usage: ./upnote-export.sh input.md

POSITIONAL=()

# Parse switches
while [[ $# -gt 0 ]]; do
  case $1 in
    --onecolumn)
      ONECOLUMN=true
      shift
      ;;
    --landscape)
      LANDSCAPE=true
      shift
      ;;
    -*)
      echo "❌ Unknown option: $1"
      exit 1
      ;;
    *)
      POSITIONAL+=("$1") # Save positional arg
      shift
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional args

INPUT="$1"
if [ -z "$INPUT" ]; then
  echo "Usage: $0 input.md"
  exit 1
fi

if [[ "$INPUT" != *.md ]]; then
  echo "❌ Input file must be a .md file"
  exit 1
fi

if [ ! -f "$INPUT" ]; then
  echo "❌ Input file not found: $INPUT"
  exit 1
fi

INPUT_PATH="$(realpath "$INPUT")"
INPUT_DIR="$(dirname "$INPUT_PATH")"
INPUT_FILE="$(basename "$INPUT_PATH" .md)"
CLEANED_FILE="${INPUT_DIR}/${INPUT_FILE}_cleaned.md"
OUTPUT_FILE="${INPUT_DIR}/${INPUT_FILE}.pdf"

# Resolve paths relative to script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILTER_DIR="$SCRIPT_DIR/filters"
TEMPLATE_PATH="$SCRIPT_DIR/dnd-notes.tex"
FIX_SCRIPT="$SCRIPT_DIR/fix-upnote-markdown.sh"

echo "🧼 Cleaning Markdown..."
"$FIX_SCRIPT" "$INPUT_PATH" "$CLEANED_FILE"
if [ $? -ne 0 ]; then
  echo "❌ Markdown cleanup failed"
  exit 1
fi

# Build Pandoc options
PANDOC_OPTS=(
  --standalone
  --from markdown+raw_attribute+yaml_metadata_block+inline_code_attributes
  --pdf-engine=lualatex
  --template="$TEMPLATE_PATH"
  --lua-filter="$FILTER_DIR/first-h1-big.lua"
  --lua-filter="$FILTER_DIR/subsubsubsection.lua"
  --lua-filter="$FILTER_DIR/sticky-headings.lua"
  --lua-filter="$FILTER_DIR/highlight-boxes.lua"
  --lua-filter="$FILTER_DIR/highlight-keywords.lua"
  --lua-filter="$FILTER_DIR/force-tabular.lua"
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
  echo "❌ PDF generation failed"
  exit 1
fi
