---
task: "Create debug workflow example documentation — Python debugging scenario"
objective: "Produce example doc demonstrating /debug path with realistic Python bug scenario"
status: in_progress
phase: implement
path: research,plan,implement
context_percent: 15
last_updated: 2026-01-22
---

## Original Prompt
> based on the previous STATE.md now do the same for an example of debuging some python code in a repository where this is installed

## Scope
**Doing**: Create example documentation showing debug workflow with Python scenario
**Not doing**: Actual debugging, real repository changes

## Progress
- [x] Research: Debug skill structure, realistic Python bug scenarios
- [x] Plan: Document structure and content outline (5 phases, 12 steps)
- [x] Implement: Write the markdown file

## Decisions
- Use FastAPI + requests external API call as bug scenario
- Show intermittent timeout bug with missing error handling
- Demonstrates full 5-step debug process
- Structure matches pipeline example exactly (parallel sections)
- Path: debug → implement (not research → plan → implement)

## Learnings
[None yet]

## Blockers
[None]

## Key Files
- `.claude/skills/debug/SKILL.md` — debug workflow reference
- `.claude/skills/debug/templates/diagnosis.md` — output template
- `examples/workflow-pipeline-example.md` — structure to match

## Checkpoint
Fresh start.

## Next Steps
Starting research phase
