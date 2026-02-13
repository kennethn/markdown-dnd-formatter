#!/bin/bash
# yaml-processor.sh - Handle YAML frontmatter separation

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# =========================
# YAML Frontmatter Processing
# =========================

separate_yaml_frontmatter() {
    local input_file="$1"
    local output_file="$2"
    
    log_info "Separating YAML frontmatter..."
    
    awk '
    BEGIN { in_yaml=0 }
    /^---$/ {
        print;
        in_yaml = !in_yaml;
        next;
    }
    {
        if (in_yaml) {
            print;
        } else {
            print "__BODY_LINE__" $0;
        }
    }' "$input_file" > "$output_file"
    
    if [[ $? -eq 0 ]]; then
        log_success "YAML frontmatter separated"
    else
        log_error "Failed to separate YAML frontmatter"
        return 1
    fi
}