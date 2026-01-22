#!/bin/bash
# context-warning.sh - Warn user when context utilization is high
#
# Used as UserPromptSubmit hook to remind user to run /summarize
# Reads metrics from .claude/metrics.json (written by statusline.sh)
#
# Exit codes: 0 = allow (always), warnings go to stderr

METRICS_FILE=".claude/metrics.json"
WARNING_THRESHOLD=60
CRITICAL_THRESHOLD=70

# Skip if metrics file doesn't exist
if [[ ! -f "$METRICS_FILE" ]]; then
    exit 0
fi

# Read current utilization
used=$(jq -r '.used_percentage // 0' "$METRICS_FILE" 2>/dev/null)

# Handle non-numeric values
if ! [[ "$used" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    exit 0
fi

# Convert to integer for comparison
used_int=${used%.*}

if (( used_int >= CRITICAL_THRESHOLD )); then
    echo "[context: ${used_int}% - critical] Run /summarize then /compact" >&2
elif (( used_int >= WARNING_THRESHOLD )); then
    echo "[context: ${used_int}% - high] Consider /compact soon" >&2
fi

exit 0
