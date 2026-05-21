---
name: test-automation
description: 從測試用例（Google Sheet TC、JIRA ticket、功能描述）生成可執行的自動化測試腳本。支援雙平台原生框架（iOS: Swift Testing + XCUITest、Android: JUnit + Espresso + Mockk）。以 QA 測試工程師角度出發，將手動 TC 轉化為自動化腳本，包含 ROI 評估和 Page Object Model。當使用者提到「自動化測試」、「生成自動化腳本」、「把測試用例自動化」、「UI test 腳本」、「automation script」、「把 TC 轉成程式碼」，或提供 Google Sheet 測試用例要求生成自動化腳本，或討論哪些 TC 值得自動化時使用。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__readSpreadsheet, mcp__google__getSpreadsheetInfo, mcp__google__writeSpreadsheet, mcp__atlassian__getJiraIssue
argument-hint: "[Google Sheet URL、JIRA 票號、功能描述、或測試檔案路徑]"
---

# test-automation

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。
> 若 `mode = markdown-only` 或 google MCP 不可用，TC 來源改用 Markdown 表格；報表用 [`modules/markdown-fallback.md`](./modules/markdown-fallback.md) 規則輸出。

## 適用場景與分界

| | 自動化 unit test 工具 | test-automation |
|---|-----------|----------------|
| 出發點 | 原始碼（`.swift`/`.kt`） | 測試用例（Google Sheet TC） |
| 視角 | 開發者 — 驗證程式碼正確性 | QA — 驗證功能行為符合預期 |
| 範圍 | 單元測試 only | Unit + UI + Integration |
| 平台 | 單平台 | iOS + Android |
| **Flutter 專案請改用** | — | `flutter-test-automation` |

## 執行流程

### Phase 1: 輸入分析

偵測輸入類型並收集資訊：

1. **Google Sheet URL** → 讀取 TC sheet，篩選 Column L（自動化）= Y 的項目
2. **JIRA 票號**（如 `{{JIRA_PROJECT_KEY}}-XXXX`）→ 抓取需求，搜尋對應的 TC sheet 或直接從需求生成
3. **功能描述** → 分析功能，建議適合自動化的場景
4. **Markdown TC 路徑** → 解析表格（同 14 欄結構）
5. **無參數** → 互動式詢問

### Phase 2: 自動化 ROI 評估

對每個 TC 評估是否值得自動化：

| 因素 | 適合自動化 | 不適合自動化 |
|------|-----------|-------------|
| 執行頻率 | 每次 Release 都跑 | 一次性驗證 |
| 穩定性 | UI/流程穩定 | 頻繁改版的 UI |
| 複雜度 | 可程式化的步驟 | 需要人眼判斷（視覺/UX） |
| 維護成本 | Locator 穩定（accessibilityIdentifier） | 依賴動態內容/第三方 UI |
| 分類適合度 | 冒煙測試、功能測試、E2E | 無障礙測試、相容性測試 |

**ROI 公式：** `(手動執行時間 x 預期執行次數) / (開發時間 + 維護時間 x 預期版本數)`
- ROI > 3 → 強烈建議自動化
- ROI 1-3 → 視資源決定
- ROI < 1 → 不建議

輸出 ROI 評估表，回寫 Google Sheet Column L 的建議（或 Markdown frontmatter）。

### Phase 3: 平台偵測與架構分析

根據當前專案自動偵測平台：
- **iOS** — 搜尋 `*.xcodeproj`、`Package.swift` → 讀取既有測試 pattern
- **Android** — 搜尋 `build.gradle`、`build.gradle.kts` → 讀取既有測試 pattern
- **Web** — 搜尋 `package.json` + 偵測 `playwright.config.*` / `cypress.config.*` / `wdio.conf.*` → 對應框架
- **跨平台** — 多邊都生成

> 若 `platforms.{ios,android,web}.repo` 已設定，可從遠端 repo 抓取 pattern；否則用本地專案。

分析專案既有測試架構：
- 搜尋現有測試檔案，學習命名慣例、目錄結構、import pattern
- 識別既有 Page Object、Test Helper、Mock/Stub

### Phase 4: 腳本生成

依 TC 分類選擇對應的測試類型和 pattern：

**TC 分類 → 測試類型對照：**

