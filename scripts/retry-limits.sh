#!/bin/bash
# Retry limits hook - track consecutive failures, block at threshold
# Usage: Called as PostToolUse hook with EXIT_CODE environment variable
#
# Tracks failures in /tmp/claude-failures-$$ (session-specific)
# Resets on success, blocks after 3 consecutive failures

FAILURE_FILE="/tmp/claude-failures-$$"
THRESHOLD=3

# Initialize file if missing
[ -f "$FAILURE_FILE" ] || echo "0" > "$FAILURE_FILE"

if [ "${EXIT_CODE:-0}" -ne 0 ]; then
    # Increment failure count
    COUNT=$(cat "$FAILURE_FILE")
    COUNT=$((COUNT + 1))
    echo "$COUNT" > "$FAILURE_FILE"

    if [ "$COUNT" -ge "$THRESHOLD" ]; then
        echo "[HOOK] $COUNT consecutive failures - escalate to human before continuing" >&2
        # Exit 2 blocks the operation (per integrations.md)
        exit 2
    else
        echo "[HOOK] Failure $COUNT/$THRESHOLD" >&2
    fi
else
    # Reset on success
    echo "0" > "$FAILURE_FILE"
fi

exit 0
