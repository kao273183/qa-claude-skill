---
name: smoke-test-analyzer
description: "Analyze existing automated tests (iOS + Android) to select which should run in Daily Smoke CI. Scans unit and UI tests across both platforms, scores each for smoke suitability, classifies into tiers (PR Smoke / Daily / Release / Manual), and generates CI configurations (.xctestplan for iOS, Gradle filters for Android). Use whenever the user mentions 'smoke test', 'daily test', 'CI test selection', 'which tests should run daily', 'optimize CI', 'test plan config', 'flaky test analysis', or wants to curate which automated tests belong in the daily smoke suite. Also trigger when discussing CI pipeline optimization or test execution time budgets."
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__createSpreadsheet, mcp__google__writeSpreadsheet, mcp__google__moveFile
argument-hint: "[optional: platform (ios/android/both) or specific test directory]"
---

# smoke-test-analyzer

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first**.
> If `mode = markdown-only`, output reports to local `.md` instead of Google Sheet.

Analyze existing automated tests to curate the optimal Daily Smoke subset for CI. Supports iOS and Android.

## Why This Matters

Running all tests on every CI trigger is wasteful. A well-tiered test suite catches 90% of regressions in 10% of the time by running the right tests at the right frequency.

## Test Tiers

| Tier | When | Time Budget | What Belongs Here |
|------|------|-------------|-------------------|
| **T0: PR Smoke** | Every PR | < 3 min | Critical path, zero flakiness tolerance |
| **T1: Daily Smoke** | Daily cron | < 10 min | Core business logic + key UI flows |
| **T2: Release** | Pre-release | < 60 min | Full regression, edge cases, slow tests |
| **T3: Manual** | On-demand | Unlimited | Exploratory, visual, accessibility |

> Time budgets adjustable via `config.smoke.time_budgets`.

## Platform Detection

Auto-detect based on project files:
- **iOS**: `*.xcodeproj`, `{ProjectName}Tests/`, `{ProjectName}UITests/`, `*.xctestplan`
- **Android**: `build.gradle(.kts)`, `src/test/`, `src/androidTest/`

If both detected, analyze both and produce a cross-platform summary.

> 可從 `config.platforms.{ios,android}.test_dirs` 自訂掃描目錄。

## 4-Phase Execution

### Phase 1: Scan & Inventory

Collect all test files and count methods per file.

**iOS**: Scan `{ProjectName}Tests/`, `{ProjectName}UITests/`, internal Swift package `Tests/` dirs. Count `@Test` and `func test*`. Read existing `*.xctestplan` to understand current CI membership.

**Android**: Scan `app/src/test/`, `app/src/androidTest/`. Count `@Test`. Check Gradle test tasks and CI workflows for current configuration.

Output an inventory table:

| Platform | File | Methods | Type (Unit/UI) | Current CI Plan |
|----------|------|---------|-----------------|-----------------|

### Phase 2: Smoke Suitability Scoring

Score each **test file** on 5 weighted criteria (1-5 scale). See [`references/scoring-heuristics.md`](./references/scoring-heuristics.md) for detailed signals and examples.

| Criteria | Weight | High Score (5) | Low Score (1) |
|----------|--------|----------------|---------------|
| Criticality | 30% | Login, Home, Payment | Cosmetic, edge case |
| Speed | 25% | Pure logic, < 1s | I/O dependent, > 10s |
| Stability | 25% | Deterministic | sleep(), timing-dependent |
| Independence | 10% | No shared state | Singletons, ordering |
| Coverage Value | 10% | High-traffic path | Rarely-used feature |

**Tier assignment by score:**
- >= 4.0 → T0 | 3.0-3.9 → T1 | 2.0-2.9 → T2 | < 2.0 → T3

### Phase 3: Classification & Recommendation

Present scored results grouped by tier, per platform. Include:
- T0/T1/T2/T3 tables with file, methods, score, rationale
- Cross-platform summary (tier counts + method counts per platform)
- Flaky risk report (flagged tests with issue + fix suggestion)

Ask user to review and adjust before generating configs.

### Phase 4: Generate CI Configuration

Based on user-confirmed tiers, generate platform-specific configs.

- **iOS**: see [`references/ios-config.md`](./references/ios-config.md) for `.xctestplan` format and CI workflow snippets
- **Android**: see [`references/android-config.md`](./references/android-config.md) for Gradle filter / `@Tag` / Suite options

Output per platform:
1. CI test configuration file (`.xctestplan` or Gradle config)
2. CI workflow snippet (GitHub Actions yaml)
3. Flaky test fix recommendations

If both platforms, also generate a **Google Sheet** (4 tabs: Summary / iOS Detail / Android Detail / Flaky Report). Upload target: `{{GDRIVE_QA_FOLDER_ID}}/CI Smoke Plan/`.

> Markdown-only mode: write `.claude/testing/ci-smoke/report.md` and per-platform `*.md` reports instead of Sheet.

## Quality Checks

- Every T0 test must be deterministic (no sleep, no timing dependency)
- T0+T1 total < 10 min per platform (依 `config.smoke.time_budgets`)
- No T0 test depends on network or external service
- Existing CI coverage not regressed (T2 tests still run somewhere)
- Same core business flows covered on both platforms

## When to Re-run

- New test files added (monthly or per-feature)
- Flaky tests identified in CI logs
- CI execution time exceeds budget
- After `test-automation` generates new scripts

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `platforms.{ios,android}.test_dirs` | Test scan directories | Use defaults |
| `smoke.time_budgets` | T0/T1/T2 minute budgets | Default 3/10/60 |
| `smoke.scoring_weights` | Override 5-criterion weights | Use defaults |
| `google.qa_tc_folder_id` | Sheet upload target | Markdown only |
| `mode = markdown-only` | Whole skill mode | No Sheet output |
