# Flutter Automation 完成度報表模板

上傳至 Google Sheet，包含 7 個 Tab。

---

## Tab 1: 總攬（Dashboard）

| 指標 | 數值 |
|------|------|
| Feature | [功能名稱] |
| 關聯 JIRA | {{JIRA_PROJECT_KEY}}-XXXX |
| Flutter 版本 | 3.24.x |
| 生成日期 | 2026-04-20 |
| 總 TC 數 | 42 |
| 已自動化 | 32 (76%) |
| ROI > 3 | 28 |
| 手動保留 | 10 |

### 三層金字塔分佈

| 層級 | 目標 | 已完成 | 完成率 | 佔比 |
|------|------|-------|--------|------|
| Unit Test | 30 | 28 | 93% | 72% |
| Widget Test | 10 | 8 | 80% | 21% |
| Integration Test | 4 | 3 | 75% | 7% |

### 進度視覺化

```
Unit       ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░  93%
Widget     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░  80%
Integration ▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░  75%
Golden      ▓▓▓▓▓▓▓▓░░░░░░░░░░░  40%
Platform CH ▓▓▓▓▓▓▓▓▓▓░░░░░░░░░  50%
```

### 覆蓋率

| 指標 | 值 |
|------|------|
| Line coverage | 78% |
| Branch coverage | 65% |
| 目標 | 80% line / 70% branch |

---

## Tab 2: Unit Test 明細

| TC-ID | 測試對象 | 類型 | 檔案 | 測試方法 | 狀態 | 備註 |
|-------|---------|------|------|---------|------|------|
| BB-FLT-001 | LoginViewModel | ViewModel | `test/unit/view_models/login_view_model_test.dart` | successful_login_sets_authenticated | ✅ | Fake 注入 |
| BB-FLT-002 | LoginViewModel | ViewModel | (同上) | wrong_password_shows_error | ✅ | |
| BB-FLT-010 | AuthRepository | Repository | `test/unit/repositories/auth_repository_test.dart` | fetch_user_falls_back_on_500 | ✅ | Mocktail HTTP |
| BB-FLT-020 | TokenValidator | Utility | `test/unit/utilities/token_validator_test.dart` | expired_token_returns_false | ⏳ | 待實作 |

---

## Tab 3: Widget Test 明細

| TC-ID | Screen/Widget | 檔案 | 測試方法 | Fake 注入 | 狀態 |
|-------|--------------|------|---------|----------|------|
| BB-FLT-030 | LoginScreen | `test/widget/login_screen_test.dart` | shows_error_when_email_empty | FakeAuthRepo | ✅ |
| BB-FLT-031 | LoginScreen | (同上) | navigates_on_successful_login | FakeAuthRepo | ✅ |
| BB-FLT-040 | PaymentScreen | `test/widget/payment_screen_test.dart` | shows_loading_during_pay | FakePaymentVM | ⏳ |

---

## Tab 4: Integration Test 明細

| TC-ID | 流程 | 檔案 | iOS | Android | Web | Firebase Test Lab |
|-------|-----|------|-----|---------|-----|-------------------|
| BB-FLT-E2E-001 | 登入 → 首頁 | `integration_test/login_flow_test.dart` | ✅ | ✅ | ✅ | ✅ |
| BB-FLT-E2E-002 | 支付完整流程 | `integration_test/payment_flow_test.dart` | ✅ | ✅ | ❌ | ✅ |
| BB-FLT-E2E-003 | 深層連結 | `integration_test/deeplink_flow_test.dart` | ⏳ | ⏳ | N/A | ⏳ |

---

## Tab 5: Golden Test 明細

| TC-ID | Widget | 檔案 | iOS baseline | Android baseline | 差異容忍 | 狀態 |
|-------|--------|------|--------------|------------------|---------|------|
| BB-FLT-G-001 | LoginScreen | `test/golden/login_screen_golden_test.dart` | `goldens/ios/login_screen.png` | `goldens/android/login_screen.png` | 0.5% | ✅ |
| BB-FLT-G-002 | PaymentSuccessScreen | `test/golden/payment_success_golden_test.dart` | ⏳ | ⏳ | - | ⏳ |

**Golden 執行指令**：
- 建立 baseline: `flutter test --update-goldens test/golden/`
- 驗證: `flutter test test/golden/`

---

## Tab 6: Platform Channel 明細

| TC-ID | Channel | Dart 測試 | iOS 測試 (XCTest) | Android 測試 (JUnit) | 狀態 |
|-------|---------|----------|------------------|---------------------|------|
| WB-FLT-PC-001 | com.example/payment | ✅ `test/unit/services/payment_service_test.dart` | ✅ `ios/RunnerTests/PaymentPluginTests.swift` | ✅ `android/app/src/test/.../PaymentPluginTest.kt` | 完整 |
| WB-FLT-PC-002 | com.example/biometric | ✅ `test/unit/services/biometric_service_test.dart` | ⏳ | ⏳ | 部分 |
| WB-FLT-PC-003 | com.example/analytics | ⏳ | ❌ | ❌ | 未開始 |

---

## Tab 7: 測試方法清單

| 檔案 | 測試方法 | 中文說明 | TC-ID |
|------|---------|---------|-------|
| `test/unit/view_models/login_view_model_test.dart` | `successful_login_sets_authenticated_state` | 成功登入後狀態為已驗證 | BB-FLT-001 |
| (同上) | `wrong_password_shows_error` | 密碼錯誤顯示錯誤訊息 | BB-FLT-002 |
| (同上) | `network_error_shows_generic_message` | 網路錯誤顯示通用訊息 | BB-FLT-003 |
| `test/widget/login_screen_test.dart` | `shows_error_when_email_empty` | Email 為空時顯示錯誤 | BB-FLT-030 |
| (同上) | `navigates_on_successful_login` | 登入成功後跳轉首頁 | BB-FLT-031 |
| `integration_test/login_flow_test.dart` | `user_can_login_and_see_home` | 使用者可登入並看到首頁 | BB-FLT-E2E-001 |

---

## 📊 報表產出規則

1. **上傳位置**: `APP-Release > QA-TC > [Feature Name]-automation-report`
2. **命名**: `[Flutter] [Feature] Automation Report - YYYY-MM-DD`
3. **色彩編碼**:
   - ✅ 綠色 — 已完成
   - ⏳ 黃色 — 進行中
   - ❌ 紅色 — 未開始 / 阻塞
4. **關聯**: 在測試用例 Sheet 的 Column M 加入本報表連結

---

## 🔔 完成通知範本（Slack）

```
🎯 Flutter 自動化完成：[Feature Name]

📊 三層金字塔：
- Unit: 28/30 (93%)
- Widget: 8/10 (80%)
- Integration: 3/4 (75%)

📈 覆蓋率：Line 78% / Branch 65%

📁 完成度報表：[Sheet URL]
📁 測試用例：[原 TC Sheet URL]

✅ CI 已整合（GitHub Actions）
⚠️ Golden baseline 待建立
```
