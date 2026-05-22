---
name: visual-regression-gen
description: 為 Web 應用生成視覺回歸測試（Visual Regression）腳本與 baseline 管理流程。支援 Playwright snapshot / Percy / Chromatic / BackstopJS 四大主流方案。自動偵測動態元素（時間 / 廣告 / animation）並 mask 掉，設定差異容忍度（pixelmatch threshold）。當使用者提到「視覺回歸 / visual regression / screenshot test / Percy / Chromatic / Playwright snapshot / 介面比對 / UI baseline」時觸發。配套：test-automation（生成 E2E 腳本）、test-master（視覺回歸 TC 規劃）、smoke-test-analyzer（VR 屬於 T2 release）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[頁面 URL / 元件路徑] [--tool=playwright|percy|chromatic|backstop]"
---

# visual-regression-gen

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。
> 啟用條件：`config.platforms.web.enabled = true` 且 `config.visual_regression.enabled = true`。

## 適用場景

- ✅ Web App 有重要的視覺品質要求（品牌頁 / Marketing site / Dashboard）
- ✅ 已有 E2E 但沒有「視覺改變」守門
- ✅ 想在 PR 看到 "視覺 diff" 自動標出
- ✅ 多瀏覽器要對齊（Chrome / Safari 渲染差異）

## 不適用場景

- ❌ 純 API 後端 — 用 `tc-to-pytest`
- ❌ UI 變動頻繁的早期 MVP — baseline 維護成本高
- ❌ 大量動態內容（隨機推薦 / 廣告） — 即使 mask 也 flaky

## 工具選擇

| 工具 | 適合 | 雲服務 | 成本 |
|------|------|-------|------|
| **Playwright snapshot**（推薦）| 自託管、開源、最簡 | ❌ self-host | 免費 |
| **Percy** | 雲端 baseline 管理、PR 整合 | ✅ | $$ |
| **Chromatic** | Storybook 元件、視覺 review workflow | ✅ | $$ |
| **BackstopJS** | Legacy 專案、需要 hot reload baseline | ❌ self-host | 免費 |

預設 `{{VR_TOOL}}`（從 config 讀），可用 `--tool=` 覆寫。

## 執行流程

### Phase 1: 偵測既有設定

```bash
# 找配置檔
ls playwright.config.* .percy.* .chromatic.* backstop.json 2>/dev/null
```

若已有對應配置 → 直接擴充，不從零建。

### Phase 2: 識別關鍵 viewport

從 `config.platforms.web.viewport_sizes` 讀（預設 desktop / tablet / mobile）：

| Viewport | 用途 |
|----------|------|
| 1920×1080 desktop | 主流桌機 |
| 1366×768 desktop | 老舊 / 低解析度 |
| 768×1024 tablet | iPad 直 |
| 375×667 mobile | iPhone SE/小螢幕 |

### Phase 3: 動態元素 masking 策略

自動偵測該 mask 掉的元素（避免 false-positive flaky）：

| 類型 | locator | 處理 |
|------|---------|------|
| 時間戳 | `[data-testid*="time"]` / `time` | mask |
| 動畫 GIF / video | `img[src*=".gif"]`, `video` | mask |
| 廣告 | `iframe[src*="ads"]`, `[class*="ad-banner"]` | mask |
| 即時數字（unread count）| `[data-testid*="badge"]` | mask |
| 隨機推薦 | `[data-testid*="recommendation"]` | mask |

讓使用者覆核，可自加自定義 mask。

### Phase 4: 生成腳本

#### Playwright snapshot 範例

```typescript
// tests/visual/home.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Home page visual regression', () => {

  for (const viewport of [
    { name: 'desktop', width: 1920, height: 1080 },
    { name: 'tablet',  width: 768,  height: 1024 },
    { name: 'mobile',  width: 375,  height: 667 },
  ]) {
    test(`TC: VR-HOME-001 home page @ ${viewport.name}`, async ({ page }) => {
      await page.setViewportSize({ width: viewport.width, height: viewport.height });
      await page.goto('/');
      await page.waitForLoadState('networkidle');

      // Mask 動態元素
      await expect(page).toHaveScreenshot(`home-${viewport.name}.png`, {
        mask: [
          page.locator('[data-testid="current-time"]'),
          page.locator('iframe[src*="ads"]'),
          page.locator('[class*="ad-banner"]'),
        ],
        maxDiffPixelRatio: 0.02,   // 2% 容忍
        animations: 'disabled',     // 凍結動畫
      });
    });
  }
});
```

#### Percy 範例

```javascript
const percySnapshot = require('@percy/playwright');

test('TC: VR-HOME-001 home page', async ({ page }) => {
  await page.goto('/');
  await percySnapshot(page, 'Home page', {
    widths: [1920, 1366, 768, 375],
    percyCSS: `
      [data-testid="current-time"] { visibility: hidden; }
      iframe[src*="ads"] { display: none; }
    `,
  });
});
```

#### Chromatic（Storybook 整合）範例

```javascript
// Button.stories.tsx
export const Primary = {
  args: { variant: 'primary', children: 'Click me' },
  parameters: { chromatic: { viewports: [320, 768, 1200] } },
};
```

### Phase 5: Baseline 管理

| 工具 | Baseline 存哪 |
|------|--------------|
| Playwright snapshot | git 內 `tests/visual/__screenshots__/` |
| Percy | Percy cloud |
| Chromatic | Chromatic cloud |
| BackstopJS | `backstop_data/` (git 或 S3) |

**git 內 baseline 注意**：
- ✅ Commit 進 git（小團隊好做 diff review）
- ⚠️ 大團隊建議 Git LFS（baseline 累積會肥）
- ❌ 不該 in CI cache（每次 CI re-generate 失去 baseline 意義）

### Phase 6: 處理 false positive

當 PR 改動觸發視覺 diff 但實際 UI 正確：

1. **誤判** → 加 mask / 提高 `maxDiffPixelRatio`
2. **真的改了 UI** → `npx playwright test --update-snapshots` 更新 baseline，commit 進 PR

### Phase 7: CI 整合

```yaml
# .github/workflows/visual-regression.yml
on:
  pull_request:
    paths: ['src/**', 'public/**', 'styles/**']

jobs:
  visual-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npx playwright install
      - run: npx playwright test --grep @visual
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: visual-diff
          path: test-results/
```

PR 內若有 diff，自動上傳 diff 影像。

## ⚠️ 安全護欄

- ❌ 不主動 `--update-snapshots`（需要使用者明確同意）
- ✅ Diff > threshold → CI fail（守門）
- ✅ Baseline commit 必須通過 review
- ⚠️ baseline 規模 > 50 個 / 100 MB → 提示用 Git LFS

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `visual_regression.enabled` | 啟用此 skill | skill 不啟用 |
| `visual_regression.tool` | 預設工具 | playwright |
| `visual_regression.max_diff_ratio` | 預設容忍度 | 0.02 (2%) |
| `platforms.web.viewport_sizes` | 跑哪些 viewport | 3 個預設 |

## 範例

詳見 [`examples.md`](./examples.md)
