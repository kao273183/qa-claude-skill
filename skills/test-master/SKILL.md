---
name: test-master
description: 一鍵生成完整測試計劃、測試用例和自動化策略的綜合測試工程師 Skill。生成黑箱/白箱測試用例（Excel）、測試策略、覆蓋缺口分析、自動化路線圖和探索性測試指引。當使用者提到「生成測試計劃」、「設計測試」、「完整測試方案」、「測試用例設計」、「寫測試案例」、「test plan」，或需要為新功能、重構、Bug 修復、Release 規劃測試策略時使用此 skill。即使使用者只是模糊地說「幫我測一下這個功能」或「這個需要什麼測試」，也應觸發。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__atlassian__getJiraIssue, mcp__atlassian__searchJiraIssuesUsingJql, mcp__google__createSpreadsheet, mcp__google__writeSpreadsheet, mcp__google__copyFile, mcp__google__moveFile, mcp__google__createFolder, mcp__google__getSpreadsheetInfo
argument-hint: "[JIRA票號 或 功能描述]"
---

# test-master

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**，載入組織設定。
> 若 `config.json` 不存在或 `mode = markdown-only`，跳過 MCP 並走 [`modules/markdown-fallback.md`](./modules/markdown-fallback.md)。

## 執行流程

### Phase 1: 需求分析
1. **讀取需求** — JIRA 票號（如 `{{JIRA_PROJECT_KEY}}-XXXX`）用 Atlassian MCP 抓取，否則請使用者描述
2. **JIRA 描述完整性檢查** — description 為空的票號標記為風險
3. **分析影響範圍** — 搜尋相關程式碼（Glob/Grep）：
   - iOS repo: `{{IOS_REPO}}`（若已設定）
   - Android repo: `{{ANDROID_REPO}}`（若已設定）
   - 識別 ViewModel / Repository / Service / API / SDK 依賴
4. **風險評估** — 金流/敏感資料/認證（高）、並發/記憶體/網路（技術）、關鍵流程/UX（業務）

### Phase 2: 測試策略設計
生成 `test-strategy.md`。模板見 [`templates.md`](./templates.md)「test-strategy.md 模板」。

### Phase 3: 測試用例生成
生成黑箱 + 白箱兩份 Google Sheet（從模板複製，模板 ID = `{{GSHEET_TC_TEMPLATE_ID}}`）。

> 若 `{{GSHEET_TC_TEMPLATE_ID}}` 為空 → 直接 `createSpreadsheet` 並建立預設欄位結構。
> 若 `mode = markdown-only` → 改產出 `test-cases-{feature}-{blackbox|whitebox}.md`，沿用相同欄位（A-N）。

**測試用例分佈：**
- 正常路徑 20% / 邊界條件 30% / 錯誤處理 30% / 並發 10% / 非功能性 10%

**依功能類型自動調整重點：**
- API 整合 → 網路錯誤、逾時、401/403/500、JSON 解析
- UI 功能 → 載入/錯誤/空白狀態、螢幕尺寸、**a11y（見下）**
- 資料同步 → 並發寫入、race condition、Thread Sanitizer
- IM/即時通訊 → 斷線重連、離線同步、多裝置

**a11y（輔助功能）必檢項目** — 每個 UI 功能都要加：
- **字級縮放**：iOS Dynamic Type 最大 / Android 字型最大 / Android 顯示大小最大
  - 內容文字應跟隨放大但不破版
  - **裝飾性數字（計數、徽章）不應跟隨放大**
- **螢幕閱讀器**：VoiceOver（iOS）/ TalkBack（Android）讀取順序與 label
- **觸控目標**：iOS ≥ 44×44 pt / Android ≥ 48×48 dp
- **對比度**：文字 vs 背景 ≥ 4.5:1（深色模式也要驗）
- **Reduce Motion**：動畫減少模式正常
- 詳細檢查模板見 [`templates.md`](./templates.md)「a11y-checklist 模板」

**優先級判斷：**
- P0: 核心業務流程（登入/支付/訂單）、資料安全、高 crash 風險
- P1: 主要功能、高頻場景、錯誤處理、**a11y 跑版**
- P2: 次要功能、邊界條件、非功能性需求

