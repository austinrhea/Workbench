#!/bin/bash
# run_silent.sh - Context-efficient test/build output
#
# Success: single checkmark line
# Failure: full diagnostic output
#
# Usage:
#   source scripts/run_silent.sh
#   run_silent "unit tests" "pytest tests/"
#   run_silent "build" "npm run build"

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

VERBOSE=${VERBOSE:-0}

run_silent() {
    local description="$1"
    local command="$2"

    if [ "$VERBOSE" = "1" ]; then
        echo "  -> Running: $command"
        eval "$command"
        return $?
    fi

    local tmp_file=$(mktemp)
    if eval "$command" > "$tmp_file" 2>&1; then
        printf "  ${GREEN}✓${NC} %s\n" "$description"
        rm -f "$tmp_file"
        return 0
    else
        local exit_code=$?
        printf "  ${RED}✗${NC} %s\n" "$description"
        printf "${RED}Command failed: %s${NC}\n" "$command"
        cat "$tmp_file"
        rm -f "$tmp_file"
        return $exit_code
    fi
}

run_silent_with_count() {
    local description="$1"
    local command="$2"
    local test_type="${3:-pytest}"

    local tmp_file=$(mktemp)
    if eval "$command" > "$tmp_file" 2>&1; then
        local test_count=""
        local duration=""

        case "$test_type" in
            pytest)
                test_count=$(grep -E "[0-9]+ passed" "$tmp_file" | grep -oE "^[0-9]+ passed" | awk '{print $1}' | tail -1)
                duration=$(grep -E "[0-9]+ passed" "$tmp_file" | grep -oE "in [0-9.]+s" | tail -1)
                ;;
            jest)
                test_count=$(jq -r '.numTotalTests // empty' "$tmp_file" 2>/dev/null)
                ;;
            go)
                test_count=$(grep -c '"Action":"pass"' "$tmp_file" 2>/dev/null || true)
                ;;
        esac

        printf "  ${GREEN}✓${NC} %s (%s tests%s)\n" "$description" "${test_count:-?}" "${duration:+, $duration}"
        rm -f "$tmp_file"
        return 0
    else
        local exit_code=$?
        printf "  ${RED}✗${NC} %s\n" "$description"
        printf "${RED}Command failed: %s${NC}\n" "$command"
        cat "$tmp_file"
        rm -f "$tmp_file"
        return $exit_code
    fi
}

# Export for use in other scripts
export -f run_silent
export -f run_silent_with_count
