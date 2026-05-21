# Test Master Templates

## test-strategy.md 模板

```markdown
# 測試策略：[功能名稱]

## 功能概述
[簡要描述功能]

## 測試目標
- 功能正確性：驗證所有需求都正確實作
- 穩定性：無 crash、memory leak、race condition
- 效能：[具體指標，如：API 回應 < 2s]
- 相容性：iOS [版本範圍] + Android [版本範圍]
- **跨平台一致性**：雙平台行為與 UI 表現一致

## 測試範圍

### In Scope（需要測試）
- ✅ [功能點 1]（iOS + Android）
- ✅ [功能點 2]（iOS + Android）
- ✅ [錯誤處理]
- ✅ [邊界條件]
- ✅ [平台特有行為]

### Out of Scope（不測試）
- ❌ [第三方 SDK 內部邏輯]
- ❌ [已有完整測試的模組]

## 平台實作比對

| 功能點 | iOS 實作 | Android 實作 | Web 實作 | 差異/風險 |
|--------|---------|-------------|---------|----------|
| [功能 1] | [檔案/類別] | [檔案/類別] | [Component/Route] | [差異說明] |
| [功能 2] | [檔案/類別] | [檔案/類別] | [Component/Route] | [差異說明] |

> Web 欄位僅在 `platforms.web.enabled = true` 時填入。

## 測試金字塔分配

| 層級 | 比例 | iOS 測試內容 | Android 測試內容 | Web 測試內容 |
|------|------|-------------|-----------------|---------------|
| Unit | 70% | ViewModel, Repository, UseCase | ViewModel, Repository, UseCase | Pure functions, Hooks, Utils |
| Integration | 20% | API 整合, SDK 整合 | API 整合, SDK 整合 | Component test, MSW mocks |
| UI / E2E | 10% | 關鍵流程 XCUITest | 關鍵流程 Espresso | Playwright / Cypress E2E |

> Web 跨瀏覽器要求：E2E 至少跑 `platforms.web.default_browsers` 中列出的 browsers（預設 Chrome + Safari）。

## 風險矩陣

| 風險 | 平台 | 影響 | 可能性 | 優先級 | 測試策略 |
|------|------|------|--------|--------|---------|
| [風險 1] | Both | High | Medium | P0 | [具體策略] |
| [風險 2] | iOS | Medium | High | P1 | [具體策略] |
```

---

## coverage-gaps.md 模板

```markdown
# 測試覆蓋缺口分析

## iOS 現有測試
✅ 已有測試：
- [TestClass1]（[功能描述]）

❌ 缺少測試：
- [ ] [缺失功能 1]（TC-XXX）
- [ ] [缺失功能 2]（TC-XXX）

## Android 現有測試
✅ 已有測試：
- [TestClass1]（[功能描述]）

❌ 缺少測試：
- [ ] [缺失功能 1]
- [ ] [缺失功能 2]

## 跨平台缺口
⚠️ 雙平台不一致：
- [ ] iOS 有測試但 Android 沒有：[列表]
- [ ] Android 有測試但 iOS 沒有：[列表]
- [ ] 雙平台都缺少：[列表]

## 優先級建議
1. P0: [缺口 1] - 影響核心功能（Both）
2. P1: [缺口 2] - 高風險區域（iOS only）
```

---

## automation-plan.md 模板

```markdown
# 自動化測試路線圖

## ROI 分析

| 測試案例 | 手動時間 | 自動化成本 | 執行頻率 | ROI | 建議 |
|---------|---------|-----------|---------|-----|------|
| TC-001 | 2 min | 4 hours | 每日 | High | ✅ 優先自動化 |
| TC-015 | 5 min | 8 hours | 每週 | Low | ❌ 保持手動 |

## 自動化路線圖

### Phase 1: 立即自動化（本週）
- TC-001: [描述]

### Phase 2: 中期自動化（2-4 週）
- TC-006: [描述]

### Phase 3: 長期自動化（1-2 個月）
- TC-024: [描述]

### 不建議自動化（手動測試）
- TC-025: [原因]
```

---

## a11y-checklist 模板

每個 UI 功能 TC 生成時，自動附加此 checklist（作為必檢項目）：

