# 自動化測試完成度報表 Template

參考範本：`16z4qVS9wD_Edc4EEFaW2XteSdNqdQthMQez7Js1zeDY`（IOM 自動化測試完成度報表）

## Sheet 結構（7 個 tab）

### Tab 1: 總攬

Dashboard 摘要，含分類統計和視覺化進度條。

```
Row 1: 「📊 {Feature} 自動化測試完成度報表」（標題，合併儲存格）
Row 2: 「更新日期：{date} | 分支：{branch} | 框架：{frameworks}」
Row 3: （空行）
Row 4: Headers → 分類 | 計畫數 | 已完成 | 完成率 | 狀態
Row 5: 🍎 iOS Unit Test | {n} | {n} | {%} | {emoji + 文字}
Row 6: 　　額外覆蓋（計畫外） | {n} | {n} | {%} | ✅ 額外完成
Row 7: 　　iOS 小計 | — | {n} methods | — | 共 {n} 個測試方法
Row 8: 🤖 Android Unit Test | {n} | {n} | {%} | {emoji + 文字}
Row 9: 　　Android 小計 | — | {n} methods | — | 共 {n} 個測試方法
Row 10: 🖥️ UI Automation (Smoke) | {n} | {n} | {%} | {emoji + 文字}
Row 11: 📋 Manual Only | {n} | 0 | — | 🔵 維持手動
Row 12: （空行）
Row 13: 「📈 完成率摘要」（section header）
Row 14: 🍎 iOS Unit Test | | {done}/{total} = {%} | | {進度條}
Row 15: 🤖 Android Unit Test | | {done}/{total} = {%} | | {進度條}
Row 16: 🖥️ UI Automation | | {done}/{total} = {%} | | {進度條}
Row 17: （空行）
Row 18: 🎯 整體可自動化覆蓋率 | | {done}/{total} = {%} | | {進度條}
```

**狀態 emoji 規則：**
- ✅ 全部完成（100%）
- 🔶 部分完成（1-99%）
- ⬜ 未開始（0%）
- 🔵 維持手動（不需自動化）

**進度條格式（Column E）：**
- 用 `█` 和 `░` 組成 30 格寬度的進度條
- 例：100% → `██████████████████████████████ 100%`
- 例：8% → `██░░░░░░░░░░░░░░░░░░░░░░░░░░░░   8%`

### Tab 2: Unit Test 明細

每個自動化 unit test 目標的追蹤。

| Col | Header | 說明 |
|-----|--------|------|
| A | # | 編號 |
| B | 測試目標 | `Class.method()` 格式 |
| C | 平台 | iOS / Android |
| D | 對應 TC-ID | 原始測試用例 ID（可多個，`/` 分隔） |
| E | 原始狀態 | 未測 / ✅ 已有 / 部分 |
| F | 當前狀態 | ✅ 已完成 / 🔶 進行中 / ⬜ 未開始 |
| G | 測試檔案 | 測試檔案名稱 |
| H | 測試數 | 該目標的測試方法數量 |
| I | 備註 | 涵蓋的邊界條件/特殊說明 |

### Tab 3: iOS 測試檔案明細

iOS 平台的測試檔案清單。

| Col | Header | 說明 |
|-----|--------|------|
| A | # | 編號 |
| B | 測試檔案 | `*Tests.swift` |
| C | 測試數 | 該檔案的測試方法數量 |
| D | 測試對象 | 被測的 class/struct 名稱 |
| E | Layer | Configuration / Model / Service / Domain / Store / Diagnostic / UI Test |
| F | 在 Xcode Project 中 | ✅ 已加入 / ❌ 未加入 |

末尾行：小計（總測試方法數）
額外行：UI Test 檔案（如 SmokeUITests.swift）

### Tab 4: Android 測試檔案明細

Android 平台的測試檔案清單，按功能分組。

| Col | Header | 說明 |
|-----|--------|------|
| A | # | 編號 |
| B | 測試檔案 | `*Test.kt` |
| C | 測試數 | 該檔案的測試方法數量 |
| D | 測試對象 | 被測的 class 名稱 |
| E | Layer | ViewModel / Model / UseCase / Validator / UI / Local Storage |
| F | 分支 | develop / feature/xxx / test/xxx |
| G | 狀態 | ✅ 已合併 / ✅ 已驗證 / 🔶 進行中 |

**分組方式（用 section header 分隔）：**
- `▶ {Feature} Feature` — 主要功能測試
- `▶ Data Layer` — 資料層測試
- `▶ Web / SSO` — Web 相關測試

末尾行：小計（總測試數 + 檔案數 + 測試對象數）

### Tab 5: UI Automation 明細

UI 自動化測試進度和 ROI 評估。

| Col | Header | 說明 |
|-----|--------|------|
| A | # | 編號 |
| B | TC-ID | 對應測試用例 ID |
| C | 測試標題 | TC 標題 |
| D | 平台 | iOS / Android / Both |
| E | 當前狀態 | ✅ 已完成 / 🔶 部分 / ⬜ 未開始 / ⬜ Android 範疇 |
| F | 對應測試 | 對應的測試 class 名稱（如 SmokeUITests）或 `—` |
| G | ROI | 高 / 中 / 低 |
| H | 備註 | 技術細節、阻擋因素、建議 |

末尾區：
- 分隔線（`━━━━━━━━━`）
- 📊 小計：{done}/{total} 完成 ({%})
- 🍎 iOS：{n} 完成 + 狀態說明
- 🤖 Android：{n} 完成 + 狀態說明

### Tab 6: 額外完成項目

超出原始計劃的額外覆蓋，記錄計劃外的成果。

| Col | Header | 說明 |
|-----|--------|------|
| A | # | 編號 |
| B | 測試檔案 | 檔案名稱（可加「（額外）」標記） |
| C | 測試數 | 測試方法數量 |
| D | 測試內容 | 涵蓋的測試場景（`/` 分隔多個場景） |
| E | 備註 | 為什麼是額外的（如「原始計畫未列入」） |

### Tab 7: 測試方法清單

所有測試方法的完整列表。

| Col | Header | 說明 |
|-----|--------|------|
| A | # | 全域編號（1, 2, 3...） |
| B | 測試檔案 | `*Tests` class 名稱（不含副檔名） |
| C | 測試方法 | `testMethodName` 或 `方法名稱_場景_預期`（Kotlin 反引號格式） |
| D | 測試說明 | 中文描述：`{測試目標} - {場景描述}` |

## 格式規則

### 顏色方案
- Section header：`#366092`（深藍）底色，白色粗體
- ✅ 已完成：綠色文字
- 🔶 進行中/部分：橘色文字
- ⬜ 未開始：灰色文字
- ❌ 未加入：紅色文字

### 命名規則
- 檔案名稱：`{Feature} 自動化測試完成度報表`
- 更新日期格式：`YYYY-MM-DD`

### 統計公式
- 完成率 = 已完成 / 計畫數
- 整體可自動化覆蓋率 = (iOS 完成 + Android 完成) / (iOS 計畫 + Android 計畫 + UI 計畫)
- 進度條：`=REPT("█", ROUND({%}*30, 0)) & REPT("░", 30-ROUND({%}*30, 0)) & " " & TEXT({%}, "0%")`
