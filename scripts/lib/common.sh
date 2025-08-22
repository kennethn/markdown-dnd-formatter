#!/bin/bash
# common.sh - Shared utilities for markdown processing

set -euo pipefail

# =========================
# Logging and Output
# =========================

log_info() {
    echo "ℹ️  $*" >&2
}

log_success() {
    echo "✅ $*" >&2
}

log_warning() {
    echo "⚠️  $*" >&2
}

log_error() {
    echo "❌ $*" >&2
}

# =========================
# File Utilities
# =========================

create_temp_file() {
    local prefix="${1:-markdown}"
    mktemp "${TMPDIR:-/tmp}/${prefix}.XXXXXX"
}

cleanup_temp_files() {
    local -a files=("$@")
    for file in "${files[@]}"; do
        [[ -f "$file" ]] && rm -f "$file"
    done
}

validate_file_exists() {
    local file="$1"
    local description="${2:-File}"
    
    if [[ ! -f "$file" ]]; then
        log_error "$description not found: $file"
        return 1
    fi
}

validate_markdown_file() {
    local file="$1"
    
    if [[ "$file" != *.md ]]; then
        log_error "Input file must be a .md file: $file"
        return 1
    fi
    
    validate_file_exists "$file" "Markdown file"
}

# =========================
# Dependency Validation
# =========================

check_command() {
    local cmd="$1"
    local description="${2:-$cmd}"
    
    if ! command -v "$cmd" &> /dev/null; then
        log_error "$description not found. Please install $cmd"
        return 1
    fi
}

validate_dependencies() {
    local -a required_commands=("awk" "perl" "dos2unix")
    local missing=0
    
    for cmd in "${required_commands[@]}"; do
        if ! check_command "$cmd"; then
            missing=1
        fi
    done
    
    return $missing
}

# =========================
# Script Directory Management
# =========================

get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[1]}")" && pwd
}

get_project_root() {
    local script_dir
    script_dir="$(get_script_dir)"
    # Assume project root is parent of scripts directory
    dirname "$script_dir"
}