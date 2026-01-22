# Workflow

Entry point for task execution. Routes to appropriate phase based on task type and existing state.

## Task
$ARGUMENTS

## Instructions

Output: `## Workflow`

### 1. Check for Existing State

Read STATE.md if it exists. Parse YAML frontmatter for structured data:

```yaml
---
task: "..."
status: in_progress | blocked | complete | parked
phase: research | plan | implement | debug | idle | quick
context_percent: N
last_updated: YYYY-MM-DD
---
```

**If STATE.md found with `status: idle` or `status: complete`**: proceed to assessment

**If STATE.md found with `status: in_progress | blocked | parked`**, output reload summary:

```markdown
## Existing State Found

**Task**: [from frontmatter]
**Phase**: [from frontmatter]
**Status**: [from frontmatter]
**Last updated**: [from frontmatter]

**Decisions**: [from body]
**Blockers**: [from body]
**Next steps**: [from body]

Options:
1. **Resume** — continue from checkpoint
2. **Park and switch** — set status to parked, begin new task
3. **Discard and start fresh** — clear state, begin new task
```

**If no STATE.md**: proceed to assessment

### 2. Assess Task Type

| Signals | Task Type | Entry Point |
|---------|-----------|-------------|
| "not working", "error", "bug", "broken" | Bug/failure | `/debug` |
| "add", "implement", "create", "build" + unclear scope | New feature | `/research` |
| Clear, small, single-file change | Quick fix | Direct implementation |
| "refactor", "change", "update" + multi-file | Modification | `/research` |

### 3. Present Recommendation

```markdown
## Task Assessment

**Task**: [one-line summary]
**Type**: [bug | feature | quick fix | modification]
**Scope**: [small | medium | large]

**Recommended path**:
[entry point] → [subsequent phases]

**Rationale**:
[Why this path fits the task]

Ready to proceed?
```

### 4. Initialize State

**Skip this step for quick fixes** — they complete in one turn and don't need state tracking.

**For all other task types**, write STATE.md with initial task state:

```yaml
---
task: "[one-line from assessment]"
status: in_progress
phase: [entry point phase]
context_percent: 0
last_updated: [today's date]
---

## Decisions
[None yet]

## Blockers
[None yet]

## Key Files
[To be discovered]

## Next Steps
[Entry point phase] in progress
```

**If parking a previous task**: Before writing new state, update the existing task's status to `parked` and preserve its content in a `## Parked` section at the bottom of STATE.md.

This ensures state is captured even if user exits mid-task.

### 5. Execute or Hand Off

- If user confirms: invoke the recommended phase command
- If user chooses different path: follow their direction
- If task is trivial (quick fix): proceed directly with implementation

## Constraints

- Don't skip assessment — even obvious tasks benefit from explicit routing
- Don't auto-chain phases — wait for approval at each boundary
- Keep STATE.md as source of truth for resumption

## Exit Criteria

User is routed to appropriate phase command, or task is completed (quick fix).
