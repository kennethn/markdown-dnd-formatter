# 🧙‍♂️ UpNote Markdown to D&D PDF Generator

This tool converts Markdown notes exported from UpNote into beautifully styled, two-column PDFs for in-game reference.
---

## 📦 Prerequisites

Install the following dependencies:

### 1. Homebrew (if not installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Pandoc

```bash
brew install pandoc
```

### 3. LaTeX Engine

Install **MacTeX** to get `xelatex` (required for font support and PDF output):

```bash
brew install --cask mactex
```

If you prefer a smaller install:

```bash
brew install --cask mactex-no-gui
```

Then add LaTeX to your path:

```bash
echo 'export PATH="/Library/TeX/texbin:$PATH"' >> ~/.zprofile
source ~/.zprofile
```

Verify with:

```bash
xelatex --version
```

### 4. Fonts

You’ll need the following fonts installed in `~/Library/Fonts`:

- **Crimson Pro** (OTF preferred for LaTeX compatibility)
- **IBM Plex Sans** (for blockquotes and UI elements)
- **Symbola** (for Unicode glyphs like ⚔ and ◆)

```bash
mkdir -p ~/Library/Fonts/CrimsonPro && \
curl -s https://api.github.com/repos/Fonthausen/CrimsonPro/contents/fonts/otf | \
grep -Eo 'https://raw.githubusercontent.com[^"]+\.otf' | \
xargs -n 1 curl -s -O && \
mv *.otf ~/Library/Fonts/CrimsonPro/ && \
fc-cache -f ~/Library/Fonts/CrimsonPro/
```

Install them manually and verify with:

```bash
fc-list | grep "Charter"
fc-list | grep "IBM Plex Sans"
fc-list | grep "Symbola"
```

### 5. Lua Filters (Custom)

Include these files in your working directory:

- `highlight-boxes.lua` — renders `:::highlightencounterbox` and `:::highlightshowimagebox` Divs
- `autobold-keywords.lua` — bolds and colors keywords like NPC names (optional)

---

## 🛠 Usage

```bash
./upnote-export.sh "UpNote Export.md"
```

This generates a PDF in the same directory as `UpNote Export.md`

This script is a simple wrapper that combines these steps:

1. Clean your UpNote Markdown export with your script:

```bash
./fix-upnote-markdown.sh "Original Export.md"
```

This creates a cleaned file like:

```text
2025-07-12 - Gloomwrought_cleaned.md
```

2. Generate the PDF using these commands:

```bash
pandoc "<filename-clean.md>" \
  -o "<filename.pdf>" \
  --pdf-engine=xelatex \
  --template=dnd-notes.tex \
  --lua-filter=highlight-boxes.lua \
  --lua-filter=autobold-keywords.lua \
  --number-sections=false
```

---

## 🎨 Features

- Two-column layout with tight spacing and good readability
- Styled blockquotes like D&D boxed text
- Callout boxes with icons and borders:
  - ⚔ **Encounter** (red)
  - ◆ **Show image** (yellow)
- Full font control: serif body, sans-serif UI text, emoji/symbol font
- Widow and orphan protection for paragraph layout
- Optional automatic bolding and color for keywords like character names
- Markdown-based workflow, no Word or InDesign required

---

## 🔧 Optional Enhancements

### Fixing Markdown from UpNote

Some steps that are performed:

- Strip emojis and variation selectors
- Remove `<br>` tags and wiki links
- Normalize headers and list formatting
- Convert callouts into fenced Divs like:

### Colored Boxed Text for Encounters and Images

The `highlight-boxes.lua` looks for tokens in the markdown that begin with `Encounter:` or `Show image:` and converts them to beautiful colored callout boxes.

### Bold & Color Key Terms

The `highlight-keywords.lua` filter reads a list of character names and highlights them inline in bold blue — except when they appear in headers.

--

## TODO:

* Import an NPC names file and pass that to `highlight-keywords.lua`
