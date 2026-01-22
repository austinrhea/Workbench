# Workflow Example: Debugging a Python API Integration

This document demonstrates the **Debug → Implement** workflow using a realistic scenario: diagnosing and fixing an intermittent API error in a Python FastAPI application.

## What You'll Learn

- How `/workflow` routes bug reports to `/debug` instead of `/research`
- The 5-step debug process: Reproduce → Isolate → Hypothesize → Test → Diagnose
- How to produce a diagnosis before proposing fixes
- How state evolves through `STATE.md` in debug → implement flow

---

## The Scenario

**Context**: A FastAPI application with a `/api/users/{id}` endpoint that fetches user data from an external user service.

**Bug Report**:
> "The `/api/users/123` endpoint is returning 500 errors intermittently.
> It works sometimes but fails randomly. Started happening after we
> increased traffic last week."

**The Codebase**:
```
myapp/
├── src/
│   ├── main.py
│   ├── api/
│   │   ├── __init__.py
│   │   └── users.py      # ← Problem is here
│   └── services/
│       └── user_service.py
├── tests/
│   └── test_users.py
└── requirements.txt
```

---

## Starting the Workflow

### The Prompt

```
/workflow The /api/users/{id} endpoint is returning 500 errors intermittently.
It works sometimes but fails randomly. Started after increased traffic.
```

### Task Assessment

The workflow skill assesses the task:

```markdown
## Task Assessment

**Task**: Debug intermittent 500 errors on /api/users endpoint
**Type**: Bug (error, failing, intermittent)
**Scope**: Small — likely single component

**Path**: debug → implement

**Rationale**:
- "500 errors", "failing", "intermittent" signals bug/failure
- Need to diagnose before fixing
- Debug path is appropriate for error investigation

Proceed?
```

User responds: **yes**

### Initial STATE.md

```yaml
---
task: "Debug intermittent 500 errors on /api/users endpoint"
objective: "Identify root cause and fix the API reliability issue"
status: in_progress
phase: debug
path: debug,implement
context_percent: 10
last_updated: 2026-01-22
---

## Original Prompt
> The /api/users/{id} endpoint is returning 500 errors intermittently.
> It works sometimes but fails randomly. Started after increased traffic.

## Scope
**Doing**: Diagnose and fix API endpoint errors
**Not doing**: Performance optimization, refactoring, new features

## Progress
- [ ] Debug: Identify root cause
- [ ] Implement: Apply fix

## Decisions
[None yet]

## Blockers
[None]

## Key Files
[To be discovered]

## Checkpoint
Fresh start.

## Next Steps
Starting debug phase
```

---

## Phase 1: Debug

The workflow invokes `/debug`:

```
Skill(skill="debug", args="Intermittent 500 errors on /api/users/{id} endpoint")
```

### Step 1: Reproduce

First, confirm the failure exists and capture the exact error.

**Run the endpoint:**
```bash
$ curl -X GET http://localhost:8000/api/users/123
```

**Result (when it fails):**
```json
{
  "detail": "Internal Server Error"
}
```

**Check the logs:**
```
2026-01-22 14:30:15 ERROR uvicorn.error - Exception in ASGI application
Traceback (most recent call last):
  File "src/api/users.py", line 12, in get_user
    response = requests.get(f"{USER_SERVICE_URL}/users/{user_id}")
  File "/usr/local/lib/python3.11/site-packages/requests/api.py", line 73, in get
    return request("get", url, params=params, **kwargs)
  ...
requests.exceptions.ReadTimeout: HTTPConnectionPool(host='user-service', port=8080): Read timed out. (read timeout=None)
```

**Environment:**
- Python 3.11, FastAPI 0.104.1, requests 2.31.0
- External service: `user-service:8080` (internal microservice)
- Failure rate: ~15% of requests under load

### Step 2: Isolate

Narrow down to the specific component.

**Trace the request flow:**
```
Client → FastAPI → src/api/users.py → requests.get() → user-service:8080
                   ^^^^^^^^^^^^^^^^
                   Failure point
```

**Read the suspect code:**

