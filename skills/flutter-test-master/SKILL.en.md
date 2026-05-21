---
name: flutter-test-master
description: End-to-end test planning + test case generation tailored for Flutter apps. Covers Flutter's 3-tier (Unit/Widget/Integration) pyramid, Golden tests, Platform Channel tests, BB/WB TC sheets, architecture-aware strategy, Fake-over-Mock samples, cross-iOS+Android verification, and Firebase Test Lab / CI integration. Trigger phrases — "Flutter test plan", "flutter test", "widget test", "integration_test", "Dart test", "Flutter test cases", "golden test", "Flutter QA". Coexists with test-master — pick this when the target is Flutter/Dart or Flutter+Native hybrid.
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__atlassian__getJiraIssue, mcp__atlassian__searchJiraIssuesUsingJql, mcp__google__createSpreadsheet, mcp__google__writeSpreadsheet, mcp__google__copyFile, mcp__google__moveFile, mcp__google__createFolder, mcp__google__getSpreadsheetInfo
argument-hint: "[JIRA key or feature description] [--mode=quick|deep]"
---

# flutter-test-master (English)

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first**.
> Activation condition: `config.platforms.flutter.enabled = true`.
> If `mode = markdown-only` → see [`modules/markdown-fallback.md`](./modules/markdown-fallback.md).

Generates a complete Flutter test plan + test cases. Uses Flutter's official 3-tier pyramid + generic QA workflow (Google Sheet TC + JIRA integration + dual-platform verification).

## When to Use

- ✅ Feature implemented in Flutter/Dart (incl. Flutter + Native hybrid)
- ✅ Widget Test or Integration Test (`integration_test`)
- ✅ Golden Test (visual regression)
- ✅ Platform Channel / Plugin tests
- ✅ Pure Dart packages

**Use `test-master` instead for:** pure Swift/SwiftUI iOS or pure Kotlin/Compose Android.

**Hybrid:** use both skills — `flutter-test-master` for Flutter layer, `test-master` for Native layer.

## The 3 Tiers

| Tier | Package | Goal | Share |
|------|---------|------|-------|
| Unit | `test` / `flutter_test` | Single function/class logic, all deps mocked | 70% |
| Widget | `flutter_test` (WidgetTester) | Single widget UI + interaction, no full app | 20% |
| Integration | `integration_test` + Patrol | E2E, routing, DI, critical flows, native dialogs | 10% |

## Recommended Tech Stack

| Use | Tool | Notes |
|-----|------|-------|
| Unit | `flutter_test` + Fake | Fake over Mock |
| Widget | `flutter_test` + `WidgetTester` | Inject Fake ViewModel |
| E2E (pure Flutter) | `integration_test` | Official, lightweight |
| E2E (with native) | Patrol | Permissions/notif/WiFi/biometric/cross-app |
| Golden | `flutter_test` + `alchemist` (opt.) | Dual-platform baseline |

**❌ Excluded:** Appium, flutter_driver (deprecated), Appium Flutter Driver / Integration Driver.

**Key principles:**
- ⭐ Fake over Mock
- ⭐ ViewModel doesn't depend on Flutter framework
- ⭐ View injects Fake (ViewModel + Repository)
- ⭐ Pick `integration_test` first; escalate to Patrol only when native is needed

## Workflow

### Phase 1: Requirement Analysis
1. JIRA key (`{{JIRA_PROJECT_KEY}}-XXXX`) or feature description + architecture (Provider/Riverpod/BLoC/GetX)
2. Detect architecture from `pubspec.yaml`, view_models, repositories, MethodChannel usage
3. Risk scoring — money/auth/FIDO2 → P0; Platform Channel; animations; Isolate

### Phase 2: Strategy
Generate `flutter-test-strategy.md`. See [`templates.md`](./templates.md).

### Phase 3: TC Generation
Copy template `{{GSHEET_TC_TEMPLATE_ID}}` → BB + WB Google Sheets.

Distribution: Unit 30% / Widget 25% / Integration 15% / Boundary 15% / Error 10% / Golden 5%.

a11y mandatory (see [`templates.md`](./templates.md)).

### Phase 4: Coverage Gap Analysis
Scan `test/**/*_test.dart`, `integration_test/**/*_test.dart`, `test/golden/`.

### Phase 5: Code Skeleton
Output Dart skeletons:
```
test/
├── unit/{view_models,repositories}/
├── widget/
├── golden/
└── fakes/
integration_test/
```

### Phase 6: CI / Firebase Test Lab

### Phase 7: Exploratory Guide
Focus: hot-reload residual state, Isolate, Platform Channel, pixel diffs.

### Phase 8: Upload
To `{{GDRIVE_QA_FOLDER_ID}}/[Flutter] [feature]/`.

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `platforms.flutter.enabled` | Activates skill | Suggests `test-master` |
| `google.tc_template_id` | Sheet template | `createSpreadsheet` from scratch |
| `google.qa_tc_folder_id` | Upload target | Prompt manual move |
| `workflow.auto_a11y_pairing` | a11y pairing | No auto-pair |
| `mode = markdown-only` | Whole-skill mode | No google MCP |
