---
name: localization-test
description: i18n / l10n 多語言測試專屬流程。驗證翻譯漏字、字串長度溢出（德文常爆版）、RTL 語言（阿拉伯、希伯來）渲染、日期/數字/貨幣格式、locale 切換不重啟、複數規則（pluralization）。當使用者提到「localization / i18n / l10n / 多語言測試 / 翻譯測試 / RTL 測試 / 字串溢出 / locale 切換 / 阿拉伯文 / 翻譯漏字」時觸發。配套：test-master（規劃 l10n TC）、test-automation（自動跑 locale 切換 UI test）、a11y-audit（VoiceOver/TalkBack 多語）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[Locale 清單 / 翻譯資源檔路徑] [--check=missing|length|rtl|format|all]"
---

# localization-test

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。

## 為什麼需要

多語言 App 常見問題：
- **字串漏譯** → 英文 fallback 出現在 UI（不專業）
- **字串溢出** → 德文 / 法文比英文長 30%，按鈕爆框
- **RTL 渲染錯** → 阿拉伯 / 希伯來文整個 layout 應該鏡像
- **格式錯** → 日期 03/05 在美式是 3 月 5 日，歐式是 5 月 3 日
- **複數錯** → 「1 item / 2 items」直接套到俄文（俄文有 3 種複數）
- **Locale 切換 bug** → 切了 locale 但部分頁面沒更新

→ 本 skill **系統性檢查上述所有問題**。

## 適用場景

- ✅ App 上架多國市場（≥ 3 種語言）
- ✅ 出海前 release 守門
- ✅ 加新語言時做 baseline check
- ✅ 中國 App 出海要含繁中/簡中/英文/日文

## 不適用場景

- ❌ 只有單一語言
- ❌ 翻譯品質審查 — 那是語言專家工作，不是 QA

## 6 大檢查維度

### 1. 翻譯完整性（Missing keys）

掃描資源檔（iOS `.strings` / Android `strings.xml` / Flutter `.arb` / i18n `.json`）：

```bash
# 找漏譯
diff <(jq -r 'keys[]' i18n/en.json | sort) \
     <(jq -r 'keys[]' i18n/ja.json | sort)
```

報告：日文版漏 23 個 key。

### 2. 字串長度溢出

各語言相對英文的平均長度（給設計用：）

| 語言 | 相對英文 |
|------|---------|
| 德文 | +30% |
| 法文 | +20% |
| 西班牙文 | +25% |
| 義大利文 | +15% |
| 日文 | -40%（字短但寬）|
| 中文 | -50%（字短但寬）|
| 阿拉伯文 | +5% |

掃 UI snapshot（用 visual-regression-gen 的 baseline）+ 量化文字寬度。

### 3. RTL 渲染

對 RTL 語言（ar / he / fa / ur）：
- Layout 應 mirror（icon 左右翻轉）
- 文字對齊右
- 但**數字 / 英文夾雜**仍 LTR 顯示
- 圖示**不該**翻轉（電池 / 信號）

跑 Playwright 截 RTL screenshot 對比：
```typescript
test('RTL layout for Arabic', async ({ page, browserName }) => {
  await page.goto('/', { locale: 'ar-SA' });
  await expect(page).toHaveScreenshot('home-ar.png');
});
```

### 4. 日期 / 數字 / 貨幣格式

驗 Intl.DateTimeFormat / Intl.NumberFormat 是否被正確使用：

| 數據 | en-US | de-DE | ja-JP | zh-TW |
|------|-------|-------|-------|-------|
| 日期 | 3/5/2026 | 5.3.2026 | 2026/3/5 | 2026/3/5 |
| 數字 | 1,234.56 | 1.234,56 | 1,234.56 | 1,234.56 |
| 貨幣 | $1,234.56 | 1.234,56 € | ¥1,235 | NT$1,234.56 |

❌ 偵測 hard-coded format：`new Date().toLocaleString()` 不傳 locale → 隨機。

### 5. Pluralization 複數規則

```javascript
// ❌ Bad
`You have ${count} ${count > 1 ? 'items' : 'item'}`

// ✅ Good (i18n library)
i18n.t('items_count', { count })
// 自動處理 ru: 1 item / 2 items / 5 items (3 種複數)
```

### 6. Locale 切換不重啟

驗使用者切 locale 後：
- 所有開啟的頁面立即更新
- 不需要重啟 App
- Push notification token 不重置（保留訂閱）

## 執行流程

### Phase 1: 偵測 i18n 框架

| 平台 | 框架 |
|------|------|
| Web | i18next / react-i18next / vue-i18n / formatjs |
| iOS | NSLocalizedString / SwiftUI String catalog |
| Android | strings.xml / Compose stringResource |
| Flutter | flutter_localizations + .arb |

### Phase 2: 自動跑 6 大檢查

對每個 locale 跑：
- 漏譯：diff against base locale
- 長度：scan UI snapshot
- RTL：visual diff
- 格式：grep code for hard-coded
- 複數：grep `count > 1 ? ` pattern
- 切換：UI test 自動切 + verify

### Phase 3: 報告

```markdown
# Localization Test Report · my-app · 2026-05-22

## 📊 整體
- Supported locales: en, zh-TW, zh-CN, ja, de, ar
- Missing translations: 28 (across 6 locales)
- Length overflow: 12 (mostly de in buttons)
- RTL issues: 4 (icon mirroring incorrect)
- Format issues: 6 (hard-coded date format)
- Pluralization issues: 3 (using `count > 1`)
- Locale switch issues: 0 ✅

## 🔴 Critical

### Missing translations - ja.json (23 keys)
- `auth.session_expired`
- `cart.empty_state`
- ...

### Length overflow - "Sign In" button (de)
- en: "Sign In" (60 px)
- de: "Anmelden" (95 px)
- 按鈕設計寬 80 px → 溢出
- 修法: 按鈕設計改 min-width: 120 px

## 🟡 Recommendations

- [ ] 補齊 23 個日文翻譯 key
- [ ] 12 個 button 改 min-width
- [ ] 4 個 icon 加 RTL aware logic
- [ ] 6 個日期格式改用 Intl.DateTimeFormat
```

## ⚠️ 安全護欄

- ❌ 不評論翻譯品質（語意是否到位）— 那是語言專家工作
- ✅ 只報「結構性問題」（漏字 / 溢出 / 格式 / RTL）
- ✅ Visual regression 對比需要先有 baseline

## 設定依賴

| 設定 Key | 用途 | 預設 |
|---------|------|------|
| `localization.supported_locales` | 支援語言列表 | ["en"] |
| `localization.base_locale` | 翻譯基準 | "en" |
| `localization.translation_files_pattern` | 資源檔 glob | `**/i18n/*.json` |
| `localization.rtl_locales` | RTL 語言 | ["ar", "he", "fa"] |

## 範例

詳見 [`examples.md`](./examples.md)
