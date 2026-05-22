# visual-regression-gen 範例

## 範例 1: Playwright snapshot 完整流程

```
User: /visual-regression-gen 首頁 + 商品列表頁 + 結帳頁
```

執行：
1. 偵測 `playwright.config.ts` 存在
2. 對 3 個頁面 × 3 個 viewport（desktop/tablet/mobile）= 9 個 snapshot
3. 自動 mask 時間戳 + 廣告 + 動畫
4. 寫 `tests/visual/{home,products,checkout}.spec.ts`
5. 跑 `npx playwright test --update-snapshots` 建立 baseline

## 範例 2: Percy 雲端整合

```
User: /visual-regression-gen --tool=percy 整個 App
```

執行：
1. 掃所有 route → 自動 visit + snapshot
2. 走 Percy CSS 隱藏動態元素
3. 上傳到 Percy cloud
4. PR 時 Percy bot 自動 comment 視覺 diff

## 範例 3: Storybook + Chromatic

```
User: /visual-regression-gen --tool=chromatic
```

執行：
1. 偵測 `.storybook/`
2. 對每個 Story 加 `chromatic` parameters
3. 設定 viewport: `[320, 768, 1200]`
4. 跑 `npx chromatic --project-token=xxx`

## 範例 4: 處理 baseline 衝突

```
PR review 看到視覺 diff:
- 預期：button 顏色改成藍色（v2 設計）
- 實際：snapshot 還是綠色

→ 確認是 intentional 改動
→ `npx playwright test --update-snapshots`
→ commit 新 baseline 到 PR
→ reviewer 看新 baseline 跟設計稿對齊
```
