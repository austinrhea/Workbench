# Debug Phase

Diagnose systematically before proposing fixes.

## Task
$ARGUMENTS

## Instructions

Output: `## Debug Phase`

### 1. Reproduce
- Confirm the failure exists
- Identify exact error message/behavior
- Note environment conditions (versions, config, state)

### 2. Isolate
- Narrow to smallest reproducible case
- Identify which component fails
- Trace information flow to failure point
- Use targeted reads/greps, not broad exploration

### 3. Hypothesize
- List possible causes (most likely first)
- For each: what evidence would confirm/reject?
- Consider: recent changes, dependencies, environment

### 4. Test Hypotheses
- Gather evidence systematically
- Update hypothesis ranking as evidence arrives
- Stop when root cause is confirmed

### 5. Produce Diagnosis

```markdown
## Symptom
[What's failing — exact error or behavior]

## Root Cause
[Why it's failing — the actual problem]

## Evidence
- `file:line` — observation
- Command output — what it showed

## Fix Options
1. Option A: [approach] — tradeoffs
2. Option B: [approach] — tradeoffs

## Recommended
[Which option and why]
```

## Context Budget

- Target: complete diagnosis under 30% context
- Use subagents for exploration if needed
- Keep evidence concise — excerpts, not full files

### 6. Checkpoint

Update STATE.md incrementally:
- Set `phase: debug`
- Add root cause and fix decision to `## Decisions`
- Add investigated files to `## Key Files`
- Update `## Next Steps` with recommended fix

Run `/checkpoint` if context is heavy or taking a break.

## Constraints

- **Do not fix yet** — diagnosis first
- If fix is obvious (<5 lines, isolated), may proceed with approval
- Otherwise, get approval before implementing
- Don't guess — verify with evidence

## Exit Criteria

Root cause identified with evidence. Fix approach clear and approved.
