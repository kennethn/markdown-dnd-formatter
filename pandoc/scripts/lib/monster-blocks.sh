#!/bin/bash
# monster-blocks.sh - Process monster stat blocks

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# =========================
# Monster Block Processing
# =========================

wrap_monster_blocks() {
    local input_file="$1"
    local output_file="$2"
    
    log_info "Wrapping monster blocks..."
    
    awk '
    BEGIN {
        inside_monsters_section = 0;
        inside_block = 0;
    }
    {
        # Detect monsters section (# Monsters)
        if ($0 ~ /^# Monsters$/) {
            inside_monsters_section = 1;
            print;
            next;
        }

        # End monsters section if we hit another top-level section (but not individual monsters)
        # Look for sections that are clearly not monster names
        if (inside_monsters_section && $0 ~ /^# (Regular|Items|Spells|NPCs|Locations|Equipment|Magic Items|Treasure)/) {
            if (inside_block) {
                print ":::";
                inside_block = 0;
            }
            inside_monsters_section = 0;
        }
        
        # Wrap individual monster blocks (# within monsters section, but not the Monsters header itself)
        if (inside_monsters_section && $0 ~ /^# / && $0 !~ /^# Monsters$/) {
            if (inside_block) {
                print ":::";
                inside_block = 0;
            }
            print "::: {.monsterblock}";
            inside_block = 1;
        }

        print;
    }
    END {
        if (inside_block) print ":::";
    }
    ' "$input_file" > "$output_file"
    
    if [[ $? -eq 0 ]]; then
        log_success "Monster blocks wrapped"
    else
        log_error "Failed to wrap monster blocks"
        return 1
    fi
}