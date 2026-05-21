---
name: flutter-test-automation
description: 專為 Flutter 應用量身打造的自動化測試腳本生成 Skill。從 Google Sheet TC、JIRA 票號或功能描述生成可執行的 Dart 測試腳本，涵蓋 Unit Test（flutter_test）、Widget Test（WidgetTester）、Integration Test（integration_test）、Golden Test、Platform Channel Test。採用 Fake-over-Mock 原則、Robot Pattern / Page Object Model、Mocktail/Mockito 策略，並整合 Firebase Test Lab、`flutter test --coverage` 覆蓋率工具。當使用者提到「Flutter 自動化」、「寫 Dart 測試」、「把 Flutter TC 轉成程式碼」、「widget test 自動化」、「integration_test 腳本」、「Flutter UI test」、「patrol 測試」、「Golden test 自動化」，或針對 Flutter/Dart 專案要求生成自動化腳本時使用。與 test-automation 並存：test-automation 適用原生 iOS (XCUITest) / Android (Espresso)，flutter-test-automation 適用 Flutter/Dart 專案或 Flutter+Native 混合。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__readSpreadsheet, mcp__google__getSpreadsheetInfo, mcp__google__writeSpreadsheet, mcp__atlassian__getJiraIssue
argument-hint: "[Google Sheet URL、JIRA 票號、功能描述、或 dart 測試檔案路徑]"
---

# flutter-test-automation

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。
> 啟用條件：`config.platforms.flutter.enabled = true`。
> 若 `mode = markdown-only` → 走 [`modules/markdown-fallback.md`](./modules/markdown-fallback.md)。

從手動測試用例生成可執行 Dart 自動化腳本。輸出遵循 Flutter 官方推薦架構：Unit → Widget → Integration 三層金字塔。

---

## 🎯 適用場景

- ✅ Flutter/Dart 專案（純 Flutter app 或 Flutter package）
- ✅ Flutter + Native 混合專案的 Flutter 層
- ✅ 需要 Widget Test / Integration Test / Golden Test 自動化
- ✅ Platform Channel 測試腳本

## 🚫 不使用本 skill（改用 test-automation）
- 純 Swift iOS（XCUITest）
- 純 Kotlin Android（Espresso）

## 🧭 Skill 分工對照

| | test-automation | **flutter-test-automation** | flutter-test-master |
|---|----------------|-------------------------|---------------------|
| 出發點 | TC (iOS/Android) | **TC (Flutter)** | 需求 → TC |
| 視角 | QA → 原生自動化 | **QA → Dart 自動化** | QA → TC 規劃 |
| 輸出 | Swift/Kotlin 測試檔 | **Dart 測試檔** | Google Sheet TC |
| 框架 | XCUITest / Espresso | **flutter_test / integration_test** | N/A |

---

## 🔄 執行流程

### Phase 1: 輸入分析

偵測輸入類型並收集資訊：

1. **Google Sheet URL** → 讀取 TC sheet，篩選 Column L（自動化）= Y 的項目
2. **JIRA 票號**（`{{JIRA_PROJECT_KEY}}-XXXX`）→ 抓取需求，搜尋對應 TC sheet 或從需求生成
3. **功能描述** → 分析功能，建議適合自動化的場景
4. **Dart 檔案路徑** → 補強既有測試覆蓋
5. **Markdown TC 路徑** → 解析表格
6. **無參數** → 互動式詢問

### Phase 2: 自動化 ROI 評估（Flutter 特化）

| 因素 | 適合自動化 | 不適合 |
|------|-----------|--------|
| 執行頻率 | 每次 commit / PR | 一次性驗證 |
| 穩定性 | UI/流程穩定（Key 固定） | 頻繁改版的 UI |
| 測試層級 | Unit / Widget / Integration 都適合 | 需要人眼判斷視覺/UX |
| Locator 策略 | 用 `ValueKey` 或 `Key` | 依賴動態 text / 位置 |
| 跨平台需求 | Dart 自動化一次跑 iOS+Android | Golden 需雙 baseline |
| 分類適合度 | 功能測試、邏輯、E2E | 無障礙、真實裝置 UX |

**Flutter ROI 加權**：
- Widget Test ROI 通常**高於** XCUITest/Espresso（執行更快、跨平台）
- Golden Test ROI 依 UI 穩定性決定
- Integration Test 建議限制在 **關鍵路徑**（登入、支付、核心功能）

ROI > 3 → 強烈建議；1-3 → 視資源；< 1 → 不建議。

### Phase 3: 專案架構偵測

