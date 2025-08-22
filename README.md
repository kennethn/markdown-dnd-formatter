# 🧙‍♂️ D&D Markdown PDF Generator

A powerful tool that converts Markdown notes (especially UpNote exports) into beautifully styled, two-column PDFs optimized for D&D gameplay and reference.

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

Install **MacTeX** to get `lualatex` (required for font support and PDF output):

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
lualatex --version
```
---

## 🛠 Usage

### Quick Start

```bash
./upnote-export.sh "Your-Notes.md"
```

This generates a PDF in the same directory as your input file.

### Manual Processing (Advanced)

The main script combines these steps:

1. **Clean the Markdown:**
   ```bash
   ./fix-upnote-markdown.sh "Input.md" "Output_cleaned.md"
   ```

2. **Generate PDF with Pandoc:**
   ```bash
   pandoc Input_cleaned.md -o Output.pdf --template=dnd-notes.tex [filters...]
   ```

---

## 🎨 Features

### Layout & Typography
- **Two-column layout** with optimized spacing for readability
- **Professional typography** using Atkinson Hyperlegible font family
- **Smart page breaks** to avoid orphaned content
- **Styled blockquotes** with D&D-inspired borders

### Callout Boxes
Create highlighted callout boxes with icons using these triggers:

| Trigger | Icon | Color | Usage |
|---------|------|-------|---------|
| `Encounter:` or ⚔️ | ⚔️ | Red | Combat encounters |
| `Image:` or `Show image:` or 🖼️ | 📜 | Blue | Visual references |
| `Remember:` or ⚠️ | ⚠ | Yellow | Important reminders |
| `Music:` or 🎵 | 🎵 | Green | Audio/atmosphere |

### Monster Stat Blocks
- Anything after `# Monsters` gets special formatting
- **Column breaks** before each monster
- **Compact styling** with smaller fonts and tight spacing
- **Consistent formatting** for stat block headers

### Keyword Highlighting
- **Automatic bolding** of important terms (NPCs, locations, etc.)
- **Customizable keyword list** in `filters/highlight-keywords.lua`
- **Smart detection** of multi-word names
- **Wikilink support** for `[[linked terms]]`

### Processing Features
- **Unicode emoji handling** with proper font rendering
- **Table formatting** with colored headers and alternating rows
- **Markdown compatibility** including task lists and code blocks
- **Smart text cleanup** removing unwanted characters and formatting

---

## 📁 Project Structure

```
├── upnote-export.sh          # Main conversion script
├── fix-upnote-markdown.sh     # Markdown preprocessing
├── dnd-notes.tex             # LaTeX template
└── filters/                  # Pandoc Lua filters
    ├── utils.lua             # Shared utilities
    ├── highlight-boxes.lua   # Callout box processing
    ├── highlight-keywords.lua # Keyword highlighting
    ├── sticky-headings.lua   # Page break control
    ├── first-h1-big.lua      # Title formatting
    └── fix-heading-list-spacing.lua # Spacing fixes
```

---

## ⚙️ Customization

### Adding Keywords
Edit `filters/highlight-keywords.lua` to add character names, locations, or other important terms:

```lua
local keywords = {
  ["Strahd"] = true,
  ["Barovia"] = true,
  ["Castle Ravenloft"] = true,
  -- Add your keywords here
}
```

### Color Scheme
Modify colors in `dnd-notes.tex` in the "Color Scheme" section:

```latex
\definecolor{sectioncolor}{HTML}{30638E}     % Main blue theme
\definecolor{encountercolor}{HTML}{A32939}   % Red for encounters
```

---

## 🔧 Troubleshooting

### Common Issues
- **Font not found**: Ensure MacTeX is properly installed and in PATH
- **Lua filter errors**: Check that all `.lua` files are present in `filters/`
- **PDF generation fails**: Verify `lualatex` is available and working

### Debugging
Run with verbose output:
```bash
set -x
./upnote-export.sh "your-file.md"
```

---

## 📄 License

MIT License - see LICENSE file for details.
