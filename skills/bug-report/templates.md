# Bug Report Templates

## Bug 報告模板（互動式 / 手動描述用）

```markdown
## Bug 描述
[一句話描述問題，例如：編輯個人資料時 App 當機]

## 重現步驟

**前置條件：**
- [條件 1]
- [條件 2]

**步驟：**
1. [步驟 1]
2. [步驟 2]
3. [步驟 3]

## 預期行為
[描述應該發生什麼]

## 實際行為
[描述實際發生什麼]

## 環境資訊
- **平台**：[iOS / Android / Both]
- **裝置**：[例如：{{IOS_DEFAULT_DEVICE}} / {{ANDROID_DEFAULT_DEVICE}}]
- **OS 版本**：[例如：{{IOS_DEFAULT_VERSION}} / {{ANDROID_DEFAULT_VERSION}}]
- **App 版本**：[例如：1.9.0 (819)]
- **環境**：[例如：Staging]
- **網路**：[例如：WiFi]
- **登入狀態**：[例如：已登入]

## 影響範圍
- **嚴重度**：[Blocker / Critical / Major / Minor]
- **影響平台**：[iOS only / Android only / Both]
- **影響使用者**：[所有使用者 / 已登入使用者 / 特定條件]
- **影響功能**：[列出受影響的功能模組]
- **業務影響**：[描述對業務的影響]

## 附件
- 截圖：[連結或附加檔案]
- 錄影：[連結或附加檔案]
- Console Log：[附加檔案或 snippet]

## Root Cause 分析
- **可能原因**：[基於程式碼分析的根因判斷]
- **相關程式碼**：
  - iOS: `[檔案路徑:行數]` - [問題描述]
  - Android: `[檔案路徑:行數]` - [問題描述]
- **建議修復方向**：[修復建議]
- **影響範圍**：[此問題可能影響的其他功能]

## 額外資訊
- **重現機率**：[100% / 偶發 (X/10 次) / 特定條件]
- **首次發現版本**：[例如：1.8.5]
- **相關 Ticket**：[例如：{{JIRA_PROJECT_KEY}}-1234, {{JIRA_PROJECT_KEY}}-5678]
- **Workaround**：[如果有暫時解決方案]

## 跨平台資訊
- **另一平台是否重現**：[是 / 否 / 未測試]
- **平台特有原因**：[如：Android Configuration Changes / iOS 記憶體警告]

## 標籤
`[模組名稱]` `[嚴重度]` `[平台]` `[環境]`
例如：`Profile` `Critical` `iOS` `Production`
```

---

## JIRA Ticket Description 模板

建立 JIRA ticket 時，Description 使用此 RIDER + Root Cause 格式：

```markdown
## Bug 描述
[TC ID] 測試標題 - Fail 原因摘要

## 重現步驟
**前置條件：**
[從 Column I 自動填入]

**步驟：**
[從 Column J 自動填入]

## 預期行為
[從 Column K 自動填入]

## 實際行為
[從 Column M 自動填入]

## Root Cause 分析
**可能原因：**
[基於程式碼分析的根因判斷]

**相關程式碼：**
- iOS: `[檔案路徑:行數]` - [問題描述]
- Android: `[檔案路徑:行數]` - [問題描述]

**建議修復方向：**
1. [修復建議 1]
2. [修復建議 2]

**影響範圍：**
[此問題可能影響的其他功能或模組]

## 環境資訊
- 平台：[Column H]
- App 版本：[自動偵測：iOS xcconfig / Android build.gradle]
- 環境：[使用者指定]

## 影響範圍
- 嚴重度：[根據 Column G 對應]
- 測試分類：[Column F]

## 自動化測試
- 自動化狀態：[Y / N]
- 自動化腳本：[搜尋到的 TestClass/testMethod（僅 Y 時顯示）]

## 參考資料
- 測試案例：[Column A]
- Google Sheet：[試算表連結]
```

---

## Markdown Fallback 模板（無 JIRA 時用）

當 `config.json#mode = markdown-only` 或 atlassian MCP 不可用時，產出 `bug-{slug}.md`：

```markdown
---
bug_id: BUG-{timestamp}
title: [Bug 標題]
severity: [Blocker/Critical/Major/Minor]
platform: [iOS/Android/Both]
status: open
created_at: {ISO 8601}
created_by: [使用者]
related_test_case: [TC-ID 若有]
---

# [Bug 標題]

（內容沿用上方 RIDER 模板）
```
