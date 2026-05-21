# Test Review Examples

## 範例 1: 黑箱測試案例審查（需求導向）

```
User: /test-review https://docs.google.com/spreadsheets/d/xxx/edit?gid=123

Bot:
[Phase 0] Spreadsheet 標題：「會員系統 - 測試案例」→ 需求主題 = 會員系統
[Phase 1] 偵測到 "Member Test Cases (Black-box)" Sheet → 黑箱審查
[Phase 2] 歸納功能模組：登入/註冊、Token 管理、會員資料編輯、推播通知、會員等級

✅ 黑箱審查完成！

📊 總體評分：78/100

關鍵發現：
⚠️ Critical: 缺少整合冒煙測試（會員系統與其他模組的互動）
⚠️ Critical: TC-020 使用 Charles Proxy 驗證 → 應移到白箱
⚠️ Major: 缺少推播註冊失敗場景（無效 token、權限拒絕）
⚠️ Major: 缺少跨裝置 session 同步驗證

覆蓋缺口（按功能模組）：
- 註冊流程（端對端）：0 TC
- 推播 cold start 場景：0 TC
- 不同 OS 版本相容性：0 TC

注意：覆蓋缺口以「會員系統」需求為中心，不以底層程式碼模組為中心。

[Phase 5] 回寫審查分數到 status sheet...
已寫入 status sheet「審查紀錄」：2026-03-16 | Claude test-review (BB) | 78 | C:3 M:5 m:4

詳細報告：.claude/testing/reviews/member-blackbox-review-2026-03-16.md
```

## 範例 2: 白箱測試案例審查（需求導向）

```
User: /test-review https://docs.google.com/spreadsheets/d/xxx/edit?gid=456

Bot:
[Phase 0] Spreadsheet 標題：「即時通訊 - 測試案例」→ 需求主題 = 即時通訊
[Phase 1] 偵測到 "Chat Test Cases (White-box)" Sheet → 白箱審查
[Phase 2] 歸納功能模組：SDK 連線管理、Token 生命週期、訊息收發、多裝置同步

✅ 白箱審查完成！

📊 總體評分：65/100

關鍵發現：
⚠️ Critical: 效能測試缺少量化閾值（訊息載入時間基線？）
⚠️ Critical: 並發安全測試未標註 TSAN 設定步驟
⚠️ Major: 缺少 Token 過期後的自動重連驗證
⚠️ Major: 記憶體測試無重複執行次數要求

分類覆蓋：效能(5) 安全性(3) 記憶體(2) 並發(4) API(6) 內部狀態(3)

詳細報告：.claude/testing/reviews/chat-whitebox-review-2026-03-16.md
```

## 範例 3: 同時包含黑箱 + 白箱的 Spreadsheet

```
User: /test-review https://docs.google.com/spreadsheets/d/xxx/edit

Bot:
[Phase 0] Spreadsheet 標題：「品牌日曆 - 測試案例」→ 需求主題 = 品牌日曆
[Phase 1] 偵測到 2 張 Sheet: Black-box + White-box → 雙重審查
[Phase 2] 歸納功能模組：日曆顯示、品牌篩選、優惠詳情、推播提醒

✅ 雙重審查完成！

📊 黑箱評分：78/100 (良好)
📊 白箱評分：62/100 (需改進)

黑箱關鍵發現（以品牌日曆需求為中心）：
⚠️ Major: 缺少跨月份切換的邊界測試
⚠️ Major: 缺少無優惠時的空白狀態驗證

白箱關鍵發現：
⚠️ Critical: API 快取策略未驗證（日曆資料更新頻率）
⚠️ Critical: 效能閾值未設定

詳細報告：
📁 .claude/testing/reviews/brand-calendar-blackbox-review-2026-03-16.md
📁 .claude/testing/reviews/brand-calendar-whitebox-review-2026-03-16.md

[Phase 5] 回寫審查分數到 status sheet...
已寫入 2 行：
  - 2026-03-16 | Claude test-review (BB) | 78 | C:0 M:2 m:0
  - 2026-03-16 | Claude test-review (WB) | 62 | C:2 M:0 m:0
綜合評分已更新：70
```

## 範例 4: 測試程式碼審查（Swift / Kotlin / Dart / Python）

```
User: /test-review LoginFlowUseCaseTests.swift

Bot: [分析測試程式碼]

✅ 審查完成！

📊 程式碼品質：95/100 (優秀)

優點：
✅ 測試結構清楚（AAA pattern）
✅ Mock 策略優秀（Protocol-based）
✅ 命名規範清晰

建議改進：
⚠️ 補充並發測試
⚠️ 優化測試資料重用

詳細報告：.claude/testing/reviews/code-review-LoginFlowUseCaseTests-2026-03-04.md
```

## 範例 5: Markdown TC 審查（mode = markdown-only）

```
User: /test-review .claude/testing/features/profile-edit/test-cases-blackbox.md

Bot: [讀取 frontmatter feature: profile-edit]
[Phase 0] 需求主題 = profile-edit

✅ 黑箱審查完成！

📊 總體評分：72/100

[Phase 5] 由於 mode = markdown-only，分數寫入：
.claude/testing/reviews/profile-edit-summary.md
```

## 範例 6: 三方審查（review_protocol.tri_party_enabled = true）

```
User: /test-review https://docs.google.com/spreadsheets/d/xxx/edit

Bot:
✅ Claude 審查完成（80/100）

提示：偵測到三方審查協議啟用，請另外執行：
- Codex: /test-review xxx（從 Codex CLI）
- Gemini: /test-master xxx 審查模式（從 Gemini CLI）

待三方都完成後，輸入「彙整審查報告 {主題}」即可生成綜合評分。
```
