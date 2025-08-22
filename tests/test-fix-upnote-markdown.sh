#!/bin/bash
# test-fix-upnote-markdown.sh - Test suite for the refactored markdown processor

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_DATA_DIR="$SCRIPT_DIR/fixtures"
FIX_SCRIPT="$PROJECT_ROOT/scripts/fix-upnote-markdown.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# =========================
# Test Framework
# =========================

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $*"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
    ((TESTS_FAILED++))
}

run_test() {
    local test_name="$1"
    shift
    
    log_test "Running: $test_name"
    ((TESTS_RUN++))
    
    if "$@"; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name"
        # Don't exit on test failure, continue running other tests
        return 0
    fi
}

# =========================
# Setup Test Environment
# =========================

setup_test_data() {
    mkdir -p "$TEST_DATA_DIR"
    
    # Create test input file
    cat > "$TEST_DATA_DIR/test-input.md" << 'EOF'
# Test Document

This is a test document with various elements.

# Monsters

# Test Monster
AC 15
HP 25

# Another Monster  
AC 12
HP 30

# Regular Section

**Encounter:** This is an encounter description.

**Image:** Show this image reference.

**Remember:** Important reminder here.

**Music:** Atmospheric music cue.

| Name | AC | HP |
|------|----|----|
| Goblin | 15 | 7 |
| Orc | 13 | 15 |

Some [[Wikilink]] text here.

Negative armor class: -2

Text with—em dash and–en dash.
EOF

    # Create expected output snippets for validation
    cat > "$TEST_DATA_DIR/expected-patterns.txt" << 'EOF'
::: {.monsterblock}
::: highlightencounterbox
::: highlightshowimagebox
::: rememberbox
::: musicbox
\\textcolor{sectioncolor}{\\textbf{Wikilink}}
\\texttt{-2}
EOF
}

# =========================
# Individual Tests
# =========================

test_script_exists() {
    [[ -f "$FIX_SCRIPT" ]] && [[ -x "$FIX_SCRIPT" ]]
}

test_basic_processing() {
    local input="$TEST_DATA_DIR/test-input.md"
    local output="$TEST_DATA_DIR/test-output.md"
    
    "$FIX_SCRIPT" "$input" "$output" &>/dev/null
    [[ -f "$output" ]] && [[ -s "$output" ]]
}

test_monster_blocks() {
    local input="$TEST_DATA_DIR/test-input.md"
    local output="$TEST_DATA_DIR/test-output.md"
    
    "$FIX_SCRIPT" "$input" "$output" &>/dev/null
    grep -q "::: {\.monsterblock}" "$output"
}

test_callout_boxes() {
    local input="$TEST_DATA_DIR/test-input.md"
    local output="$TEST_DATA_DIR/test-output.md"
    
    "$FIX_SCRIPT" "$input" "$output" &>/dev/null
    
    grep -q "::: highlightencounterbox" "$output" &&
    grep -q "::: highlightshowimagebox" "$output" &&
    grep -q "::: rememberbox" "$output" &&
    grep -q "::: musicbox" "$output"
}

test_wiki_links() {
    local input="$TEST_DATA_DIR/test-input.md"
    local output="$TEST_DATA_DIR/test-output.md"
    
    "$FIX_SCRIPT" "$input" "$output" &>/dev/null
    grep -q "textcolor{sectioncolor}" "$output"
}

test_negative_numbers() {
    local input="$TEST_DATA_DIR/test-input.md"
    local output="$TEST_DATA_DIR/test-output.md"
    
    "$FIX_SCRIPT" "$input" "$output" &>/dev/null
    # Test that negative numbers are preserved but NOT wrapped in texttt
    grep -q "\-2" "$output" && ! grep -q "texttt{-" "$output"
}

test_table_processing() {
    local input="$TEST_DATA_DIR/test-input.md"
    local output="$TEST_DATA_DIR/test-output.md"
    
    "$FIX_SCRIPT" "$input" "$output" &>/dev/null
    grep -q "begin{tabular}" "$output"
}

test_error_handling() {
    local nonexistent="/tmp/nonexistent-file.md"
    local output="$TEST_DATA_DIR/error-test-output.md"
    
    # Should fail gracefully
    ! "$FIX_SCRIPT" "$nonexistent" "$output" &>/dev/null
}

test_empty_file() {
    local input="$TEST_DATA_DIR/empty.md"
    local output="$TEST_DATA_DIR/empty-output.md"
    
    touch "$input"
    "$FIX_SCRIPT" "$input" "$output" &>/dev/null
    [[ -f "$output" ]]
}

# =========================
# Test Runner
# =========================

cleanup_tests() {
    rm -rf "$TEST_DATA_DIR"
}

print_summary() {
    echo
    echo "=================================="
    echo "Test Summary"
    echo "=================================="
    echo "Tests run: $TESTS_RUN"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}Failed: $TESTS_FAILED${NC}"
        return 1
    else
        echo "All tests passed!"
        return 0
    fi
}

main() {
    echo "Setting up test environment..."
    setup_test_data
    
    echo "Running tests..."
    echo
    
    # Run all tests
    run_test "Script exists and is executable" test_script_exists
    run_test "Basic processing works" test_basic_processing
    run_test "Monster blocks are wrapped" test_monster_blocks
    run_test "Callout boxes are created" test_callout_boxes
    run_test "Wiki links are processed" test_wiki_links
    run_test "Negative numbers are preserved" test_negative_numbers
    run_test "Tables are processed" test_table_processing
    run_test "Error handling works" test_error_handling
    run_test "Empty files are handled" test_empty_file
    
    # Cleanup and summary
    cleanup_tests
    print_summary
}

# Trap cleanup on exit
trap cleanup_tests EXIT

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi