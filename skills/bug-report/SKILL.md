---
name: bug-report
description: 協助撰寫標準化、可重現的 Bug 報告（RIDER 格式），支援互動式問答、Root Cause 分析、自動建立 JIRA ticket 並發送 Slack DM 通知。可從 Google Sheet 測試用例批次生成 Bug 報告。當使用者提到「寫 bug 報告」、「回報問題」、「記錄 bug」、「bug report」、「開 bug 單」、「建立 JIRA bug」，或測試發現問題需要記錄，或提供 Google Sheet 測試用例要批次建立 Bug tickets 時使用。即使使用者只是說「這個有問題」或「測試失敗了」，也應觸發。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__atlassian__createJiraIssue, mcp__atlassian__searchJiraIssuesUsingJql, mcp__atlassian__addCommentToJiraIssue, mcp__google__readSpreadsheet, mcp__google__getSpreadsheetInfo, mcp__google__writeSpreadsheet
argument-hint: "[問題描述 或 Google Sheet URL]"
---

# bug-report

> ⚙️ **執行前先讀 `modules/config-loader.md`**，載入組織設定（JIRA / Slack / 平台預設）。
> 若 `config.json` 不存在或 `mode = markdown-only`，跳過所有 MCP 呼叫並走 [`modules/markdown-fallback.md`](./modules/markdown-fallback.md)。

## RIDER 格式

Bug 報告遵循 RIDER 五要素。詳細說明和範例見 [`rider-format.md`](./rider-format.md)。

| 要素 | 內容 |
|------|------|
| **R**eproduction Steps | 前置條件 + 編號步驟（具體操作：點擊/輸入/滑動） |
| **I**mpact | 嚴重度（Blocker/Critical/Major/Minor）+ 影響範圍 |
| **D**evice/Environment | 平台、OS、裝置、App 版本、環境、網路 |
| **E**xpected vs Actual | 預期行為 vs 實際行為（含錯誤訊息） |
| **R**eferences | 截圖、錄影、Console log、相關 ticket、Root Cause |

## 執行模式

### 模式 1: 互動式問答（預設）
依 Phase 1→6 逐步執行，每個 Phase 完成後才進入下一步。

### 模式 2: 快速模式（使用者一次提供完整資訊）
直接解析資訊 → Phase 2 查重 → Phase 3 Root Cause → Phase 4 建 JIRA → Phase 5 同步 → Phase 6 追蹤

### 模式 3: 從 Google Sheet 測試用例批次生成
> 需要 `config.json#mode != markdown-only` 且 `google.qa_tc_folder_id` 已設定。

1. 讀取 Google Sheet（status sheet + 測試用例 sheet）
2. 篩選 Column C = Fail 的項目
3. 檢查 Column N 是否已有 JIRA ticket → 有則跳過
4. 對每個 Fail 項目執行 Phase 2~4
5. 回寫 ticket 號碼到 Google Sheet Column N
6. 發送 Slack DM 彙總通知（依 `slack.notification_rules.bug_report`）

---

## 6 Phase 標準流程

### Phase 1: 資訊收集

**必備環境資訊（不完整要主動問）：**

| 項目 | 必填 | 說明 |
|------|------|------|
| 平台 | ✅ | iOS / Android |
| 裝置型號 | ✅ | 預設 iOS：`{{IOS_DEFAULT_DEVICE}}`、Android：`{{ANDROID_DEFAULT_DEVICE}}` |
| OS 版本 | ✅ | 預設 iOS：`{{IOS_DEFAULT_VERSION}}`、Android：`{{ANDROID_DEFAULT_VERSION}}` |
| App 版本 | ✅ | 自動偵測：iOS `{{IOS_VERSION_FILE_PATTERN}}` / Android `**/build.gradle` |
| 環境 | ✅ | Production / Staging / UAT |
| 網路環境 | ⚠️ | WiFi / 4G / 5G（網路相關 Bug 必問） |
| 登入狀態 | ⚠️ | 已登入 / 未登入（登入相關 Bug 必問） |
| 安裝方式 | ⚠️ | 首次安裝 / 升級安裝（資料遷移 Bug 必問） |
| 語系設定 | ⚠️ | 中文 / 英文（UI 顯示 Bug 必問） |

**版本→分支對應（Root Cause 分析需要）：**
```bash
# iOS — 找 release/testing 分支
gh api repos/{{IOS_REPO}}/branches --jq '.[].name' --paginate | grep "{version}"
# Android — 找 tag（若 default branch 不是 release 用）
gh api "repos/{{ANDROID_REPO}}/tags?per_page=10" --jq '.[] | .name'
```
> 若 `{{IOS_REPO}}` / `{{ANDROID_REPO}}` 為空，跳過版本→分支對應步驟，直接以 default branch 分析。

### Phase 2: 查重

建 JIRA 前**必須**搜尋是否已有相同/類似 ticket：
```
JQL: project = {{JIRA_PROJECT_KEY}} AND summary ~ "關鍵字" AND status != Done ORDER BY created DESC
JQL: project = {{JIRA_PROJECT_KEY}} AND parent = {{JIRA_PROJECT_KEY}}-XXXX AND issuetype = Bug ORDER BY created DESC
```
- 找到相同 → 不開新的，在既有 ticket 加 comment 補充
- 找到類似 → 開新的，description 中 reference 相關 ticket

### Phase 3: Root Cause 分析

依據 `config.json#workflow.auto_root_cause_depth` 決定深度：

