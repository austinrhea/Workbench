#!/bin/bash
# Estimates context cost for upcoming phase
# Usage: estimate-context.sh <phase> [current_percent]

PHASE="${1:-unknown}"
CURRENT="${2:-}"

# Read current metrics if not provided as argument
METRICS_FILE=".claude/metrics.json"
if [[ -z "$CURRENT" ]] && [[ -f "$METRICS_FILE" ]]; then
    CURRENT=$(jq -r '.used_percentage // 0' "$METRICS_FILE" 2>/dev/null || echo "0")
fi
CURRENT="${CURRENT:-0}"

# Phase cost estimates (empirical averages)
declare -A PHASE_COSTS=(
    [research]=15
    [plan]=10
    [implement]=20
    [debug]=15
    [checkpoint]=2
    [summarize]=5
)

COST="${PHASE_COSTS[$PHASE]:-10}"
# Use integer arithmetic (context % is always integer)
CURRENT_INT="${CURRENT%.*}"
PROJECTED=$((CURRENT_INT + COST))

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "Context Estimation"
echo "─────────────────────────────"
echo "Current:    ${CURRENT_INT}%"
echo "Phase:      $PHASE (+~${COST}%)"
echo "Projected:  ${PROJECTED}%"
echo

if [[ $PROJECTED -gt 60 ]]; then
    echo -e "${RED}⚠ WARNING${NC}: Projected context exceeds 60%"
    echo "Consider running /summarize then /compact before proceeding"
    exit 2
elif [[ $PROJECTED -gt 50 ]]; then
    echo -e "${YELLOW}CAUTION${NC}: Projected context >50%"
    echo "Quality may degrade. Monitor closely."
    exit 1
else
    echo -e "${GREEN}✓${NC} Context budget OK"
    exit 0
fi