```python
# src/api/users.py
from fastapi import APIRouter
import requests
import os

router = APIRouter()
USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://user-service:8080")

@router.get("/users/{user_id}")
async def get_user(user_id: int):
    response = requests.get(f"{USER_SERVICE_URL}/users/{user_id}")
    return response.json()
```

**Problems identified:**
1. No timeout specified on `requests.get()`
2. No error handling (try/except)
3. No retry logic for transient failures
4. Blocking `requests` call in async endpoint

### Step 3: Hypothesize

List possible causes, most likely first:

| Hypothesis | Evidence Needed | Likelihood |
|------------|-----------------|------------|
| External service timeout | Timeout error in traceback | **High** |
| Network congestion under load | Correlation with traffic | Medium |
| External service overloaded | Service metrics | Medium |
| DNS resolution issues | DNS errors in logs | Low |
| Authentication failure | 401/403 errors | Low |

**Key observation**: The traceback shows `ReadTimeout` with `timeout=None`, confirming no timeout is set.

### Step 4: Test Hypotheses

**Test 1: Check if external service is responsive**
```bash
$ curl -w "%{time_total}s\n" http://user-service:8080/users/123
{"id": 123, "name": "John Doe", "email": "john@example.com"}
0.045s
```
Service responds normally when not under load.

**Test 2: Simulate load and measure response times**
```bash
$ ab -n 100 -c 10 http://localhost:8000/api/users/123
...
Failed requests: 14
Time per request: 2847ms (mean)
```
14% failure rate under concurrent load — matches reported ~15%.

**Test 3: Check external service under load**
```bash
$ ab -n 100 -c 10 http://user-service:8080/users/123
...
Failed requests: 0
Time per request: 89ms (mean), but max: 4200ms
```
External service has high latency variance (89ms mean, 4.2s max).

**Conclusion**: External service occasionally takes >4 seconds. With no timeout and no error handling, these slow requests cause cascading failures.

### Step 5: Diagnosis

```markdown
## Symptom
Intermittent 500 Internal Server Error on `/api/users/{id}` endpoint.

```
requests.exceptions.ReadTimeout: HTTPConnectionPool(host='user-service', port=8080):
Read timed out. (read timeout=None)
```

**Reproduction steps:**
1. Start the application
2. Send concurrent requests: `ab -n 100 -c 10 http://localhost:8000/api/users/123`
3. Observe: ~15% of requests fail with 500 error

**Expected:** All requests return user data or graceful error
**Actual:** Random 500 errors under load

## Root Cause
**Missing timeout and error handling on external API call.**

**Component:** `src/api/users.py:10`
**Mechanism:**
1. External service occasionally takes 4+ seconds to respond
2. `requests.get()` has no timeout (waits indefinitely)
3. No try/except to catch timeout exceptions
4. Unhandled exception propagates as 500 error

## Evidence

| Source | Observation |
|--------|-------------|
| `src/api/users.py:10` | `requests.get()` with no timeout parameter |
| `src/api/users.py:10-11` | No try/except around external call |
| Traceback | `ReadTimeout` with `timeout=None` |
| Load test | 14% failure at 10 concurrent users |
| External service | Latency variance: 89ms mean, 4.2s max |

## Fix Options

### Option A: Add Timeout + Basic Error Handling
**Approach:** Add timeout parameter and try/except with graceful error response
**Files:** `src/api/users.py`
**Tradeoffs:**
- Pro: Simple, quick fix
- Pro: Fails fast instead of hanging
- Con: Still fails on timeout (just faster and cleaner)

### Option B: Add Timeout + Retry with Backoff
**Approach:** Use `tenacity` or `urllib3.Retry` for automatic retries
**Files:** `src/api/users.py`, `requirements.txt`
**Tradeoffs:**
- Pro: Handles transient failures automatically
- Pro: Better user experience
- Con: More complexity
- Con: Could mask persistent issues

### Option C: Circuit Breaker Pattern
**Approach:** Use `pybreaker` to fail fast when service is unhealthy
**Files:** `src/api/users.py`, `requirements.txt`
**Tradeoffs:**
- Pro: Prevents cascade failures
- Pro: Self-healing
- Con: Most complex
- Con: Overkill for this scenario

## Recommended
**Option B: Timeout + Retry with Backoff**

