#!/bin/bash
# Check STATE.md for stale or in-progress state
# Called from UserPromptSubmit hook or manually at session start

STATE_FILE="STATE.md"

if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# Parse frontmatter
status=$(grep -E "^status:" "$STATE_FILE" | head -1 | sed 's/status: *//')
last_updated=$(grep -E "^last_updated:" "$STATE_FILE" | head -1 | sed 's/last_updated: *//')
task=$(grep -E "^task:" "$STATE_FILE" | head -1 | sed 's/task: *"//' | sed 's/"$//')

# Check if stale (older than 24 hours)
if [[ -n "$last_updated" ]]; then
    # Convert date to epoch (handles YYYY-MM-DD format)
    if [[ "$(uname)" == "Darwin" ]]; then
        state_epoch=$(date -j -f "%Y-%m-%d" "$last_updated" +%s 2>/dev/null || echo 0)
    else
        state_epoch=$(date -d "$last_updated" +%s 2>/dev/null || echo 0)
    fi
    now_epoch=$(date +%s)
    age_hours=$(( (now_epoch - state_epoch) / 3600 ))

    if [[ $age_hours -gt 24 && "$status" == "in_progress" ]]; then
        echo "⚠️  STATE.md is ${age_hours}h old with status: $status"
        echo "   Task: $task"
        echo "   Consider: /workflow to review state"
    fi
fi

exit 0
