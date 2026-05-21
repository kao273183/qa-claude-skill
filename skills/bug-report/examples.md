# Bug Report Examples

## 範例 1: 互動式 Bug 報告

```
User: /bug-report
Bot: 請用一句話描述問題：
User: 編輯個人資料時 App 當機

Bot: 請描述重現步驟（或回答「幫我結構化」）：
User: 幫我結構化

Bot: 好的，請回答以下問題：
1. 在哪個頁面發現問題？
User: 個人資料編輯頁面

Bot: 2. 執行什麼操作？
User: 修改暱稱後點擊儲存

Bot: 3. 有前置條件嗎（例如：需要登入）？
User: 需要已登入

Bot: 4. 是否每次都能重現？
User: 是的，100% 重現

Bot: 好的，我已整理重現步驟。請確認環境資訊：
- 裝置：[請輸入，預設：{{IOS_DEFAULT_DEVICE}}]
User: {{IOS_DEFAULT_DEVICE}}
Bot: - iOS 版本：[請輸入，預設：{{IOS_DEFAULT_VERSION}}]
User: {{IOS_DEFAULT_VERSION}}
Bot: - App 版本：[自動偵測] 1.9.0 (819)
Bot: - 環境：[Staging / Production]
User: Staging

Bot: 基於你的描述，我判斷嚴重度為：**Critical**
理由：影響主要功能（個人資料編輯）且導致 crash
是否同意？(Y/N)
User: Y

Bot: 正在分析 Root Cause...

🔍 Root Cause 分析：

**可能原因：**
MemberInfoEditor 在儲存暱稱時，未正確處理 API 401 回應。

**相關程式碼：**
- iOS: `[your-project]/Member/MemberInfoEditor.swift:145` - saveNickname() 未使用 @MainActor

**建議修復方向：**
1. saveNickname() 加上 @MainActor 標記
2. 在 API 回應處理中確保 UI 更新回到主執行緒

Bot: 正在建立 JIRA ticket（含 Root Cause 分析）...

✅ 已建立 JIRA ticket：{{JIRA_PROJECT_KEY}}-2500
- Summary：編輯個人資料時 App 當機
- Priority：High (Critical)
- URL：{{JIRA_INSTANCE_URL}}/browse/{{JIRA_PROJECT_KEY}}-2500

Bot: 正在發送 Slack 通知...
✅ 已發送 DM 通知（依 slack.notification_rules.bug_report）
```

## 範例 2: 快速模式（提供完整資訊）

```
User: /bug-report
編輯個人資料時 App 當機
裝置：{{IOS_DEFAULT_DEVICE}}, {{IOS_DEFAULT_VERSION}}
App 版本：1.9.0
步驟：登入 → 我的 → 編輯 → 修改暱稱 → 儲存 → Crash

Bot: 收到！正在建立 JIRA ticket...

✅ 已建立 JIRA ticket：{{JIRA_PROJECT_KEY}}-2501
📊 摘要：
- Summary：編輯個人資料時 App 當機
- Priority：High (Critical)
- URL：{{JIRA_INSTANCE_URL}}/browse/{{JIRA_PROJECT_KEY}}-2501

✅ 已發送 Slack 通知
```

## 範例 3: 從 Google Sheet 測試用例生成

```
User: /bug-report test-cases-feature-x

Bot: 搜尋 Google Drive 中的測試用例...
找到：test-cases-feature-x (Google Sheet)
正在讀取測試結果和 status 工作表...

📋 測試資訊：
- 測試版本：1.9.0 (819)
- 測試日期：2026-03-04
- 測試人員：Jack
- 測試環境：Staging

📊 測試結果統計：
- Total：52 | Pass：45 (86.5%) | Fail：4 (7.7%)
- Blocked：1 (1.9%) | Not Run：2 (3.8%)
- 執行率：96.2% | 通過率：91.8% (達標：>=95% ❌)

❌ 找到 4 個失敗的測試用例：

1. TC-IOM-001 | 冒煙-Feature Done | P0 | iOS
   標題：商品頁面載入
   備注：頁面載入白屏超過 10 秒
   🤖 自動化腳本：ProductPageTests/testPageLoad (iOS)

2. TC-IOM-018 | 功能測試 | P1 | Both
   標題：商品搜尋功能
   備注：{{JIRA_PROJECT_KEY}}-2345 搜尋結果顯示錯誤

3. TC-IOM-025 | 異常/邊界測試 | P1 | iOS
   標題：網路中斷後恢復
   備注：恢復後頁面空白

4. TC-IOM-040 | 功能測試 | P2 | Both
   標題：頁面切換穩定性
   備注：連續切換 20 次後 App 卡頓

請選擇要生成 Bug 報告的項目：(A=全部 / 1,3=指定 / C=取消)

User: A

Bot: 正在分析 4 個失敗的測試用例...

🔍 Root Cause 分析完成
正在建立 JIRA tickets...

⏭️ TC-IOM-018 已有 JIRA ticket：{{JIRA_PROJECT_KEY}}-2345（跳過）

✅ 建立 JIRA tickets：
1. TC-IOM-001 → {{JIRA_PROJECT_KEY}}-2400 (Blocker)
2. TC-IOM-025 → {{JIRA_PROJECT_KEY}}-2401 (Major)
3. TC-IOM-040 → {{JIRA_PROJECT_KEY}}-2402 (Minor)

✅ Google Sheet 已同步更新
✅ 已發送 Slack 通知

📊 處理完成：新建 3 / 跳過 1
```

## 範例 4: Markdown-Only 模式

> 適用於 `config.json#mode = markdown-only` 或無 atlassian MCP 的環境。

```
User: /bug-report
編輯個人資料時 App 當機，{{IOS_DEFAULT_DEVICE}}/{{IOS_DEFAULT_VERSION}}

Bot: 偵測到 markdown-only 模式（或 JIRA 不可用），改為產出 Markdown Bug 報告。

✅ 已產出：./bugs/bug-2026-05-21-profile-edit-crash.md

下一步建議：
1. 將檔案附到 PR 或寄給負責工程師
2. 切回 full-mcp 模式後可重跑此 skill，自動建立對應 JIRA ticket
```
