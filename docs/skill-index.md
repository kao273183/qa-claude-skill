# Skill 速查表

15 個 QA 專業 Skill — 觸發詞 / 主要產出 / 串接關係速查。

## 📋 按類別查

### 🎯 測試設計（8 個）

| Skill | 中文觸發詞 | English Triggers | 主要產出 |
|-------|----------|------------------|---------|
| `test-master` | 生成測試計劃 / 設計測試 / 完整測試方案 / 寫測試案例 | "generate test plan", "design tests", "test plan" | BB+WB Google Sheet + strategy.md + coverage-gaps.md + automation-plan.md + exploratory-guide.md |
| `flutter-test-master` | Flutter 測試計劃 / widget test / Dart 測試 / Golden test | "Flutter test plan", "widget test", "integration_test", "Dart test" | 同上 + Dart code skeleton |
| `test-review` | 審查測試 / review 測試案例 / 測試品質 / test review | "review tests", "review test cases", "test quality" | 10 維度評分 .md + 寫回 status sheet |
| `regression-test` | 回歸測試 / release 測試 / 版本測試計劃 | "regression test", "release test", "version test plan" | 5-tab 回歸 Sheet + 時間估算 |
| `speckit-to-tc` | 從 spec 草 TC / draft TC from spec | "draft TC from spec", "speckit to TC" | `tc-be-{KEY}-draft.md` |
| `tc-version-diff` | TC 版本 diff / TC 升版 / 比對 v0.2 v0.3 / 補測清單 | "TC version diff", "compare v0.2 v0.3", "retest checklist" | `tc-changelog-v{old}-v{new}.md` |
| `sheet-md-sync` | Sheet 變 md / md 上 Sheet / TC 進 repo | "Sheet to md", "md to Sheet", "TC into repo" | `tc-{feature}.md` 同步 |
| `smoke-test-analyzer` | smoke test / daily test / CI test selection / 哪些測試該 daily 跑 | "smoke test", "daily test", "CI test selection" | `.xctestplan` / Gradle config + 4-tab Sheet |

### 🤖 自動化（3 個）

| Skill | 中文觸發詞 | English Triggers | 主要產出 |
|-------|----------|------------------|---------|
| `test-automation` | 自動化測試 / UI test 腳本 / 把 TC 轉成程式碼 | "test automation", "generate UI tests", "convert TC to code" | iOS XCUITest / Android Espresso 腳本 + 7-tab 完成度報表 |
| `flutter-test-automation` | Flutter 自動化 / 寫 Dart 測試 / widget test 自動化 / integration_test 腳本 | "Flutter automation", "write Dart tests", "Flutter UI test", "patrol test" | Dart 三層測試 + Golden + Platform Channel |
| `tc-to-pytest` | TC 轉 pytest / Sheet 變測試碼 / 把白箱 TC 變 pytest | "TC to pytest", "Sheet to test code", "white-box TC → pytest" | `schemas.py` + `conftest.py` + `tests/test_*_api.py` |

### 🐛 Bug 管理（1 個）

| Skill | 中文觸發詞 | English Triggers | 主要產出 |
|-------|----------|------------------|---------|
| `bug-report` | 寫 bug 報告 / 回報問題 / 記錄 bug / 開 bug 單 | "write a bug report", "file a bug", "report this issue", "create JIRA bug" | JIRA ticket + Slack 通知 + RIDER 格式 .md |

### 🧪 品質量化（2 個）

| Skill | 中文觸發詞 | English Triggers | 主要產出 |
|-------|----------|------------------|---------|
| `mutation-testing` | 變異測試 / TC 真實覆蓋 / 我的測試夠不夠強 / mutmut | "mutation testing", "TC strength", "mutmut" | `~/.local/share/qa-mutation/{feature}/report-{date}.md` + 補測清單 |
| `property-based-test-gen` | property-based testing / hypothesis / fuzz test / 邊界自動掃 | "property-based testing", "hypothesis", "fuzz test", "boundary scan" | `tests/test_<feature>_property.py` |

