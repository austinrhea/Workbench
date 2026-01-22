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

### 2. Create/Update STATE.md

Write to `STATE.md` in project root with YAML frontmatter:

```markdown
---
task: "Brief task description"
status: in_progress | blocked | complete
phase: research | plan | implement | debug | idle
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

**Primary** (if status line configured):
- Green (<50%): Continue freely
- Yellow (50-70%): Run `/summarize` then `/compact`
- Red (>70%): Run `/summarize` then session break

**Explicit check**: Run `/cost` to see exact token usage.

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
