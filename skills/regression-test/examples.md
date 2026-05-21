# Regression Test Examples

## Example 1: Release 1.9.0 回歸測試

### 使用者輸入
```
幫我做 1.9.0 的回歸測試表格
```

### Phase 1 輸出 — Release 需求摘要

| 類型 | 數量 | 重點項目 |
|------|------|---------|
| 新功能 | 5 | Brand Calendar 改版、IM 群組功能、會員等級頁重構 |
| Bug Fix | 8 | 登入 Token 過期處理、推播點擊無反應、地圖 Marker 重疊 |
| 改善 | 3 | 首頁載入速度優化、圖片快取策略調整 |

### Phase 2 輸出 — 歷史 Bug 分析

**重複性問題（過去 3 版出現 2+ 次）：**
| 模組 | 問題描述 | 出現次數 | 最近版本 |
|------|---------|---------|---------|
| 登入/Token | Token refresh 失敗導致登出 | 3 | 1.8.0, 1.7.2, 1.7.0 |
| IM | 聊天室訊息未讀數不同步 | 2 | 1.8.0, 1.7.0 |
| 推播 | 點擊推播後 Deep link 失敗 | 2 | 1.8.0, 1.7.2 |

### Phase 3 輸出 — 風險矩陣

| 模組 | 變更量 | 歷史 Bug | 業務關鍵 | 跨平台 | 重複問題 | 綜合風險 |
|------|--------|---------|---------|--------|---------|---------|
| 登入/認證 | Medium | High | High | Both | Yes | **High** |
| IM/聊天 | High | Medium | High | Both | Yes | **High** |
| Brand Calendar | High | Low | Medium | Both | No | **Medium** |
| 推播/Deep link | Low | Medium | Medium | Both | Yes | **High** |
| 首頁 | Medium | Low | High | Both | No | **Medium** |
| 會員中心 | High | Low | Medium | Both | No | **Medium** |
| 地圖 | Low | Low | Low | Both | No | **Low** |

### Phase 4 輸出 — 回歸測試用例（部分）

| 編號 | 測試區域 | 測試類型 | 測試項目 | 平台 | 優先度 | 風險等級 |
|------|---------|---------|---------|------|--------|---------|
| RT-001 | 登入 | Smoke Test | 帳號密碼登入成功 | Both | P0 | High |
| RT-002 | 首頁 | Smoke Test | 首頁載入並顯示內容 | Both | P0 | Medium |
| RT-003 | IM | Smoke Test | 聊天室列表載入正常 | Both | P0 | High |
| RT-004 | 導航 | Smoke Test | 五大 Tab 切換正常 | Both | P0 | Low |
| RT-005 | 支付 | Smoke Test | 支付流程可完成 | Both | P0 | High |
| RT-010 | Brand Calendar | 新功能驗證 | 改版後日曆正確顯示 | Both | P0 | Medium |
| RT-011 | IM | 新功能驗證 | 群組建立和邀請成員 | Both | P0 | High |
| RT-020 | 登入 | Bug Fix 驗證 | Token 過期後自動 refresh | Both | P0 | High |
| RT-021 | 推播 | Bug Fix 驗證 | 推播點擊正確開啟對應頁面 | Both | P0 | High |
| RT-030 | 登入 | 高風險回歸 | SSO 登入流程完整驗證 | Both | P1 | High |
| RT-031 | IM | 高風險回歸 | 長時間使用後記憶體穩定 | Both | P1 | High |
| RT-040 | 登入/Token | 歷史問題回歸 | 多次 Token refresh 穩定性 | Both | P0 | High |
| RT-041 | IM | 歷史問題回歸 | 未讀數跨裝置同步正確 | Both | P1 | High |

### Phase 5 輸出 — 測試時間估算

| 平台 | P0 | P1 | P2 | 總項目 | 預估天數 | 含 Buffer (x1.2) |
|------|----|----|-----|-------|---------|-----------------|
| iOS | 15 | 12 | 8 | 35 | 5.6 | 6.7 |
| Android | 15 | 12 | 8 | 35 | 5.6 | 6.7 |
| 合計 | 30 | 24 | 16 | 70 | 11.2 | 13.4 |

**建議測試順序：**
1. Smoke Test (0.5 天) — 全 Pass 才繼續
2. 高風險回歸 (2 天) — 登入/IM/推播
3. 新功能驗證 (2 天) — Brand Calendar / IM 群組 / 會員等級
4. Bug Fix 驗證 (1.5 天) — 8 個修復項目
5. 歷史問題回歸 (1 天) — 3 個重複問題
6. Buffer (1.2 天) — 環境問題/retesting

### Phase 6 輸出 — Slack 通知（依 `slack.notification_rules.regression_published`）

```
📋 回歸測試計劃已就緒 — v1.9.0

📊 統計：
- 總測試項目：70 (iOS 35 + Android 35)
- P0: 30 | P1: 24 | P2: 16
- 預估天數：13.4 天（含 buffer）

🔥 高風險模組：登入/認證、IM/聊天、推播/Deep link

📁 Google Sheet：{{JIRA_INSTANCE_URL}}/... (依實際 link)
```

## Example 2: 緊急 Hotfix 回歸

### 使用者輸入
```
1.8.1 hotfix 的回歸測試，只修了兩個 critical bug
```

### 輸出特點
- 測試範圍大幅縮小：只有 Smoke + Bug Fix 驗證 + 受影響模組回歸
- 不需要全面回歸，但 Smoke Test 不可省略
- 時間估算：iOS 1.5 天 + Android 1.5 天

## Example 3: Markdown-only 模式

```
User: /regression-test 1.9.0

Bot: 偵測到 mode = markdown-only，跳過 Google Sheet 整合。

✅ 產出：
- .claude/testing/regression/v1.9.0/overview.md
- .claude/testing/regression/v1.9.0/risk-matrix.md
- .claude/testing/regression/v1.9.0/changelog.md
- .claude/testing/regression/v1.9.0/test-cases.md  (15 欄表格)
- .claude/testing/regression/v1.9.0/history-analysis.md

📊 統計：70 項目 / 預估 13.4 天

切換到 full-mcp 後可重跑此 skill，將表格自動上傳為 Google Sheet。
```
