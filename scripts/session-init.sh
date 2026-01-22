#!/bin/bash
# Inject STATE.md into context for session recovery
# Called from UserPromptSubmit hook
#
# Triggers in TWO scenarios:
#
# 1. POST-COMPACT RECOVERY (immediate)
#    - Context is fresh (<25% utilization)
#    - STATE.md has active status (in_progress/active/blocked)
#    - Ensures continuity after /compact when task incomplete
#
# 2. SESSION RESUME (after break)
#    - STATE.md is stale (>1 hour since modification)
#    - STATE.md has active status
#    - Restores context when returning to work
#
# Silent exit when:
# - No STATE.md file
# - status: idle or complete (task finished)
# - Active session (fresh file + normal context)

STATE_FILE="STATE.md"
STALE_THRESHOLD_SECONDS=3600     # 1 hour
FRESH_CONTEXT_THRESHOLD=25       # % utilization

if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# Parse status from frontmatter (if present)
status=$(grep -E "^status:" "$STATE_FILE" | head -1 | sed 's/status: *//')

# Skip if explicitly idle or complete - task is done
if [[ "$status" == "idle" || "$status" == "complete" ]]; then
    exit 0
fi

# Get context utilization (fallback to 50 if metrics unavailable)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "$SCRIPT_DIR/../.claude/skills/shared/scripts/read-metrics.sh" ]]; then
    context_percent=$("$SCRIPT_DIR/../.claude/skills/shared/scripts/read-metrics.sh" used_percentage 2>/dev/null || echo "50")
else
    context_percent=50
fi

# Extract common fields
task=$(grep -E "^task:" "$STATE_FILE" | head -1 | sed 's/task: *"//' | sed 's/"$//')
phase=$(grep -E "^phase:" "$STATE_FILE" | head -1 | sed 's/phase: *//')
next_steps=$(grep -A1 "^## Next Steps" "$STATE_FILE" | tail -1)

# SCENARIO 1: Post-compact recovery
# Fresh context + active state = likely just compacted, inject immediately
if [[ $context_percent -lt $FRESH_CONTEXT_THRESHOLD ]]; then
    echo "## State Recovery (post-compact)"
    echo ""
    echo "**Task**: ${task:-[unspecified]}"
    echo "**Phase**: ${phase:-[unspecified]}"
    echo "**Status**: ${status:-in_progress}"
    if [[ -n "$next_steps" && "$next_steps" != "## Next Steps" ]]; then
        echo "**Last activity**: ${next_steps}"
    fi
    echo ""
    echo "Full state:"
    echo '```'
    cat "$STATE_FILE"
    echo '```'
    echo ""
    echo "**To continue**: Type \`/workflow continue\` or describe what you'd like to do next."
    exit 0
fi

# SCENARIO 2: Session resume after break
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

# If file was modified recently, we're in an active session - no injection needed
if [[ $age_seconds -lt $STALE_THRESHOLD_SECONDS ]]; then
    exit 0
fi

# Stale and active - inject for session resume
if [[ $age_hours -ge 1 ]]; then
    echo "## Resuming Session (${age_hours}h since last update)"
else
    echo "## Resuming Session (${age_minutes}m since last update)"
fi
echo ""
echo "**Task**: ${task:-[unspecified]}"
echo "**Phase**: ${phase:-[unspecified]}"
echo "**Status**: ${status:-in_progress}"
if [[ -n "$next_steps" && "$next_steps" != "## Next Steps" ]]; then
    echo "**Last activity**: ${next_steps}"
fi
echo ""
echo "Full state:"
echo '```'
cat "$STATE_FILE"
echo '```'
echo ""
echo "**To continue**: Type \`/workflow continue\` or describe what you'd like to do next."

exit 0
