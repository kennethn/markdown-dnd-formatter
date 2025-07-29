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
INPUT_DIR="$(dirname "$INPUT")"

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

BASENAME="${INPUT%.md}"
CLEANED="${BASENAME}_cleaned.md"
OUTPUT="${BASENAME}.pdf"

echo "🧼 Cleaning Markdown..."
./fix-upnote-markdown.sh "$INPUT" "$CLEANED"
if [ $? -ne 0 ]; then
  echo "❌ Markdown cleanup failed"
  exit 1
fi

# Build Pandoc options
PANDOC_OPTS=(
  --standalone
  --from markdown+raw_attribute+yaml_metadata_block+inline_code_attributes
  --pdf-engine=lualatex
  --template=dnd-notes.tex
  --lua-filter=first-h1-big.lua
  --lua-filter=subsubsubsection.lua
  --lua-filter=highlight-boxes.lua
  --lua-filter=highlight-keywords.lua
  --lua-filter=force-tabular.lua
  --lua-filter=fix-heading-list-spacing.lua
  -V tables=false
  --number-sections=false
  --resource-path="$INPUT_DIR"
)

echo "📄 Generating PDF..."
pandoc "$CLEANED" -o "$OUTPUT" "${PANDOC_OPTS[@]}"
if [ $? -eq 0 ]; then
  echo "✅ PDF created: $OUTPUT"
else
  echo "❌ PDF generation failed"
  exit 1
fi