Rationale:
- Timeout prevents indefinite hangs
- Retry handles transient network issues (which we confirmed)
- Backoff prevents overwhelming the external service
- Reasonable complexity for the benefit

**Estimated scope:** Small (one file, ~20 lines)
**Risk:** Low

## Verification Plan
After fix, verify by:
1. Run `pytest tests/test_users.py` — should pass
2. Load test: `ab -n 100 -c 10` — should have <1% failure rate
3. Manual test with service delay — should retry and succeed
```

### Gate

```markdown
## Diagnosis Complete

**Root cause**: Missing timeout and error handling on external API call in `src/api/users.py:10`

**Recommended fix**: Add timeout (5s) + retry with exponential backoff (3 attempts)

Approve fix approach?
```

User responds: **yes**

### STATE.md After Debug

```yaml
---
task: "Debug intermittent 500 errors on /api/users endpoint"
objective: "Identify root cause and fix the API reliability issue"
status: in_progress
phase: implement
path: debug,implement
context_percent: 30
last_updated: 2026-01-22
---

## Original Prompt
> The /api/users/{id} endpoint is returning 500 errors intermittently.

## Scope
**Doing**: Diagnose and fix API endpoint errors
**Not doing**: Performance optimization, refactoring, new features

## Progress
- [x] Debug: Identify root cause (timeout + no error handling)
- [ ] Implement: Apply fix (timeout + retry)

## Decisions
- Root cause: No timeout, no error handling on external call
- Fix approach: Option B — timeout + retry with backoff
- Use `tenacity` library for retry logic

## Learnings
- External service has high latency variance under load
- Always set explicit timeouts on external calls
- 5-step debug process prevented guessing

## Blockers
[None]

## Key Files
- `src/api/users.py:10` — the buggy line
- `requirements.txt` — add tenacity

## Checkpoint
Diagnosis complete. Fix approved.

## Next Steps
Implement timeout + retry fix
```

---

## Phase 2: Fix Implementation

The workflow invokes `/implement`:

```
Skill(skill="implement", args="Apply timeout + retry fix to src/api/users.py")
```

### The Fix

**Before** (`src/api/users.py`):
```python
from fastapi import APIRouter
import requests
import os

router = APIRouter()
USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://user-service:8080")

@router.get("/users/{user_id}")
async def get_user(user_id: int):
    response = requests.get(f"{USER_SERVICE_URL}/users/{user_id}")
    return response.json()
```

**After** (`src/api/users.py`):
```python
from fastapi import APIRouter, HTTPException
import requests
from requests.exceptions import RequestException, Timeout
from tenacity import retry, stop_after_attempt, wait_exponential
import os

router = APIRouter()
USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://user-service:8080")
REQUEST_TIMEOUT = 5  # seconds


@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=10),
    reraise=True
)
def fetch_user_from_service(user_id: int) -> dict:
    """Fetch user data from external service with retry logic."""
    response = requests.get(
        f"{USER_SERVICE_URL}/users/{user_id}",
        timeout=REQUEST_TIMEOUT
    )
    response.raise_for_status()
    return response.json()


@router.get("/users/{user_id}")
async def get_user(user_id: int):
    """Get user by ID from external user service."""
    try:
        return fetch_user_from_service(user_id)
    except Timeout:
        raise HTTPException(
            status_code=504,
            detail="User service timed out. Please try again."
        )
    except RequestException as e:
        raise HTTPException(
            status_code=502,
            detail=f"User service unavailable: {str(e)}"
        )
```

**Update requirements.txt:**
```
tenacity>=8.2.0
```

### Verification

**1. Install dependency:**
```bash
$ pip install tenacity>=8.2.0
```

**2. Run tests:**
```bash
$ pytest tests/test_users.py -v
tests/test_users.py::test_get_user_success PASSED
tests/test_users.py::test_get_user_timeout_retry PASSED
tests/test_users.py::test_get_user_service_unavailable PASSED
3 passed in 0.42s
```

**3. Load test:**
```bash
$ ab -n 100 -c 10 http://localhost:8000/api/users/123
...
Failed requests: 0
Time per request: 156ms (mean)
```
0% failure rate (down from 14%)!

**4. Manual verification:**
```bash
# Normal request
$ curl http://localhost:8000/api/users/123
{"id": 123, "name": "John Doe", "email": "john@example.com"}

