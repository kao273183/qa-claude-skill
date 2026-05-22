---
name: visual-regression-gen
description: Generate visual regression test scripts and baseline management for web apps. Supports Playwright snapshot / Percy / Chromatic / BackstopJS. Auto-detects dynamic elements (time/ads/animations) and masks them, sets pixelmatch diff tolerance. Trigger phrases — "visual regression", "screenshot test", "Percy", "Chromatic", "Playwright snapshot", "UI baseline".
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[page URL / component path] [--tool=playwright|percy|chromatic|backstop]"
---

# visual-regression-gen (English)

> ⚙️ Read [`modules/config-loader.md`](./modules/config-loader.md) first.
> Activation: `platforms.web.enabled = true` AND `visual_regression.enabled = true`.

## When to Use
- Web app with strict visual quality (brand pages, dashboards)
- Have E2E but no "visual change" gatekeeper
- Want PR to show visual diff automatically
- Cross-browser alignment (Chrome vs Safari rendering)

## Tool Picker

| Tool | Best for | Cloud | Cost |
|------|----------|-------|------|
| **Playwright snapshot** (default) | Self-hosted, simple | ❌ | Free |
| **Percy** | Cloud baseline, PR integration | ✅ | $$ |
| **Chromatic** | Storybook components | ✅ | $$ |
| **BackstopJS** | Legacy, hot-reload baselines | ❌ | Free |

## Workflow

### Phase 1: Detect existing config
Check for `playwright.config.*`, `.percy.*`, `.chromatic.*`, `backstop.json`.

### Phase 2: Identify viewports
From `config.platforms.web.viewport_sizes`: desktop / tablet / mobile.

### Phase 3: Dynamic element masking
Auto-detect: timestamps, animations, ads, badges, recommendations → mask.

### Phase 4: Generate script

**Playwright snapshot**:
```typescript
await expect(page).toHaveScreenshot(`home-${viewport.name}.png`, {
  mask: [page.locator('[data-testid="current-time"]')],
  maxDiffPixelRatio: 0.02,
  animations: 'disabled',
});
```

**Percy**:
```javascript
await percySnapshot(page, 'Home', { widths: [1920, 768, 375] });
```

### Phase 5: Baseline management
- Playwright: git tracked (or Git LFS for large repos)
- Percy/Chromatic: cloud
- BackstopJS: `backstop_data/`

### Phase 6: Handle false positives
- Wrong → add mask / raise tolerance
- Real change → `--update-snapshots` + commit

### Phase 7: CI integration
Upload diff artifacts on failure for review.

## Safety
- ❌ Never auto `--update-snapshots`
- ✅ Diff > threshold → CI fail
- ⚠️ Baseline > 50 / 100 MB → use Git LFS

## Config Dependencies

| Key | Purpose |
|-----|---------|
| `visual_regression.enabled` | Activates skill |
| `visual_regression.tool` | playwright / percy / chromatic / backstop |
| `visual_regression.max_diff_ratio` | Default 0.02 |
| `platforms.web.viewport_sizes` | Which viewports |
