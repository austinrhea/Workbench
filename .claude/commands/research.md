# Research Phase

Before proposing changes, understand the problem space.

## Task
$ARGUMENTS

## Instructions

Output: `## Research Phase`

**State**: At phase start, update STATE.md:
- Set `phase: research`
- Set `status: in_progress`

### 1. Study the Relevant Context
- Read all user-mentioned files completely (no limit/offset)
- Study existing patterns in the codebase
- Don't assume functionality is missing—confirm with search first

### 2. Decompose the Problem
Break into composable research areas. Use subagents for parallel exploration:
- Up to 500 parallel subagents for searches/reads
- Keep parent context focused on synthesis

### 3. Map the Territory
- Identify files, modules, and dependencies involved
- Understand information flow
- Note existing conventions and patterns
- Surface assumptions for validation

### 4. Identify Risks
- What could go wrong?
- What's unclear or underspecified?
- Where might the approach need adjustment?

### 5. Produce Research Artifact

```yaml
## Summary
[Concise overview of findings]

## Relevant Files
- `file:line` — description

## Patterns Discovered
- Pattern name: where it's used

## Assumptions
- [ ] Assumption to validate

## Questions
- Open questions for clarification

## Recommended Approach
[Brief description of proposed direction]
```

## Constraints

- **Do not propose solutions or write code**
- Focus on understanding, not implementing
- Be a documentarian, not a critic
- Maximum 125 characters for quoted source material
- Verify claims before stating them

### 6. Incremental State Updates

Update STATE.md **during research** when:
- Significant pattern or constraint discovered → add to `## Decisions`
- Key file identified → add to `## Key Files`
- Blocker found → add to `## Blockers`

**At research completion**:
- Update `## Next Steps` with research conclusions
- Run `/checkpoint` if context is heavy or taking a break

## Exit Criteria

Can explain the problem space and proposed approach without hand-waving.

**Gate**: "Here's what I found. Ready to plan?"
