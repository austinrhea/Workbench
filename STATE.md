---
task: "Design token-saving strategies using hooks and skills"
status: complete
phase: idle
context_percent: 32
last_updated: 2026-01-22
---

## Decisions
- Three token-saving layers: hooks (auto-enforcement), skills (user-invoked), subagents (discovery isolation)
- Already have: run_silent.sh, retry-limits.sh, metrics persistence
- User wants: auto-summarize at thresholds, auto-format all edits, output truncation

## Blockers
[None]

## Key Files
- `agent_docs/integrations.md:166-230` — hook configuration patterns
- `agent_docs/context.md:92-121` — subagent model selection for cost
- `agent_docs/testing.md:14-51` — run_silent pattern
- `.claude/settings.json:36-60` — current hook config

## Next Steps
Task complete. Token-saving hooks and skills implemented.
