---
name: flutter-test-master
description: 專為 Flutter 應用量身打造的完整測試計劃與測試用例生成 Skill。生成 Flutter 三層測試（Unit/Widget/Integration）、Golden Test、Platform Channel 測試、黑箱/白箱 TC（Google Sheet）、架構測試策略、Fake-over-Mock 實作範例、跨 iOS+Android 驗證策略、以及 Firebase Test Lab / CI 整合指引。當使用者提到「Flutter 測試計劃」、「flutter test」、「widget test」、「integration_test」、「Dart 測試」、「寫 Flutter 測試案例」、「Flutter test plan」、「Flutter 自動化」、「Dart unit test」、「golden test」、「Flutter QA」，或針對使用 Flutter/Dart 的專案規劃測試時使用。與 test-master 並存：test-master 適用原生 iOS/Android（Swift/Kotlin），flutter-test-master 適用 Flutter/Dart 專案或 Flutter+Native 混合專案。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__atlassian__getJiraIssue, mcp__atlassian__searchJiraIssuesUsingJql, mcp__google__createSpreadsheet, mcp__google__writeSpreadsheet, mcp__google__copyFile, mcp__google__moveFile, mcp__google__createFolder, mcp__google__getSpreadsheetInfo
argument-hint: "[JIRA票號 或 功能描述] [--mode=quick|deep]"
---

# flutter-test-master

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。
> 啟用條件：`config.platforms.flutter.enabled = true`。
> 若 `mode = markdown-only` → 走 [`modules/markdown-fallback.md`](./modules/markdown-fallback.md)。

為 Flutter 應用生成完整測試方案。採用 Flutter 官方推薦的三層測試金字塔，並融合通用測試流程（Google Sheet TC 模板 + JIRA 整合 + 雙平台驗證）。

---

## 🎯 適用場景

### 使用此 skill 的時機
- ✅ 功能由 Flutter/Dart 實作（即使是 Flutter + Native 混合）
- ✅ 需要 Widget Test 或 Integration Test（`integration_test`）
- ✅ 需要 Golden Test（視覺回歸）
- ✅ Platform Channel / Plugin 測試
- ✅ 純 Dart package 測試

### 不使用此 skill（改用 test-master）
- ❌ 純 Swift/SwiftUI iOS App
- ❌ 純 Kotlin/Jetpack Compose Android App

### 混合情境（Native+Flutter）
同時使用兩個 skill：
- `flutter-test-master` 處理 Flutter 層
- `test-master` 處理 Native 層（ObjC/Swift/Kotlin）

---

## 📦 前置知識：Flutter 測試三層

| 層級 | 套件 | 目標 | 佔比 |
|------|------|------|------|
| **Unit Test** | `test` / `flutter_test` | 單一 function/class 邏輯，Mock 所有依賴 | 70% |
| **Widget Test** | `flutter_test` (WidgetTester, Finder, Matcher) | 單一 widget UI + 互動，不啟動整個 app | 20% |
| **Integration Test** | **`integration_test` + Patrol** | E2E、路由、DI、關鍵流程、原生權限/對話框 | 10% |

## 🎯 推薦技術棧

| 用途 | 工具 | 備註 |
|------|------|------|
| 單元測試 | `flutter_test` + Fake | Fake over Mock |
| Widget 測試 | `flutter_test` + `WidgetTester` | Fake ViewModel 注入 |
| E2E（純 Flutter） | **`integration_test`** | 輕量、Flutter 官方 |
| E2E（含原生互動）| **Patrol** | 權限/通知/WiFi/生物辨識/跨 App |
| Golden | `flutter_test` + `alchemist`（可選） | 雙平台 baseline |

**❌ 明確不採用**：
- Appium（Flutter Canvas 渲染，widget tree 不可見）
- flutter_driver（Flutter 官方已 deprecated）
- Appium Flutter Driver / Integration Driver（社群維護、不穩定）

**關鍵原則**：
- ⭐ **Fake over Mock**：優先建 `FakeUserRepository` 而非 mocking library
- ⭐ **ViewModel 不依賴 Flutter 框架**：UI 邏輯用純 Dart 測試
- ⭐ **View 注入 Fake**：Widget test 時傳入 FakeViewModel + FakeRepository
- ⭐ **E2E 先挑 integration_test，遇原生才升級 Patrol**

---

## 🔄 執行流程

### Phase 1: 需求分析
1. **讀取需求**
   - JIRA 票號（`{{JIRA_PROJECT_KEY}}-XXXX`）→ Atlassian MCP 撈取
   - 否則請使用者描述功能 + 架構（Provider / Riverpod / BLoC / GetX）
