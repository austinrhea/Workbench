#!/bin/bash
# statusline.sh - Context utilization monitor
#
# Thresholds from agent_docs:
#   - principles.md: 40-60% target
#   - context.md: 50-70% degrading, 70%+ dumb zone

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
USED=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Read phase from STATE.md if it exists
PHASE=""
if [ -f "STATE.md" ]; then
    PHASE=$(grep -m1 "^phase:" STATE.md | sed 's/phase: *//' | tr -d '[:space:]')
fi

# Color thresholds from agent_docs/context.md
if awk "BEGIN {exit !($USED > 70)}"; then
    COLOR="\033[31m"  # Red - dumb zone
elif awk "BEGIN {exit !($USED > 50)}"; then
    COLOR="\033[33m"  # Yellow - degrading
else
    COLOR="\033[32m"  # Green - target range
fi

RESET="\033[0m"
DIM="\033[2m"

if [ -n "$PHASE" ]; then
    printf "${COLOR}[%s] %.0f%%${RESET} \$%.3f ${DIM}| %s${RESET}\n" "$MODEL" "$USED" "$COST" "$PHASE"
else
    printf "${COLOR}[%s] %.0f%%${RESET} \$%.3f\n" "$MODEL" "$USED" "$COST"
fi
