#!/bin/bash
# Check if STATE.md should be updated before compaction
# Run manually before /compact, or integrate with future PreCompact hook

STATE_FILE="STATE.md"
METRICS_FILE=".claude/metrics.json"

# Check if STATE.md exists
if [[ ! -f "$STATE_FILE" ]]; then
    echo "⚠️  No STATE.md found. Run /checkpoint or /summarize before compacting."
    exit 0
fi

# Check if STATE.md is recent
if [[ -f "$METRICS_FILE" ]]; then
    metrics_time=$(stat -c %Y "$METRICS_FILE" 2>/dev/null || stat -f %m "$METRICS_FILE" 2>/dev/null)
    state_time=$(stat -c %Y "$STATE_FILE" 2>/dev/null || stat -f %m "$STATE_FILE" 2>/dev/null)

    # If metrics updated more recently than STATE.md by >5 minutes, warn
    diff=$(( metrics_time - state_time ))
    if [[ $diff -gt 300 ]]; then
        echo "⚠️  STATE.md may be stale (metrics updated since last checkpoint)"
        echo "   Run /summarize to capture current state before /compact"
    fi
fi

exit 0