2. **架構偵測**
   - 搜尋 `pubspec.yaml` 確認 state management 套件
   - 搜尋 ViewModel/Repository/Service pattern（Glob: `**/view_models/**`, `**/repositories/**`）
   - 搜尋 platform channel 使用（Grep: `MethodChannel`, `EventChannel`）
3. **風險評估**
   - 金流/認證/FIDO2 → P0 高風險
   - Platform Channel → Plugin 跨層風險
   - 動畫/手勢 → Widget Test 覆蓋必要
   - Isolate/並發 → 並發測試必要

### Phase 2: 測試策略設計
生成 `flutter-test-strategy.md`（模板見 [`templates.md`](./templates.md)）

**Flutter 特有決策點**：
- Golden Test 是否啟用？（UI 穩定的畫面才啟用）
- Integration Test 執行平台？（Mobile / Web / Desktop / Firebase Test Lab）
- Mock 工具選擇？（mocktail 優先 / mockito 次選 / 純手寫 Fake 最推薦）

### Phase 3: 測試用例生成

生成 **黑箱 + 白箱** 兩份 Google Sheet（從模板 `{{GSHEET_TC_TEMPLATE_ID}}` 複製，若空則 `createSpreadsheet` 從零建）。

**Flutter 測試用例分佈建議**：
- Unit / 邏輯驗證：30%
- Widget / UI 互動：25%
- Integration / E2E：15%
- 邊界條件：15%
- 錯誤處理：10%
- Golden / 視覺回歸：5%（僅穩定 UI）

**依功能類型自動調整**：
| 功能類型 | 重點測試類型 |
|---------|-------------|
| 表單輸入 | Widget test（驗證規則）+ Unit test（邏輯） |
| API 整合 | Unit test（Repository + Mock HTTP）+ Integration test（快樂路徑） |
| Platform Channel | Dart unit + Native unit + Integration（至少 1 個） |
| 動畫/轉場 | Widget test（`pumpAndSettle` + 狀態驗證）+ Golden |
| 導覽 | Integration test（深層連結、返回堆疊） |
| 本地資料庫 | Unit test（Fake DB）+ Integration test（實機 SQLite） |
| Isolate | Unit test（訊息傳遞）+ 效能 benchmark |

**a11y（輔助功能）必檢項目** — 每個 UI 功能都要加：
- **字級縮放**（Flutter 核心）：
  - `MediaQuery.textScaler` 測試（最大級距）
  - iOS Dynamic Type / Android 字型大小同步驗證
  - **裝飾性數字不應跟隨放大**（用 `MediaQuery(data: ...copyWith(textScaler: TextScaler.noScaling))` 包裝）
- **Semantics widget**：
  - 互動元件有 `Semantics(label: ...)`
  - 裝飾性元件 `ExcludeSemantics`
- **VoiceOver / TalkBack**：讀取順序、label 正確
- **觸控目標**：Flutter `kMinInteractiveDimension` (48dp)
- **對比度 / Reduce Motion**：同原生規則
- 詳細檢查模板見 [`templates.md`](./templates.md)「a11y-checklist 模板（Flutter 版）」

**跨平台 a11y 配對原則**（若 `workflow.auto_a11y_pairing = true`）：Flutter 一份程式碼跑雙平台，但系統字級的**觸發路徑不同**（iOS Dynamic Type vs Android fontScale），測試時**兩邊都要驗**。a11y bug 建議開一對 ticket 並用 Relates 連結。

**Google Sheet 格式（A-N 欄）**：

| 欄位 | 值（Flutter 版本） |
|------|------|
| A: ID | `BB-FLT-XXX` / `WB-FLT-XXX` |
| B: Phase | Feature Done |
| F: 測試分類 | 冒煙-Feature Done / 功能測試 / 異常/邊界測試 / **Widget Test** / **Integration Test** / **Platform Channel** / **Golden Test** |
| H: 平台 | Both（Flutter 天然跨平台，除非平台特定差異）/ iOS / Android |
| L: 自動化 | Y（Flutter 適合自動化）/ N |

### Phase 4: 覆蓋缺口分析

搜尋現有 Flutter 測試：
- `test/**/*_test.dart` → Unit + Widget
- `integration_test/**/*_test.dart` → E2E
- `test/golden/**/*.png` → Golden baselines

比對新增用例 vs 現有測試，識別缺口。模板見 [`templates.md`](./templates.md)「coverage-gaps.md」。

### Phase 5: 自動化評估 + 測試程式碼骨架

與 `test-automation` skill 不同，本 phase **直接產出 Dart 測試程式碼骨架**（供開發者參考）：

