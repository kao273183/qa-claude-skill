---
name: test-master
description: One-stop QA skill that generates full test plans, black-box/white-box test cases, automation roadmaps, and exploratory guides. Trigger phrases — "generate test plan", "design tests", "test cases for X", "test plan", or any request to plan testing for a new feature, refactor, bug fix, or release.
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__atlassian__getJiraIssue, mcp__atlassian__searchJiraIssuesUsingJql, mcp__google__createSpreadsheet, mcp__google__writeSpreadsheet, mcp__google__copyFile, mcp__google__moveFile, mcp__google__createFolder, mcp__google__getSpreadsheetInfo
argument-hint: "[JIRA key OR feature description]"
---

# test-master (English)

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first** to load org settings.
> If `config.json` is missing or `mode = markdown-only`, skip MCP and follow [`modules/markdown-fallback.md`](./modules/markdown-fallback.md).

## Workflow

### Phase 1: Requirement Analysis
1. Fetch requirement — JIRA key (`{{JIRA_PROJECT_KEY}}-XXXX`) via Atlassian MCP, otherwise ask the user
2. Flag empty descriptions as risk
3. Map impact across iOS (`{{IOS_REPO}}`) and Android (`{{ANDROID_REPO}}`)
4. Risk scoring — money/security/auth (high), concurrency/memory/network (technical), critical UX (business)

### Phase 2: Strategy
Generate `test-strategy.md`. See [`templates.md`](./templates.md).

### Phase 3: Test Case Generation
Create two Google Sheets (black-box + white-box) from template `{{GSHEET_TC_TEMPLATE_ID}}`.
- If template empty → `createSpreadsheet` from scratch
- If `mode = markdown-only` → write `.md` tables instead

**Distribution:** happy path 20% / boundary 30% / error handling 30% / concurrency 10% / non-functional 10%

**By feature type:**
- API → network errors, timeouts, 401/403/500, JSON parse
- UI → load/error/empty states, screen sizes, **a11y (see below)**
- Sync → concurrent writes, race conditions, TSAN
- IM/realtime → reconnect, offline sync, multi-device

**a11y (mandatory for every UI feature):**
- Font scaling (iOS Dynamic Type max / Android max font + display size)
  - Content text scales, layout intact
  - **Decorative numbers (counts, badges) must NOT scale**
- Screen readers — VoiceOver / TalkBack labels and reading order
- Touch targets — iOS ≥ 44×44pt / Android ≥ 48×48dp
- Contrast — text vs background ≥ 4.5:1 (dark mode too)
- Reduce Motion
- See [`templates.md`](./templates.md) → a11y-checklist

**Priorities:**
- P0 — core business flows (login/payment/order), data safety, high crash risk
- P1 — main features, high-frequency scenarios, error handling, **a11y layout breaks**
- P2 — secondary features, boundaries, non-functional

**Cross-platform a11y pairing** (when `workflow.auto_a11y_pairing = true`): file iOS + Android tickets together with Relates link.

### Phase 4: Coverage Gap Analysis
Scan existing tests:
- iOS: `*Tests.swift` / `*Test.swift`
- Android: `*Test.kt` / `*Tests.kt`

Diff new cases vs existing tests, identify gaps. See [`templates.md`](./templates.md).

### Phase 5: Automation Assessment
Criteria — repetition, runtime, complexity, stability, ROI. See [`templates.md`](./templates.md).

### Phase 6: Exploratory Guide
See [`templates.md`](./templates.md).

### Phase 7: Google Drive Upload
Only when `mode != markdown-only` and `google.qa_tc_folder_id` set.

1. Create feature subfolder under `{{GDRIVE_QA_FOLDER_ID}}`
2. Upload Sheets
3. Optionally upload other `.md` docs

## Output Files

```
.claude/testing/features/[feature-name]/
├── test-strategy.md
├── test-cases-{feature}-blackbox.xlsx  (Google Sheet)
├── test-cases-{feature}-whitebox.xlsx  (Google Sheet)
├── coverage-gaps.md
├── automation-plan.md
└── exploratory-guide.md
```

## Modes

- `--mode=quick` — Test case Sheets only
- `--mode=deep` — Full docs + Mock/Stub code samples
- default — All docs

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `google.tc_template_id` | Sheet template | Use `createSpreadsheet` from scratch |
| `google.qa_tc_folder_id` | Target folder | Prompt user to move manually |
| `platforms.{ios,android}.repo` | Code impact analysis | Skip, ask user for paths |
| `workflow.auto_a11y_pairing` | Auto-pair a11y tickets | No auto-pair |
| `mode = markdown-only` | Whole skill mode | No MCP, `.md` output only |

## Next Steps After Generation

1. Generate automation code? (→ `test-automation` skill)
2. Sync test plan to JIRA?
3. Review TC quality? (→ `test-review` skill)
