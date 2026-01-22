---
name: workflow
description: Entry point for task execution. Routes to research, plan, implement, or debug based on task type and existing state. Orchestrates phase transitions after approval.
disable-model-invocation: true
allowed-tools: Read, Write, Glob, Skill, AskUserQuestion
---

# Workflow

Entry point and orchestrator. Routes to appropriate phase, then manages transitions after each approval gate.

## Task
$ARGUMENTS

## Instructions

Output: `## Workflow`

### 1. Check for Existing State

Read STATE.md if it exists. Parse YAML frontmatter:

```yaml
---
task: "..."
status: in_progress | blocked | complete | parked
phase: research | plan | implement | debug | idle | quick
path: research,plan,implement  # orchestration path
context_percent: N
last_updated: YYYY-MM-DD
---
```

**If `status: idle` or `status: complete`**: proceed to assessment

**If `status: in_progress` with `path` set**: offer continuation

```markdown
## Existing State Found

**Task**: [task]
**Current phase**: [phase]
**Path**: [path]
**Progress**: [which phases complete]

Options:
1. **Continue** — resume at current phase
2. **Park and switch** — set status to parked, begin new task
3. **Discard** — clear state, begin new task
```

**If `status: in_progress` without `path`**: legacy state, offer resume or restart

**If no STATE.md**: proceed to assessment

### 2. Assess Task Type

| Signals | Task Type | Path |
|---------|-----------|------|
| "not working", "error", "bug", "broken" | Bug | `debug` (then implement if needed) |
| "add", "implement", "create", "build" + unclear scope | Feature | `research,plan,implement` |
| Clear, small, single-file change | Quick fix | (no path, direct implementation) |
| "refactor", "change", "update" + multi-file | Modification | `research,plan,implement` |

### 3. Present Recommendation

```markdown
## Task Assessment

**Task**: [one-line summary]
**Type**: [bug | feature | quick fix | modification]
**Scope**: [small | medium | large]

**Path**: [phase] → [phase] → [phase]

**Rationale**: [Why this path fits]

Proceed?
```

### 4. Initialize State

**Skip for quick fixes** — complete in one turn.

**For all other task types**, write STATE.md:

```yaml
---
task: "[one-line]"
status: in_progress
phase: [first phase in path]
path: [comma-separated phases]
context_percent: 0
last_updated: [today]
---

## Decisions
[None yet]

## Blockers
[None]

## Key Files
[To be discovered]

## Next Steps
Starting [first phase]
```

### 5. Orchestration Loop

After user approves, execute this loop:

```
while path has remaining phases:
    1. Invoke current phase skill (using Skill tool)
    2. Phase skill runs, ends with gate question
    3. User approves (or redirects)
    4. Update STATE.md: advance phase, update context_percent
    5. If more phases remain, continue loop
    6. If user redirects, update path and continue
```

**Invoking phase skills**:
- `/research` — exploration, returns findings
- `/plan` — creates implementation plan
- `/implement` — executes plan with checkpoints
- `/debug` — diagnoses issue, may lead to implement

**After each phase completes**:
- Update `phase:` to next in path
- Update `## Next Steps`
- Present transition: "Research complete. Ready to plan?"

**On user redirect**: Update `path:` to new direction, continue from there.

### 6. Completion

When all phases complete:
- Set `status: complete`, `phase: idle`
- Clear `path:`
- Output: "Task complete. Please verify."

## Constraints

- Don't skip assessment — even obvious tasks benefit from explicit routing
- Wait for approval at each phase boundary (gates are mandatory)
- Keep STATE.md as source of truth

### Context Hygiene (Mandatory)

**Pre-flight check**: Before invoking any phase skill, run:

```bash
.claude/skills/shared/scripts/read-metrics.sh used_percentage
```

| Utilization | Action |
|-------------|--------|
| < 50% | Proceed normally |
| 50-60% | Warn user, proceed with caution |
| 60%+ | **GATE**: Run `/checkpoint`, then `/compact` before proceeding |

**Hard gate at 60%**: Do not invoke the next phase skill until context is below 60%. This is not a suggestion — degraded context means degraded work quality.

**Update STATE.md `context_percent`**: After each phase completion, record current utilization from metrics.

## Exit Criteria

Task completed through all phases, or user explicitly exits workflow.
