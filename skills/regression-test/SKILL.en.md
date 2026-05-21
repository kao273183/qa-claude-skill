---
name: regression-test
description: Generate cross-platform (iOS + Android) regression test plans for each release. Pulls release tickets and recent 3-version critical/recurring bugs from JIRA, runs risk assessment, generates regression sheet in Google Sheets and estimates testing days. Trigger phrases — "regression test", "release test", "release QA", "version test plan", "what should I test for this release", "QA checklist".
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__atlassian__searchJiraIssuesUsingJql, mcp__atlassian__getJiraIssue, mcp__google__createSpreadsheet, mcp__google__writeSpreadsheet, mcp__google__readSpreadsheet, mcp__google__copyFile, mcp__google__getSpreadsheetInfo, mcp__google__moveFile, mcp__google__createFolder
argument-hint: "[Release version, e.g. 1.9.0]"
---

# regression-test (English)

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first**.
> If `mode = markdown-only` or google MCP unavailable, see [`modules/markdown-fallback.md`](./modules/markdown-fallback.md).

## Workflow

### Phase 1: Collect Release Info
1. Confirm version (e.g. `1.9.0`)
2. Pull release tickets:
   ```
   project = {{JIRA_PROJECT_KEY}} AND fixVersion ~ "{version}" ORDER BY priority DESC
   ```
3. Classify by impacted module
4. Mark platform (iOS / Android / Both) from labels and `jira.boards`

### Phase 2: Historical Bug Analysis
1. Pull last-3-version bugs:
   ```
   project = {{JIRA_PROJECT_KEY}} AND issuetype = Bug
   AND priority in (Highest, High, Medium)
   AND created >= -90d ORDER BY priority DESC
   ```
2. Identify recurring problems (same module ≥ 2 occurrences)
3. Identify regression bugs (resolved → reopened)
4. Aggregate bug density per module

### Phase 3: Risk Assessment

| Factor | High | Medium | Low |
|--------|------|--------|-----|
| Change size | Many adds/edits | Some edits | None |
| Historical bug density | ≥3 Major+ | 1-2 | 0 |
| Business criticality | Login/payment/order/member | Main feature | Secondary |
| Cross-platform impact | Both affected | One platform | None |
| Recurrence history | Yes | - | No |

Overall risk = max of any factor.

### Phase 4: Generate Regression Sheet
Copy template `{{GSHEET_REGRESSION_TEMPLATE}}` or `createSpreadsheet` from scratch.

5 tabs: 風險總覽 / 變更清單 / 回歸測試用例 / 歷史Bug風險分析 / 測試總覽

Core fixed items (per `config.regression.core_items`) prefilled; version-specific items inserted in the version block.

JIRA link formula:
```
=HYPERLINK("{{JIRA_INSTANCE_URL}}/browse/{{JIRA_PROJECT_KEY}}-xxxx", "{{JIRA_PROJECT_KEY}}-xxxx")
```

Section headers must use `valueInputOption: RAW` to avoid `#ERROR!` parsing.

### Phase 5: Time Estimate
- P0: 0.5d each / P1: 0.3d / P2: 0.2d
- Per-platform totals
- × 1.2 buffer
- Suggested order: Smoke → High-risk → New features → Bug fixes → Recurring

### Phase 6: Upload & Notify
- Upload to `{{GDRIVE_QA_FOLDER_ID}}/Release {version}/`
- Slack notification per `slack.notification_rules.regression_published`:
  - `channel` → `{{SLACK_RELEASE_CHANNEL_ID}}`
  - `dm` → `{{SLACK_USER_ID}}`

## Quality Checks
- [ ] Smoke covers all core flows
- [ ] All bug fixes have verification items
- [ ] High-risk modules have ≥3 items each
- [ ] iOS/Android platforms marked correctly
- [ ] Recurring problems included
- [ ] Time estimate reasonable with buffer

## Integration
- Regression finds bug → `bug-report` skill
- Deep-dive on feature → `test-master` skill
- Review quality → `test-review` skill
- Publish results → `publish-regression` skill

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `google.regression_template_id` | Regression template | `createSpreadsheet` from scratch |
| `google.qa_tc_folder_id` | Upload target | Prompt manual move |
| `jira.boards` | Team / platform allocation | Prompt user |
| `slack.release_channel_id` | Release notification | No channel notification |
| `mode = markdown-only` | Whole-skill mode | Produce `.md` plan |
