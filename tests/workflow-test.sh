#!/bin/bash
# Integration tests for workflow phases
# Usage: workflow-test.sh

# Don't use set -e - we need to handle test failures gracefully

TESTS_DIR="$(dirname "$0")"
FIXTURES_DIR="$TESTS_DIR/fixtures"
TEMP_DIR=$(mktemp -d)

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASSED=0
FAILED=0

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

echo "## Workflow Integration Tests"
echo

# Test 1: STATE.md linter validates good state
echo "### Test: STATE.md Linter"
cat > "$TEMP_DIR/STATE.md" << 'EOF'
---
task: "Test task"
status: in_progress
phase: research
path: research,plan,implement
context_percent: 25
last_updated: 2026-01-22
---

## Original Prompt
> Test prompt

## Scope
**Doing**: Testing
**Not doing**: Production

## Decisions
None yet

## Blockers
None

## Key Files
- test.ts

## Next Steps
Continue testing
EOF

if bash scripts/lint-state.sh "$TEMP_DIR/STATE.md" > /dev/null 2>&1; then
    pass "Linter accepts valid STATE.md"
else
    fail "Linter rejected valid STATE.md"
fi

# Test 2: STATE.md linter catches invalid status
cat > "$TEMP_DIR/STATE-bad.md" << 'EOF'
---
task: "Test task"
status: invalid_status
phase: research
---

## Original Prompt
> Test
EOF

if ! bash scripts/lint-state.sh "$TEMP_DIR/STATE-bad.md" > /dev/null 2>&1; then
    pass "Linter rejects invalid status"
else
    fail "Linter accepted invalid status"
fi

# Test 3: Context estimation warns at high utilization
echo
echo "### Test: Context Estimation"
if bash scripts/estimate-context.sh implement 45 2>&1 | grep -q "WARNING\|CAUTION"; then
    pass "Estimation warns at 45% + implement(20%)"
else
    fail "Estimation did not warn at projected 65%"
fi

if bash scripts/estimate-context.sh checkpoint 20 > /dev/null 2>&1; then
    pass "Estimation passes at 20% + checkpoint(2%)"
else
    fail "Estimation failed at low utilization"
fi

# Test 4: Error compaction extracts key info
echo
echo "### Test: Error Compaction"
PYTHON_ERROR="Traceback (most recent call last):
  File \"app.py\", line 10, in main
    result = process()
ValueError: invalid input"

COMPACTED=$(echo "$PYTHON_ERROR" | bash scripts/compact-error.sh)
if echo "$COMPACTED" | grep -q "Python Exception" && echo "$COMPACTED" | grep -q "ValueError"; then
    pass "Error compaction extracts Python error type"
else
    fail "Error compaction missed Python error"
fi

# Test 5: Metrics analysis runs without error
echo
echo "### Test: Metrics Analysis"
if [[ -f ".claude/metrics.json" ]]; then
    if bash scripts/analyze-metrics.sh > /dev/null 2>&1; then
        pass "Metrics analysis runs successfully"
    else
        fail "Metrics analysis failed"
    fi
else
    echo "  (skipped - no metrics.json)"
fi

# Test 6: All skills have required sections
echo
echo "### Test: Skill Structure"
SKILL_ERRORS=0
for SKILL_FILE in .claude/skills/*/SKILL.md; do
    SKILL_NAME=$(dirname "$SKILL_FILE" | xargs basename)

    # Check for required sections
    if ! grep -q "^## Instructions" "$SKILL_FILE"; then
        fail "$SKILL_NAME missing ## Instructions"
        ((SKILL_ERRORS++))
    fi

    if ! grep -q "^## Exit Criteria\|^## Constraints" "$SKILL_FILE"; then
        fail "$SKILL_NAME missing exit criteria or constraints"
        ((SKILL_ERRORS++))
    fi
done

if [[ $SKILL_ERRORS -eq 0 ]]; then
    pass "All skills have required sections"
fi

# Summary
echo
echo "─────────────────────────────"
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ $FAILED -gt 0 ]]; then
    exit 1
else
    echo -e "${GREEN}All tests passed${NC}"
    exit 0
fi
