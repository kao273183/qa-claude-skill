# Flutter Test Automation Examples

---

## 範例 1: 從 Google Sheet TC 生成 Dart 腳本

```
User: /flutter-test-automation https://docs.google.com/spreadsheets/d/[SHEET_ID]

執行步驟：
1. 讀取 Sheet 的「黑箱 TC」分頁
2. 篩選 Column L（自動化）= Y 的項目
3. 按 Column F（測試分類）分組：
   - 功能測試 → Unit + Widget
   - Widget Test → Widget
   - Integration Test → Integration
   - Platform Channel → Dart + Native
4. 偵測專案架構：
   - 讀 pubspec.yaml
   - 找現有 Fake 實作
   - 找 Robot/Page Object 慣例
5. 生成 Dart 測試檔案（放在正確位置）
6. 執行 `flutter test` 確認通過
7. 回寫 Google Sheet Column M 加入檔案路徑
8. 生成完成度報表（新 Sheet）
```

## 範例 2: 從 JIRA 票號直接自動化

```
User: /flutter-test-automation {{JIRA_PROJECT_KEY}}-6207

執行步驟：
1. 抓取 {{JIRA_PROJECT_KEY}}-6207 需求
2. 搜尋對應的 Google Sheet TC（沒有就提示使用者先跑 /flutter-test-master）
3. 按照範例 1 流程進行
```

## 範例 3: 針對特定 Dart 檔案補強測試

```
User: /flutter-test-automation lib/features/login/login_view_model.dart

執行步驟：
1. 讀取 login_view_model.dart
2. 分析公開方法與 state 邏輯
3. 搜尋既有測試：test/unit/view_models/login_view_model_test.dart
4. 比對覆蓋差異
5. 生成補強測試 case（按 AAA 結構）
6. 執行驗證
```

## 範例 4: 只要 ROI 評估（不生成）

```
User: /flutter-test-automation [SHEET_URL] --mode=roi-only

執行步驟：
1. 讀取 TC
2. 對每個 TC 計算 ROI
3. 輸出建議清單（哪些值得自動化）
4. 不生成程式碼
```

## 範例 5: 生成並推送到 CI

```
User: /flutter-test-automation [SHEET_URL] --ci=github-actions

執行步驟：
1. 生成 Dart 測試檔
2. 額外產出 .github/workflows/flutter-test.yml
3. 包含：flutter test / integration / coverage / Firebase Test Lab
4. 產出 PR-ready checklist
```

---

## 範例輸出（摘要）

```
✅ Flutter 自動化腳本生成完成

📊 ROI 評估：
- 總 TC 數：42
- 建議自動化：28 (67%)
  - Unit: 15 / Widget: 10 / Integration: 3
- 不建議自動化：14
  - 視覺判斷 UX：8
  - 一次性驗證：4
  - 頻繁改版 UI：2

📁 生成檔案：
test/
├── unit/
│   ├── view_models/
│   │   ├── login_view_model_test.dart        (5 test cases)
│   │   └── payment_view_model_test.dart      (7 test cases)
│   └── repositories/
│       ├── auth_repository_test.dart          (4 test cases)
│       └── payment_repository_test.dart       (6 test cases)
├── widget/
│   ├── login_screen_test.dart                (3 test cases)
│   ├── payment_screen_test.dart              (4 test cases)
│   └── robots/
│       ├── login_robot.dart
│       └── payment_robot.dart
├── golden/
│   └── payment_success_golden_test.dart      (1 baseline)
└── fakes/
    ├── fake_auth_repository.dart
    └── fake_payment_repository.dart

integration_test/
├── login_flow_test.dart                       (2 test cases)
└── payment_flow_test.dart                     (1 test case)

✅ 編譯檢查：flutter analyze — 0 errors
✅ 執行結果：flutter test — 32 passed / 0 failed
⚠️ Golden baseline：需首次執行 `flutter test --update-goldens` 建立

📋 下一步：
1. Review 生成的測試檔
2. 首次執行 `flutter test --update-goldens` 建立 golden baseline
3. 整合到 CI（.github/workflows/flutter-test.yml 已生成）
4. 上傳完成度報表至 QA-TC 雲端硬碟
5. 通知 Tadashi / CheJu 團隊 Review

🔗 完成度報表：
https://docs.google.com/spreadsheets/d/[NEW_SHEET_ID]
```

---

## 觸發關鍵字範例

會觸發本 skill：
- 「把這份 Flutter TC 自動化」
- 「幫我寫 Dart widget test」
- 「flutter integration_test 怎麼生」
- 「這個 Flutter feature 的 TC 哪些可以自動化」
- 「寫 patrol 測試」
- 「Golden test 自動化」
- 「ROI 評估這份 Flutter TC」
- 「flutter test 腳本」

不會觸發本 skill（改觸發 test-automation）：
- 「寫 XCUITest」
- 「Android Espresso 腳本」
- 「把這份 Swift TC 自動化」
- 「iOS UI test」

---

## 與 flutter-test-master 搭配使用

完整工作流：

```
1. /flutter-test-master {{JIRA_PROJECT_KEY}}-6207
   → 產出 Google Sheet TC（含 Column L 自動化標記）

2. /flutter-test-automation [產出的 Sheet URL]
   → 讀取 L=Y 的 TC，生成 Dart 測試腳本

3. /test-review [產出的測試檔]
   → 審查測試品質

4. /smoke-test-analyzer
   → 選出每日 smoke CI 要跑的集合
```
