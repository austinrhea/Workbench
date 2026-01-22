# Implementation Phase

Execute the approved plan incrementally.

## Plan Reference
$ARGUMENTS

## Instructions

### 1. Execute One Step at a Time
- Complete step fully before moving to next
- Verify each step per the plan's criteria
- Mark steps complete as you go

### 2. Maintain Context Hygiene
- Keep output concise
- Use `run_silent` patterns for test/build
- Summarize verbose command output
- Flag if context is getting heavy (approaching 60%+)

### 3. Handle Deviations

If something doesn't work as planned:
1. Stop immediately
2. Explain what happened
3. Propose adjustment
4. Get approval before continuing

If errors occur:
1. Feed error back into context (formatted concisely)
2. Attempt self-correction
3. After 2-3 consecutive failures, escalate to human

### 4. Report Progress

After each phase:
```markdown
## Phase N Complete

### Completed
- [x] Step description

### Verified
- `npm test` ✓
- `npm run build` ✓

### Notes
Any learnings or adjustments made

### Next
What's coming in the next phase
```

### 5. Pause for Human Verification

- Pause after each phase for human review
- Never check off manual testing steps until user confirms
- Don't rush—maintain quality over speed

## Constraints

- Follow the plan's intent while adapting to what you find
- Plans are guides, not rigid specifications
- Maintain "forward momentum" while keeping end goal in mind
- If stuck for more than 2-3 attempts, ask for help

## Exit Criteria

All plan steps complete and verified. Summary of what was done provided.