```
test/
├── unit/
│   ├── view_models/
│   │   └── home_view_model_test.dart        ← ViewModel unit test
│   └── repositories/
│       └── user_repository_test.dart         ← Repository unit test (mock HTTP)
├── widget/
│   └── home_screen_test.dart                 ← Widget test (inject Fake VM)
├── golden/
│   └── home_screen_golden_test.dart          ← Golden test
└── fakes/
    ├── fake_user_repository.dart             ← Fake 實作（優先於 Mock）
    └── fake_booking_repository.dart

integration_test/
└── app_test.dart                             ← E2E 測試
```

模板見 [`templates.md`](./templates.md)「flutter-test-code 模板」。

### Phase 6: CI / Firebase Test Lab 整合指引

根據專案 CI 系統（GitHub Actions / Bitrise / Codemagic）產出執行指令：

| 平台 | 指令 |
|------|------|
| Mobile 本機 | `flutter test integration_test/app_test.dart` |
| Web | `chromedriver --port=4444` → `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d chrome` |
| Linux CI | `xvfb-run flutter test integration_test/app_test.dart -d linux` |
| Firebase Test Lab | `flutter build apk --debug` + `./gradlew app:assembleAndroidTest` → 上傳 |
| 單元測試 CI | `flutter test --coverage` + `lcov` 產出覆蓋率 |

### Phase 7: 探索性測試指引（Flutter 特化）

模板見 [`templates.md`](./templates.md)「flutter-exploratory-guide.md」，聚焦：
- **熱重載殘留狀態**（hot reload 後行為）
- **Isolate 通訊**（背景運算中斷）
- **Platform Channel 異常**（native 崩潰時 Dart 端表現）
- **多平台像素差異**（iOS vs Android 相同 widget 的像素差）

### Phase 8: Google Drive 上傳

> 僅在 `mode != markdown-only` 且 `google.qa_tc_folder_id` 設定時執行。

1. 在 QA-TC 資料夾（`{{GDRIVE_QA_FOLDER_ID}}`）下建立 `[Flutter] [功能名]` 子資料夾
2. 上傳黑箱/白箱 Google Sheet
3. 詢問是否上傳其他文件（test-strategy / coverage-gaps / 程式碼骨架壓縮檔）

---

## 📁 輸出檔案

```
.claude/testing/features/[feature-name]-flutter/
├── flutter-test-strategy.md
├── test-cases-{feature}-blackbox.xlsx    (Google Sheet 或 .md)
├── test-cases-{feature}-whitebox.xlsx    (Google Sheet 或 .md)
├── coverage-gaps.md
├── automation-plan.md
├── exploratory-guide.md
└── code-skeleton/
    ├── test/
    │   ├── unit/
    │   ├── widget/
    │   ├── golden/
    │   └── fakes/
    └── integration_test/
```

---

## 🎛 互動模式

- **基礎模式（預設）**：生成所有文件
- **快速模式** `--mode=quick`：只生成測試用例 Sheet（黑箱 + 白箱）
- **深度模式** `--mode=deep`：完整文件 + 可執行的 Dart 測試程式碼（含 Fake 實作）

---

## ✅ 品質檢查

生成後自動驗證：
- [ ] 三層金字塔比例合理（Unit 70% / Widget 20% / Integration 10%）
- [ ] Fake over Mock 原則已套用（ViewModel/View test 用 Fake）
- [ ] 所有 Repository 都有 Mock HTTP/DB 的 unit test
- [ ] 所有 ViewModel 都有純 Dart unit test（不依賴 flutter_test）
- [ ] 所有 View 都有 Widget test
- [ ] 至少 1 個 Integration test 涵蓋核心流程
- [ ] Platform Channel 有 Dart + Native 雙邊測試
- [ ] CI 執行指令針對目標平台正確
- [ ] 跨 iOS/Android 像素差異已評估（Golden test 差異容忍值）

---

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `platforms.flutter.enabled` | 啟用此 skill | 提示使用者改用 `test-master` |
| `google.tc_template_id` | 複製 TC 模板 | 改用 `createSpreadsheet` |
| `google.qa_tc_folder_id` | 上傳目標 | 提示手動移檔 |
| `workflow.auto_a11y_pairing` | a11y 配對 | 不自動配對 |
| `mode = markdown-only` | 全程模式 | 不呼叫 google MCP |

---

## 🤝 與其他 Skill 的關係

| Skill | 分工 |
|-------|------|
| `test-master` | 原生 iOS/Android（Swift/Kotlin） |
| **`flutter-test-master`** | **Flutter/Dart（本 skill）** |
| `flutter-test-automation` | 將 Flutter TC 轉成可執行 Dart 腳本 |
| `test-review` | 審查產出的 TC 品質 |
| `regression-test` | Release 前回歸測試計劃（跨框架） |
| `bug-report` | 發現 bug 後的開單流程（跨框架） |

## 範例

詳見 [`examples.md`](./examples.md)