```markdown
# a11y（輔助功能）測試檢查清單

## 1. 字級縮放

### iOS
- [ ] 設定 → 顯示與亮度 → 文字大小 → **最大**
- [ ] 設定 → 輔助使用 → 顯示與文字大小 → **較大字體 → 最大**（超大級距 AX5）
- [ ] 機制：Dynamic Type（`UIFont.preferredFont(forTextStyle:)`）

### Android
- [ ] 設定 → 顯示 → 字型大小 → **最大**
- [ ] 設定 → 顯示 → 顯示大小 → **最大**（會影響整體 layout）
- [ ] 機制：`sp` 會跟隨縮放 / `dp` 不會

### 驗證項目
- [ ] 內容文字（title/body/description）跟隨放大
- [ ] 版面不破版、不截斷、不重疊
- [ ] **裝飾性數字**（計數、徽章、反應 count）**不應跟隨放大**（固定 dp / 固定 size）
- [ ] 按鈕文字放大後仍在按鈕範圍內
- [ ] ScrollView 可正常滾動看到所有內容
- [ ] Tab Bar / NavigationBar 高度與位置不變化

## 2. 螢幕閱讀器

### iOS VoiceOver
- [ ] 設定 → 輔助使用 → VoiceOver 開啟
- [ ] 所有互動元件有 `accessibilityLabel`
- [ ] 讀取順序符合視覺順序
- [ ] 圖片有適當 label 或標為裝飾（`isAccessibilityElement = false`）

### Android TalkBack
- [ ] 設定 → 輔助使用 → TalkBack 開啟
- [ ] 所有互動元件有 `contentDescription`
- [ ] focusable / clickable 元件順序正確
- [ ] 非互動裝飾圖片 `importantForAccessibility = no`

## 3. 觸控目標
- [ ] iOS：可點擊區域 ≥ 44×44 pt
- [ ] Android：可點擊區域 ≥ 48×48 dp

## 4. 對比度
- [ ] 淺色模式：文字 vs 背景 ≥ 4.5:1（WCAG AA）
- [ ] **深色模式**：文字 vs 背景 ≥ 4.5:1

## 5. 動畫與動作
- [ ] 設定 → 輔助使用 → Reduce Motion / 移除動畫 → 開啟
- [ ] 主要動畫改用淡入淡出或直接完成
- [ ] 視差效果不使頭暈

## 6. 顏色非唯一訊息
- [ ] 錯誤狀態不只靠紅色（加文字 / icon）
- [ ] 成功/失敗不只靠綠/紅（色盲友善）

## 7. Root Cause 快速對照（若跑版）

| 平台 | 檢查點 | 正確做法 |
|------|--------|---------|
| iOS UIKit | `adjustsFontForContentSizeCategory = true` | 改 `false` + `UIFont.systemFont(ofSize:)` |
| iOS SwiftUI | `.font(.caption)` 等 text style | `.font(.system(size:))` + `.dynamicTypeSize(.large)` 上限 |
| Android View | `android:textSize="14sp"` | 改 `"14dp"` 或包裝覆寫 `Configuration.fontScale` |
| Android Compose | `fontSize = 14.sp` | 裝飾性數字改固定 dp，或外層 `LocalDensity` 覆寫 |
| Flutter | `MediaQuery.textScaleFactor` 未覆寫 | wrap `MediaQuery(data: ..copyWith(textScaler:))` |

## 8. 跨平台配對原則

- a11y 類 bug / 優化單**預設開一對**（iOS + Android）
- 用 JIRA Relates link 連結
- 範例：`{{JIRA_PROJECT_KEY}}-001`（Android）↔ `{{JIRA_PROJECT_KEY}}-002`（iOS）字級跑版
```

---

## exploratory-guide.md 模板

```markdown
# 探索性測試指引

## 測試章程（Test Charter）
探索 [功能名稱] 在 [特定條件] 下的 [特定風險]

## 測試區域

### 1. 邊界探索
- [ ] 最小輸入 / 最大輸入 / 空輸入 / 特殊字元

### 2. 狀態轉換
- [ ] 所有畫面切換 / 返回按鈕 / 深層連結

### 3. 中斷測試
- [ ] 電話來電 / 推播通知 / 網路中斷 / 記憶體警告

### 4. 裝置覆蓋

**iOS：**
- [ ] 最小螢幕機型 / 最大螢幕機型（含 Dynamic Island / Notch）
- [ ] 最低支援版本（`{{MIN_IOS_VERSION}}`）/ 最新版本（`{{IOS_DEFAULT_VERSION}}`）

**Android：**
- [ ] 小螢幕（< 5.5"）/ 大螢幕 / 平板 / 摺疊螢幕
- [ ] 最低 API（`{{MIN_ANDROID_API}}`）/ 最新版本（`{{ANDROID_DEFAULT_VERSION}}`）
- [ ] Samsung（One UI）/ Google Pixel（Pure Android）/ 國產品牌 OEM 客製 ROM

## 時間盒（Time-boxed）
- 預計時間：[X] 小時
- 重點領域：[列出優先順序]
```
