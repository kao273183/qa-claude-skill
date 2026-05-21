---
name: test-automation
description: Generate executable automation scripts from test cases (Google Sheet TC, JIRA ticket, feature description). Native iOS (Swift Testing + XCUITest) and Android (JUnit + Espresso + Mockk). Trigger phrases — "test automation", "generate UI tests", "automate test cases", "convert TC to code".
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__readSpreadsheet, mcp__google__getSpreadsheetInfo, mcp__google__writeSpreadsheet, mcp__atlassian__getJiraIssue
argument-hint: "[Google Sheet URL, JIRA key, feature description, or test file path]"
---

# test-automation (English)

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first**.
> If `mode = markdown-only` or google MCP unavailable, fall back per [`modules/markdown-fallback.md`](./modules/markdown-fallback.md).

## Scope

| | unit-test workflow | test-automation |
|---|-------------------|-----------------|
| Start | Source code | Test cases (Sheet/Markdown) |
| Perspective | Dev — verify code correctness | QA — verify behavior |
| Range | Unit only | Unit + UI + Integration |
| Platform | Single | iOS + Android |
| **Flutter projects** | — | Use `flutter-test-automation` |

## Workflow

### Phase 1: Input
1. Google Sheet URL — read TC, filter Col L = Y
2. JIRA key (`{{JIRA_PROJECT_KEY}}-XXXX`) — fetch via Atlassian MCP
3. Feature description — analyze
4. Markdown TC path — parse 14-column table
5. No arg — ask

### Phase 2: ROI Assessment

| Factor | Automate | Skip |
|--------|----------|------|
| Frequency | Every release | One-time |
| Stability | Stable UI/flow | Volatile UI |
| Complexity | Programmable | Visual / UX judgment |
| Maintenance | Stable locators (accessibilityIdentifier) | Dynamic content |
| Category | Smoke, functional, E2E | a11y, compatibility |

ROI formula: `(manual_time × executions) / (dev_time + maint_time × versions)`
- ROI > 3 → Automate
- 1-3 → Depends on resources
- < 1 → Skip

### Phase 3: Platform Detection
- iOS: `*.xcodeproj`, `Package.swift`
- Android: `build.gradle`, `build.gradle.kts`

If `platforms.{ios,android}.repo` set, pull patterns from remote; otherwise from local project.

### Phase 4: Script Generation

| TC Category | Test Type | iOS Framework | Android Framework |
|-------------|-----------|---------------|-------------------|
| Smoke (4-phase) | UI Test | XCUITest | Espresso |
| Functional | Unit + UI | Swift Testing + XCUITest | JUnit + Espresso |
| Boundary/Exception | Unit | Swift Testing | JUnit + Mockk |
| E2E | UI | XCUITest | Espresso |
| Performance | Performance | XCTest.measure | Benchmark |
| Concurrency (TSAN) | Unit | Swift Testing + Actor | JUnit + Coroutines |
| API verification | Unit | Swift Testing + Stub | JUnit + Mockk |

See [`ios-patterns.md`](./ios-patterns.md) and [`android-patterns.md`](./android-patterns.md).

Principles:
- AAA / Given-When-Then for unit tests
- Page Object Model for UI tests
- Method names from TC title (Column E); TC ID in comment
- Steps → test body, expected → assertions
- Preconditions → test setup / page object navigation

### Phase 5: Integrate & Verify
- iOS placement: `{ProjectName}Tests/` or `{ProjectName}UITests/`
- Android placement: `app/src/test/` or `app/src/androidTest/`
- Compile: `xcodebuild build-for-testing` / `./gradlew compileDebugUnitTest`
- Run tests
- Write back to Sheet (Col L = Y, Col M = file path)

### Phase 6: Completion Report

7-tab Google Sheet. See [`report-template.md`](./report-template.md).
Upload to `{{GDRIVE_QA_FOLDER_ID}}`.
Markdown-only → `.claude/testing/automation/{feature}/report.md`.

## Quality Checks

- [ ] Every script references its TC ID
- [ ] UI tests use Page Object (no raw locators in bodies)
- [ ] Unit tests use Stub/Mock — no real network/DB
- [ ] Behavior-revealing names (no `test1`/`test2`)
- [ ] Preconditions handled
- [ ] Specific assertions, not "not nil"

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `google.qa_tc_folder_id` | Upload report | Local `.md` instead |
| `platforms.{ios,android}.repo` | Remote pattern source | Local project only |
| `mode = markdown-only` | Whole skill mode | `.md` everywhere |
