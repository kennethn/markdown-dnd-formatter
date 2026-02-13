#!/bin/bash
# fix-markdown.sh - Modular markdown processor
# Usage: ./scripts/fix-markdown.sh input.md output.md

set -euo pipefail

# =========================
# Setup and Initialization
# =========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Load shared utilities
source "$LIB_DIR/common.sh"
source "$LIB_DIR/monster-blocks.sh"
source "$LIB_DIR/yaml-processor.sh"
source "$LIB_DIR/content-transformer.sh"
source "$LIB_DIR/cleanup.sh"

# =========================
# Argument Validation
# =========================

print_usage() {
    echo "Usage: $0 input.md output.md"
    echo "Processes markdown notes for D&D PDF generation"
}

validate_arguments() {
    local input="$1"
    local output="$2"
    
    if [[ -z "$input" || -z "$output" ]]; then
        print_usage
        exit 1
    fi
    
    validate_markdown_file "$input"
}

# =========================
# Main Processing Pipeline
# =========================

process_markdown() {
    local input_file="$1"
    local output_file="$2"
    
    log_info "Starting markdown processing pipeline"
    log_info "Input: $input_file"
    log_info "Output: $output_file"
    
    # Validate dependencies
    if ! validate_dependencies; then
        log_error "Missing required dependencies"
        exit 1
    fi
    
    # Create temporary files
    temp_normalized=$(create_temp_file "normalized")
    temp_monsters=$(create_temp_file "monsters")
    temp_yaml=$(create_temp_file "yaml")
    temp_transformed=$(create_temp_file "transformed")
    temp_final=$(create_temp_file "final")

    # Setup cleanup function and trap
    cleanup_on_exit() {
        [[ -n "${temp_normalized:-}" && -f "$temp_normalized" ]] && rm -f "$temp_normalized" 2>/dev/null || true
        [[ -n "${temp_monsters:-}" && -f "$temp_monsters" ]] && rm -f "$temp_monsters" 2>/dev/null || true
        [[ -n "${temp_yaml:-}" && -f "$temp_yaml" ]] && rm -f "$temp_yaml" 2>/dev/null || true
        [[ -n "${temp_transformed:-}" && -f "$temp_transformed" ]] && rm -f "$temp_transformed" 2>/dev/null || true
        [[ -n "${temp_final:-}" && -f "$temp_final" ]] && rm -f "$temp_final" 2>/dev/null || true
    }
    trap cleanup_on_exit EXIT

    # Processing pipeline
    normalize_line_endings "$input_file" "$temp_normalized" || {
        log_error "Failed to normalize line endings"
        exit 1
    }

    wrap_monster_blocks "$temp_normalized" "$temp_monsters" || {
        log_error "Monster block processing failed"
        exit 1
    }
    
    separate_yaml_frontmatter "$temp_monsters" "$temp_yaml" || {
        log_error "YAML processing failed"
        exit 1
    }
    
    transform_content "$temp_yaml" "$temp_transformed" || {
        log_error "Content transformation failed"
        exit 1
    }
    
    collapse_blank_lines "$temp_transformed" "$output_file" || {
        log_error "Final cleanup failed"
        exit 1
    }
    
    log_success "Markdown processing complete: $output_file"
}

# =========================
# Script Entry Point
# =========================

main() {
    local input_file="${1:-}"
    local output_file="${2:-}"
    
    validate_arguments "$input_file" "$output_file"
    process_markdown "$input_file" "$output_file"
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi