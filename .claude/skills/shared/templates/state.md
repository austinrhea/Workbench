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

## Progress
${PROGRESS:-[Track completed/pending steps with checkboxes]}

## Decisions
${DECISIONS:-[None yet]}

## Learnings
${LEARNINGS:-[Patterns, insights, gotchas discovered]}

## Blockers
${BLOCKERS:-[None]}

## Key Files
${KEY_FILES:-[To be discovered]}

## Checkpoint
${CHECKPOINT:-[Last known good state]}

## Next Steps
${NEXT_STEPS:-${PHASE} in progress}
