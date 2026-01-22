#!/bin/bash
# Checks for drift between agent_docs principles and skill implementations
# Usage: lint-docs.sh

set -e

AGENT_DOCS="agent_docs"
SKILLS_DIR=".claude/skills"

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

WARNINGS=0
ERRORS=0

echo "## Documentation Drift Analysis"
echo

# Check 1: Principles mentioned in docs but not in skills
echo "### Checking principle references..."

# Key patterns from principles.md that should appear in skills
PRINCIPLE_PATTERNS=(
    "wave.*execution:research,implement"
    "retry.*limit:implement"
    "context.*60%:workflow,implement"
    "checkpoint:checkpoint,workflow"
    "subagent.*model:research"
    "goal.*backward.*verification:implement"
    "deviation.*rule:implement"
)

for PATTERN_DEF in "${PRINCIPLE_PATTERNS[@]}"; do
    PATTERN=$(echo "$PATTERN_DEF" | cut -d: -f1)
    EXPECTED_SKILLS=$(echo "$PATTERN_DEF" | cut -d: -f2)

    # Check if pattern exists in expected skills
    for SKILL in $(echo "$EXPECTED_SKILLS" | tr ',' ' '); do
        SKILL_FILE="$SKILLS_DIR/$SKILL/SKILL.md"
        if [[ -f "$SKILL_FILE" ]]; then
            if grep -qi "$PATTERN" "$SKILL_FILE" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} '$PATTERN' found in $SKILL"
            else
                echo -e "${YELLOW}⚠${NC} '$PATTERN' not found in $SKILL"
                ((WARNINGS++))
            fi
        fi
    done
done
echo

# Check 2: Skills reference templates that exist
echo "### Checking template references..."
for SKILL_FILE in "$SKILLS_DIR"/*/SKILL.md; do
    SKILL_NAME=$(dirname "$SKILL_FILE" | xargs basename)

    # Find template references
    REFS=$(grep -oE '\[.*\]\((templates|../shared/templates)/[^)]+\)' "$SKILL_FILE" 2>/dev/null || true)

    for REF in $REFS; do
        # Extract path
        PATH_REF=$(echo "$REF" | grep -oE '\([^)]+\)' | tr -d '()')

        # Resolve relative path
        SKILL_DIR=$(dirname "$SKILL_FILE")
        FULL_PATH="$SKILL_DIR/$PATH_REF"

        if [[ -f "$FULL_PATH" ]]; then
            echo -e "${GREEN}✓${NC} $SKILL_NAME: $PATH_REF exists"
        else
            echo -e "${RED}✗${NC} $SKILL_NAME: $PATH_REF missing"
            ((ERRORS++))
        fi
    done
done
echo

# Check 3: Script references in skills
echo "### Checking script references..."
for SKILL_FILE in "$SKILLS_DIR"/*/SKILL.md; do
    SKILL_NAME=$(dirname "$SKILL_FILE" | xargs basename)

    # Find script references
    SCRIPTS=$(grep -oE '\./scripts/[a-z_-]+\.sh|scripts/[a-z_-]+\.sh' "$SKILL_FILE" 2>/dev/null | sort -u || true)

    for SCRIPT in $SCRIPTS; do
        # Normalize path
        SCRIPT_PATH="${SCRIPT#./}"

        if [[ -f "$SCRIPT_PATH" ]]; then
            echo -e "${GREEN}✓${NC} $SKILL_NAME: $SCRIPT_PATH exists"
        else
            echo -e "${RED}✗${NC} $SKILL_NAME: $SCRIPT_PATH missing"
            ((ERRORS++))
        fi
    done
done
echo

# Check 4: agent_docs file references
echo "### Checking agent_docs references..."
for SKILL_FILE in "$SKILLS_DIR"/*/SKILL.md; do
    SKILL_NAME=$(dirname "$SKILL_FILE" | xargs basename)

    DOCS=$(grep -oE 'agent_docs/[a-z_-]+\.md' "$SKILL_FILE" 2>/dev/null | sort -u || true)

    for DOC in $DOCS; do
        if [[ -f "$DOC" ]]; then
            echo -e "${GREEN}✓${NC} $SKILL_NAME: $DOC exists"
        else
            echo -e "${RED}✗${NC} $SKILL_NAME: $DOC missing"
            ((ERRORS++))
        fi
    done
done
echo

# Summary
echo "─────────────────────────────"
if [[ $ERRORS -gt 0 ]]; then
    echo -e "${RED}$ERRORS error(s)${NC}, $WARNINGS warning(s)"
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    echo -e "${GREEN}Pass${NC} with $WARNINGS warning(s)"
    exit 0
else
    echo -e "${GREEN}All checks passed${NC}"
    exit 0
fi
