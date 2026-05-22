---
name: push-notification-test
description: 推播通知測試專屬流程，覆蓋 APNs（iOS）/ FCM（Android）/ Web Push 三大平台。驗證送達率、點擊行為（cold start / warm / background）、Deep link 跳轉、權限拒絕後 fallback、字級放大不破版、batch 大量推播效能。當使用者提到「推播測試 / push notification / APNs / FCM / Deep link / 通知點擊 / 推播權限 / 推播送達率 / silent push / 通知 Action button」時觸發。配套：test-master（規劃 push TC）、test-automation（push UI test）、a11y-audit（推播在 lock screen 的 a11y）、bug-report（push 相關 bug）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[平台 ios|android|web] [--scenario=delivery|click|deeplink|permission|all]"
---

# push-notification-test

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。

## 為什麼推播測試容易出包

推播流程跨 4 個系統：
1. **你的後端** → 發送
2. **APNs / FCM** → 路由 + 鎖屏渲染
3. **OS（iOS / Android）** → 通知中心 / 權限
4. **App** → 啟動 / Deep link / 狀態還原

任何一段壞，使用者看不到通知。
且**只有真實裝置才能完整測試**（Simulator 不支援推播）。

## 適用場景

- ✅ 有用 push 的 App（行銷推播 / 訂單通知 / 即時訊息 / 提醒）
- ✅ 改 push payload schema 前（容易壞 Deep link）
- ✅ 升 iOS / Android 主版本後（權限機制常變）
- ✅ 改 App 圖示 / 名稱後（通知 banner 可能跑掉）

## 不適用場景

- ❌ App 完全不用推播
- ❌ 純後端發送邏輯 — 用 `tc-to-pytest` 測 API

## 8 大測試場景

### 1. 送達率測試（Delivery）

| 測試 | 期望 |
|------|------|
| 一般推播（App 在 background）| 10 秒內顯示在通知中心 |
| App 在 foreground | UI 內 in-app 提示 + 不顯系統 banner |
| App killed / 重啟手機 | 仍能收到（除非禁止）|
| 弱網 / 飛航模式 | 開啟後立刻補送 |
| Silent push（content-available）| 不顯通知但喚醒 App |

### 2. 點擊行為（Click handling）

各狀態下點擊推播：

| 狀態 | 期望行為 |
|------|---------|
| **Cold start**（App 完全沒在跑）| 啟動 App → 直接跳目標頁 |
| **Warm**（App 在 background）| 回到 App → 跳目標頁 |
| **Active**（App 在 foreground）| 直接跳目標頁 |
| **Locked**（鎖屏）| 解鎖後跳目標頁 |

### 3. Deep link 跳轉

對每種 payload type：

```json
{
  "aps": { "alert": "新訂單！", "category": "ORDER" },
  "deep_link": "myapp://orders/12345",
  "campaign_id": "summer-sale"
}
```

驗證：
- `myapp://orders/12345` → 正確跳到訂單詳情頁
- 訂單 ID 解析正確
- 已登出狀態 → 先去登入 → 登入後跳目標
- 訂單已刪除 → 跳列表 + 提示「訂單不存在」

### 4. 權限處理

| 場景 | 期望 |
|------|------|
| 首次 App 啟動 | 在合適時機（不是一啟動就問）跳權限對話框 |
| 使用者「不允許」| in-app 引導去設定開啟 |
| 使用者後來開啟 | App 偵測到 + 自動重新註冊 token |
| iOS 15+ Provisional auth | 安靜送達，使用者第一次看到後選擇 |

### 5. Action buttons

豐富推播 (rich push):
- 訂單通知含「查看」/「忽略」按鈕
- 訊息推播含「回覆」/「標已讀」按鈕

驗證：
- 按鈕顯示正確（label / icon）
- 點擊正確 routing
- 不啟動 App 即可處理（Notification Service Extension）

### 6. 字級放大不破版

推播在鎖屏顯示時：
- iOS Dynamic Type 最大 → title 不截斷或要明顯標 ...
- Android 字型大小最大 → 同上
- emoji 在所有字級下大小一致

### 7. Localization

推播 title / body 在不同 locale 下：
- 翻譯正確（**用伺服器端翻譯**或 `loc-key` + APNs localization）
- 字串長度不爆 banner

→ 配合 `localization-test` skill。

### 8. 大批推播效能

行銷推播 send 100 萬人：
- 後端送出時間 < N 分鐘
- APNs / FCM 回應 throttle 處理
- App 重啟 (cold) 不卡 → 必須在主執行緒外處理

## 執行流程

### Phase 1: 設定環境

```yaml
# iOS
APNs: 用 development cert (sandbox) / production cert
測試裝置: 真實裝置（必）

# Android
FCM: server key + sender id
測試裝置: 真實 / emulator with Google Play Services

# 工具
- Postman + push templates
- Apple Push Notification Tool (Pusher)
- Firebase Console
- Knuff (mac, free)
```

### Phase 2: 生成測試 payload

對每個情境生 payload + 跑送達工具：

```bash
# 用 curl + APNs
curl -v -d '{"aps":{"alert":"Test"},"deep_link":"myapp://test"}' \
  --http2 --cert apns-cert.pem \
  https://api.development.push.apple.com/3/device/<device-token>
```

### Phase 3: 自動化 + 人工檢查

| 場景 | 可自動化 | 需人工 |
|------|---------|--------|
| Deep link 解析 | ✅ Unit test | 推播觸發要人 |
| Payload schema | ✅ Contract test | - |
| 字級放大 banner | ❌ | ✅ 截圖比對 |
| 鎖屏 a11y | ❌ | ✅ VoiceOver 讀通知 |

混合：可自動化的進 CI，人工的列 checklist。

### Phase 4: 監控指標

上線後 dashboard 看：
- 送達率（>95% 健康）
- 點擊率（CTR）
- Permission grant rate
- token registration success rate

## ⚠️ 安全護欄

- ❌ 推播測試**不發給真實使用者**（用 dev token 隊伍）
- ✅ Production cert 嚴格 IAM 控制
- ⚠️ Silent push 不能用於跟蹤使用者（隱私政策合規）

## 設定依賴

| 設定 Key | 用途 | 預設 |
|---------|------|------|
| `push_notification.platforms` | 啟用平台 | [ios, android] |
| `push_notification.test_devices` | dev token 清單 | [] |
| `push_notification.deep_link_scheme` | App URL scheme | "" |
| `push_notification.payload_templates_dir` | payload 範本目錄 | tests/push/ |

## 範例

詳見 [`examples.md`](./examples.md)
