---
name: bug-report
description: Help draft standardized, reproducible bug reports (RIDER format). Supports interactive Q&A, root-cause analysis, automatic JIRA ticket creation, and Slack DM notifications. Can batch-generate bug reports from Google Sheet test cases. Trigger phrases — "write a bug report", "file a bug", "report this issue", "create JIRA bug", or when a test fails and needs to be recorded.
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__atlassian__createJiraIssue, mcp__atlassian__searchJiraIssuesUsingJql, mcp__atlassian__addCommentToJiraIssue, mcp__google__readSpreadsheet, mcp__google__getSpreadsheetInfo, mcp__google__writeSpreadsheet
argument-hint: "[problem description OR Google Sheet URL]"
---

# bug-report (English)

> ⚙️ **Read `modules/config-loader.md` first** to load org settings (JIRA / Slack / platform defaults).
> If `config.json` is missing or `mode = markdown-only`, skip all MCP calls and follow [`modules/markdown-fallback.md`](./modules/markdown-fallback.md).

## RIDER Format

Bug reports follow the 5-part RIDER format. See [`rider-format.md`](./rider-format.md) for details.

| Element | Content |
|---------|---------|
| **R**eproduction Steps | Preconditions + numbered steps |
| **I**mpact | Severity (Blocker/Critical/Major/Minor) + scope |
| **D**evice/Environment | Platform, OS, device, app version, env, network |
| **E**xpected vs Actual | Expected behavior vs actual (with error messages) |
| **R**eferences | Screenshots, video, console log, related tickets, root cause |

## Execution Modes

### Mode 1: Interactive Q&A (default)
Run Phase 1 → 6 sequentially. Each phase must complete before moving on.

### Mode 2: Fast mode (user provides full info up-front)
Parse → Phase 2 dedupe → Phase 3 RCA → Phase 4 create JIRA → Phase 5 sync → Phase 6 follow-up.

### Mode 3: Batch from Google Sheet test cases
Requires `config.json#mode != markdown-only` and `google.qa_tc_folder_id` set.

1. Read Google Sheet (status sheet + test-case sheet)
2. Filter rows where Column C = Fail
3. Skip rows where Column N already has a JIRA ticket
4. Run Phase 2~4 for each Fail row
5. Write ticket key back to Column N
6. Send Slack DM summary (per `slack.notification_rules.bug_report`)

---

## 6-Phase Workflow

### Phase 1: Information gathering

| Field | Required | Note |
|-------|----------|------|
| Platform | ✅ | iOS / Android |
| Device model | ✅ | Default iOS: `{{IOS_DEFAULT_DEVICE}}`, Android: `{{ANDROID_DEFAULT_DEVICE}}` |
| OS version | ✅ | Default iOS: `{{IOS_DEFAULT_VERSION}}`, Android: `{{ANDROID_DEFAULT_VERSION}}` |
| App version | ✅ | Auto-detect from iOS xcconfig / Android build.gradle |
| Environment | ✅ | Production / Staging / UAT |
| Network | ⚠️ | Required for network-related bugs |
| Login state | ⚠️ | Required for auth-related bugs |
| Install type | ⚠️ | Required for data-migration bugs |
| Locale | ⚠️ | Required for UI/i18n bugs |

### Phase 2: Dedupe

```
JQL: project = {{JIRA_PROJECT_KEY}} AND summary ~ "<keyword>" AND status != Done ORDER BY created DESC
JQL: project = {{JIRA_PROJECT_KEY}} AND parent = {{JIRA_PROJECT_KEY}}-XXXX AND issuetype = Bug ORDER BY created DESC
```
- Match found → comment on existing ticket, don't create new
- Similar found → create new, reference existing in description

### Phase 3: Root Cause Analysis

Depth determined by `config.json#workflow.auto_root_cause_depth`:

| Platform | `deep` | `suggestion-only` |
|----------|--------|-------------------|
| iOS | Inspect code with file:line refs | Only causes & fix suggestions |
| Android | Inspect code with file:line refs | Only causes & fix suggestions |

### Phase 4: Create JIRA Ticket

| Field | Value |
|-------|-------|
| Project | `{{JIRA_PROJECT_KEY}}` |
| Issue Type | Bug (id: `{{JIRA_BUG_ISSUE_TYPE_ID}}`) |
| Priority | Per `jira.priority_mapping` |
| Reviewer | `{{JIRA_REVIEWER_FIELD}}` = `{{JIRA_REVIEWER_ACCOUNT_ID}}` |

### Phase 5: Sync

- Write back to Google Sheet (if from test case)
- Slack notifications per `slack.notification_rules.bug_report`
- Cross-platform suggestion (if `auto_cross_platform_check = true`)
- a11y pairing (if `auto_a11y_pairing = true`)

### Phase 6: Follow-up

After ticket creation, remind the user:
1. Re-test after fix
2. Update Google Sheet (Fail → Pass) once verified
3. If no test case exists for this scenario, invoke `test-master`

## Quality Checks

- [ ] Reproduction steps are clear and executable
- [ ] Expected vs actual is unambiguous
- [ ] Environment info is complete
- [ ] Severity matches scope
- [ ] No subjective language ("slow" → ">5s")
- [ ] No sensitive data (passwords, tokens → `[REDACTED]`)
- [ ] Phase 2 dedupe has been run

## See Also

- [`templates.md`](./templates.md) — JIRA description + interactive templates
- [`examples.md`](./examples.md) — full conversation samples
- [`modules/`](./modules/) — pluggable integrations (JIRA / Slack / Markdown-fallback)
