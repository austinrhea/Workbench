# Integrations

Extending Claude Code with MCP servers, hooks, status line, and persistence.

## Status Line

Real-time context utilization monitoring. Configured in `.claude/settings.json`.

### Configuration

```json
{
  "statusLine": {
    "type": "command",
    "command": "./scripts/statusline.sh"
  }
}
```

### Available Metrics

The status line script receives JSON via stdin:

```json
{
  "model": { "display_name": "Opus" },
  "context_window": {
    "used_percentage": 42.5,
    "remaining_percentage": 57.5,
    "context_window_size": 200000,
    "total_input_tokens": 15234,
    "total_output_tokens": 4521
  },
  "cost": {
    "total_cost_usd": 0.0123,
    "total_lines_added": 156,
    "total_lines_removed": 23
  }
}
```

### Thresholds

From `context.md` and `principles.md`:

| Utilization | Color | Status | Action |
|-------------|-------|--------|--------|
| 0-50% | Green | Target range | Continue freely |
| 50-70% | Yellow | Degrading | Consider `/compact` |
| 70%+ | Red | Dumb zone | Session break |

### Customization

Edit `scripts/statusline.sh` to change display format. Must output single line to stdout. Supports ANSI colors.

### Metrics Persistence

The status line script persists metrics to `.claude/metrics.json` for commands to read:

```json
{
  "used_percentage": 42.5,
  "remaining_percentage": 57.5,
  "context_window_size": 200000,
  "total_input_tokens": 15234,
  "total_output_tokens": 4521,
  "total_cost_usd": 0.0123,
  "model": "Opus",
  "updated_at": "2026-01-22T..."
}
```

Commands (`/checkpoint`, `/summarize`, `/cost`) read this file for context health checks:

```bash
cat .claude/metrics.json | jq '.used_percentage'
```

This bridges the gap between status line display and programmatic access.

## MCP Servers

### When to Add

Add MCP servers when:
- You need context-aware operations (not just CLI commands)
- Natural language workflows reduce friction
- Multiple operations need session state

Don't add speculatively—each server costs ~5-15k tokens of context.

### Priority Integrations

| Integration | Server | Token Cost | Enable When |
|-------------|--------|------------|-------------|
| GitHub | @modelcontextprotocol/server-github | ~12k | PR-heavy workflows |
| Database | @anthropic/dbhub | ~8k | Schema exploration, queries |
| AWS | awslabs.mcp-aws-api-server | ~10k | Infrastructure operations |
| Memory | @anthropic/mcp-memory-service | ~4k | Cross-session recall needed |
| Custom | stdio Python/TS | varies | Internal tool access |

### Adding MCP Servers

Add to `.claude/settings.json`:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@scope/package-name"],
      "env": {
        "API_KEY": "${ENV_VAR_NAME}"
      }
    }
  }
}
```

**Patterns by transport:**

```json
// NPX (most common)
"github": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
}

// Python (uvx)
"aws": {
  "command": "uvx",
  "args": ["awslabs.mcp-aws-api-server@latest"],
  "env": { "AWS_PROFILE": "default" }
}

// Local script (stdio)
"internal": {
  "command": "python",
  "args": ["/path/to/server.py"]
}
```

### Building Custom MCP Servers

Minimal Python implementation:

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("my-server")

@mcp.tool()
async def my_tool(arg: str) -> str:
    """Tool description for Claude."""
    return "result"

if __name__ == "__main__":
    mcp.run(transport="stdio")
```

**Critical**: Use `logging` to stderr, never `print()` in stdio servers.

Install: `pip install "mcp[cli]"`

## Hooks

### Purpose

Deterministic policy enforcement. Hooks intercept tool execution—rules enforced by code, not LLM compliance.

### Lifecycle Events

| Event | When | Use Case |
|-------|------|----------|
| PreToolUse | Before tool executes | Block dangerous ops, validate inputs |
| PostToolUse | After tool completes | Format code, log failures |
| PermissionRequest | On permission prompt | Custom approval logic |
| UserPromptSubmit | Before processing input | Input validation |

### Configuration

Add to `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "command": "your-validation-script.sh",
            "description": "What this hook does"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": ["prettier --write \"$FILE\" 2>/dev/null || true"]
      }
    ]
  }
}
```

**Exit codes**: 0 = allow, 2 = block

**Available variables**: `$TOOL_INPUT`, `$FILE`, `$EXIT_CODE`

### Patterns from agent_docs