### 📤 報告發布（1 個）

| Skill | 中文觸發詞 | English Triggers | 主要產出 |
|-------|----------|------------------|---------|
| `publish-regression` | 發布回歸 / 上傳回歸報告 / push regression to S3 / update dashboard | "publish regression", "upload regression report", "update dashboard" | S3 HTML 報告 + CloudFront invalidation + Slack 通知 |

---

## 🔗 按工作流查（Skill 串接）

### 工作流 1: 規格 → TC → pytest 的完整 BE pipeline

```
規格 ticket close
   ↓
speckit-to-tc          產出 tc-be-{KEY}-draft.md
   ↓
test-review            審查草稿（10 維度評分）
   ↓
sheet-md-sync          正式上 Google Sheet
   ↓
tc-to-pytest           白箱段轉 pytest 三件套
   ↓
mutation-testing       量化 TC 抓 bug 能力
   ↓
property-based-test-gen  fuzz 封死 boundary 缺口
   ↓
release-ready
```

### 工作流 2: Release 前準備

```
test-master            為新功能規劃 TC
   ↓
test-automation        值得自動化的 TC 轉腳本
   ↓
smoke-test-analyzer    挑出哪些測試該 daily smoke
   ↓
regression-test        Release 前回歸計劃
   ↓
[執行測試]
   ↓
bug-report             失敗項目轉 JIRA
   ↓
publish-regression     報告上傳 S3 Dashboard
```

### 工作流 3: TC 升版

```
spec 變動
   ↓
test-master --mode=quick   補新 TC
   ↓
test-review            v0.3 自評
   ↓
tc-version-diff        v0.2 → v0.3 changelog + 補測清單
   ↓
tc-to-pytest --incremental  同步 pytest
   ↓
[執行補測]
   ↓
status sheet 自動更新
```

### 工作流 4: 純 markdown 模式（無 MCP / 單人開發者）

```
mode = markdown-only

test-master            產 .md（取代 Sheet）
   ↓
test-review            審查 .md
   ↓
test-automation        轉腳本（仍可運作）
   ↓
bug-report             產 bug-{slug}.md（取代 JIRA）
```

---

## 🎛 模式 × Skill 對照

| Skill | full-mcp | partial-mcp | markdown-only |
|-------|----------|-------------|---------------|
| `bug-report` | JIRA + Slack | 有什麼用什麼 | 寫 `./bugs/*.md` |
| `test-master` | Google Sheet | Sheet 或 .md | 純 .md |
| `test-review` | 寫回 status sheet | 偵測 MCP 自動切換 | 寫 `.claude/testing/reviews/*-summary.md` |
| `regression-test` | 5-tab Sheet | 同上 | `.claude/testing/regression/v{version}/*.md` |
| `test-automation` | 寫回 Sheet | 同上 | TC 來源用 .md，腳本仍生成 |
| `flutter-test-master` | Google Sheet | 同上 | 純 .md |
| `flutter-test-automation` | 寫回 Sheet | 同上 | TC 來源用 .md |
| `tc-to-pytest` | 讀 Sheet | 同上 | 讀 .md |
| `mutation-testing` | (不依賴 MCP) | (同) | (同) |
| `property-based-test-gen` | (不依賴 MCP) | (同) | (同) |
| `speckit-to-tc` | 抓 Jira ticket | 用 Jira 或 spec.md | 用 spec.md |
| `tc-version-diff` | 寫回 status sheet | 同上 | 純 .md diff |
| `sheet-md-sync` | 雙向同步 | 同上 | **skill 不啟用** |
| `smoke-test-analyzer` | Google Sheet | 同上 | 純 .md report |
| `publish-regression` | S3 + CloudFront | local_html 或 S3 | `.md` summary |
