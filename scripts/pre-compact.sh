#!/bin/bash
# Pre-compact checklist - run before /compact to preserve state
# Reminds user to save state so it survives compaction

STATE_FILE="STATE.md"
METRICS_FILE=".claude/metrics.json"

echo "## Pre-Compact Checklist"
echo ""

# Check 1: STATE.md exists
if [[ ! -f "$STATE_FILE" ]]; then
    echo "❌ No STATE.md found"
    echo "   → Run /summarize to create state file before compacting"
    echo ""
    exit 0
fi

# Check 2: STATE.md is recent
stale=false
if [[ -f "$METRICS_FILE" ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        metrics_time=$(stat -f %m "$METRICS_FILE")
        state_time=$(stat -f %m "$STATE_FILE")
    else
        metrics_time=$(stat -c %Y "$METRICS_FILE")
        state_time=$(stat -c %Y "$STATE_FILE")
    fi

    diff=$(( metrics_time - state_time ))
    if [[ $diff -gt 300 ]]; then
        stale=true
    fi
fi

if [[ "$stale" == "true" ]]; then
    echo "⚠️  STATE.md may be stale (>5 min since last update)"
    echo "   → Run /summarize to capture current progress"
else
    echo "✓ STATE.md exists and is recent"
fi

# Check 3: Remind about recovery
echo ""
echo "After /compact, your state will auto-reload if task was in_progress."
echo "Run /summarize now to ensure nothing is lost."

exit 0
