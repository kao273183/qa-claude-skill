---
name: tc-version-diff
description: Diff two TC versions (v0.x → v0.y) and produce changelog + retest checklist + auto-write to status sheet review history. Trigger phrases — "TC version diff", "TC bump", "compare v0.2 v0.3", "which TCs to rerun", "retest checklist". Pair with test-review (pre-bump audit), test-master (expand on bump), tc-to-pytest (sync API TC bump).
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__readSpreadsheet, mcp__google__getSpreadsheetInfo, mcp__google__writeSpreadsheet
argument-hint: "[v_old Sheet/file] [v_new Sheet/file]"
---

# tc-version-diff (English)

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first**.
> If `mode = markdown-only`, skip Sheet ops; pure markdown diff.

## Use When
- TC bumps (v0.2 → v0.3) — generate changelog
- Spec changes after Sprint review — see which rows affected
- Pre-release sanity: did latest TC bump cover everything?

## Don't Use For
- First draft (use `test-master`)
- Module-wide rewrite (use `test-master` upgrade flow)
- Typo fixes — just edit

## Workflow

### Phase 1: Sources
- Two Sheet URLs / two markdown files / single Sheet + auto-find prior version

### Phase 2: ID-key dict
Build `{id: row_data}` per BB/WB; ignore blanks and status tab.

### Phase 3: Classify

| Type | Rule | Action |
|------|------|--------|
| 🆕 Added | id in new not old | Must retest |
| 🗑️ Removed | id in old not new | Verify intentional |
| ✏️ Modified | same id, content changed | See below |
| ✅ Unchanged | identical | Skip retest |

Modified breakdown by column changed:
- Expected K → must retest (acceptance changed)
- Steps J / Preconditions I / Platform H → mid impact, retest
- Title / Notes / Automation flag → low impact

### Phase 4: Changelog
Write `tc-changelog-v{old}-v{new}.md` with Added / Modified (by severity) / Removed / Retest checklist / pytest mapping.

### Phase 5: Write status sheet
Append row to `status.審查紀錄`:
```
{date} | tc-version-diff | — | — | — | — | v0.2 → v0.3: +N BB / +M WB / N retest
```

### Phase 6: Slack notification
Per `slack.notification_rules.tc_version_diff`.

## Safety
- ✅ Write only `tc-changelog-*.md` and append to status sheet
- ❌ Don't touch BB/WB main tabs
- ❌ Don't auto-run retests
- ❌ Don't auto-modify pytest (use `tc-to-pytest --incremental`)

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `mode = markdown-only` | Whole skill | .md only, no sheet writeback |
| `slack.notification_rules.tc_version_diff` | Notify | Skip Slack |
