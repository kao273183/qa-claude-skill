# a11y-audit 範例

## 範例 1: Web Lighthouse audit

```
User: /a11y-audit https://example.com
```

執行：
1. 跑 `lighthouse https://example.com --only-categories=accessibility`
2. 解析 12 個 violations
3. 對應 WCAG criteria
4. 寫 `a11y-audit-report.md`
5. 提示是否建 JIRA Critical ticket

輸出：
```
✅ Lighthouse a11y score: 87 / 100
⚠️ 12 violations: 3 Critical / 5 Serious / 4 Moderate
🔴 Top issues:
  - 1.4.3 對比度（.product-price 2.84:1）
  - 4.1.2 button 缺 aria-label（.cart-icon）
  - 2.4.7 焦點不可見（input:focus 沒 outline）
```

## 範例 2: iOS XCUI a11y audit

```
User: /a11y-audit --platform=ios
```

執行：
1. 注入 `app.performAccessibilityAudit()` 到既有 UI test
2. 跑 `xcodebuild test`
3. 解析 diagnostic
4. 找到 8 個 issue（缺 accessibilityLabel / touch target < 44pt）

## 範例 3: 政府合規場景

```
User: /a11y-audit --standard=Section508
```

→ 切到 Section 508 標準（美國聯邦無障礙法規）
→ 報告含合規聲明區段
→ 自動寫 audit log（給合規稽核）

## 範例 4: 手動補強 checklist

工具找不到的問題：

```markdown
# 人工 a11y 檢查（補工具盲區）

## 螢幕閱讀器讀順測試
- [ ] VoiceOver 從上到下讀 — 順序符合視覺
- [ ] 按鈕 label 讀起來合理（「購物車，3 件商品」不是「buy」）
- [ ] 圖片 alt 描述 ≤ 16 字（簡潔）

## 鍵盤導航
- [ ] Tab 順序符合視覺順序
- [ ] Focus visible（outline / ring）
- [ ] Esc 關 modal

## Dynamic Type
- [ ] iOS AX5 / Android 200% 字級下 layout 不破版
- [ ] 裝飾性數字（badge）固定大小

## 動畫
- [ ] Reduce Motion 開啟時動畫降級
- [ ] 不使前庭障礙者頭暈
```
