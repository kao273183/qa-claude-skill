---
name: regression-test
description: 為每個 Release 版本生成跨平台（iOS + Android）回歸測試計劃。自動從 JIRA 撈取本次 Release 需求和最近 3 版的嚴重/重複 Bug，進行風險評估，生成回歸測試表格（Google Sheet）並估算測試天數。當使用者提到「回歸測試」、「regression test」、「release 測試」、「release QA」、「版本測試計劃」、「release 前要測什麼」，或準備進行版本發佈前的測試規劃時使用。即使使用者只是說「這個版本要測什麼」、「準備 release」、「QA checklist」，也應觸發。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__atlassian__searchJiraIssuesUsingJql, mcp__atlassian__getJiraIssue, mcp__google__createSpreadsheet, mcp__google__writeSpreadsheet, mcp__google__readSpreadsheet, mcp__google__copyFile, mcp__google__getSpreadsheetInfo, mcp__google__moveFile, mcp__google__createFolder
argument-hint: "[Release 版本號，例如 1.9.0]"
---

# regression-test

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。
> 若 `mode = markdown-only` 或 google MCP 不可用，走 [`modules/markdown-fallback.md`](./modules/markdown-fallback.md) 產出 Markdown 回歸測試計劃。

## 執行流程

### Phase 1: 收集 Release 資訊

1. **確認版本號** — 從參數取得或詢問（例如 `1.9.0`）
2. **撈取本次 Release 需求** — JIRA JQL（Fix Version 用 `~` 模糊比對）：
   ```
   project = {{JIRA_PROJECT_KEY}} AND fixVersion ~ "{version}" ORDER BY priority DESC
   ```
   分類：新功能 / Bug Fix / 改善 / 技術債
3. **識別影響模組** — 從 ticket 的 component 或標題歸類到功能模組
4. **區分平台** — 根據 ticket labels/team 標記 iOS / Android / Web / Both / All（依 `platforms.{ios,android,web,flutter}` 啟用情況決定）

### Phase 2: 歷史 Bug 分析

1. **撈取最近 3 個版本的 Bug** — JQL：
   ```
   project = {{JIRA_PROJECT_KEY}} AND issuetype = Bug
   AND priority in (Highest, High, Medium)
   AND created >= -90d ORDER BY priority DESC
   ```
2. **識別重複性問題** — 同模組出現 2+ 次的 Bug，標記為「歷史重複」
3. **識別 Regression Bug** — 曾修復又復發的問題（搜尋 resolved 後又 reopen 的 ticket）
4. **統計模組 Bug 密度** — 哪些模組歷史 Bug 最多 → 輸入 Phase 3 風險評估

### Phase 3: 風險評估

依以下維度評估每個模組的風險等級：

| 風險因素 | High | Medium | Low |
|---------|------|--------|-----|
| 本次變更量 | 大量新增/修改 | 部分修改 | 無變更 |
| 歷史 Bug 密度 | >=3 個 Major+ | 1-2 個 | 0 個 |
| 業務關鍵性 | 登入/支付/訂單/會員 | 主要功能 | 次要功能 |
| 跨平台影響 | 雙平台皆受影響 | 單平台 | 無影響 |
| 重複問題歷史 | 有重複紀錄 | - | 無 |

綜合風險 = 最高單項風險（任一項 High → 整體 High）。

### Phase 4: 回歸測試表格生成

**使用模板建立 Google Sheet**（模板 ID = `{{GSHEET_REGRESSION_TEMPLATE}}`）：

1. **複製模板**：使用 `mcp__google__copyFile` 複製模板
   - 命名為 `回歸測試-v{version}`
   - 如果 copyFile 失敗（共用雲端硬碟限制），改用 `createSpreadsheet` 建立新 Sheet 並手動建立分頁結構
   - 如果 `{{GSHEET_REGRESSION_TEMPLATE}}` 為空 → 直接從零建立

2. **模板應包含 5 個 tab**：風險總覽、變更清單、回歸測試用例、歷史Bug風險分析、測試總覽

3. **「回歸測試用例」tab 預填核心固定項目**（每團隊可在 `config.regression.core_items` 自訂），預設涵蓋：
   - App 基礎 Smoke（啟動/登入/導航）
   - 核心業務流程（依 `jira.boards` 中各 team 的 scope 自動帶入）
   - WebView / 推播 / 深層連結

