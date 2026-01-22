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
| `/checkpoint` | Save current state for session breaks. Includes context health check and recommendations. |
| `/cost` | Quick context health check. See /checkpoint for full state management. |
| `/debug` | Diagnose bugs systematically before proposing fixes. |
| `/docs` | Update README.md commands table from skills. |
| `/implement` | Execute approved plan incrementally with verification at each step. |
| `/plan` | Create specific implementation steps for review. |
| `/research` | Understand problem space before proposing changes. |
| `/summarize` | Prepare context for compaction. Run before /compact to ensure critical state survives. |
| `/test` | Run tests with context-efficient output. |
| `/workflow` | Entry point for task execution. Routes and orchestrates phase transitions after approval. |
<!-- COMMANDS:END -->

## Examples

- [Workflow Pipeline Example](examples/workflow-pipeline-example.md) — Full walkthrough of research → plan → implement with ServiceNow → Snowflake ETL scenario

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
