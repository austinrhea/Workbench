# Workbench

Personal development and research environment with structured Claude Code workflow.

## Quick Start

```bash
claude
> /workflow <describe your task>
```

The `/workflow` command assesses your task and routes to the appropriate phase:
- **Bug/failure** → `/debug`
- **New feature** → `/research` → `/plan` → `/implement`
- **Quick fix** → Direct implementation

## Commands

<!-- COMMANDS:START -->
| Command | Description |
|---------|-------------|
| `/checkpoint` | Save current state for session breaks or complex work |
| `/cost` | Check context utilization and token costs |
| `/debug` | Diagnose systematically before proposing fixes |
| `/docs` | Update README.md commands table from source |
| `/implement` | Execute the approved plan incrementally |
| `/plan` | Create a specific implementation plan for review |
| `/research` | Before proposing changes, understand the problem space |
| `/summarize` | Prepare context for compaction using FILTER→CHUNK→STITCH→VERIFY pattern |
| `/test` | Run tests with context-efficient output |
| `/workflow` | Entry point for task execution |
<!-- COMMANDS:END -->

## Documentation

- `CLAUDE.md` — Instructions for Claude (operating model, working modes)
- `agent_docs/` — Extended guidance:
  - `workflow.md` — Research-Plan-Implement details
  - `context.md` — Subagents, compaction, state management
  - `principles.md` — 12-factor agent principles
  - `integrations.md` — MCP, hooks, commands, persistence
  - `testing.md` — Output filtering, run_silent patterns

## State Management

Session state is saved to `STATE.md` via `/checkpoint`. This happens automatically after each workflow phase, enabling resume from any point.
