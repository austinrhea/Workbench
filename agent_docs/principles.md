# Agent Principles

Core principles for effective AI agent work. Derived from 12-Factor Agents and related research.

## The Core Insight

Production agents are **deterministic code with strategic LLM steps**, not purely autonomous systems. The LLM decides what to do; deterministic code executes it.

## Key Thresholds

| Metric | Value |
|--------|-------|
| Max agent turns before problems | 10-20 |
| Recommended task scope | 3-10 steps |
| Error retry limit | 2-3 consecutive |
| Context utilization target | 40-60% |

## Temperature & Sampling

| Task Type | Temperature | Notes |
|-----------|-------------|-------|
| Code generation | 0.0-0.3 | Deterministic, reproducible |
| Planning/analysis | 0.3-0.5 | Slight creativity, mostly focused |
| Brainstorming | 0.7-1.0 | Diverse options, exploration |
| Structured output (JSON) | 0.0 | Must be parseable |

**Rules**:
- Lower temperature for anything that needs to be correct/reproducible
- Higher temperature only when you want variety
- For agents: default to low (0.0-0.3) since you want consistent behavior
- If using tools: temperature 0 prevents hallucinated tool calls

## The 12 Factors

### 1. Natural Language → Structured Output

LLM converts intent to structured JSON. Deterministic code executes.

```
User: "deploy the backend to production"
      ↓
LLM:  { "intent": "deploy_backend", "target": "production", "version": "v1.2.3" }
      ↓
Code: switch(intent) → execute_deploy()
```

### 2. Own Your Prompts

Treat prompts as first-class code. Version control them. Never use black-box abstractions.

### 3. Own Your Context

Structure deliberately. Format for parseability:

```xml
<slack_message>
    From: @alex
    Channel: #deployments
    Text: Can you deploy the latest backend?
</slack_message>

<list_tags_result>
    - v1.2.3 (abc123, 2024-03-15)
    - v1.2.2 (def456, 2024-03-14)
</list_tags_result>
```

### 4. Tools Are Decisions, Not Execution

Tool calls express intent. Your code decides actual execution:

```python
class DeployBackend:
    intent: "deploy_backend"
    version: str
    environment: str

class RequestHumanInput:
    intent: "request_human_input"
    question: str
    urgency: Literal["low", "medium", "high"]
```

### 5. Unify State in Context

Conversation history is the single source of truth:

```python
class Thread:
    events: List[Event]

class Event:
    type: str  # "tool_call", "tool_result", "human_response", "error"
    data: dict
```

Don't maintain parallel state machines.

### 6. Launch / Pause / Resume

Design explicit lifecycle with save points:

```python
if next_step.intent == 'request_human_input':
    thread.events.append(next_step)
    save_state(thread)
    notify_human(next_step)
    break  # Pause for async response

# Resume via webhook
thread = load_state(thread_id)
thread.events.append({'type': 'human_response', 'data': response})
continue_execution(thread)
```

### 7. Human Contact as Tool

`request_human_input` is just another tool:

```python
class RequestHumanInput:
    intent: "request_human_input"
    question: str
    context: str
    options: {
        urgency: "low" | "medium" | "high",
        format: "free_text" | "yes_no" | "multiple_choice",
        choices: List[str]
    }
```

### 8. Own Your Control Flow

Build your own loop. Intercept between decision and action:

```python
while True:
    next_step = determine_next_step(thread_to_prompt(thread))
    thread.events.append(next_step)

    if next_step.intent == 'done':
        return next_step.result

    if needs_approval(next_step):
        request_approval(next_step)
        save_state(thread)
        break  # Wait for human

    result = execute(next_step)
    thread.events.append({'type': 'result', 'data': result})
```

### 9. Compact Errors into Context

Feed errors back for self-correction:

```python
consecutive_errors = 0
while True:
    try:
        result = execute(next_step)
        consecutive_errors = 0
    except Exception as e:
        consecutive_errors += 1
        if consecutive_errors < 3:
            thread.events.append({
                'type': 'error',
                'data': format_error(e)  # Concise, not full stack
            })
            continue
        else:
            escalate_to_human(e)
            break
```

### 10. Small, Focused Agents

3-10 steps per workflow. Compose with deterministic orchestration:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Research    │ ──→ │ Plan        │ ──→ │ Implement   │
│ Agent       │     │ Agent       │     │ Agent       │
│ (5 steps)   │     │ (5 steps)   │     │ (10 steps)  │
└─────────────┘     └─────────────┘     └─────────────┘
        ↑                                      │
        └────── Deterministic Orchestration ───┘
```

### Wave-Based Execution

Group parallelizable tasks by dependency:

```
Wave 1 (parallel):     Wave 2 (parallel):     Wave 3 (sequential):
┌─────────┐            ┌─────────┐            ┌─────────┐
│ Search  │            │ Edit A  │            │ Build   │
│ files   │            └─────────┘            └────┬────┘
└─────────┘            ┌─────────┐                 │
┌─────────┐            │ Edit B  │            ┌────▼────┐
│ Read    │      →     └─────────┘      →     │ Test    │
│ config  │            ┌─────────┐            └────┬────┘
└─────────┘            │ Edit C  │                 │
┌─────────┐            └─────────┘            ┌────▼────┐
│ Check   │                                   │ Deploy  │
│ deps    │                                   └─────────┘
└─────────┘
```

Rules:
- Tasks with no dependencies run in parallel
- Tasks depending on previous results wait
- Build/test/deploy are sequential checkpoints
- Up to 500 parallel reads/searches, but only 1 build at a time

### 11. Trigger from Anywhere

Support multiple entry points:
- Slack messages
- Webhooks / APIs
- Cron jobs
- Email
- CI/CD events

### 12. Stateless Reducer

Agent as pure function:

```
(previous_state, new_event) → (new_state, effects)
```

Benefits:
- Reproducible (same input = same output)
- Testable (mock inputs, assert outputs)
- Debuggable (replay any point)
- Forkable (branch from any state)

## The Agent Loop (Complete)

```python
def run_agent(initial_event):
    thread = Thread(events=[initial_event])

    while True:
        prompt = thread_to_prompt(thread)
        next_step = llm.determine_next_step(prompt)
        thread.events.append(next_step)

        if next_step.intent == 'done':
            return next_step.final_answer

        if next_step.intent == 'request_human_input':
            save_state(thread)
            notify_human(next_step)
            return  # Async pause

        result = execute_tool(next_step)
        thread.events.append({
            'type': f'{next_step.intent}_result',
            'data': result
        })
```

## Anti-Patterns

| Pattern | Problem |
|---------|---------|
| Framework dependency | Can't customize prompts/context |
| Pure autonomy | No approval gates for risky actions |
| Monolithic agents | 50+ steps = lost focus |
| Hidden state | Can't reproduce behavior |
| Unlimited retries | No escalation when stuck |
| Tight tool coupling | Tool name ≠ function name flexibility |
