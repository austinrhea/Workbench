#!/bin/bash
# Read context metrics from .claude/metrics.json
# Usage: ./read-metrics.sh [field]
#   No args: returns full JSON
#   With arg: returns specific field (e.g., "used_percentage")
# Returns JSON with current utilization or error status

METRICS_FILE=".claude/metrics.json"

if [[ ! -f "$METRICS_FILE" ]]; then
    echo '{"error": "metrics file not found", "used_percentage": null}'
    exit 0
fi

# Check if file is stale (older than 5 minutes)
if [[ "$(uname)" == "Darwin" ]]; then
    file_age=$(($(date +%s) - $(stat -f %m "$METRICS_FILE")))
else
    file_age=$(($(date +%s) - $(stat -c %Y "$METRICS_FILE")))
fi

if [[ $file_age -gt 300 ]]; then
    stale="true"
else
    stale="false"
fi

# Read and augment metrics
METRICS=$(jq --argjson stale "$stale" '. + {stale: $stale}' "$METRICS_FILE" 2>/dev/null)

if [[ $? -ne 0 ]]; then
    echo '{"error": "invalid json", "used_percentage": null}'
    exit 1
fi

# If field requested, extract it
if [[ -n "$1" ]]; then
    echo "$METRICS" | jq -r ".$1 // \"unknown\""
else
    echo "$METRICS"
fi
