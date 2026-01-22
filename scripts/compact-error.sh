#!/bin/bash
# Compacts error output to essential information
# Usage: some_command 2>&1 | compact-error.sh
# Or: compact-error.sh < error_file

set -e

# Read from stdin or file
INPUT=$(cat)

# Extract key error information
extract_error() {
    local input="$1"

    echo "## Error Summary"
    echo

    # Python errors
    if echo "$input" | grep -q "Traceback"; then
        echo "**Type**: Python Exception"
        # Get the exception type and message (last lines of traceback)
        echo "**Error**: $(echo "$input" | grep -E "^[A-Z][a-zA-Z]+Error:|^[A-Z][a-zA-Z]+Exception:" | tail -1)"
        # Get the file and line
        echo "**Location**: $(echo "$input" | grep -E "File \"" | tail -1 | sed 's/^[[:space:]]*//')"
        echo
        echo "**Context**:"
        echo '```'
        # Show just the last 5 lines of traceback
        echo "$input" | grep -A1 "File \"" | tail -10
        echo '```'
        return
    fi

    # Node.js errors
    if echo "$input" | grep -qE "at .+\(.*:[0-9]+:[0-9]+\)"; then
        echo "**Type**: Node.js Error"
        echo "**Error**: $(echo "$input" | grep -E "^(Error|TypeError|ReferenceError|SyntaxError):" | head -1)"
        echo "**Location**: $(echo "$input" | grep -E "at .+\(" | head -1 | sed 's/^[[:space:]]*//')"
        echo
        echo "**Stack** (top 3):"
        echo '```'
        echo "$input" | grep -E "^\s+at " | head -3
        echo '```'
        return
    fi

    # Go errors
    if echo "$input" | grep -qE "\.go:[0-9]+:"; then
        echo "**Type**: Go Error"
        echo "**Location**: $(echo "$input" | grep -oE "[a-zA-Z0-9_/]+\.go:[0-9]+:" | head -1)"
        echo "**Error**: $(echo "$input" | grep -v "^#" | head -3)"
        return
    fi

    # Rust errors
    if echo "$input" | grep -qE "^error\[E[0-9]+\]:"; then
        echo "**Type**: Rust Compiler Error"
        echo "**Error**: $(echo "$input" | grep -E "^error\[E[0-9]+\]:" | head -1)"
        echo "**Location**: $(echo "$input" | grep -E "^\s*-->" | head -1)"
        return
    fi

    # TypeScript/ESLint errors
    if echo "$input" | grep -qE "\([0-9]+,[0-9]+\):"; then
        echo "**Type**: TypeScript/Lint Error"
        echo '```'
        echo "$input" | grep -E "\([0-9]+,[0-9]+\):" | head -5
        echo '```'
        return
    fi

    # Shell/Bash errors
    if echo "$input" | grep -qE "line [0-9]+:"; then
        echo "**Type**: Shell Error"
        echo "**Error**: $(echo "$input" | grep -E "line [0-9]+:" | head -1)"
        return
    fi

    # Generic fallback - just show first 10 lines
    echo "**Type**: Unknown"
    echo "**Output** (truncated):"
    echo '```'
    echo "$input" | head -10
    echo '```'
}

extract_error "$INPUT"

# Add suggestion if recognizable
echo
echo "**Suggestion**: Check the location above and verify:"
echo "1. File exists and is accessible"
echo "2. Syntax is correct"
echo "3. Dependencies are installed"
