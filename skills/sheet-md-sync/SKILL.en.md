---
name: sheet-md-sync
description: Two-way sync between TC Google Sheet and local markdown. Pull Sheet → markdown (for git diff / PR review), or push local draft markdown → Sheet (initial publish). Trigger phrases — "Sheet to md", "md to Sheet", "TC into repo", "commit to git", "align sheet and markdown", "sync sheet". Pair with speckit-to-tc (draft producer), tc-to-pytest (sync pytest from md/sheet), tc-version-diff (version diff).
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__readSpreadsheet, mcp__google__getSpreadsheetInfo, mcp__google__writeSpreadsheet, mcp__google__copyFile, mcp__google__moveFile
argument-hint: "[Sheet URL or local md path] [--to-md | --to-sheet | --sync]"
---

# sheet-md-sync (English)

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first**.
> Activation: `mode != markdown-only` (skill is itself a Sheet ↔ md sync).

## Why

Sheet is the QA source-of-truth but has no git diff / PR review. The skill keeps both in sync without replacing either.

## Use When
- Sheet finalized → commit a md mirror into repo (Sheet → md)
- Local draft (`speckit-to-tc` output) → publish to Sheet (md → Sheet)
- Periodic sync to check divergence
- Find what changed in Sheet but not in md

## Don't Use For
- Just viewing Sheet content
- Both sides actively changing
- Diffing two Sheet versions (use `tc-version-diff`)

## Workflow

### Phase 1: Direction
- Sheet URL only → `--to-md`
- md path only → `--to-sheet`
- Both → `--sync` (diff report)
- Default: non-destructive — stop on conflict

### Phase 2: Read both sides
- Sheet via google MCP `readSpreadsheet`
- md via Read + table parsing (14 columns A-N)

### Phase 3: Sync rules

**Sheet → md**: write `tc-{feature}-{phase}.md` with frontmatter (sheet_url, sheet_id, last_synced, revision).

**md → Sheet**:
- New Sheet: `copyFile` from template `{{GSHEET_TC_TEMPLATE_ID}}` → rename → move to team folder
- Existing Sheet: diff, ask user, `writeSpreadsheet` only changed rows

**`--sync`**: produce a diff report; don't write either side.

### Phase 4: Update tc-index.md
Status, drive link, last_synced timestamp.

### Phase 5: Slack notification (per rules)

## Safety
- ✅ Touch only `tc-{feature}-{phase}.md` + `tc-index.md`
- ✅ md → Sheet **always asks confirmation**
- ✅ Frontmatter declares source-of-truth
- ❌ No auto-commit/push
- ❌ Don't touch status.審查紀錄 (that's `test-review`)
- ❌ Conflict → stop, ask user

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `google.tc_template_id` | Template for new Sheet | `createSpreadsheet` from scratch |
| `google.qa_tc_folder_id` | Default team folder | Ask interactively |
| `jira.boards[].drive_folder_id` | Per-team folder | Use `qa_tc_folder_id` |
| `mode = markdown-only` | Whole skill | **Skill disabled** |
