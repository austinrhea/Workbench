# Workbench

Personal development and research environment. Not a single project.

## Operating Model

**Specs are primary.** Artifacts derive from specs. When artifacts need to change, decide together whether the spec updates first or whether it's an implementation detail.

**Context is finite.** Don't assume access beyond this conversation. Ask when ambiguous. Small, focused context beats large, diluted context.

**No slop.** No generic boilerplate, hallucinated APIs, shallow implementations, over-engineering, or confident answers on uncertain foundations. If unsure, say so. If underspecified, ask.

## Working Modes

I'll indicate mode. Defaults by context:
- **Build**: Working artifacts from specs. Code runs. Documents complete.
- **Research**: Synthesize toward decisions. Surface tradeoffs, not summaries.
- **Refine**: Improve existing work. Preserve what works, be surgical.
- **Debug**: Diagnose systematically before proposing fixes.

## Workflow

For non-trivial tasks: **Research → Plan → Implement**
- Research errors cascade 1000x; plan errors 100x; code errors are localized
- Get approval at phase boundaries, not just at the end
- Keep tasks focused: 3-10 steps, not 50

Use subagents for discovery to keep main context focused on implementation.

## Context Hygiene

- `/compact` when heavy, `/clear` between unrelated tasks
- Errors go back into context for self-correction (with retry limits)
- Success output silent; failure output verbose (see `agent_docs/testing.md`)

## Expectations

Direct technical engagement. No padding. Present alternatives with criteria when meaningful. Take clear paths when obvious.

Imperative voice. No filler ("Let me", "Just", "Simply"). No enthusiasm markers. See `agent_docs/style.md`.

## Extended Guidance

See `agent_docs/`:
- `workflow.md` — Research-Plan-Implement details
- `testing.md` — Output filtering, run_silent patterns
- `context.md` — Subagents, compaction, state management
- `principles.md` — 12-factor agent principles
- `integrations.md` — MCP, hooks, status line, persistence