| TC 分類 | 測試類型 | iOS 框架 | Android 框架 | Web 框架 |
|---------|---------|---------|-------------|---------|
| 冒煙測試（4 階段） | UI Test | XCUITest | Espresso | Playwright / Cypress E2E |
| 功能測試 | Unit + UI | Swift Testing + XCUITest | JUnit + Espresso | Jest/Vitest + Playwright |
| 異常/邊界測試 | Unit Test | Swift Testing | JUnit + Mockk | Vitest / Jest |
| 端對端測試 | UI Test | XCUITest | Espresso | Playwright (multi-project) |
| 效能測試 | Performance Test | XCTest.measure | Benchmark | Lighthouse CI / Playwright trace |
| 並發安全測試 | Unit Test (TSAN) | Swift Testing + Actor | JUnit + Coroutine | (N/A — browser single-thread) |
| API 驗證測試 | Unit Test | Swift Testing + Stub | JUnit + Mockk | Playwright `request` / `cy.request` |
| Component Test | (N/A — UIKit/SwiftUI 用 UI Test) | (N/A — Compose 用 UI Test) | Playwright Component / Cypress Component |
| Visual Regression | XCUITest snapshot (rare) | Espresso 截圖比對 (rare) | Playwright snapshot / Percy / Chromatic |
| Cross-browser | (N/A) | (N/A) | Playwright multi-project (chromium / webkit / firefox) |

**腳本生成規則：**

iOS pattern 詳見 [`ios-patterns.md`](./ios-patterns.md)，Android pattern 詳見 [`android-patterns.md`](./android-patterns.md)，Web pattern 詳見 [`web-patterns.md`](./web-patterns.md)。

核心原則：
- **Unit Test**：遵循 AAA（Arrange/Act/Assert）或 Given/When/Then
- **UI Test**：使用 Page Object Model，每個頁面一個 Page Object
- **命名**：從 TC 標題（Column E）生成方法名，保留 TC ID 在註釋中
- **TC 步驟對應**：Column J（測試步驟）→ test body，Column K（預期結果）→ assertions
- **前置條件**：Column I → test setup / Page Object navigation

### Phase 5: 整合與驗證

1. **放置檔案** — 遵循專案目錄慣例
   - iOS 範例：`{ProjectName}Tests/` 或 `{ProjectName}UITests/`
   - Android 範例：`app/src/test/` 或 `app/src/androidTest/`
   - Web 範例：`tests/` / `e2e/` / `cypress/e2e/` / `src/**/__tests__/` / `playwright/`
2. **編譯檢查**
   - iOS：`xcodebuild build-for-testing`
   - Android：`./gradlew compileDebugUnitTest`
   - Web：`npx tsc --noEmit` / `eslint` / `npx playwright test --list`
3. **執行測試** — 確認生成的腳本能通過（或標記需要環境配置的項目）
   - Web：`npx playwright test --project=chromium` / `npx cypress run --browser chrome`
4. **回寫 Google Sheet** — 更新 Column L = Y，Column M 備註加入測試檔案路徑

### Phase 6: 輸出完成度報表

生成 Google Sheet「{Feature} 自動化測試完成度報表」，包含 7 個 tab。格式詳見 [`report-template.md`](./report-template.md)。

| Tab | 內容 |
|-----|------|
| **總攬** | Dashboard — 分類統計（iOS Unit/Android Unit/UI/Manual）+ 完成率 + 視覺化進度條 |
| **Unit Test 明細** | 每個 unit test 目標 |
| **iOS 測試檔案明細** | iOS 測試檔案清單 |
| **Android 測試檔案明細** | Android 測試檔案清單 |
| **UI Automation 明細** | UI 自動化進度 + ROI 評估 |
| **額外完成項目** | 超出原始計劃的額外覆蓋 |
| **測試方法清單** | 所有測試方法逐一列出 |

上傳到 `{{GDRIVE_QA_FOLDER_ID}}` 對應的 feature 或 release 資料夾。

> Markdown-only 模式下，報表改為 `.claude/testing/automation/{feature}/report.md`。

## 品質檢查

- [ ] 每個自動化腳本都能對應回原始 TC（TC ID 在註釋中）
- [ ] UI Test 使用 Page Object Model，不在 test body 寫 raw locator
- [ ] Unit Test 使用 Stub/Mock，不依賴真實網路或資料庫
- [ ] 命名清晰：方法名反映測試行為，不是 `test1`/`test2`
- [ ] 前置條件正確處理（登入狀態、資料準備）
- [ ] 斷言對應 TC 的預期結果，不只是 "not nil"

## 整合其他 Skill

```
test-master (生成 TC) → test-automation (生成腳本) → 覆蓋率工具
                     ↗
test-review (審查 TC 品質，確認 Column L 標記正確)
```

- `test-master` 完成後 → 詢問是否自動化
- `test-review` 發現自動化標記不合理 → 觸發 ROI 重新評估
- 腳本生成後 → 量測覆蓋率變化（iOS：`xccov` / Android：`jacoco`）

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `google.qa_tc_folder_id` | 上傳報表 | 改寫本地 `.md` |
| `platforms.{ios,android}.repo` | 抓遠端 pattern | 用本地專案分析 |
| `mode = markdown-only` | 全程模式 | 全部以 .md 處理（不寫回 Sheet） |

## 範例

詳見 [`examples.md`](./examples.md)
