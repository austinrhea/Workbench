# Cost

Check context utilization and token costs.

## Task
$ARGUMENTS

## Instructions

Output: `## Cost`

**State**: Utility command. Does not modify STATE.md.

### 1. Read Current Metrics

**Read from `.claude/metrics.json`** (updated by status line):

```bash
cat .claude/metrics.json
```

This file contains:
- `used_percentage` — context window utilization
- `total_cost_usd` — session cost
- `total_input_tokens` / `total_output_tokens` — token counts
- `updated_at` — when metrics were last captured

**Alternative**: Run built-in `/cost` command for official totals.

### 2. Interpret Results

| Utilization | Status | Action |
|-------------|--------|--------|
| 0-30% | Peak | Continue freely |
| 30-50% | Good | Reliable performance |
| 50-70% | Degrading | Consider `/compact` soon |
| 70%+ | Dumb zone | Run `/summarize` then `/compact` or session break |

### 3. If High Utilization

When approaching 50%+:
1. Run `/summarize` to prepare STATE.md
2. Run `/compact` to compress context
3. Or start fresh session with `/clear`

See `agent_docs/context.md` for detailed thresholds.

## Exit Criteria

User understands current context health and recommended action.
