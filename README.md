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
---

## 🎨 Features

- Two-column layout with tight spacing and good readability
- Styled blockquotes like D&D boxed text
- Callout boxes with icons and borders. Use these keywords:
  - **Encounter:"** Text following this will be rendered in a red box with skull icon
  - **Image:** Text following this will be rendered in a yellow box with an image icon
- Monster stat blocks. Anything after "# Monsters" will be treated as a monster stat block
- Optional automatic bolding and color for keywords like character names
