# Makefile for D&D Markdown Formatter

.PHONY: help test clean install lint format validate

# Default target
help:
	@echo "D&D Markdown Formatter - Available Commands"
	@echo "==========================================="
	@echo "make test        - Run test suite"
	@echo "make clean       - Clean temporary files"
	@echo "make install     - Install dependencies"
	@echo "make lint        - Run linting checks"
	@echo "make format      - Format shell scripts"
	@echo "make validate    - Validate configuration files"
	@echo "make demo        - Run demonstration"

# Test the refactored script
test:
	@echo "Running test suite..."
	./tests/test-fix-markdown.sh

# Clean temporary and generated files
clean:
	@echo "Cleaning temporary files..."
	find . -name "*.tmp" -delete
	find . -name "*_cleaned.md" -delete
	rm -rf tests/fixtures
	@echo "Cleanup complete"

# Install dependencies (macOS)
install:
	@echo "Checking dependencies..."
	@command -v pandoc >/dev/null 2>&1 || { echo "Installing pandoc..."; brew install pandoc; }
	@command -v lualatex >/dev/null 2>&1 || { echo "Installing MacTeX..."; brew install --cask mactex; }
	@command -v dos2unix >/dev/null 2>&1 || { echo "Installing dos2unix..."; brew install dos2unix; }
	@echo "Dependencies ready"

# Lint shell scripts
lint:
	@echo "Linting shell scripts..."
	@command -v shellcheck >/dev/null 2>&1 || { echo "Installing shellcheck..."; brew install shellcheck; }
	find pandoc/scripts -name "*.sh" -exec shellcheck {} \;
	@echo "Linting complete"

# Format shell scripts
format:
	@echo "Formatting shell scripts..."
	@command -v shfmt >/dev/null 2>&1 || { echo "Installing shfmt..."; brew install shfmt; }
	find pandoc/scripts -name "*.sh" -exec shfmt -w -i 4 {} \;
	@echo "Formatting complete"

# Validate configuration files
validate:
	@echo "Validating configuration..."
	@command -v jq >/dev/null 2>&1 || { echo "Installing jq..."; brew install jq; }
	jq empty pandoc/config/transform-config.json
	@echo "Configuration valid"

# Run a demonstration
demo:
	@echo "Running demonstration..."
	@echo "Creating sample input..."
	@mkdir -p demo
	@echo "# Sample D&D Notes" > demo/sample.md
	@echo "" >> demo/sample.md
	@echo "**Encounter:** Goblins attack!" >> demo/sample.md
	@echo "**Remember:** Roll initiative!" >> demo/sample.md
	@echo "Processing with refactored script..."
	./pandoc/scripts/fix-markdown.sh demo/sample.md demo/sample_cleaned.md
	@echo "Demo complete. Check demo/sample_cleaned.md"

# Development helpers
dev-setup:
	@echo "Setting up development environment..."
	mkdir -p pandoc/scripts/lib tests pandoc/config
	@echo "Development environment ready"