| 平台 | `deep` | `suggestion-only` |
|------|--------|-------------------|
| iOS | 深入程式碼分析 + 檔案行數 | 只給可能原因與修復方向 |
| Android | 深入程式碼分析 + 檔案行數 | 只給可能原因與修復方向 |

**`deep` 模式步驟：**
1. **版本差異分析** — 比較測試版本 vs 前一版本：
   ```bash
   gh api "repos/{{IOS_REPO}}/compare/{prev}...{current}" --jq '{
     total_commits, changed_files: [.files[].filename] | length
   }'
   ```
2. **篩選相關檔案** — 用關鍵字過濾變更檔案
3. **用正確分支讀程式碼** — `git show origin/{branch}:{path}` 或 GitHub API
4. **檢查是否已修復** — 搜尋 main/develop 是否有 fix commit
5. **跨平台比對**（若 `workflow.auto_cross_platform_check = true`）— iOS 有問題時也查 Android 對應程式碼，反之亦然

### Phase 4: 建立 JIRA Ticket

**RIDER 格式填入 JIRA Description**（模板見 [`templates.md`](./templates.md)）

**JIRA 欄位設定：**
| 欄位 | 值 |
|------|---|
| Project | `{{JIRA_PROJECT_KEY}}` |
| Issue Type | Bug (id: `{{JIRA_BUG_ISSUE_TYPE_ID}}`) |
| Priority | 依 `jira.priority_mapping` 對應（Blocker→Highest, Critical→High, Major→Medium, Minor→Low） |
| Parent | 依使用者指定（詢問） |
| Team | 依 `jira.boards[]` 選擇（詢問） |
| 驗收者 | `{{JIRA_REVIEWER_FIELD}}` = `{{JIRA_REVIEWER_ACCOUNT_ID}}` |

**附件上傳**（JIRA MCP 不支援檔案上傳）：
1. `uploadFileToDrive` 上傳到 Google Drive
2. `set_drive_file_permissions` → link_sharing = reader
3. `addCommentToJiraIssue` 貼 Google Drive 連結
4. 命名規則：`{ticket號}_{描述}.{副檔名}`

> 若 `config.json#mode = markdown-only` 或 atlassian MCP 不可用，改走 [`modules/markdown-fallback.md`](./modules/markdown-fallback.md) 產出 `bug-{slug}.md` 檔案。

### Phase 5: 同步更新

**Google Sheet 回寫（如 Bug 來自測試用例）：**
- Column C → `Fail`
- Column D → 失敗原因描述
- Column N → `=HYPERLINK("{{JIRA_INSTANCE_URL}}/browse/{{JIRA_PROJECT_KEY}}-xxxx", "{{JIRA_PROJECT_KEY}}-xxxx")`

**Slack 通知（依 `slack.notification_rules.bug_report` 設定）：**
- 若包含 `dm`：發 DM 到 `{{SLACK_USER_ID}}`
- 若包含 `channel`：發到 `{{SLACK_BUG_CHANNEL_ID}}`
- 內容：ticket 號、標題、priority、關鍵資訊

**跨平台驗證建議**（若 `workflow.auto_cross_platform_check = true`，每次必做）：
- iOS 有問題 → 主動建議驗證 Android 同一場景
- Android 有問題 → 主動建議驗證 iOS 同一場景
- 另一平台也有問題 → 在同一 ticket 補充或開新 ticket（用 Relates 連結）

**a11y 自動配對**（若 `workflow.auto_a11y_pairing = true`）：
- a11y 相關 bug 預設開一對 iOS + Android ticket，並用 Relates 連結

### Phase 6: 後續追蹤

建完 ticket 後提醒使用者：
1. Bug 修復後需要重新驗證
2. 驗證通過 → 更新 Google Sheet（Fail → Pass）
3. 檢查此場景是否有對應 test case，沒有的話建議補上（→ `test-master` skill）

## 品質檢查

生成前自動驗證：
- [ ] 重現步驟清楚可執行
- [ ] 預期 vs 實際行為明確
- [ ] 環境資訊完整（9 項必填/條件必填）
- [ ] 嚴重度與影響範圍一致
- [ ] 避免主觀描述（「很慢」→「載入 > 5 秒」）
- [ ] 不包含敏感資訊（密碼、Token、個資用 `[已遮蔽]`）
- [ ] 已執行 Phase 2 查重

## 報告模板

詳見 [`templates.md`](./templates.md)（含互動式模板和 JIRA Description 模板）

## 範例

詳見 [`examples.md`](./examples.md)

## 整合其他 Skill

- 測試計劃中發現 Bug → 自動觸發 `bug-report`
- Bug 修復後 → `test-master` 補充防護測試
- Code Review 發現問題 → 詢問建立 Bug 報告或 Task

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `jira.instance_url` + `jira.project_key` | 建 ticket | 走 markdown fallback |
| `jira.reviewer_account_id` | 設驗收者 | 不設此欄位 |
| `jira.bug_issue_type_id` | Issue type | 預設 10046（標準 JIRA） |
| `slack.user_id` / `slack.bug_channel_id` | 通知 | 跳過對應通知 |
| `google.qa_tc_folder_id` | 批次模式 | 模式 3 不可用 |
| `platforms.ios.repo` / `platforms.android.repo` | Root Cause 分析 | 跳過版本→分支查找 |
| `workflow.auto_cross_platform_check` | 跨平台建議 | 不主動建議 |
| `workflow.auto_a11y_pairing` | a11y bug 配對 | 不自動開對 |
| `workflow.auto_root_cause_depth` | RCA 深度 | iOS 預設 deep、Android 預設 suggestion-only |
