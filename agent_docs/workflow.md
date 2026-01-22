# Research → Plan → Implement Workflow

Structured workflow for non-trivial tasks. Prevents cascading errors from incomplete understanding.

## Why This Matters

Error impact scales by phase:
- **Research errors** cascade 1000x (one flawed assumption → thousands of bad code lines)
- **Planning errors** cascade 100x (one bad step → hundreds of bad lines)
- **Code errors** are localized

Human review has highest leverage early, not at code review.

## Phase 1: Research

**Goal**: Understand the codebase/problem before proposing changes.

Activities:
- Map relevant structure and architecture
- Identify files, dependencies, information flow
- Understand existing patterns and conventions
- Surface assumptions for validation

**Exit criteria**: Can explain the problem space and proposed approach without hand-waving.

## Phase 2: Plan

**Goal**: Define specific implementation steps before writing code.

Activities:
- List specific file edits required
- Define testing/verification for each step
- Identify risks or decision points
- Get human approval before proceeding

**Exit criteria**: Plan is specific enough that implementation is mechanical.

## Phase 3: Implement

**Goal**: Execute the plan incrementally with verification.

Activities:
- Execute one step at a time
- Verify each step before proceeding
- Compact status back into plan after verification
- Flag deviations from plan for re-evaluation

**Exit criteria**: All plan steps complete and verified.

## Scope Control

**Keep tasks focused**: 3-10 steps per agent workflow, not 50+.

As context grows, agents lose focus. Large monolithic tasks fail reliably. Instead:
- Break large work into focused sub-tasks
- Chain small agents with deterministic orchestration
- Prefer regeneration over rebasing when conflicts arise

**Bounded autonomy**: Run in time-limited cycles with checkpoint reviews rather than indefinitely. Know your desired end state and testing criteria before starting.

## Error Handling

When something fails:
1. Error goes back into context (formatted concisely)
2. Agent attempts self-correction
3. After 2-3 consecutive failures, escalate to human

Don't: unlimited retry loops, swallow errors, keep all failed attempts in context.

## Deviation Rules

When implementation diverges from plan:

| Rule | Condition | Action |
|------|-----------|--------|
| Rule 1 | Minor syntax/typo fixes | Auto-fix, continue |
| Rule 2 | Missing import/dependency | Add it, continue |
| Rule 3 | Small refactor needed | Do it if <5 lines, continue |
| Rule 4 | Architectural change needed | **STOP**, explain, get approval |

**The key distinction**: Rules 1-3 are mechanical adjustments. Rule 4 requires human judgment because it changes the plan's assumptions.

## Goal-Backward Verification

Before marking any task complete, verify in three levels:

1. **Exists**: The thing was created/modified
2. **Substantive**: It does what it's supposed to do
3. **Wired**: It's connected to the rest of the system

Example:
```
Task: Add logout button

1. Exists: Button component created? ✓
2. Substantive: Clicking it clears auth state? ✓
3. Wired: Navigation shows it? Routing handles post-logout? ✓
```

Don't mark complete until all three levels pass.

## Quick Fix Mode

Simple tasks (single-file changes, obvious fixes) skip the full workflow:

| Task Type | What Happens |
|-----------|--------------|
| Typo fix, add log, rename variable | Direct implementation, no STATE.md |
| Single-file bug fix | Debug → fix, minimal gates |
| Clear, scoped change | Skip research phase |

**Quick fix criteria**: Task is obvious, low-risk, and doesn't require understanding new code.

## Automation Features

The workflow includes several automatic behaviors:

| Feature | Trigger | Benefit |
|---------|---------|---------|
| **Auto-checkpoint** | After each gate approval | No manual `/checkpoint` needed |
| **Smart exit defaults** | Task completion | Suggests clear/compact based on git state |
| **Post-compact recovery** | Fresh context + active STATE.md | Auto-injects state after `/compact` |
| **Session resume** | Stale STATE.md (>1h) | Prompts continuation on return |
| **Context warnings** | 60%+ utilization | Suggests `/summarize` then `/compact` |

**Pre-compact checklist**: Run `bash scripts/pre-compact.sh` before `/compact` to verify STATE.md is current.

## Phase-Boundary Approval Gates

Explicit approval points prevent runaway execution:

| Boundary | Gate |
|----------|------|
| Research → Plan | "Here's what I found. Ready to plan?" |
| Plan → Implement | "Here's the plan. Approve to proceed?" |
| Implement → Done | "Implementation complete. Please verify." |

**Why gates matter**:
- Catches misunderstandings before they cascade
- Gives human leverage at high-impact moments
- Prevents "helpful" over-execution

**Gate format**:
```markdown
## Ready for [Next Phase]

### Summary
What was accomplished

### Key Decisions
Choices made and why

### Risks/Concerns
What might go wrong

### Approval Request
Specific ask: "Approve plan?" / "Continue to phase 2?"
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Chatbot iteration | Back-and-forth wastes context | Use R→P→I structure |
| Vibe coding | Implementation without understanding | Research first |
| Passive engagement | Expecting full automation | Active participation |
| Monolithic agents | 50+ steps = lost focus | 3-10 steps per agent |
| Running forever | No checkpoints | Bounded cycles |
| Overbaking | Adding unrequested features | Stick to spec |
| Sycophancy loop | Agreeing vs being correct | Prioritize accuracy |
| Spec drift | Changing requirements mid-task | Checkpoint, re-plan |
| Context hoarding | Keeping everything "just in case" | Aggressive pruning |
