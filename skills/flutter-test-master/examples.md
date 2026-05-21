# Flutter Test Master Examples

## 範例 1: 基於 JIRA 票號（Flutter 專案）

```
User: /flutter-test-master {{JIRA_PROJECT_KEY}}-6207

執行步驟：
1. 使用 Atlassian MCP 抓取 {{JIRA_PROJECT_KEY}}-6207 需求
2. 偵測專案架構：
   - 讀 pubspec.yaml 確認 Flutter 版本、state management
   - Grep state_management 套件（riverpod / provider / bloc）
3. 搜尋相關 Dart 檔案：
   - Glob: lib/**/[feature]*.dart
   - Glob: lib/**/view_models/[feature]*.dart
   - Glob: lib/**/repositories/[feature]*.dart
4. 分析現有測試覆蓋：
   - test/unit/**/*_test.dart
   - test/widget/**/*_test.dart
   - integration_test/**/*_test.dart
5. 生成：
   - flutter-test-strategy.md
   - 黑箱 TC Sheet（QA 執行）
   - 白箱 TC Sheet（開發 + QA）
   - 可執行 Dart 測試程式碼骨架
6. 上傳至 QA-TC 共用硬碟 → 發 Slack 通知
```

## 範例 2: 基於功能描述（無 JIRA）

```
User: /flutter-test-master
功能：使用者可以在 Flutter 支付頁面輸入卡號，經由 Platform Channel 呼叫原生 SDK 處理金流，7 分鐘內重新驗證身份

執行步驟：
1. 分析功能需求
2. 風險識別：
   - ⚠️ 金流 → P0
   - ⚠️ Platform Channel → 雙層測試必要
   - ⚠️ 7 分鐘驗證 → 狀態管理
3. 搜尋：
   - Grep MethodChannel 確認 channel 名稱
   - Grep 現有 payment 相關 ViewModel
4. 生成測試計劃：
   - Unit: PaymentViewModel（Fake channel handler）
   - Widget: PaymentScreen（Fake ViewModel）
   - Integration: 完整支付 E2E（Firebase Test Lab）
   - Golden: 支付成功/失敗頁（UI 穩定後）
   - Platform Channel: 雙邊驗證
```

## 範例 3: Flutter + Native 混合專案

```
User: /flutter-test-master {{JIRA_PROJECT_KEY}}-1234
（需求涉及 Flutter 畫面 + 原生登入模組）

執行步驟：
1. 偵測混合架構：
   - Flutter: lib/login/ 新登入 UI
   - Native iOS: ios/Runner/Legacy/ 舊登入邏輯
   - Native Android: android/app/src/main/java/.../legacy/
2. 拆分測試範圍：
   - Flutter 層 → 本 skill 生成
   - Native 層 → 提示使用 test-master 生成
3. 特別關注：
   - Platform Channel 橋接測試（integration test 必要）
   - 狀態在兩層間的傳遞
4. 輸出：
   - Flutter 測試（本 skill）
   - 提示：「Native 部分請另外執行 /test-master {{JIRA_PROJECT_KEY}}-1234」
```

## 範例輸出（摘要）

```
✅ Flutter 測試計劃生成完成

🧪 測試金字塔分配：
- Unit Test: 70% (28 cases)
  - ViewModel: 10 / Repository: 8 / Service: 6 / Utility: 4
- Widget Test: 20% (8 cases)
  - Screen: 5 / 自訂 widget: 3
- Integration Test: 10% (4 cases)
  - 登入 / 支付 / 設定 / 深層連結

📊 黑箱測試用例：
- 總數：32 個
  - 冒煙-Feature Done: 5
  - 功能測試: 12
  - 異常/邊界測試: 8
  - Widget Test: 5
  - Integration Test: 2
- P0: 8 / P1: 14 / P2: 10
- 平台：Both 28 / iOS 2 / Android 2

📊 白箱測試用例：
- 總數：22 個
  - Unit（ViewModel）: 8
  - Unit（Repository）: 6
  - Platform Channel: 4
  - Golden Test: 2
  - 效能/記憶體: 2
- P0: 4 / P1: 12 / P2: 6

📁 生成檔案：
- flutter-test-strategy.md
- test-cases-{feature}-blackbox.xlsx
- test-cases-{feature}-whitebox.xlsx
- coverage-gaps.md
- automation-plan.md
- exploratory-guide.md
- code-skeleton/
  ├── test/unit/view_models/[feature]_view_model_test.dart
  ├── test/widget/[feature]_screen_test.dart
  ├── test/fakes/fake_[feature]_repository.dart
  └── integration_test/[feature]_flow_test.dart

🎯 關鍵風險：
- ⚠️ Platform Channel 缺少錯誤處理測試 → 白箱 P0
- ⚠️ 7 分鐘 token 過期狀態測試 → 黑箱 P0
- ⚠️ Isolate 通訊異常 → 白箱 P1

🔄 架構層覆蓋：
- ViewModel: ✅ 10/10 有 unit test
- Repository: ✅ 8/8 有 unit test（Mock HTTP）
- View: ✅ 5/5 有 widget test（Fake VM）
- Platform Channel: ⚠️ 2/4 有 Dart 測試，原生層未覆蓋

📋 下一步：
1. 上傳測試用例至 Google Drive QA-TC 資料夾
2. 把 code-skeleton/ 交給 Tadashi / CheJu 團隊
3. Review 黑箱 TC（QA 團隊）
4. CI 整合：flutter test --coverage
5. Firebase Test Lab 設置（支付 E2E）
```