# Simulated timeout (if service is slow)
$ curl http://localhost:8000/api/users/123
{"detail": "User service timed out. Please try again."}  # 504, not 500
```

### Gate

```markdown
## Implementation Complete

### Completed
- [x] Added `tenacity` to requirements.txt
- [x] Added timeout (5s) to requests.get()
- [x] Added retry logic (3 attempts, exponential backoff)
- [x] Added proper error handling with appropriate HTTP status codes

### Verified
- `pytest tests/test_users.py` ✓ (3 passed)
- Load test: 0% failure rate (was 14%) ✓
- Manual test: Graceful error responses ✓

Implementation complete. Please verify.
```

### Final STATE.md

```yaml
---
task: "Debug intermittent 500 errors on /api/users endpoint"
objective: "Identify root cause and fix the API reliability issue"
status: complete
phase: idle
path:
context_percent: 40
last_updated: 2026-01-22
---

## Original Prompt
> The /api/users/{id} endpoint is returning 500 errors intermittently.

## Scope
**Doing**: Diagnose and fix API endpoint errors
**Not doing**: Performance optimization, refactoring, new features

## Progress
- [x] Debug: Identify root cause (timeout + no error handling)
- [x] Implement: Apply fix (timeout + retry)

## Decisions
- Root cause: No timeout, no error handling on external call
- Fix: timeout (5s) + retry with exponential backoff (3 attempts)
- Used `tenacity` library for retry logic
- Return 504 for timeout, 502 for service unavailable

## Learnings
- Always set explicit timeouts on external HTTP calls
- Retry with backoff handles transient failures gracefully
- 5-step debug process found root cause without guessing
- Load testing confirms fix effectiveness

## Blockers
[None]

## Key Files
- `src/api/users.py` — fixed with timeout + retry
- `requirements.txt` — added tenacity
- `tests/test_users.py` — tests passing

## Checkpoint
Bug fixed and verified.

## Next Steps
Task complete. Consider:
- Add monitoring/alerting for timeout rates
- Document the retry policy
- Review other external API calls for same issue
```

---

## Key Takeaways

### What the Debug Workflow Provides

| Feature | Benefit |
|---------|---------|
| **5-step process** | Systematic diagnosis prevents guessing |
| **Diagnosis before fix** | Ensures you understand the problem |
| **Evidence gathering** | Confirms root cause, not just symptoms |
| **Fix options** | Considers tradeoffs before implementing |
| **Approval gate** | Human review before code changes |

### When to Use Debug vs Research

| Scenario | Path | Why |
|----------|------|-----|
| "It's broken", "error", "failing" | `/debug` | Known problem, need diagnosis |
| "Add feature X", "build Y" | `/research` → `/plan` | New functionality, need understanding |
| "Why does this work this way?" | `/research` | Exploration, no implementation |
| "Quick typo fix" | Direct | Obvious fix, no diagnosis needed |

### The 5-Step Debug Process

```
1. REPRODUCE    → Confirm the failure, capture exact error
2. ISOLATE      → Narrow to specific component
3. HYPOTHESIZE  → List possible causes, most likely first
4. TEST         → Gather evidence for each hypothesis
5. DIAGNOSE     → Document root cause, propose fix options
```

**Key principle**: Don't guess. Each step builds evidence toward the root cause.

### Common Python Bugs This Process Catches

| Bug Type | Symptoms | Common Root Cause |
|----------|----------|-------------------|
| Timeout errors | Intermittent 500s | No timeout on external calls |
| Import errors | App won't start | Circular imports |
| Type errors | Random crashes | None returned where object expected |
| Async bugs | Race conditions | Shared mutable state |
| Config bugs | Works locally, fails in prod | Missing environment variables |

---

## References

- [Debug Skill](../.claude/skills/debug/SKILL.md) — Full debug workflow instructions
- [Diagnosis Template](../.claude/skills/debug/templates/diagnosis.md) — Output format
- [Workflow Concepts](../agent_docs/workflow.md) — R→P→I and debug paths
- [Pipeline Example](workflow-pipeline-example.md) — Research → Plan → Implement example
