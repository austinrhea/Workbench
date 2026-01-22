# Cost

Context health check. See `/checkpoint` for full state management.

## Task
$ARGUMENTS

## Instructions

Output: `## Cost`

**Note**: This is a lightweight utility. For full state management, use `/checkpoint`.

### Quick Check

Read metrics from `.claude/metrics.json`:

```bash
cat .claude/metrics.json 2>/dev/null | jq '.'
```

Fields:
- `used_percentage` — context window utilization
- `total_cost_usd` — session cost
- `total_input_tokens` / `total_output_tokens` — token counts
- `updated_at` — when metrics were last captured

### Interpretation

| Utilization | Status | Action |
|-------------|--------|--------|
| <30% | Peak | Continue freely |
| 30-50% | Good | Reliable performance |
| 50-70% | Degrading | Consider `/compact` soon |
| >70% | Dumb zone | Run `/summarize` then `/compact` |

### For Detailed Costs

Use the built-in `/cost` CLI command for official token counts and pricing.

## Exit Criteria

User understands current context health.
