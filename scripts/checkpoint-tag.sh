#!/bin/bash
# Creates a git tag at checkpoint
# Usage: checkpoint-tag.sh [phase-name]

PHASE="${1:-checkpoint}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TAG_NAME="checkpoint/${PHASE}-${TIMESTAMP}"

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not a git repository"
    exit 1
fi

# Check for uncommitted changes
if [[ -n "$(git status --porcelain)" ]]; then
    echo "Warning: uncommitted changes exist"
    echo "Tag will point to last commit, not current working state"
fi

# Get current commit info
COMMIT_HASH=$(git rev-parse --short HEAD)
COMMIT_MSG=$(git log -1 --format=%s)

# Create the tag
if git tag "$TAG_NAME" -m "Checkpoint: $PHASE at $COMMIT_HASH"; then
    echo "✓ Created tag: $TAG_NAME"
    echo "  Commit: $COMMIT_HASH - $COMMIT_MSG"
    echo
    echo "Rollback command:"
    echo "  git checkout $TAG_NAME"
else
    echo "Failed to create tag"
    exit 1
fi

# List recent checkpoint tags
echo
echo "Recent checkpoints:"
git tag -l "checkpoint/*" --sort=-creatordate | head -5
