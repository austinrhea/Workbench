# Docs

Update README.md commands table from source.

## Task
$ARGUMENTS

## Instructions

Output: `## Docs`

### 1. Scan Commands

Read all files in `.claude/commands/*.md` and extract:
- Command name (filename without .md)
- Description (first non-heading line of file)

### 2. Generate Table

Format as markdown table:

```markdown
| Command | Description |
|---------|-------------|
| `/command` | First line description |
```

Sort alphabetically by command name.

### 3. Update README

Replace content between markers in README.md:

```
<!-- COMMANDS:START -->
[generated table]
<!-- COMMANDS:END -->
```

### 4. Report

Show the updated commands table.

## Constraints

- Only update the section between markers
- Preserve all other README content
- Don't add commands that don't exist

## Exit Criteria

README.md commands section updated with current commands.