**跨平台 a11y 配對原則**（若 `workflow.auto_a11y_pairing = true`）：開 a11y 類 bug/優化單時，**預設開一對**（iOS + Android），用 Relates 連結。

**Google Sheet 格式** — 遵循 `config.test_case_format` 中設定的 A-N 欄位結構與分類。預設欄位：

| 欄 | 內容 |
|----|------|
| A | ID（`BB-` 黑箱 / `WB-` 白箱 前綴） |
| B | Phase |
| C | 測試結果 |
| D | 測試結論 |
| E | 測試標題 |
| F | 測試分類 |
| G | 優先度（P0/P1/P2） |
| H | 平台（iOS/Android/Both） |
| I | 前置條件 |
| J | 測試步驟 |
| K | 預期結果 |
| L | 自動化（Y/N） |
| M | 備註 |
| N | JIRA Ticket |

### Phase 4: 測試覆蓋缺口分析
搜尋雙平台現有測試：
- iOS：`*Tests.swift` 或 `*Test.swift`
- Android：`*Test.kt` 或 `*Tests.kt`

比對新增用例 vs 現有測試，識別缺口。模板見 [`templates.md`](./templates.md)「coverage-gaps.md 模板」。

### Phase 5: 自動化評估
評估標準：重複頻率、執行時間、複雜度、穩定性、ROI。模板見 [`templates.md`](./templates.md)「automation-plan.md 模板」。

### Phase 6: 探索性測試指引
模板見 [`templates.md`](./templates.md)「exploratory-guide.md 模板」。

### Phase 7: Google Drive 上傳
> 僅在 `mode != markdown-only` 且 `google.qa_tc_folder_id` 已設定時執行。

1. 在 QA-TC 資料夾（`{{GDRIVE_QA_FOLDER_ID}}`）下建立 feature 子資料夾
2. 上傳黑箱/白箱 Google Sheet 到該資料夾
3. 詢問是否上傳其他文件（test-strategy.md、coverage-gaps.md 等）

> 若 `google.default_drive = shared` 且 MCP 無法直寫共用硬碟，提示使用者「請手動將 Sheet 移至 `{{GDRIVE_QA_FOLDER_ID}}`」。

## 輸出檔案

```
.claude/testing/features/[feature-name]/
├── test-strategy.md
├── test-cases-{feature}-blackbox.xlsx  (Google Sheet)
├── test-cases-{feature}-whitebox.xlsx  (Google Sheet)
├── coverage-gaps.md
├── automation-plan.md
└── exploratory-guide.md
```

> Markdown-only 模式下，Sheet 改為同名 `.md` 檔。

## 互動模式

- **基礎模式（預設）**：生成所有文件
- **快速模式** `--mode=quick`：只生成測試用例 Sheet
- **深度模式** `--mode=deep`：完整文件 + Mock/Stub 程式碼範例

## 品質檢查

生成後自動驗證：
- [ ] Happy Path + 邊界條件 (>=3) + 錯誤處理 (>=5) + 並發 + 生命週期
- [ ] 測試金字塔比例合理（70% Unit / 20% Integration / 10% UI）
- [ ] 風險矩陣涵蓋所有高風險項目
- [ ] ROI 計算包含維護成本和 Flaky test 風險
- [ ] 雙平台（iOS + Android）實作差異已分析
- [ ] 覆蓋缺口含雙平台現有測試比對

## 後續動作

完成後詢問：
1. 生成自動化測試程式碼？（→ `test-automation` skill）
2. 同步測試計劃到 JIRA？
3. 審查測試用例品質？（→ `test-review` skill）

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `google.tc_template_id` | 複製模板建立 Sheet | 改用 `createSpreadsheet` 從零建 |
| `google.qa_tc_folder_id` | 上傳目標資料夾 | 提示使用者手動移檔 |
| `platforms.ios.repo` / `platforms.android.repo` | 程式碼影響面分析 | 跳過自動分析，請使用者貼路徑 |
| `workflow.auto_a11y_pairing` | a11y 自動配對 | 不自動建議配對 |
| `mode = markdown-only` | 全程模式 | 不呼叫任何 MCP，輸出 `.md` |

## 範例

詳見 [`examples.md`](./examples.md)
