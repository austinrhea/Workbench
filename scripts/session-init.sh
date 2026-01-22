#!/bin/bash
# Inject STATE.md into context when resuming after a break
# Called from UserPromptSubmit hook
#
# Works with two formats:
#
# 1. Workflow-managed (full YAML frontmatter):
#    ---
#    task: "..."
#    status: in_progress
#    phase: implement
#    ...
#    ---
#
# 2. Simple (minimal or no frontmatter):
#    ---
#    status: active
#    ---
#    ## Context
#    Whatever you want to persist
#
# Behavior:
# - If no STATE.md: silent exit
# - If status is idle/complete: silent exit
# - If status is active/in_progress OR no status field: check staleness
# - If stale (file not modified in >1 hour): output STATE.md content
# - If fresh: silent exit (already in session)

STATE_FILE="STATE.md"
STALE_THRESHOLD_SECONDS=3600  # 1 hour

if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# Parse status from frontmatter (if present)
status=$(grep -E "^status:" "$STATE_FILE" | head -1 | sed 's/status: *//')

# Skip if explicitly idle or complete
if [[ "$status" == "idle" || "$status" == "complete" ]]; then
    exit 0
fi

# Check file modification time for staleness
if [[ "$(uname)" == "Darwin" ]]; then
    file_mtime=$(stat -f %m "$STATE_FILE")
else
    file_mtime=$(stat -c %Y "$STATE_FILE")
fi
now=$(date +%s)
age_seconds=$((now - file_mtime))
age_hours=$((age_seconds / 3600))
age_minutes=$((age_seconds / 60))

# If file was modified recently, we're in an active session
if [[ $age_seconds -lt $STALE_THRESHOLD_SECONDS ]]; then
    exit 0
fi

# Stale and not idle - inject into context
if [[ $age_hours -ge 1 ]]; then
    echo "## Resuming Session (${age_hours}h since last update)"
else
    echo "## Resuming Session (${age_minutes}m since last update)"
fi
echo ""
echo "STATE.md content:"
echo ""
echo '```'
cat "$STATE_FILE"
echo '```'

exit 0
