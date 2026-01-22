---
task: "Evaluate hooks/skills/subagents/commands management in Claude Code"
phase: research
status: complete
last_updated: 2026-01-22
---

# Research: Claude Code Extension Architecture

## Summary

Claude Code has four primary extension mechanisms: **hooks** (deterministic event handlers), **skills** (auto-discovered capabilities), **commands** (explicit user-invoked prompts), and **subagents** (isolated context workers). The current `agent_docs/` setup is strong on principles but underutilizes newer capabilities—particularly skills and advanced hooks.

## Key Findings from External Sources

### 1. Hooks: Full Lifecycle Coverage

**Anthropic docs** define 12 lifecycle events (vs. 4 in current `integrations.md`):

| Event | Purpose | Current Coverage |
|-------|---------|-----------------|
| SessionStart | Initialize environment | Missing |
| UserPromptSubmit | Validate/augment prompts | Implemented |
| PreToolUse | Block/modify tool calls | Implemented |
| PermissionRequest | Custom approval logic | Missing |
| PostToolUse | Format output, track failures | Implemented |
| PostToolUseFailure | Handle failed tools | Missing |
| SubagentStart/Stop | Subagent lifecycle | Missing |
| Stop | Validate completion | Missing |
| PreCompact | Pre-summarization hook | Missing |
| Notification | Route notifications | Missing |
| SessionEnd | Cleanup | Missing |

**Gap**: Current hooks cover ~30% of available lifecycle events.

### 2. Skills vs Commands: Migration Path

**Official stance**: Commands have been merged into skills. A file at `.claude/commands/foo.md` and `.claude/skills/foo/SKILL.md` both create `/foo` and work identically, but skills offer additional features:

| Feature | Commands | Skills |
|---------|----------|--------|
| User invocation (`/name`) | Yes | Yes |
| Auto-invocation by Claude | No | Yes (via description) |
| Supporting files (scripts/, refs/) | No | Yes |
| Forked context (`context: fork`) | No | Yes |
| Model override | No | Yes |
| Tool restrictions | No | Yes |

**Current state**: All workflows in `.claude/commands/` are commands, not skills.

### 3. Progressive Disclosure Pattern

**Anthropic engineering** and community sources emphasize three-level disclosure:

1. **Metadata** (name + description): Always loaded, used for matching
2. **Core content** (SKILL.md body): Loaded when Claude deems relevant
3. **Referenced files** (scripts/, references/): Loaded on demand

**Current state**: Commands load fully or not at all—no progressive disclosure.

### 4. Auto-Activation Patterns

**Community innovation** (diet103 showcase): `skill-rules.json` maps context patterns to skill suggestions. Combined with `UserPromptSubmit` hook, enables context-aware skill recommendations without manual invocation.

**Current state**: No auto-activation beyond manual `/workflow` entry point.

### 5. Subagent Model Selection

**Consistent guidance** across all sources: Use cheaper models for mechanical tasks.

| Task | Model | Cost Ratio |
|------|-------|------------|
| Grep/glob/search | haiku | 1x |
| File reading/summarization | haiku | 1x |
| Code exploration | sonnet | 3x |
| Complex reasoning | opus | 10x |

**Current state**: Documented in `context.md:105-127` but not enforced.

### 6. Skill Architecture Best Practices

**From leehanchung deep dive**:
- Keep SKILL.md under 500 lines (some say 5000 words)
- Use imperative language ("Analyze code for...")
- Always use `{baseDir}` variable for paths
- Store deterministic automation in `scripts/`
- Store detailed documentation in `references/`

**From sshh blog**:
- Minimal commands philosophy: "the entire point of an agent is you can type almost whatever you want"
- Only maintain essential commands (catchup, pr)
- MCPs should be "secure gateways" with 1-2 high-level tools

## Comparison: Current agent_docs vs Best Practices

### Aligned

| Aspect | agent_docs | External |
|--------|-----------|----------|
| Research → Plan → Implement | `workflow.md` | Anthropic best practices |
| Error retry limits | `principles.md:15` | 12-factor agents |
| Context utilization thresholds | `context.md:75-80` | Universal guidance |
| Subagent isolation | `context.md:92-127` | All sources |
| STATE.md persistence | `context.md:141-166` | Community patterns |

### Gaps

| Gap | Current State | Best Practice |
|-----|--------------|---------------|
| Hook lifecycle coverage | 4 events | 12 events |
| Skills vs commands | Commands only | Skills with frontmatter |
| Progressive disclosure | Full loading | Three-level disclosure |
| Auto-activation | Manual entry | Context-aware suggestions |
| Supporting files | None | scripts/, references/ |
| Skill invocation control | N/A | disable-model-invocation, user-invocable |
| Forked context execution | N/A | `context: fork` for heavy work |

## Recommended File Structure

Current:
```
.claude/
├── commands/
│   ├── workflow.md
│   ├── research.md
│   ├── plan.md
│   └── ...
├── settings.json
└── metrics.json
```