| Principle | Hook Implementation |
|-----------|---------------------|
| Block destructive ops | PreToolUse: reject `--force`, `--hard`, `rm -rf /` |
| Auto-format on edit | PostToolUse: prettier/gofmt after Edit |
| Retry limits | PostToolUse: track consecutive failures, block at 3 |

### Retry Limits Script

The `scripts/retry-limits.sh` script implements failure tracking:

```bash
# Tracks failures in /tmp/claude-failures-$$ (session-specific)
# Resets counter on success
# After 3 consecutive failures: exits with code 2 (blocks)
```

This aligns with `/implement.md`: "After 2-3 consecutive failures, escalate to human."

### Automation Scripts

| Script | Purpose | Exit Codes |
|--------|---------|------------|
| `lint-state.sh` | Validate STATE.md structure | 0=valid, 1=errors |
| `checkpoint-tag.sh` | Create git tag at checkpoint | 0=success, 1=failure |
| `estimate-context.sh` | Project context cost for phase | 0=OK, 1=caution, 2=warning |
| `compact-error.sh` | Summarize error for context | Always 0 |
| `analyze-metrics.sh` | Generate session metrics report | 0=success |
| `lint-docs.sh` | Check principles vs skills drift | 0=pass, 1=errors |

### Integration Tests

```bash
bash tests/workflow-test.sh
```

Validates: STATE.md linting, context estimation, error compaction, metrics analysis, skill structure.

## Persistence

### Tier 1: STATE.md (Default)

For single-session or daily workflows. See `/checkpoint` command.

```markdown
# STATE.md (<100 lines)

## Current Focus
[Active task]

## Decisions
- Decision: rationale

## Blockers
- [ ] Unresolved

## Key Files
- `path:line` — why
```

**Rules**: Update at session end, read at session start, delete resolved items.

### Tier 2: MCP Memory

For multi-day projects needing semantic recall:

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-memory-service"]
    }
  }
}
```

Operations: `remember`, `recall`, `forget`, `search`

### Tier 3: External Database

For teams, audit trails, complex workflows. Build custom MCP server with PostgreSQL/S3 backend.

### Selection Guide

| Duration | Complexity | Tier |
|----------|------------|------|
| Hours | Low | STATE.md |
| Days | Medium | Memory MCP |
| Weeks+ | High | External DB |

## Skills

Skills are the preferred way to add custom commands. They live in `.claude/skills/*/SKILL.md` and support richer structure than plain commands.

### Directory Structure

```
.claude/skills/
├── skill-name/
│   ├── SKILL.md           # Main skill definition
│   ├── scripts/           # Shell scripts for deterministic operations
│   │   └── helper.sh
│   ├── templates/         # Output format templates
│   │   └── output.md
│   └── references/        # Supporting documentation
│       └── guide.md
```

### SKILL.md Template

```markdown
# Skill Name

Brief description (shown in `/help`).

## Task
$ARGUMENTS

## Instructions

### 1. First Step
- Details

## Constraints

- What NOT to do

## Exit Criteria

How to know it's complete.
```

### Conventions

- Use `$ARGUMENTS` for user input
- Follow Research → Plan → Implement where applicable
- Include verification criteria
- Keep focused (one responsibility per skill)
- Reference templates/scripts with relative paths: `[template](templates/output.md)`

### Supporting Files

| Directory | Purpose | Example |
|-----------|---------|---------|
| `scripts/` | Deterministic operations | `parse-state.sh`, `run_silent.sh` |
| `templates/` | Output format templates | `findings.md`, `plan-format.md` |
| `references/` | Detailed guidance | `decomposition.md` |

Scripts should be executable and work standalone for testing.

### When to Use context: fork

Use forked context for exploration-heavy skills where intermediate results shouldn't pollute the main conversation:

- **Research**: Exploring unfamiliar code, many file reads
- **Debug**: Diagnosis that may involve dead ends

Don't fork for skills that need to modify shared state (plan, implement, checkpoint).

### Migration from Commands

Skills and commands coexist. To migrate:

1. Create `.claude/skills/name/SKILL.md` with command content
2. Add supporting files if needed
3. Keep `.claude/commands/name.md` as thin redirect (optional)

Both `/name` invocations work identically.

### Existing Skills

| Skill | Purpose |
|-------|---------|
| `/workflow` | Entry point, routes to appropriate phase |
| `/research` | Map problem space before changes |
| `/plan` | Create implementation checklist |
| `/implement` | Execute plan incrementally |
| `/debug` | Diagnose before fixing |
| `/checkpoint` | Save state with context health check |
| `/summarize` | Prepare context for compaction |
| `/cost` | Quick context utilization check |
| `/docs` | Update README from skills |
| `/test` | Run tests with minimal output |

