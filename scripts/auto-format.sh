#!/bin/bash
# auto-format.sh - Auto-format files after Edit tool
#
# Used as PostToolUse hook for Edit
# Detects file type and runs appropriate formatter
#
# Exit codes: 0 = always (formatting is best-effort, never blocks)

# $FILE is set by Claude Code for Edit tool hooks
if [[ -z "$FILE" ]]; then
    exit 0
fi

# Skip if file doesn't exist
if [[ ! -f "$FILE" ]]; then
    exit 0
fi

# Get file extension
ext="${FILE##*.}"

# Format based on extension
case "$ext" in
    js|jsx|ts|tsx|json|css|scss|html|md|yaml|yml)
        # Use prettier if available and config exists
        if command -v prettier &>/dev/null; then
            if [[ -f ".prettierrc" || -f ".prettierrc.json" || -f "prettier.config.js" ]]; then
                prettier --write "$FILE" 2>/dev/null || true
            fi
        fi
        ;;
    go)
        # Use gofmt if available
        if command -v gofmt &>/dev/null; then
            gofmt -w "$FILE" 2>/dev/null || true
        fi
        ;;
    py)
        # Use black if available
        if command -v black &>/dev/null; then
            black --quiet "$FILE" 2>/dev/null || true
        fi
        ;;
    rs)
        # Use rustfmt if available
        if command -v rustfmt &>/dev/null; then
            rustfmt "$FILE" 2>/dev/null || true
        fi
        ;;
    sh|bash)
        # Use shfmt if available
        if command -v shfmt &>/dev/null; then
            shfmt -w "$FILE" 2>/dev/null || true
        fi
        ;;
esac

exit 0