自動偵測 Flutter 專案：

- `pubspec.yaml` → 確認 Flutter 版本、dependencies
- State management: `provider` / `riverpod` / `bloc` / `get` / `mobx`
- Mock 套件: `mocktail`（優先） / `mockito` / 純 Fake
- 測試套件: 已安裝 `integration_test` / `patrol` / `alchemist`（golden）
- 既有測試目錄：
  - `test/` → Unit + Widget
  - `test/golden/` → Golden baselines
  - `integration_test/` → E2E

搜尋既有 pattern：
- `**/view_models/*.dart` → 找 ViewModel
- `**/repositories/*.dart` → 找 Repository
- `test/fakes/*.dart` → 找現有 Fake 實作
- `test_driver/` → 舊版 driver 檔

### Phase 4: 腳本生成策略

## 🔧 標準技術棧

| 層級 | 工具 | 備註 |
|------|------|------|
| Unit Test | `flutter_test` + Fake | 純 Dart，不依賴 Flutter binding |
| Widget Test | `flutter_test` + `WidgetTester` | Fake ViewModel 注入 |
| Golden Test | `flutter_test` + `alchemist`（可選） | 雙平台 baseline |
| **Integration Test (基礎)** | **`integration_test`** | 官方套件、純 Dart E2E |
| **Integration Test (進階)** | **Patrol** | 原生對話框、權限、通知、跨 app |
| Platform Channel | `flutter_test` + XCTest/JUnit | Dart + Native 雙邊 |

**❌ 不採用**：Appium（Flutter widget tree 不可見，相容性差）
**❌ 不採用**：flutter_driver（官方已 deprecated）

---

**TC 分類 → Flutter 測試類型對照：**

| TC 分類 | 測試類型 | 主要工具 | 檔案位置 |
|---------|---------|---------|---------|
| 冒煙-Feature Done | Integration Test | **`integration_test`** | `integration_test/smoke/` |
| 功能測試 | Unit + Widget | `flutter_test` | `test/unit/`, `test/widget/` |
| 異常/邊界測試 | Unit Test | `flutter_test` + Fake | `test/unit/` |
| Widget Test | Widget Test | `flutter_test` (WidgetTester) | `test/widget/` |
| Integration Test（純 Flutter） | Integration Test | **`integration_test`** | `integration_test/` |
| Integration Test（含原生對話/權限）| Integration Test | **Patrol** | `integration_test/patrol/` |
| Platform Channel | Unit Test + Native | `flutter_test` + XCTest/JUnit | `test/unit/services/`, native tests |
| Golden Test | Widget Test | `flutter_test` + `matchesGoldenFile` | `test/golden/` |
| API 驗證測試 | Unit Test | `flutter_test` + Mock HTTP | `test/unit/repositories/` |

---

**🎯 integration_test vs Patrol 決策樹：**

```
需要點擊「允許位置權限」系統對話框？ → Patrol
需要處理「推播通知授權」？           → Patrol
需要跨 App 流程（外部瀏覽器回跳）？  → Patrol
需要控制 WiFi / 網路 / 飛航模式？   → Patrol
需要處理 biometric（指紋/Face ID）？ → Patrol
以上都沒有，純 Flutter 畫面內流程？ → integration_test（較輕量）
```

**核心原則**（詳見 [`flutter-patterns.md`](./flutter-patterns.md)）：
- ⭐ **Fake over Mock**：ViewModel/View test 優先用 Fake 實作
- ⭐ **Robot Pattern / Page Object**：Widget/Integration test 封裝互動邏輯
- ⭐ **AAA（Arrange/Act/Assert）** 或 **Given/When/Then** 結構
- ⭐ **ValueKey 作為 locator**：`find.byKey(const ValueKey('login_button'))`
- ⭐ **TC ID 註釋**：每個測試方法頂部加 `// TC: BB-FLT-001`
- ⭐ **pumpAndSettle 管理**：動畫/異步操作後必 settle

### Phase 5: 整合與驗證

1. **放置檔案** — 遵循專案慣例（`test/` 或 `integration_test/`）
2. **編譯檢查** — `dart analyze` / `flutter analyze`
3. **執行測試**：
   - Unit/Widget: `flutter test [path]`
   - Integration: `flutter test integration_test/[file]` (需裝置/emulator)
   - Golden: `flutter test --update-goldens`（首次建立 baseline）
4. **回寫 Google Sheet**：更新 Column L = Y、Column M 加測試檔案路徑

### Phase 6: CI 整合產出

根據偵測的 CI 系統產出範本：

