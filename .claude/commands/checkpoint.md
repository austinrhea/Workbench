# Checkpoint

Save current state for session breaks or complex work.

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

### 2. Update STATE.md (Incremental)

**Merge updates into existing STATE.md** rather than overwriting:
- Update YAML frontmatter fields (status, phase, context_percent, last_updated)
- Append new decisions to `## Decisions`
- **Prune stale decisions** (see rules below)
- Update `## Blockers` (add new, mark resolved with [x])
- Update `## Key Files` (add new discoveries)
- Replace `## Next Steps` with current guidance

**Decision pruning rules** — delete decisions when:
- Now encoded in commands (e.g., "Added X to /implement" → it's in the command now)
- Project-wide facts, not active choices (move to `agent_docs/`)
- The task they relate to is complete

If STATE.md doesn't exist, create with this structure:

```markdown
---
task: "Brief task description"
status: in_progress | blocked | complete | parked
phase: research | plan | implement | debug | idle | quick
context_percent: [current utilization]
last_updated: [today's date]
---

## Decisions
- [Decision]: [rationale]

## Blockers
- [ ] [Unresolved issue]

## Key Files
- `path:line` — [why it matters]

## Next Steps
[What to do when resuming — be specific]
```

For heavy context (>50%), use `/summarize` instead for structured compaction prep.

### 3. Git State (If Applicable)

If changes are stable and worth preserving:

```markdown
## Rollback Point
Commit: [hash]
Command: git checkout [hash] -- [files]
```

### 4. Update Docs (If Commands Changed)

If commands were added/modified this session, run `/docs` to update README.md.

### 5. Context Health Check

**Read metrics from `.claude/metrics.json`** (updated by status line):

```bash
cat .claude/metrics.json | jq '.used_percentage'
```

| Utilization | Color | Action |
|-------------|-------|--------|
| <50% | Green | Continue freely |
| 50-70% | Yellow | Run `/summarize` then `/compact` |
| >70% | Red | Run `/summarize` then session break |

**Update STATE.md** `context_percent` field from metrics.

**Built-in CLI commands** (not custom):
- `/cost` — show token usage and costs
- `/compact` — compress context while preserving key state
- `/clear` — reset context entirely

**Fallback** (if metrics unavailable): Watch for degradation symptoms:
- Forgetting earlier constraints or decisions
- Hallucinating libraries or APIs
- Missing obvious issues

See `context.md` "Dumb Zone" for full symptom list.

## Constraints

- Keep STATE.md under 100 lines (forces prioritization)
- Delete resolved items aggressively
- Don't checkpoint trivial progress
- Focus on what's needed to resume, not history
- When status is `complete`, set phase to `idle` (clears status line between tasks)

## Exit Criteria

STATE.md saved. Session can resume from cold start with full context.

### Context Recommendation (based on current %)

After checkpoint, suggest next action based on utilization:

| Utilization | Recommendation |
|-------------|----------------|
| <50% | Continue freely |
| 50-70% | "Consider `/compact` before next task" |
| >70% | "Run `/summarize` then `/compact` or start fresh with `/clear`" |

If task is complete and context >50%, proactively suggest compaction.
