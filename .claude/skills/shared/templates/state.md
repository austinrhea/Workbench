---
task: "${TASK}"
objective: "${OBJECTIVE:-}"
status: ${STATUS:-in_progress}
phase: ${PHASE}
path: ${PATH:-}
context_percent: ${CONTEXT_PERCENT:-0}
last_updated: ${DATE}
---

## Original Prompt
> ${ORIGINAL_PROMPT:-[Capture verbatim user request here]}

## Scope
**Doing**: ${DOING:-[Explicit inclusions]}
**Not doing**: ${NOT_DOING:-[Explicit exclusions]}

## Research Findings
${RESEARCH_FINDINGS:-[Populated by /research phase]}
<!-- Handoff format: Completed, Context (Key Files, Patterns, Constraints), Remaining -->

## Plan
${PLAN:-[Populated by /plan phase]}
<!-- Handoff format: Completed, Context (Plan Summary, Verification Commands, Risks), Remaining -->

## Progress
${PROGRESS:-[Track completed/pending steps with checkboxes]}

## Decisions
${DECISIONS:-[None yet]}

## Blockers
${BLOCKERS:-[None]}

## Key Files
${KEY_FILES:-[To be discovered]}

## Git State
${GIT_STATE:-[Run git status to populate]}

## Checkpoint
${CHECKPOINT:-[Last known good state]}

## Next Steps
${NEXT_STEPS:-${PHASE} in progress}
