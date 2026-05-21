# test-automation 使用範例

## 範例 1: 從 Google Sheet 批次生成

```
User: /test-automation https://docs.google.com/spreadsheets/d/1abc.../edit
```

**執行流程：**
1. 讀取 Sheet，找到 Column L = Y 的 TC（共 12 個）
2. 依 Column H 分組：iOS 5 個、Android 3 個、Both 4 個
3. ROI 評估：12 個中 10 個 ROI > 3，2 個建議不自動化（無障礙測試）
4. 生成腳本：
   - `{ProjectName}UITests/TestCase/CheckoutSmokeUITests.swift`（4 個冒煙 UI test）
   - `{ProjectName}Tests/Checkout/CheckoutManagerTests.swift`（3 個 unit test）
   - `{ProjectName}UITests/PageObjects/CheckoutPage.swift`（Page Object）
5. 編譯驗證通過
6. 回寫 Sheet：Column L 更新、Column M 加入檔案路徑

**輸出摘要：**
```
自動化報告
├── 總 TC 數：12
├── 已生成腳本：10（iOS: 7, Android: 3）
├── 跳過：2（無障礙測試 — 需人眼判斷，ROI < 1）
├── 新建 Page Object：1（CheckoutPage）
└── 建議：CheckoutPage 需要補充 3 個 accessibilityIdentifier
```

## 範例 2: 從功能描述生成

```
User: 幫我寫 WebView 模組的 UI test，要測試 Cookie 注入和頁面載入
```

**執行流程：**
1. 搜尋現有程式碼：`WebViewStore`、`CookieManager`（在 `{{IOS_REPO}}` 或本地 repo）
2. 搜尋現有 TC Sheet（如果有）
3. 分析可自動化的場景：
   - Cookie 注入成功 → WebView 載入正確頁面
   - Cookie 過期 → 自動重新注入
   - 無網路 → 顯示錯誤頁面
   - Deep link → WebView 正確攔截
4. 生成 iOS UI Test + Page Object
5. 生成 Android UI Test + Page Object（如果在 Android 專案 `{{ANDROID_REPO}}`）

## 範例 3: ROI 評估 only

```
User: 這些測試能自動化嗎？幫我評估一下
     https://docs.google.com/spreadsheets/d/1xyz.../edit
```

**輸出 ROI 表：**

| TC ID | 標題 | 分類 | ROI | 建議 | 原因 |
|-------|------|------|-----|------|------|
| TC-001 | App 啟動顯示首頁 | 冒煙 | 8.5 | Y | 每次 Release 必跑，步驟簡單 |
| TC-005 | Tab 切換正確 | 冒煙 | 7.2 | Y | 高頻執行，Locator 穩定 |
| TC-012 | 動態 Banner 顯示 | 功能 | 1.2 | N | Banner 內容常變，維護成本高 |
| TC-020 | VoiceOver 朗讀正確 | 無障礙 | 0.5 | N | 需人耳判斷語音品質 |

## 範例 4: 指定平台生成

```
User: 只幫我生成 Android 的 Espresso UI test，功能是登入流程
```

**生成檔案：**
- `app/src/androidTest/java/.../pageobjects/LoginPage.kt`
- `app/src/androidTest/java/.../pageobjects/HomePage.kt`
- `app/src/androidTest/java/.../tests/LoginFlowUITest.kt`

## 範例 5: Markdown-only 模式（純文件輸出）

```
User: /test-automation .claude/testing/features/profile-edit/test-cases-blackbox.md
```

由於 `mode = markdown-only`：
- 不寫回 Sheet，改寫回原 Markdown 表格的 Column L、M
- 報表輸出到 `.claude/testing/automation/profile-edit/report.md`
- 仍會生成實際 `.swift` / `.kt` 測試檔到對應目錄