**GitHub Actions（範例）**：
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.x'

- name: Unit + Widget Tests
  run: flutter test --coverage

- name: Integration Tests (Android)
  run: |
    flutter build apk --debug
    ./gradlew app:assembleAndroidTest
    # 上傳至 Firebase Test Lab

- name: Coverage Report
  uses: codecov/codecov-action@v4
  with:
    file: coverage/lcov.info
```

**Firebase Test Lab**：
```bash
gcloud firebase test android run \
  --type instrumentation \
  --app build/app/outputs/apk/debug/app-debug.apk \
  --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=redfin,version=30,locale=en,orientation=portrait
```

### Phase 7: 輸出完成度報表

生成 Google Sheet「{Feature} Flutter 自動化完成度報表」，包含 7 個 tab。格式詳見 [`report-template.md`](./report-template.md)。

| Tab | 內容 |
|-----|------|
| **總攬** | Dashboard — 三層統計（Unit/Widget/Integration）+ 完成率 + 覆蓋率 |
| **Unit Test 明細** | 目標：ViewModel/Repository/Service/Utility |
| **Widget Test 明細** | Screen/Widget + Fake 注入狀況 |
| **Integration Test 明細** | E2E 流程 + 平台執行狀態（iOS/Android/Web） |
| **Golden Test 明細** | Baseline 清單 + 雙平台狀態 |
| **Platform Channel 明細** | Dart + Native（iOS XCTest / Android JUnit）配對狀態 |
| **測試方法清單** | 所有 Dart 測試方法逐一列出 |

上傳到 `{{GDRIVE_QA_FOLDER_ID}}` 對應資料夾。

> Markdown-only 模式下，改寫到 `.claude/testing/automation/{feature}-flutter/report.md`。

---

## ✅ 品質檢查

生成後自動驗證：
- [ ] 每個測試對應回原始 TC（TC ID 在註釋中）
- [ ] Widget/Integration Test 使用 Robot 或 Page Object Pattern
- [ ] Unit Test 使用 Fake/Mock，不依賴真實網路或 DB
- [ ] 命名清晰：方法名反映行為，不是 test1/test2
- [ ] 使用 `ValueKey` 做 locator，不用動態 text
- [ ] 前置條件透過 `setUp()` 或 Robot helper 處理
- [ ] 異步操作後有 `pumpAndSettle()` 或 `pump(Duration)`
- [ ] 斷言對應 TC 預期結果，不只 `isNotNull`
- [ ] 遵循 Fake-over-Mock 原則（ViewModel/View test）
- [ ] Golden test 有雙平台 baseline（iOS + Android）

---

## 🔗 整合其他 Skill

```
flutter-test-master (規劃 TC)
    ↓
flutter-test-automation (本 skill：生成 Dart 腳本)
    ↓
test-review (審查測試品質)
    ↓
smoke-test-analyzer (選出每日 smoke 測試集)
```

- `flutter-test-master` 產出 TC → 本 skill 轉成程式碼
- `test-review` 找出 Column L 標記不合理 → 觸發 ROI 重新評估
- 腳本生成後 → `smoke-test-analyzer` 選出每日 CI 跑的集合

---

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `platforms.flutter.enabled` | 啟用此 skill | 提示使用者改用 `test-automation` |
| `google.qa_tc_folder_id` | 上傳目標 | 改寫本地 .md |
| `mode = markdown-only` | 全程模式 | 不呼叫 google MCP |

## ❌ 不採用的工具（明確排除）

| 工具 | 原因 |
|------|------|
| **Appium** | Flutter Canvas 渲染 → UIAutomator/XCUITest 看不到 widget |
| **flutter_driver** | Flutter 官方已 deprecated，改推 `integration_test` |
| **Appium Flutter Driver / Integration Driver** | 社群維護、Flutter 版本升級常壞 |
| **Maestro（主力）** | 作為次要補充可以，但對 Flutter 的理解不及 Patrol |

---

## 🤝 與其他 Skill 的關係

| Skill | 分工 |
|-------|------|
| `test-automation` | 原生 iOS (XCUITest) / Android (Espresso) |
| **`flutter-test-automation`** | **Flutter/Dart (本 skill)** |
| `flutter-test-master` | Flutter TC 規劃（產出 Google Sheet） |
| `test-master` | 原生 TC 規劃 |
| `test-review` | 審查 TC 品質（跨框架） |
| `smoke-test-analyzer` | 選 Daily Smoke 測試集（跨框架） |

## 範例

詳見 [`examples.md`](./examples.md)
