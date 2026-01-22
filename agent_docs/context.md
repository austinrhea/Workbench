# Context Management

Techniques for maintaining context quality. Context is the only lever—treat it deliberately.

## Core Principle: Own Your Context

Context engineering—structuring all inputs (prompts, history, external data)—directly determines output quality. Even with large context windows, small focused prompts outperform large diluted ones.

**Optimization priority**:
1. Correctness (no hallucinations)
2. Completeness (all necessary details)
3. Size (minimal noise)
4. Trajectory (steering toward solution)

## The Numbers

| Metric | Value | Notes |
|--------|-------|-------|
| Claude context window | ~168-170k tokens | Advertised vs usable |
| Smart zone ceiling | ~75k tokens | 40-45% utilization |
| Target utilization | 40-60% | Quality degrades above |
| Instruction capacity | ~150-200 | Frontier LLMs |
| Claude Code system prompt | ~50 instructions | Already consumed |
| Your CLAUDE.md budget | ~100-150 instructions | What remains |
| Recommended CLAUDE.md | <60 lines | HumanLayer's actual |
| Maximum CLAUDE.md | <300 lines | Absolute ceiling |
| MCP server tool tax | ~10k tokens each | Hidden context cost |

## Quality Degradation Curve

Context utilization directly affects output quality:

| Utilization | Quality | Behavior |
|-------------|---------|----------|
| 0-30% | Peak | Full instruction following, accurate recall |
| 30-50% | Good | Reliable performance, occasional minor misses |
| 50-70% | Degrading | Starts forgetting constraints, needs reminders |
| 70%+ | Poor | Hallucinations, lost focus, "dumb zone" behaviors |

## The "Dumb Zone"

Symptoms when exceeding ~75k tokens:
- Hallucinating libraries that don't exist
- Forgetting established constraints
- Missing obvious bugs
- "Context-anxious" behaviors (aggressive truncation, piping to /dev/null)

## Subagents for Isolation

Use subagents (Task tool) for discovery work:
- Searching/grepping codebases
- Reading multiple files to understand structure
- Exploring unfamiliar areas
- Summarizing large documents

**Why**: Raw tool output pollutes main context. Subagents return distilled findings, keeping parent context focused.

**Agent tool limits** (from Ralph patterns):
- Up to 500 parallel subagents for searches/reads
- Only 1 subagent for builds/tests (backpressure)
- Opus subagents for complex reasoning

## State Lives in Context

Unify execution state and conversation state. The conversation history is the single source of truth—don't maintain parallel state machines.

Benefits:
- Trivial serialization (save/resume)
- Complete debugging visibility
- Easy to resume from any point
- Can fork thread at any point

To pause: save conversation state. To resume: deserialize and continue.

### STATE.md Pattern

For cross-session persistence, maintain a living memory file:

```markdown
# STATE.md (<100 lines)

## Current Focus
What we're working on right now

## Recent Decisions
- Decision 1: rationale
- Decision 2: rationale

## Blockers
- [ ] Unresolved issue

## Key Files
- `path/to/file.ts:42` — why it matters
```

Rules:
- Keep under 100 lines (forces prioritization)
- Update at session end or major milestones
- Read at session start to restore context
- Delete resolved items aggressively

## Compaction

When context grows heavy, use `/compact`. This preserves:
- Current goals and approach
- Completed steps
- Active blockers
- Key decisions made

Better than `/clear` when you need continuity.

### Compaction Artifact Format

When writing summaries, use this structure with YAML frontmatter:

```markdown
---
task: "Brief task description"
status: in_progress | blocked | complete
context_percent: 45
last_updated: 2024-03-15
---

## Task(s)
- [x] Completed item
- [ ] In progress item

## Critical References
- `file:line` format for key locations

## Learnings
Important patterns, bugs, or insights

## Checkpoint
Last known good state (can rollback here)

## Next Steps
Guidance for continuing
```

### Checkpoint/Rollback Pattern

Create explicit save points during complex work:

```markdown
## Checkpoint: Pre-refactor (2024-03-15 14:30)
- All tests passing
- Feature X working
- Files: src/auth.ts, src/api.ts

## Changes Since Checkpoint
- Modified auth flow
- Added new endpoint

## Rollback Command
git checkout abc123 -- src/auth.ts src/api.ts
```

When to checkpoint:
- Before risky changes
- After each working phase
- Before context gets heavy (>50%)

## When to Clear

Use `/clear` between unrelated tasks. Signs you need it:
- Agent references outdated information
- Confusion about current goals
- Quality drift in outputs

## Error Compaction

Errors go back into context for self-correction:
1. Format error concisely (strip irrelevant stack frames)
2. Agent attempts correction
3. After 2-3 consecutive failures, escalate

Don't: unlimited retries, swallow errors, keep all failed attempts.

## The Instruction Budget

Claude Code injects this system reminder into CLAUDE.md content:
> "IMPORTANT: this context may or may not be relevant to your tasks. You should not respond to this context unless it is highly applicable."

This means:
- Non-universal instructions get deprioritized
- Every line must earn its place
- Task-specific guidance belongs in separate files

**Instruction decay patterns**:
- Smaller models: Exponential decay as instructions increase
- Frontier models: Linear decay (more graceful)
- At 500 instructions: Even best models hit ~68% accuracy

## Context Format

Use XML-style tags for structured context:

```xml
<tool_result>
    type: list_files
    data:
      - src/main.ts
      - src/utils.ts
</tool_result>
```

This helps the model parse and prioritize information.
