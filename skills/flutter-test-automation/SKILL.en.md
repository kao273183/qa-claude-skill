---
name: flutter-test-automation
description: Generates executable Dart automation scripts for Flutter apps from manual TCs. Covers Unit (flutter_test), Widget (WidgetTester), Integration (integration_test), Golden, and Platform Channel tests. Uses Fake-over-Mock, Robot Pattern / POM, mocktail/mockito; integrates with Firebase Test Lab and `flutter test --coverage`. Trigger phrases — "Flutter automation", "write Dart tests", "convert Flutter TC to code", "widget test automation", "integration_test script", "Flutter UI test", "patrol test", "Golden test automation". Coexists with test-automation — pick this for Flutter/Dart or Flutter+Native hybrid.
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__readSpreadsheet, mcp__google__getSpreadsheetInfo, mcp__google__writeSpreadsheet, mcp__atlassian__getJiraIssue
argument-hint: "[Google Sheet URL, JIRA key, feature description, or Dart test file]"
---

# flutter-test-automation (English)

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first**.
> Activation: `config.platforms.flutter.enabled = true`.
> If `mode = markdown-only` → see [`modules/markdown-fallback.md`](./modules/markdown-fallback.md).

Generates executable Dart automation scripts from manual TCs. Three-tier pyramid (Unit → Widget → Integration).

## When to Use

- ✅ Flutter/Dart projects
- ✅ Flutter + Native hybrid (Flutter layer)
- ✅ Widget / Integration / Golden automation needed
- ✅ Platform Channel scripts

**Use `test-automation` instead** for pure Swift iOS or pure Kotlin Android.

## Workflow

### Phase 1: Input
1. Google Sheet URL → filter Col L = Y
2. JIRA key (`{{JIRA_PROJECT_KEY}}-XXXX`)
3. Feature description
4. Existing Dart file path → fill gaps
5. Markdown TC path
6. No arg → ask

### Phase 2: ROI

| Factor | Automate | Skip |
|--------|----------|------|
| Frequency | Every commit/PR | One-time |
| Stability | Stable Keys | Volatile UI |
| Layer | Unit / Widget / Integration | Visual judgment |
| Locator | `ValueKey`/`Key` | Dynamic text/position |
| Cross-platform | Dart runs both | Goldens need 2 baselines |

ROI > 3 → automate; 1-3 → depends; < 1 → skip.

### Phase 3: Project Detection
- `pubspec.yaml`, state management, mock library, existing test directories
- Pattern scan: view_models, repositories, fakes, test_driver

### Phase 4: Generation Strategy

| TC Category | Test Type | Tool | Location |
|-------------|-----------|------|----------|
| Smoke-Feature Done | Integration | `integration_test` | `integration_test/smoke/` |
| Functional | Unit + Widget | `flutter_test` | `test/unit/`, `test/widget/` |
| Boundary/Error | Unit | `flutter_test` + Fake | `test/unit/` |
| Widget Test | Widget | `flutter_test` (WidgetTester) | `test/widget/` |
| Integration (pure Flutter) | Integration | `integration_test` | `integration_test/` |
| Integration (with native) | Integration | Patrol | `integration_test/patrol/` |
| Platform Channel | Unit + Native | `flutter_test` + XCTest/JUnit | `test/unit/services/`, native |
| Golden | Widget | `flutter_test` + `matchesGoldenFile` | `test/golden/` |
| API verification | Unit | `flutter_test` + Mock HTTP | `test/unit/repositories/` |

### integration_test vs Patrol Decision Tree

```
System dialog (permission)? → Patrol
Push permission?            → Patrol
Cross-app flow?             → Patrol
WiFi/network control?       → Patrol
Biometric?                  → Patrol
Otherwise                   → integration_test (lighter)
```

Principles — see [`flutter-patterns.md`](./flutter-patterns.md):
- ⭐ Fake over Mock for ViewModel/View tests
- ⭐ Robot / Page Object pattern
- ⭐ AAA / Given-When-Then
- ⭐ `ValueKey` locators
- ⭐ TC ID in method comment
- ⭐ `pumpAndSettle` after async

### Phase 5: Integrate & Verify
- Compile: `dart analyze` / `flutter analyze`
- Run: `flutter test`, `flutter test integration_test/`, `flutter test --update-goldens`
- Write back Sheet (Col L = Y, Col M = file path)

### Phase 6: CI Output
GitHub Actions / Firebase Test Lab snippets in [`SKILL.md`](./SKILL.md).

### Phase 7: Completion Report
7-tab Sheet → `{{GDRIVE_QA_FOLDER_ID}}`. Markdown-only → `.claude/testing/automation/{feature}-flutter/report.md`.

## Quality Checks

- [ ] Every test has TC ID in comment
- [ ] Widget/Integration uses Robot or POM
- [ ] No real network/DB in unit tests
- [ ] Behavior-revealing names
- [ ] `ValueKey` locators
- [ ] `setUp()` for preconditions
- [ ] `pumpAndSettle()` after async
- [ ] Specific assertions
- [ ] Fake-over-Mock for VM/View
- [ ] Dual-platform Golden baselines

## Excluded Tools

| Tool | Reason |
|------|--------|
| Appium | Flutter canvas — widget tree invisible |
| flutter_driver | Deprecated |
| Appium Flutter Driver | Unstable across Flutter versions |
| Maestro (primary) | Less Flutter-aware than Patrol |

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `platforms.flutter.enabled` | Activates skill | Suggests `test-automation` |
| `google.qa_tc_folder_id` | Upload target | Local `.md` |
| `mode = markdown-only` | Whole-skill | No google MCP |
