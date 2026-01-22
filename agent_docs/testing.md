# Testing and Build Output

Strategies for context-efficient test and build execution.

## The Problem

Test suites generate hundreds of lines of output. A typical monorepo test run can consume half a context window with low-information content (timing, progress bars, passing test names).

This costs twice: tokens consumed + degraded reasoning quality.

## The run_silent Pattern

Success shows a single symbol. Failure dumps full output.

### Production Implementation

```bash
#!/bin/bash
set -e

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

VERBOSE=${VERBOSE:-0}

run_silent() {
    local description="$1"
    local command="$2"

    if [ "$VERBOSE" = "1" ]; then
        echo "  → Running: $command"
        eval "$command"
        return $?
    fi

    local tmp_file=$(mktemp)
    if eval "$command" > "$tmp_file" 2>&1; then
        printf "  ${GREEN}✓${NC} %s\n" "$description"
        rm -f "$tmp_file"
        return 0
    else
        local exit_code=$?
        printf "  ${RED}✗${NC} %s\n" "$description"
        printf "${RED}Command failed: %s${NC}\n" "$command"
        cat "$tmp_file"
        rm -f "$tmp_file"
        return $exit_code
    fi
}
```

### With Test Count Extraction

```bash
run_silent_with_test_count() {
    local description="$1"
    local command="$2"
    local test_type="${3:-pytest}"

    local tmp_file=$(mktemp)
    if eval "$command" > "$tmp_file" 2>&1; then
        case "$test_type" in
            pytest)
                test_count=$(grep -E "[0-9]+ passed" "$tmp_file" | grep -oE "^[0-9]+ passed" | awk '{print $1}' | tail -1)
                duration=$(grep -E "[0-9]+ passed" "$tmp_file" | grep -oE "in [0-9.]+s" | tail -1)
                ;;
            jest)
                test_count=$(jq -r '.numTotalTests // empty' "$tmp_file" 2>/dev/null)
                ;;
            go)
                test_count=$(grep -c '"Action":"pass"' "$tmp_file" 2>/dev/null || true)
                ;;
        esac
        printf "  ✓ %s (%s tests%s)\n" "$description" "${test_count:-?}" "${duration:+, $duration}"
        rm -f "$tmp_file"
        return 0
    else
        printf "  ✗ %s\n" "$description"
        cat "$tmp_file"
        rm -f "$tmp_file"
        return 1
    fi
}
```

## Fail-Fast Flags

Stop at first failure to minimize output:

| Framework | Flag | Notes |
|-----------|------|-------|
| pytest | `-x` | Stop after first failure |
| jest | `--bail` | Stop after first failure |
| vitest | `--bail` | Stop after first failure |
| go test | `-failfast` | Stop after first failure |
| cargo test | `-- --test-threads=1` | No native fail-fast |
| Maven | `-ff` | Still verbose |
| Gradle | `--fail-fast` | Still verbose |

## Usage Examples

```bash
# Basic
run_silent "unit tests" "pytest tests/"
run_silent "type check" "npm run typecheck"
run_silent "build" "npm run build"

# With test counts
run_silent_with_test_count "Python tests" "pytest tests/" "pytest"
run_silent_with_test_count "Go tests" "go test -json ./..." "go"
run_silent_with_test_count "Jest tests" "jest --json" "jest"
```

**Expected output (success):**
```
  ✓ Python tests (45 tests, in 2.3s)
  ✓ Go tests (123 tests)
  ✓ Jest tests (67 tests)
```

**Expected output (failure):**
```
  ✗ API tests
Command failed: pytest tests/api/
FAILED tests/api/test_users.py::test_validate_email - AssertionError
```

## Anti-Patterns

| Pattern | Problem |
|---------|---------|
| `> /dev/null 2>&1` | Hides failures, forces re-runs to diagnose |
| `\| head -50` | Partial output incomprehensible, forces re-runs |
| Model-decided truncation | Inconsistent, often too conservative |
| Verbose success output | Wastes 2-3% context per run |

## Target

- Success runs: <10 tokens (single checkmark line)
- Failure runs: Full diagnostic output
- Overall: Keep test/build output under 20 lines for passing runs
