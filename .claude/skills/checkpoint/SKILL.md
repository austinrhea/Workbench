# Checkpoint

Save current state for session breaks. Includes context health check and recommendations.

## Task
$ARGUMENTS

## Instructions

Output: `## Checkpoint`

### 1. Assess Current State

Review what's been accomplished:
- What task are we working on?
- What's completed vs in progress?
- Any blockers or decisions pending?
- Key files touched or discovered?

### 2. Context Health Check

**Read metrics from `.claude/metrics.json`** (updated by status line):

```bash
cat .claude/metrics.json 2>/dev/null | jq -r '.used_percentage // "unavailable"'
```

| Utilization | Status | Recommendation |
|-------------|--------|----------------|
| <30% | Peak | Continue freely |
| 30-50% | Good | Reliable performance |
| 50-70% | Degrading | Run `/summarize` then `/compact` soon |
| >70% | Dumb zone | Run `/summarize` then `/compact` or `/clear` |

**Fallback** (if metrics unavailable): Watch for degradation symptoms:
- Forgetting earlier constraints or decisions
- Hallucinating libraries or APIs
- Missing obvious issues

### 3. Update STATE.md (Incremental)

**Merge updates into existing STATE.md** rather than overwriting:
- Update YAML frontmatter fields (status, phase, context_percent, last_updated)
- Append new decisions to `## Decisions`
- **Prune stale decisions** (see rules below)
- Update `## Blockers` (add new, mark resolved with [x])
- Update `## Key Files` (add new discoveries)
- Replace `## Next Steps` with current guidance

**Decision pruning rules** — delete decisions when:
- Now encoded in skills/commands (it's in the code now)
- Project-wide facts, not active choices (move to `agent_docs/`)
- The task they relate to is complete

If STATE.md doesn't exist, use [state template](templates/checkpoint-state.md).

### 4. Git State (If Applicable)

If changes are stable and worth preserving:

```markdown
## Rollback Point
Commit: [hash]
Command: git checkout [hash] -- [files]
```

### 5. Update Docs (If Skills Changed)

If skills were added/modified this session, run `/docs` to update README.md.

### 6. Output Recommendation

Based on utilization and task status:

| Condition | Output |
|-----------|--------|
| Task complete, context <50% | "Task complete. Context healthy." |
| Task complete, context >50% | "Task complete. Consider `/compact` before next task." |
| Task in progress, context <50% | "Checkpoint saved. Continue freely." |
| Task in progress, context 50-70% | "Checkpoint saved. Consider `/compact` before next major step." |
| Task in progress, context >70% | "Checkpoint saved. Run `/summarize` then `/compact` before continuing." |

## Constraints

- Keep STATE.md under 100 lines (forces prioritization)
- Delete resolved items aggressively
- Don't checkpoint trivial progress
- Focus on what's needed to resume, not history
- When status is `complete`, set phase to `idle`

## Exit Criteria

STATE.md saved. Context recommendation provided. Session can resume from cold start.
