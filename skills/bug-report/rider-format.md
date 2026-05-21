# RIDER Format Reference

## R - Reproduction Steps（重現步驟）

**原則：**
- 清楚、可重現、一步步列出
- 標注前置條件（例如：需要登入、特定資料狀態）
- 使用編號列表
- 包含具體操作（點擊、輸入、滑動）

**範例：**
```
前置條件：
- 已登入帳號
- 網路連線正常

重現步驟：
1. 開啟 App
2. 前往「我的」tab
3. 點擊「設定」
4. 點擊「編輯個人資料」
5. 修改暱稱為「測試使用者」
6. 點擊「儲存」
```

## I - Impact（影響範圍）

**嚴重度分級：**

| 等級 | 定義 | 範例 |
|------|------|------|
| **Blocker** | 無法使用核心功能，阻擋 release | App 啟動就 crash、無法登入 |
| **Critical** | 影響主要業務流程，有替代方案 | 支付失敗、貼文無法發布 |
| **Major** | 功能受損但非關鍵，有 workaround | 按讚失敗、圖片載入慢 |
| **Minor** | 視覺瑕疵或邊緣情境 | 文字對齊錯誤、edge case bug |

> 對應 JIRA Priority 由 `config.json#jira.priority_mapping` 決定。

**影響範圍描述：**
- 影響使用者比例（所有使用者 / 特定條件）
- 影響功能模組（單一功能 / 多個功能）
- 業務影響（金流 / 資料遺失 / 使用者體驗）

## D - Device/Environment（裝置環境）

**必填資訊：**
- **平台**：iOS / Android
- OS 版本（例如：`{{IOS_DEFAULT_VERSION}}` / `{{ANDROID_DEFAULT_VERSION}}`）
- 裝置型號（例如：`{{IOS_DEFAULT_DEVICE}}` / `{{ANDROID_DEFAULT_DEVICE}}`）
- App 版本（例如：1.9.0 (819)）
- 環境（例如：Staging / Production）

**可選資訊：**
- 網路環境（WiFi / 4G / 5G / 離線）
- 登入狀態（已登入 / 未登入）
- 特殊設定
  - iOS：VoiceOver / Dynamic Type / 低電量模式
  - Android：TalkBack / 字體縮放 / 深色模式 / 省電模式
- **跨平台資訊**：另一平台是否也有同樣問題？

> App 最低支援：iOS `{{MIN_IOS_VERSION}}` / Android API `{{MIN_ANDROID_API}}`。低於此版本的問題不開單。

## E - Expected vs Actual（預期 vs 實際）

**預期行為：**
- 明確描述「應該」發生什麼
- 參考設計稿、需求文件或正常邏輯

**實際行為：**
- 明確描述「實際」發生了什麼
- 包含錯誤訊息（如果有）
- 描述視覺問題（如果是 UI bug）

**範例：**
```
預期行為：
1. 顯示「正在儲存...」載入狀態
2. 儲存成功後顯示「已儲存」訊息
3. 返回個人資料頁面，顯示更新後的暱稱

實際行為：
1. 點擊「儲存」後 App 當機
2. 返回主畫面
3. 重新開啟後發現資料未儲存
```

## R - References（參考資料）

**建議附件：**
- 截圖（標注問題區域）
- 螢幕錄影（重現步驟）
- Console logs（Crash log、Error log）
- 相關 ticket（重複 bug、相關問題）
- 設計稿（UI bug）

**Console Log 擷取方式：**
```
iOS:
  Xcode → Window → Devices and Simulators → 選擇裝置 → Open Console
  或：設定 → 隱私權與安全性 → 分析與改進 → 分析資料 → 找到 crash report

Android:
  adb logcat -d > crash.log
  或：開發者選項 → 錯誤報告 → 互動式錯誤報告
```
