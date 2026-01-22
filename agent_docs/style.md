# Style Guide

Communication and formatting conventions. Keeps output consistent and context-efficient.

## Communication

**Imperative voice**: Direct commands, not passive construction.

| Avoid | Prefer |
|-------|--------|
| "Let me check the file" | "Checking the file" or just do it |
| "I'll just add a test" | "Adding test" |
| "Simply update the config" | "Update the config" |
| "Great question!" | (omit) |

**No filler words**: Let me, Just, Simply, Basically, Actually

**No enthusiasm markers**: Great!, Awesome!, Perfect!, Absolutely!

**Brevity with substance**: One-liners should be technical and specific, not generic.

## Naming Conventions

| Context | Convention | Example |
|---------|------------|---------|
| Files, directories | kebab-case | `user-auth.ts`, `api-routes/` |
| XML tags, commands | kebab-case | `<task-list>`, `/run-tests` |
| Step names, variables | snake_case | `validate_input`, `user_id` |
| Bash variables | CAPS_UNDERSCORES | `$OUTPUT_DIR`, `$API_KEY` |
| Type attributes | colon-separated | `type="checkpoint:human-verify"` |

## Task Structure

Each task in a plan should have four elements:

```markdown
### Task: [name]

**Action**: What to do and why
**Files**: Specific paths (`src/auth.ts:42`)
**Verify**: Testable command (`npm test -- auth.test.ts`)
**Done**: Measurable acceptance criteria
```

### Task Types

| Type | Meaning | Gate |
|------|---------|------|
| `auto` | Claude executes autonomously | None |
| `checkpoint:human-verify` | User must verify result | "Please verify X works" |
| `checkpoint:decision` | User chooses direction | AskUserQuestion with options |

## Commit Conventions

Format: `{type}({scope}): {description}`

**Types**:
| Type | When |
|------|------|
| `feat` | New functionality |
| `fix` | Bug fix |
| `test` | Adding tests (TDD RED phase) |
| `refactor` | Code restructure, no behavior change |
| `docs` | Documentation only |
| `chore` | Maintenance, dependencies |

**Rules**:
- One commit per logical change
- Description focuses on "why" not "what"
- Include Co-Authored-By line

**Example**:
```
feat(auth): add session timeout handling

Sessions now expire after 30 minutes of inactivity.
Prevents stale credentials from persisting.

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Anti-Patterns

| Pattern | Problem |
|---------|---------|
| Temporal language in code comments | "Changed from X to Y" — just describe current state |
| Enterprise ceremony | Story points, sprint planning, RACI matrices |
| Generic descriptions | "Updated the code" — be specific |
| Hedging language | "Maybe we could try" — be direct |
