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

## Compaction

When context grows heavy, use `/compact`. This preserves:
- Current goals and approach
- Completed steps
- Active blockers
- Key decisions made

Better than `/clear` when you need continuity.

### Compaction Artifact Format

When writing summaries, use this structure:

```yaml
## Task(s)
- [x] Completed item
- [ ] In progress item

## Critical References
- `file:line` format for key locations

## Learnings
Important patterns, bugs, or insights

## Next Steps
Guidance for continuing
```

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
