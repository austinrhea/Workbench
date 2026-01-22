#!/bin/bash
# Analyzes .claude/metrics.json for trends and insights
# Usage: analyze-metrics.sh [--history]

set -e

METRICS_FILE=".claude/metrics.json"
HISTORY_DIR=".claude/metrics-history"

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ ! -f "$METRICS_FILE" ]]; then
    echo "No metrics file found at $METRICS_FILE"
    echo "Metrics are populated by the status line during sessions."
    exit 0
fi

echo -e "${BLUE}## Session Metrics Analysis${NC}"
echo

# Current metrics
USED=$(jq -r '.used_percentage // 0' "$METRICS_FILE")
COST=$(jq -r '.total_cost_usd // 0' "$METRICS_FILE")
MODEL=$(jq -r '.model // "unknown"' "$METRICS_FILE")
INPUT_TOKENS=$(jq -r '.total_input_tokens // 0' "$METRICS_FILE")
OUTPUT_TOKENS=$(jq -r '.total_output_tokens // 0' "$METRICS_FILE")
UPDATED=$(jq -r '.updated_at // "unknown"' "$METRICS_FILE")

echo "### Current State"
echo "| Metric | Value |"
echo "|--------|-------|"
echo "| Model | $MODEL |"
echo "| Context Used | ${USED}% |"
echo "| Input Tokens | $INPUT_TOKENS |"
echo "| Output Tokens | $OUTPUT_TOKENS |"
echo "| Session Cost | \$${COST} |"
echo "| Last Updated | $UPDATED |"
echo

# Health assessment
echo "### Health Assessment"
if (( $(echo "$USED < 30" | awk '{print ($1 < 30)}') )); then
    echo -e "${GREEN}✓${NC} Context: Healthy (${USED}%)"
elif (( $(echo "$USED < 50" | awk '{print ($1 < 50)}') )); then
    echo -e "${GREEN}✓${NC} Context: Good (${USED}%)"
elif (( $(echo "$USED < 60" | awk '{print ($1 < 60)}') )); then
    echo -e "${YELLOW}⚠${NC} Context: Elevated (${USED}%) - consider /summarize"
else
    echo -e "${RED}⚠${NC} Context: High (${USED}%) - /compact recommended"
fi

# Token efficiency
if [[ $INPUT_TOKENS -gt 0 && $OUTPUT_TOKENS -gt 0 ]]; then
    RATIO=$(awk "BEGIN {printf \"%.1f\", $OUTPUT_TOKENS / $INPUT_TOKENS}")
    echo "Token ratio (out/in): ${RATIO}x"
    if (( $(echo "$RATIO < 0.1" | awk '{print ($1 < 0.1)}') )); then
        echo -e "${YELLOW}Note${NC}: Low output ratio - may indicate exploration-heavy session"
    fi
fi
echo

# Cost projection
if [[ "$COST" != "0" && "$USED" != "0" ]]; then
    echo "### Cost Projection"
    COST_PER_PERCENT=$(awk "BEGIN {printf \"%.4f\", $COST / $USED}")
    FULL_SESSION_COST=$(awk "BEGIN {printf \"%.2f\", $COST_PER_PERCENT * 60}")
    echo "Cost per 1% context: \$${COST_PER_PERCENT}"
    echo "Projected cost at 60%: \$${FULL_SESSION_COST}"
    echo
fi

# History analysis (if --history flag)
if [[ "$1" == "--history" ]]; then
    if [[ -d "$HISTORY_DIR" ]]; then
        echo "### Session History"
        echo "| Date | Peak Context | Cost |"
        echo "|------|--------------|------|"
        for f in $(ls -t "$HISTORY_DIR"/*.json 2>/dev/null | head -5); do
            DATE=$(basename "$f" .json)
            PEAK=$(jq -r '.used_percentage // 0' "$f")
            HIST_COST=$(jq -r '.total_cost_usd // 0' "$f")
            echo "| $DATE | ${PEAK}% | \$${HIST_COST} |"
        done
    else
        echo "No history directory found. Create $HISTORY_DIR and archive metrics to track trends."
    fi
fi

echo
echo "---"
echo "Run \`/cost\` for quick status or \`analyze-metrics.sh --history\` for trends."