4. **只需填入版本專屬內容**：
   - **回歸測試用例 tab**：在「版本專屬測試用例」區塊插入版本專屬項目（RT-001~RT-039），包含：
     - Smoke Test（P0，阻擋 release）
     - 新功能驗證
     - Bug Fix 驗證
     - 高風險回歸
     - 歷史問題回歸
   - **風險總覽 tab**：填入本版風險分析
   - **變更清單 tab**：填入本版 JIRA ticket 清單，按平台分組
   - **歷史 Bug 風險分析 tab**：填入風險模式分析
   - **測試總覽 tab**：填入 Release 資訊和測試統計

每項測試用例含 15 欄（A-O）：編號、測試區域、測試類型、測試項目、平台、優先度、風險等級、前置條件、步驟、預期結果、iOS 結果、Android 結果、預估時間、相關 JIRA、備註。

> **Web 平台**（若 `platforms.web.enabled = true`）：可在 K/L 欄位之外新增 `Web (Chrome)` / `Web (Safari)` 結果欄；或將 K=主瀏覽器結果、L=次瀏覽器結果，命名規範依團隊。E 欄「平台」可填 `Web` 或具體 `Web (Chrome)` / `Web (Safari)`。

欄位結構、格式、顏色方案詳見 [`templates.md`](./templates.md)。

**注意事項：**
- Section header（如 `=== Smoke Test ===`）寫入時必須用 `valueInputOption: RAW`，否則 `=` 開頭會被當成公式（#ERROR!）
- 寫入前先用 `readSpreadsheet` 確認現有欄位結構
- JIRA 單號用 HYPERLINK 公式：
  ```
  =HYPERLINK("{{JIRA_INSTANCE_URL}}/browse/{{JIRA_PROJECT_KEY}}-xxxx", "{{JIRA_PROJECT_KEY}}-xxxx")
  ```

### Phase 5: 測試時間估算

1. **依優先度加權**：
   - P0：每項 0.5 天（必測，不可跳過）
   - P1：每項 0.3 天
   - P2：每項 0.2 天
2. **依平台分別計算**：iOS 和 Android 各需多少天
3. **加入 buffer**：總時間 x 1.2（含環境準備、Bug 回報、retesting）
4. **建議測試順序**：Smoke → 高風險 → 新功能 → Bug Fix → 全面回歸
5. **產出時程表**：寫入總覽 Sheet

### Phase 6: 輸出與上傳

1. 在 QA-TC 資料夾（`{{GDRIVE_QA_FOLDER_ID}}`）下建立 Release 資料夾：`Release {version}/`
2. 將 Google Sheet 移動到該資料夾（共用雲端硬碟需用 Drive API + `supportsAllDrives=true`）
3. 檔案命名：`回歸測試-v{version}`
4. **Slack 通知**（依 `slack.notification_rules.regression_published`）：
   - 包含 `channel` → 發到 `{{SLACK_RELEASE_CHANNEL_ID}}`
   - 包含 `dm` → 發 DM 到 `{{SLACK_USER_ID}}`
   - 內容：版本號、測試項目數、預估天數、Google Sheet 連結

## 品質檢查

- [ ] Smoke Test 涵蓋所有核心流程（依 `config.regression.core_items` 自動帶入）
- [ ] 本次所有 Bug Fix 都有對應驗證項目
- [ ] 高風險模組有足夠回歸覆蓋（>=3 項/模組）
- [ ] iOS 和 Android 平台標記正確
- [ ] 歷史重複問題都已納入
- [ ] 時間估算含 buffer 且合理

## 整合其他 Skill

- 回歸測試發現 Bug → `bug-report` skill 建立 JIRA ticket
- 需要深入某功能測試 → `test-master` skill 生成詳細用例
- 測試完成後 review → `test-review` skill 審查品質
- 完成後發布結果 → `publish-regression` skill 上傳至 Dashboard

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `google.regression_template_id` | 複製回歸模板 | 改用 `createSpreadsheet` 從零建 |
| `google.qa_tc_folder_id` | 上傳目標 | 提示使用者手動移檔 |
| `jira.boards` | 識別 Team / 平台分配 | 提示使用者手動指定 |
| `slack.release_channel_id` | Release 通知 | 不發 channel 通知 |
| `mode = markdown-only` | 全程模式 | 改產出 `.md` 計劃檔 |

## 範例

詳見 [`examples.md`](./examples.md)
