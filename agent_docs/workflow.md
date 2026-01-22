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

## When to Skip

Simple tasks (single-file changes, obvious fixes) don't need the full workflow. Use judgment—if you're about to make changes you don't fully understand, stop and research.

## Anti-Patterns

- **Chatbot iteration**: Back-and-forth without structure wastes context
- **Vibe coding**: Jumping to implementation without understanding
- **Passive engagement**: Expecting automation without active participation
- **Monolithic agents**: One agent for 50+ step workflows
- **Running forever**: Unbounded execution without checkpoints
