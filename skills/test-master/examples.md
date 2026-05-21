# Test Master Examples

## 範例 1: 基於 JIRA 票號

```
User: /test-master {{JIRA_PROJECT_KEY}}-1234

執行步驟：
1. 使用 Atlassian MCP 抓取 {{JIRA_PROJECT_KEY}}-1234 需求
2. 使用 gh search code 搜尋雙平台相關程式碼
   - iOS: {{IOS_REPO}}
   - Android: {{ANDROID_REPO}}
3. 比對雙平台實作差異
4. 生成跨平台測試計劃和用例
5. 詢問是否需要查看測試覆蓋缺口或自動化建議
```

## 範例 2: 基於功能描述

```
User: /test-master
功能：使用者可以編輯個人資料（暱稱、頭像、簡介），需要 7 分鐘內重新驗證身份

執行步驟：
1. 分析功能需求
2. gh search code "Profile" --repo {{IOS_REPO}}
3. gh search code "Profile" --repo {{ANDROID_REPO}}
4. 識別關鍵風險（7 分鐘驗證機制、資料同步、跨平台行為差異）
5. 生成跨平台測試文件
```

## 範例輸出（摘要）

```
✅ 測試計劃生成完成

📊 黑箱測試用例（一般使用者操作）：
- 總數：42 個
  - 冒煙測試: 7 | 功能測試: 12 | 異常/邊界: 8
  - 端對端: 5 | 相容性: 9 | 無障礙: 1
- P0: 10 / P1: 18 / P2: 14
- 平台：Both 30 / iOS 5 / Android 7

📊 白箱測試用例（需要開發者工具）：
- 總數：18 個
  - 效能測試: 4 | 安全性: 3 | 記憶體: 3
  - 並發安全: 3 | API 驗證: 3 | 內部狀態: 2
- P0: 2 / P1: 10 / P2: 6

📁 生成檔案：
- test-strategy.md
- test-cases-{feature}-blackbox.xlsx ← QA 團隊主要使用
- test-cases-{feature}-whitebox.xlsx ← 開發 + QA 協作
- coverage-gaps.md
- automation-plan.md
- exploratory-guide.md

🔍 跨平台分析：
- iOS repo: 分析了 X 個相關檔案
- Android repo: 分析了 Y 個相關檔案
- 實作差異: Z 處需要注意

🎯 關鍵風險：
- ⚠️ Token 刷新機制缺少測試（Both）→ 白箱
- ⚠️ 並發場景需要 TSAN 驗證（iOS）→ 白箱

📋 下一步：
1. 上傳測試用例至 Google Drive（資料夾 ID: {{GDRIVE_QA_FOLDER_ID}}）
2. Review 黑箱測試用例（QA 團隊）
3. Review 白箱測試用例（開發團隊）
4. 優先實作 P0 自動化測試
5. 執行探索性測試
```

---

## 範例 3: a11y 類問題的跨平台配對

### 背景
社群頁面詳情頁，表情符號反應計數（👍 12）在系統字級放大時跟著放大，造成 UI 破版。

### 正確處理方式：一對 ticket（iOS + Android）

> 此行為由 `config.json#workflow.auto_a11y_pairing = true` 啟用。

**Android 版**: [{{JIRA_PROJECT_KEY}}-001]({{JIRA_INSTANCE_URL}}/browse/{{JIRA_PROJECT_KEY}}-001)
- 觸發：系統 → 字型大小 → 最大
- Root Cause 方向：`sp` 應改 `dp`、或覆寫 `fontScale`
- Labels: `Android`, `optimization`, `a11y`

**iOS 版**: [{{JIRA_PROJECT_KEY}}-002]({{JIRA_INSTANCE_URL}}/browse/{{JIRA_PROJECT_KEY}}-002)
- 觸發：顯示與亮度 → 文字大小 → 最大 / 輔助使用 → 較大字體
- Root Cause 方向：`adjustsFontForContentSizeCategory = false`、或 SwiftUI `.dynamicTypeSize(.large)` 上限
- Labels: `iOS`, `optimization`, `a11y`, `dynamic-type`

**兩張 ticket 用 Relates link 連結**，確保修復時不會漏掉另一個平台。

### 生成 TC 時的啟示

Skill 在產出 TC 時，若偵測到功能涉及**文字/數字顯示**，必須自動生成以下 TC：

| TC-ID | 標題 | 平台 | 優先度 |
|-------|------|------|--------|
| BB-XXX-A11Y-01 | 系統字級最大時內容文字應跟隨放大且不破版 | Both | P1 |
| BB-XXX-A11Y-02 | 系統字級最大時裝飾性數字（計數/徽章）**不應**放大 | Both | P1 |
| BB-XXX-A11Y-03 | VoiceOver / TalkBack 讀取順序正確 | Both | P2 |
| BB-XXX-A11Y-04 | 深色模式下對比度符合 WCAG AA | Both | P2 |

參考 [`templates.md`](./templates.md) 的「a11y-checklist 模板」。

---

## 範例 4: Markdown-Only 模式

```
User: /test-master "新功能：個人資料編輯"

Bot: 偵測到 mode = markdown-only，跳過 Google Sheet 整合，改為產出 Markdown。

✅ 產出：
- .claude/testing/features/profile-edit/test-strategy.md
- .claude/testing/features/profile-edit/test-cases-blackbox.md  (含 14 欄表格)
- .claude/testing/features/profile-edit/test-cases-whitebox.md
- .claude/testing/features/profile-edit/coverage-gaps.md
- .claude/testing/features/profile-edit/automation-plan.md
- .claude/testing/features/profile-edit/exploratory-guide.md

📊 統計：黑箱 32 / 白箱 12 / a11y 4

切換到 full-mcp 後可重跑此 skill，將 .md 表格自動上傳為 Google Sheet。
```
