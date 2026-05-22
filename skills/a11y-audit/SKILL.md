---
name: a11y-audit
description: 對 Web / iOS / Android App 跑獨立無障礙審查，整合 Lighthouse / axe-core / iOS Accessibility Inspector / Android Accessibility Scanner。產出 WCAG 2.1 AA 評分報告、CVSS-like 嚴重度分級、修復建議含 code snippet。當使用者提到「a11y 審查 / accessibility audit / WCAG / Lighthouse a11y / axe-core / VoiceOver 檢查 / TalkBack 檢查 / 無障礙評分 / 字級放大測試」時觸發。配套：test-master（內建 a11y 必檢，本 skill 是深度補強）、bug-report（追 a11y bug）、regression-test（release 前 a11y 回歸）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[URL / App 平台 / 元件路徑] [--standard=WCAG21AA|WCAG22AA|Section508]"
---

# a11y-audit

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。

## 為什麼需要這個 skill

`test-master` 內建 a11y 必檢項是「**規劃時的提醒**」（每個 UI 功能要加 4 條 a11y TC），但實際 audit 需要：
- 跑工具（Lighthouse / axe / VoiceOver）
- 解析報告
- 對照 WCAG 標準
- 給修復建議含 code snippet

→ 本 skill **專做這個深度 audit**。

## 適用場景

- ✅ 政府 / 金融 / 醫療 — 必須符合 WCAG 2.1 AA（法規要求）
- ✅ Release 前最後 a11y 守門
- ✅ 設計改版後系統性檢查
- ✅ 提報企業合規（GDPR / ADA / 歐盟 EAA）

## 不適用場景

- ❌ 規劃 a11y TC — 用 `test-master`（已內建）
- ❌ 純 UI 視覺改動 — 用 `visual-regression-gen`

## 工具對應

| 平台 | 工具 | 標準 |
|------|------|------|
| **Web** | Lighthouse / axe-core / WAVE | WCAG 2.1/2.2 |
| **iOS** | Accessibility Inspector (Xcode) | Apple HIG a11y |
| **Android** | Accessibility Scanner | Material a11y |
| **Flutter** | Flutter Inspector + axe-core (Web 模式) | WCAG + Material |

## WCAG 2.1 AA 4 大原則 + 13 條 criteria

| 原則 | Criteria 範例 | 工具能檢 |
|------|-------------|---------|
| **Perceivable** | 1.1.1 非文字內容 / 1.4.3 對比 / 1.4.4 字級縮放 | ✅ axe / Lighthouse |
| **Operable** | 2.1.1 鍵盤可達 / 2.4.7 焦點可見 / 2.5.5 觸控目標 ≥ 44pt | ✅ 大部分 |
| **Understandable** | 3.1.1 語言宣告 / 3.3.1 錯誤訊息 / 3.3.2 標籤 | ⚠️ 工具部分檢 |
| **Robust** | 4.1.1 解析錯誤 / 4.1.2 a11y API name+role+value | ✅ axe |

## 執行流程

### Phase 1: 偵測平台 + 工具

```bash
# Web
ls package.json playwright.config.*
# iOS
ls *.xcodeproj
# Android
ls build.gradle*
```

### Phase 2: 跑工具

#### Web — Lighthouse

```bash
lighthouse https://example.com --only-categories=accessibility --output=json --output=html --output-path=./a11y-report
```

或 axe-core (Playwright):
```typescript
import AxeBuilder from '@axe-core/playwright';

test('a11y audit on homepage', async ({ page }) => {
  await page.goto('/');
  const results = await new AxeBuilder({ page })
    .withTags(['wcag21aa'])
    .analyze();
  expect(results.violations).toEqual([]);
});
```

#### iOS — Accessibility Inspector + XCUI

```swift
// 跑 a11y audit on UI test
func testAccessibilityHomepage() throws {
    let app = XCUIApplication()
    app.launch()
    try app.performAccessibilityAudit()
    // 若有 violation → test fail with diagnostic
}
```

#### Android — Accessibility Scanner

```kotlin
// Espresso a11y check
@Test fun homepageA11yScan() {
    AccessibilityChecks.enable().setRunChecksFromRootView(true)
    onView(withId(R.id.homeContainer)).check(matches(isDisplayed()))
}
```

### Phase 3: 解析 + 統一報告

合併各平台輸出 → `a11y-audit-report.md`：

```markdown
# A11y Audit Report · my-app · 2026-05-22

## 📊 整體
- 標準: WCAG 2.1 AA
- Lighthouse score: 87 / 100
- axe violations: 12 (3 Critical / 5 Serious / 4 Moderate)

## 🔴 Critical (必修)

### 1.4.3 對比度不足
- **頁面**: /products
- **元素**: `.product-price`（前景 #999 / 背景 #fff）
- **比率**: 2.84:1（要求 ≥ 4.5:1）
- **修法**: 改前景成 #595959 或更深
- **WCAG**: https://www.w3.org/WAI/WCAG21/quickref/#contrast-minimum

### 4.1.2 互動元件缺 name
- **元素**: `<button class="cart-icon">` 沒有 aria-label 或文字
- **修法**:
  ```html
  <button aria-label="購物車（3 件）">🛒</button>
  ```

## 🟡 Serious / Moderate
[5 條 Serious + 4 條 Moderate ...]

## 🟢 Pass (87 條)
[摘要列]

## 📋 修復清單

| 優先 | Criteria | 位置 | 估時 |
|------|----------|------|------|
| Critical | 1.4.3 對比 | /products .product-price | 30 min |
| Critical | 4.1.2 button name | /header .cart-icon | 15 min |
| ...

## 📈 趨勢
- 上次 audit (2026-04): Lighthouse 72 / 18 violations
- 這次:                  87 / 12 violations（改善 +15 / -6）
```

### Phase 4: 手動補強（工具找不到的）

工具只能檢 ~40% WCAG。其他需要人工：
- 螢幕閱讀器**讀起來合理**（讀順 / label 對齊視覺）
- 鍵盤 Tab 順序符合視覺順序
- 字級放大後**內容仍可讀且不破版**
- 暗色模式對比仍達標
- 動畫對前庭障礙者安全（Reduce Motion）

skill 自動產出人工 checklist 並提醒。

### Phase 5: 自動建 ticket

互動式問：
- 為 Critical 建 JIRA Bug ticket（用 `bug-report` skill）
- 把 a11y 跑進 nightly CI

## ⚠️ 安全護欄

- ❌ 不假裝工具能檢 100%（明確標 "tooling can detect ~40% of WCAG"）
- ✅ 報告含「人工驗證」section（補工具盲區）
- ✅ Critical 自動 propose 為 P0 ticket

## 設定依賴

| 設定 Key | 用途 | 預設 |
|---------|------|------|
| `a11y_audit.standard` | WCAG 標準版本 | WCAG21AA |
| `a11y_audit.lighthouse_threshold` | Lighthouse a11y 分數門檻 | 90 |
| `a11y_audit.tools` | 啟用工具 | axe / lighthouse |
| `workflow.auto_a11y_pairing` | a11y bug 自動配對 iOS+Android | true |

## 範例

詳見 [`examples.md`](./examples.md)