Recommended:
```
.claude/
├── skills/
│   ├── workflow/
│   │   ├── SKILL.md           # Entry point with frontmatter
│   │   ├── phases.md          # Reference: phase details
│   │   └── scripts/
│   │       └── state-check.sh # Deterministic STATE.md parsing
│   ├── research/
│   │   ├── SKILL.md
│   │   └── templates/
│   │       └── findings.md    # Research artifact template
│   ├── plan/
│   │   ├── SKILL.md           # context: fork for exploration
│   │   └── templates/
│   │       └── plan-format.md
│   └── implement/
│       ├── SKILL.md
│       └── scripts/
│           └── verify-step.sh
├── hooks/
│   └── hooks.json             # Centralized hook config
├── settings.json
└── metrics.json
```

## Recommended Improvements

### 1. Migrate Commands to Skills

Convert current commands to skills with proper frontmatter:

```yaml
---
name: research
description: Understand problem space before proposing changes. Use when exploring unfamiliar code, analyzing bugs, or planning features.
disable-model-invocation: true
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob, Task
---
```

**Benefits**:
- `context: fork` isolates exploration from main context
- `agent: Explore` uses appropriate subagent
- `disable-model-invocation: true` keeps manual control
- Description enables future auto-suggestion

### 2. Expand Hook Lifecycle Coverage

Add missing hooks to `settings.json`:

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "./scripts/session-init.sh",
        "description": "Load STATE.md, check context health"
      }]
    }],
    "SubagentStop": [{
      "hooks": [{
        "type": "command",
        "command": "./scripts/subagent-summarize.sh",
        "description": "Ensure subagent findings are captured"
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "prompt",
        "prompt": "Check if task is truly complete: $ARGUMENTS",
        "description": "Prevent premature completion"
      }]
    }],
    "PreCompact": [{
      "hooks": [{
        "type": "command",
        "command": "./scripts/pre-compact-checkpoint.sh",
        "description": "Save STATE.md before compaction"
      }]
    }]
  }
}
```

### 3. Implement Auto-Activation Hook

Create `skill-rules.json` for context-aware suggestions:

```json
{
  "rules": [
    {
      "patterns": ["not working", "error", "bug", "broken", "failing"],
      "suggest": "debug",
      "reason": "Error signals detected"
    },
    {
      "patterns": ["add", "implement", "create", "build", "new feature"],
      "suggest": "research",
      "reason": "New work requires research phase"
    },
    {
      "patterns": ["refactor", "change", "update", "modify"],
      "suggest": "research",
      "reason": "Modification requires understanding first"
    }
  ]
}
```

Wire via `UserPromptSubmit` hook:
```bash
#!/bin/bash
# scripts/skill-suggester.sh
PROMPT=$(cat /dev/stdin | jq -r '.prompt')
RULES=$(cat .claude/skill-rules.json)
# Match patterns, output suggestion
```

### 4. Add Supporting File Structure

For `/research` skill:
```
.claude/skills/research/
├── SKILL.md                 # Core instructions
├── templates/
│   └── findings.md          # Research artifact template
├── references/
│   └── decomposition.md     # Detailed decomposition guidance
└── scripts/
    └── summarize-findings.sh
```

Template files get read by Claude when needed, not loaded into initial context.

### 5. Document Skill Development Guidelines

Add to `agent_docs/integrations.md`:

```markdown
## Skill Development

### Frontmatter Reference
| Field | Purpose | Example |
|-------|---------|---------|
| name | Identifier | `research` |
| description | Auto-match trigger | "Use when exploring unfamiliar code" |
| disable-model-invocation | Manual only | `true` for workflows with side effects |
| user-invocable | Claude only | `false` for background knowledge |
| context | Execution mode | `fork` for isolated context |
| agent | Subagent type | `Explore`, `Plan`, `general-purpose` |
| allowed-tools | Tool restrictions | `Read, Grep, Glob` |
| model | Override model | `haiku`, `sonnet`, `opus` |

### Progressive Disclosure
1. Keep SKILL.md under 500 lines
2. Move detailed reference to `references/` subdirectory
3. Put templates in `templates/` subdirectory
4. Put deterministic scripts in `scripts/` subdirectory
5. Use relative paths: `See [decomposition guide](references/decomposition.md)`
```

### 6. Create Context Budget Enforcement

Add hook to warn on skill overload:

```bash
#!/bin/bash
# scripts/skill-budget-check.sh
# Called on skill load, warns if total skill content exceeds threshold
LOADED_SKILLS=$(cat /dev/stdin | jq -r '.loaded_skills | length')
if [ "$LOADED_SKILLS" -gt 5 ]; then
  echo '{"systemMessage": "Warning: Many skills loaded. Consider /clear if performance degrades."}'
fi
```

## Questions for Clarification

1. **Migration strategy**: Gradual (commands remain, skills added) or full migration?
2. **Auto-activation**: Enable by default or opt-in via flag?
3. **Hook verbosity**: Silent operation or status line integration?
4. **Skill scope**: Project-only or also personal (`~/.claude/skills/`)?

## Recommended Approach

**Phase 1**: Migrate existing commands to skills with frontmatter (retains current behavior)
**Phase 2**: Add supporting file structure (templates/, scripts/)
**Phase 3**: Expand hook lifecycle coverage
**Phase 4**: Implement auto-activation (optional, off by default)

This preserves current functionality while enabling new capabilities incrementally.
