#!/bin/bash
# Validates STATE.md structure and content
# Exit codes: 0 = valid, 1 = errors found

set -e

STATE_FILE="${1:-STATE.md}"
ERRORS=0
WARNINGS=0

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

error() { echo -e "${RED}ERROR${NC}: $1"; ((ERRORS++)); }
warn() { echo -e "${YELLOW}WARN${NC}: $1"; ((WARNINGS++)); }
ok() { echo -e "${GREEN}✓${NC} $1"; }

if [[ ! -f "$STATE_FILE" ]]; then
    echo "No STATE.md found (this is fine for fresh sessions)"
    exit 0
fi

echo "Linting $STATE_FILE..."
echo

# Check line count
LINE_COUNT=$(wc -l < "$STATE_FILE")
if [[ $LINE_COUNT -gt 100 ]]; then
    warn "STATE.md has $LINE_COUNT lines (recommended: <100)"
else
    ok "Line count: $LINE_COUNT"
fi

# Check YAML frontmatter exists
if ! head -1 "$STATE_FILE" | grep -q "^---$"; then
    error "Missing YAML frontmatter (should start with ---)"
else
    ok "YAML frontmatter present"
fi

# Extract frontmatter
FRONTMATTER=$(sed -n '1,/^---$/p' "$STATE_FILE" | tail -n +2 | head -n -1)

# Required frontmatter fields
for FIELD in task status phase; do
    if echo "$FRONTMATTER" | grep -q "^${FIELD}:"; then
        ok "Field '$FIELD' present"
    else
        error "Missing required field: $FIELD"
    fi
done

# Check status value
STATUS=$(echo "$FRONTMATTER" | grep "^status:" | cut -d: -f2 | tr -d ' "')
VALID_STATUS="in_progress blocked complete parked idle"
if [[ -n "$STATUS" ]] && ! echo "$VALID_STATUS" | grep -qw "$STATUS"; then
    error "Invalid status: '$STATUS' (valid: $VALID_STATUS)"
else
    ok "Status value valid: $STATUS"
fi

# Check phase value
PHASE=$(echo "$FRONTMATTER" | grep "^phase:" | cut -d: -f2 | tr -d ' "')
VALID_PHASES="research plan implement debug idle quick"
if [[ -n "$PHASE" ]] && ! echo "$VALID_PHASES" | grep -qw "$PHASE"; then
    error "Invalid phase: '$PHASE' (valid: $VALID_PHASES)"
else
    ok "Phase value valid: $PHASE"
fi

# Required sections
REQUIRED_SECTIONS=("Original Prompt" "Scope" "Decisions" "Blockers" "Key Files" "Next Steps")
for SECTION in "${REQUIRED_SECTIONS[@]}"; do
    if grep -q "^## $SECTION" "$STATE_FILE"; then
        ok "Section '## $SECTION' present"
    else
        warn "Missing section: ## $SECTION"
    fi
done

# Check for stale state (>24h old)
if [[ -n "$(find "$STATE_FILE" -mmin +1440 2>/dev/null)" ]]; then
    warn "STATE.md is >24h old - consider updating or clearing"
fi

echo
echo "─────────────────────────────"
if [[ $ERRORS -gt 0 ]]; then
    echo -e "${RED}$ERRORS error(s)${NC}, $WARNINGS warning(s)"
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    echo -e "${GREEN}Valid${NC} with $WARNINGS warning(s)"
    exit 0
else
    echo -e "${GREEN}Valid${NC} - no issues found"
    exit 0
fi
