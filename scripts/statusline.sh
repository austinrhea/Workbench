#!/bin/bash
# statusline.sh - Context utilization monitor
#
# Thresholds from agent_docs:
#   - principles.md: 40-60% target
#   - context.md: 50-70% degrading, 70%+ dumb zone
#
# Persists metrics to .claude/metrics.json for commands to read

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
USED=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Persist metrics for commands to read (atomic write via temp file)
METRICS_FILE=".claude/metrics.json"
mkdir -p .claude
echo "$input" | jq '{
  used_percentage: .context_window.used_percentage,
  remaining_percentage: .context_window.remaining_percentage,
  context_window_size: .context_window.context_window_size,
  total_input_tokens: .context_window.total_input_tokens,
  total_output_tokens: .context_window.total_output_tokens,
  total_cost_usd: .cost.total_cost_usd,
  model: .model.display_name,
  updated_at: now | todate
}' > "${METRICS_FILE}.tmp" 2>/dev/null && mv "${METRICS_FILE}.tmp" "$METRICS_FILE"

# Read phase from STATE.md if it exists
PHASE=""
if [ -f "STATE.md" ]; then
    PHASE=$(grep -m1 "^phase:" STATE.md | sed 's/phase: *//' | tr -d '[:space:]')
fi

# Color thresholds from agent_docs/context.md
# Default to 0 if USED is empty/null
USED=${USED:-0}
if [ "$USED" != "0" ] && [ "$USED" != "null" ]; then
    if awk "BEGIN {exit !($USED > 70)}"; then
        COLOR="\033[31m"  # Red - dumb zone
    elif awk "BEGIN {exit !($USED > 50)}"; then
        COLOR="\033[33m"  # Yellow - degrading
    else
        COLOR="\033[32m"  # Green - target range
    fi
else
    COLOR="\033[32m"  # Green - no data yet
fi

RESET="\033[0m"
DIM="\033[2m"

if [ -n "$PHASE" ]; then
    printf "${COLOR}[%s] %.0f%%${RESET} \$%.3f ${DIM}| %s${RESET}\n" "$MODEL" "$USED" "$COST" "$PHASE"
else
    printf "${COLOR}[%s] %.0f%%${RESET} \$%.3f\n" "$MODEL" "$USED" "$COST"
fi
