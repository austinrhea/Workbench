# Phase Handoff Template

Standard format for passing context between workflow phases.

## Format

```markdown
## Handoff: [from_phase] → [to_phase]

### Completed
- [x] What was accomplished
- [x] Key deliverables produced

### Context
**Key Files**:
- `path/to/file.ts:line` — why it matters

**Patterns Discovered**:
- Pattern: where/how it's used

**Constraints**:
- Must maintain X
- Cannot change Y

**Decisions Made**:
- Decision: rationale

### Remaining
- [ ] Next phase's primary goal
- [ ] Specific items to address
```

## Examples

### Research → Plan

```markdown
## Handoff: research → plan

### Completed
- [x] Mapped authentication flow
- [x] Identified existing JWT patterns

### Context
**Key Files**:
- `src/auth/middleware.ts:42` — main auth handler
- `src/api/routes.ts:15` — protected route setup

**Patterns Discovered**:
- JWT stored in httpOnly cookies
- Refresh tokens in separate endpoint

**Constraints**:
- Must maintain v1 API compatibility
- Cannot break existing mobile clients

**Decisions Made**:
- Use existing JWT library (already vetted)

### Remaining
- [ ] Create implementation plan
- [ ] Define migration strategy for existing tokens
```

### Plan → Implement

```markdown
## Handoff: plan → implement

### Completed
- [x] 5-step implementation plan created
- [x] Success criteria defined

### Context
**Plan Summary**:
1. Add token refresh endpoint
2. Update middleware to check expiry
3. Add client-side refresh logic
4. Migration script for existing tokens
5. Integration tests

**Verification Commands**:
- `npm test -- --grep "auth"`
- `npm run build`

**Risks Identified**:
- Token migration may need rollback plan

### Remaining
- [ ] Execute plan steps 1-5
- [ ] Verify each step before proceeding
```

## Usage

Each phase skill should:
1. **Consume** previous phase's handoff (if exists)
2. **Produce** handoff for next phase
3. **Append** handoff to STATE.md under phase-specific section
