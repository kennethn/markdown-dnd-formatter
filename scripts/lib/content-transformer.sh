#!/bin/bash
# content-transformer.sh - Content transformation for D&D markdown preprocessing

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# =========================
# Content Transformation
# =========================

TRANSFORMER_PL="$(dirname "${BASH_SOURCE[0]}")/transform-content.pl"

transform_content() {
    local input_file="$1"
    local output_file="$2"

    log_info "Transforming markdown content..."

    perl -CSD "$TRANSFORMER_PL" "$input_file" > "$output_file"

    if [[ $? -eq 0 ]]; then
        log_success "Content transformation complete"
    else
        log_error "Content transformation failed"
        return 1
    fi
}
