# push-notification-test 範例

## 範例 1: 8 大場景全測

```
User: /push-notification-test --platform=ios --scenario=all
```

執行：
1. 從 `config.push_notification.test_devices` 撈 dev tokens
2. 對 8 大場景產生 payload + 發送：
   - Delivery（background / foreground / killed）
   - Click（cold / warm / active / locked）
   - Deep link 跳轉（3 種 payload type）
   - Permission（grant / deny / re-grant）
   - Action buttons
   - 字級放大（Dynamic Type AX5）
   - Localization
   - Silent push

3. 產 Test Plan markdown 給 QA 對著真機跑

## 範例 2: Deep link 驗證

```
User: /push-notification-test --scenario=deeplink
```

執行：
1. 用所有 `myapp://*` schema 發推播
2. 點擊 → 解析路由
3. 驗證：
   - `myapp://orders/12345` → 訂單詳情頁 ✅
   - `myapp://orders/deleted-id` → 訂單列表 + 提示 ✅
   - `myapp://restricted/admin` → 需要管理員 → 登入頁 ⚠️

## 範例 3: 跨平台對齊

```
User: 我改了 push payload schema，要驗 iOS + Android 都對齊
```

執行：
1. 用同一 payload 發 APNs + FCM
2. 對比兩平台行為：
   - 通知 banner 文案一致
   - 點擊 routing 一致
   - 圖示 / 顏色 平台符合慣例

→ 找到 Android title 用 `notification.title` 但 iOS 用 `aps.alert.title`（payload 結構差）

## 範例 4: 大批推播壓測

```
User: /push-notification-test --scenario=batch --recipients=1000000
```

執行：
1. 模擬發 100 萬人推播
2. 監控：
   - 後端送出時間 < 5 分鐘
   - APNs / FCM throttle 處理
   - 後續推播 (after spike) 仍正常送達

跟 `performance-test-gen` 配合跑。
