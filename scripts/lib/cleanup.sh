#!/bin/bash
# cleanup.sh - Final cleanup and formatting

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# =========================
# Final Cleanup
# =========================

collapse_blank_lines() {
    local input_file="$1"
    local output_file="$2"
    
    log_info "Collapsing multiple blank lines..."
    
    awk '
    BEGIN { blank=0 }
    /^$/ {
        if (blank == 0) {
            print;
            blank = 1;
        }
        next;
    }
    {
        blank = 0;
        print;
    }
    ' "$input_file" > "$output_file"
    
    if [[ $? -eq 0 ]]; then
        log_success "Blank lines collapsed"
    else
        log_error "Failed to collapse blank lines"
        return 1
    fi
}

# =========================
# Line Ending Normalization
# =========================

normalize_line_endings() {
    local file="$1"
    
    log_info "Normalizing line endings..."
    
    if command -v dos2unix &> /dev/null; then
        dos2unix "$file" 2>/dev/null
        log_success "Line endings normalized"
    else
        log_warning "dos2unix not available, skipping line ending normalization"
    fi
}