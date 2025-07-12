#!/bin/bash

# Usage: ./upnote-export.sh input.md

INPUT="$1"

if [ -z "$INPUT" ]; then
  echo "Usage: $0 <input.md>"
  exit 1
fi

# Check for .md extension
if [[ "$INPUT" != *.md ]]; then
  echo "❌ Input file must be a .md file"
  exit 1
fi

# Strip .md and build filenames
BASENAME="${INPUT%.md}"
CLEANED="${BASENAME}_cleaned.md"
OUTPUT="${BASENAME}.pdf"

# Run fix-upnote-markdown script
echo "🧼 Cleaning Markdown..."
./fix-upnote-markdown.sh "$INPUT" "$CLEANED"
if [ $? -ne 0 ]; then
  echo "❌ Markdown cleanup failed"
  exit 1
fi

# Run Pandoc to generate PDF
echo "📄 Generating PDF..."
pandoc "$CLEANED" \
  -o "$OUTPUT" \
  --pdf-engine=xelatex \
  --template=dnd-notes.tex \
  --lua-filter=highlight-boxes.lua \
  --lua-filter=highlight-keywords.lua \
  --number-sections=false

if [ $? -eq 0 ]; then
  echo "✅ PDF created: $OUTPUT"
else
  echo "❌ PDF generation failed"
  exit 1
fi