## 範例 4: 快速模式（只要 TC）

```
User: /flutter-test-master --mode=quick
功能：在集章頁面加入「最近集章時間」顯示

執行步驟（簡化）：
1. 只生成黑箱 + 白箱 Google Sheet
2. 略過 test-strategy、coverage-gaps、code-skeleton
3. 大約 1-2 分鐘完成
```

## 範例 5: 深度模式（含可執行程式碼）

```
User: /flutter-test-master {{JIRA_PROJECT_KEY}}-6207 --mode=deep

執行步驟（完整）：
1. 全部 8 個 Phase 都執行
2. code-skeleton/ 產出**可直接執行**的 Dart 測試
3. 包含 Fake 實作的完整程式碼
4. 包含 Golden baseline 的 placeholder
5. 包含 CI yaml 片段
```

---

## 觸發關鍵字範例

以下使用者輸入都會觸發本 skill：
- 「幫我寫 Flutter 測試」
- 「這個 Flutter 功能要怎麼測」
- 「{{JIRA_PROJECT_KEY}}-XXX 是 Flutter，寫 TC」
- 「Widget test 怎麼規劃」
- 「我要做 integration_test」
- 「給我 Golden test 的建議」
- 「Flutter QA 計劃」
- 「flutter test plan for [feature]」

## 不會觸發本 skill 的情境（改觸發 test-master）

- 「{{JIRA_PROJECT_KEY}}-XXX 寫 TC」（預設假設原生，除非明確提到 Flutter）
- 「iOS Swift 測試」
- 「Android Kotlin 測試」
- 「Espresso / XCUITest」

---

## 範例 6: a11y 字級縮放的跨平台配對（Flutter 情境）

### 背景
即使 Flutter 是單一 codebase，**iOS Dynamic Type 與 Android fontScale 仍是兩套觸發機制**，需要雙平台驗證。

### 歷史案例（原生版）
- [APP-395]({{JIRA_INSTANCE_URL}}/browse/APP-395) — Android
- [APP-399]({{JIRA_INSTANCE_URL}}/browse/APP-399) — iOS
- 用 Relates 連結 → 修復時不會漏

### Flutter 版的預防性 TC

Skill 偵測到**文字/數字顯示**功能時，自動產出：

| TC-ID | 標題 | 測試類型 |
|-------|------|---------|
| BB-FLT-A11Y-01 | `TextScaler.linear(3.0)` 下內容文字跟隨放大且不破版 | Widget Test |
| BB-FLT-A11Y-02 | 裝飾性數字（計數/徽章）使用 `TextScaler.noScaling` 固定大小 | Widget Test |
| BB-FLT-A11Y-03 | iOS Dynamic Type 最大時雙平台行為一致 | Manual / Integration |
| BB-FLT-A11Y-04 | Android fontScale 最大時雙平台行為一致 | Manual / Integration |
| BB-FLT-A11Y-05 | Semantics label 與 VoiceOver / TalkBack 讀取順序 | Integration |

### 自動化優先項目（Widget Test 最划算）

```dart
testWidgets('reaction count ignores text scaling', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
        child: ReactionCountWidget(count: 12),
      ),
    ),
  );
  final textSize = tester.widget<Text>(find.text('12')).style?.fontSize;
  expect(textSize, 12, reason: '裝飾性計數不應隨系統字級放大');
});
```

詳細 checklist 見 `@templates.md` 的「a11y-checklist 模板（Flutter 版）」。
