# Planning Phase

Create a specific implementation plan for review.

## Task
$ARGUMENTS

## Instructions

Output: `## Planning Phase`

### 1. Gather Context
- Read files identified in research
- Verify understanding is current
- Spawn parallel research tasks if gaps exist

### 2. Define Success Criteria

**Automated verification:**
- Build commands that must pass
- Test commands that must pass
- Type check commands

**Manual verification:**
- UI/UX checks requiring human review
- Performance validation
- Edge case review

### 3. Scope Boundaries

**What we're doing:**
- Specific deliverables

**What we're NOT doing:**
- Explicit exclusions (prevents scope creep)

### 4. Create Step-by-Step Plan

Format as checklist with verification:

```markdown
## Phase 1: [Name]

- [ ] Step 1: Description
      File: `path/to/file.ts`
      Verification: how to verify this step

- [ ] Step 2: Description
      File: `path/to/other.ts`
      Verification: run `npm test`

## Phase 2: [Name]

- [ ] Step 3: ...
```

### 5. Identify Decision Points

- Where are there meaningful alternatives?
- What tradeoffs exist?
- What needs human input before proceeding?

### 6. Checkpoint

Update STATE.md incrementally:
- Set `phase: plan`
- Add plan decisions to `## Decisions`
- Update `## Next Steps` with plan summary and approval status

Run `/checkpoint` if context is heavy or taking a break.

## Constraints

- **Do not implement yet**
- Plan should be specific enough that implementation is mechanical
- Each phase should be independently verifiable
- Keep total steps reasonable (3-10 per phase, 20 max overall)

## Exit Criteria

Plan is approved by human before proceeding to implementation.
