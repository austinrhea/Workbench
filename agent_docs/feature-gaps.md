# Feature Gaps

Limitations in Claude Code that affect workflow automation.

## Auto-Clear on Task Completion

**Status**: Gap identified 2026-01-22

**Problem**: After task completion with clean git and up-to-date STATE.md, the user must manually type `/clear`. This friction is unnecessary when state recovery is reliable.

**Current behavior**:
```
Task complete + STATE.md current + git clean
    ↓
Workflow suggests: "/clear recommended"
    ↓
User must type: /clear
    ↓
(If task was incomplete, session-init.sh would restore STATE.md)
```

**Desired behavior**:
```
Task complete + STATE.md current + git clean
    ↓
Auto-clear (programmatic)
    ↓
Fresh context, ready for next task
```

**Why it's safe**:
- STATE.md captures all important state (task, phase, decisions, blockers, key files)
- `session-init.sh` auto-injects STATE.md on fresh context if status is active
- Git state is clean (no lost work)
- User explicitly completed the task (not interrupted)

**Blocked by**: No programmatic way to invoke `/clear`. It's a built-in CLI command.

**Possible solutions**:
1. Expose `/clear` as a tool Claude can invoke
2. Add `PostTaskComplete` hook that can trigger clear
3. Add `auto_clear_on_complete: true` setting
4. Make `/clear` a skill that wraps the built-in (if possible)

**Workaround**: User types `/clear` manually after task completion prompt.

**Impact**: Minor friction (one command), but breaks the "fully automated workflow" promise.

---

## Other Gaps

(Add future gaps here)
