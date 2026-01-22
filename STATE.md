---
task: "Create workflow example documentation — ServiceNow → Snowflake pipeline"
objective: "Produce a comprehensive example doc demonstrating the workflow system with realistic ETL scenario"
status: complete
phase: idle
path:
context_percent: 70
last_updated: 2026-01-22
---

## Original Prompt
> I need you to create a doc for an example of using this pipeline to ingested from a ServiceNow instance into snowflake via a Matillion job and provides the user with a summary of the table. you dont need to write the code just more or less a plan as an example of the workflow somewhere. You can make the prompt a little better for the sake of the example include code examples in the doc and examples of the workflow and how it processes each step. start from scratch

## Scope
**Doing**: Create example documentation with workflow walkthrough, code samples, step-by-step process
**Not doing**: Building actual pipeline, connecting to real systems

## Progress
- [x] Research: What makes a good workflow example doc
- [x] Research: ServiceNow REST API patterns
- [x] Research: Matillion ETL components
- [x] Research: Snowflake VARIANT/FLATTEN/MERGE
- [x] Plan: Document structure and content outline (6 phases, 10 steps)
- [x] Implement: Write the markdown file

## Decisions
- Document goes in `examples/workflow-pipeline-example.md`
- Show full workflow lifecycle with STATE.md snapshots at each phase
- Include working SQL/API code examples
- Improved prompt for the example scenario

## Learnings
- Workflow orchestration works via Skill tool after removing `disable-model-invocation`
- STATE.md snapshots at each phase show state evolution clearly
- Real code examples (SQL, API) make the example more useful

## Blockers
[None]

## Key Files
- `examples/workflow-pipeline-example.md` — the deliverable (658 lines)
- `agent_docs/workflow.md` — R→P→I concepts source
- `.claude/skills/workflow/SKILL.md` — orchestration reference

## Checkpoint
Task complete. Document verified.

## Next Steps
Consider adding link to example from README.md
