# 一文搞懂 smoke-test-analyzer

> 給第一次聽到「測試分層 T0/T1/T2/T3」的 QA / DevOps 看的快速導讀。
> 看完就知道「為什麼不該每次 PR 都跑全部測試」。

---

## 🎯 一句話總結

> **「掃描你的自動化測試，幫你決定哪些該 PR 跑、哪些該 daily 跑、哪些 release 前才跑。」**

讓 CI 從「跑全部」變成「跑該跑的」— 一般可省 80% CI 時間，PR 等待時間從 30 min → 3 min。

---

## 🆚 跟你熟悉的「每次都跑全部」差在哪？

### 傳統做法（全跑）

```
PR 提交
   ↓
CI 跑全部 500 個測試（30 min）
   ↓
PR 通過 / 合併
```

**問題**：
- ⏱ 等很久（每個 PR 30 min）
- 💸 燒 CI 配額（每月炸 $$$）
- 🔁 跑越多次越多 flaky test → false negative
- 📵 工程師失去耐心 → 開始 skip CI

### 分層測試做法（smoke-test-analyzer）

```
PR 提交
   ↓
跑 T0 PR Smoke（< 3 min，50 個關鍵測試）
   ↓
PR 通過 / 合併
   ↓
每日凌晨：跑 T1 Daily Smoke（< 10 min，150 個核心測試）
   ↓
Release 前：跑 T2 Full Regression（< 60 min，500 個全部）
   ↓
T3 Manual：探索性測試、a11y、視覺，On-demand
```

**好處**：
- 🚀 PR 等待時間 30 min → 3 min（10x）
- 💰 CI 成本下降 80%
- 🎯 critical 問題仍能立刻發現
- 🧘 工程師 happy

---

## 📊 四層測試分類

### T0: PR Smoke（< 3 min）

**每次 PR 都跑** — 守住 critical 路徑。

哪些測試該進 T0？
- ✅ 登入流程
- ✅ 首頁載入
- ✅ 支付流程
- ✅ 純邏輯 unit test（< 1 秒）
- ❌ UI 測試（太慢）
- ❌ 有 `sleep()` 的測試（容易 flaky）
- ❌ 依賴網路 / API 的測試

**零容忍 flakiness** — 一個 flaky 進 T0 整個團隊都遭殃。

### T1: Daily Smoke（< 10 min）

**每天凌晨跑一次** — 抓住非 critical 但重要的問題。

哪些測試該進 T1？
- ✅ 核心 UI 流程（登入 → 首頁 → 支付）
- ✅ 中等速度的 unit test（1-10 秒）
- ✅ 大部分整合測試
- ❌ 全功能回歸（太慢）
- ❌ 視覺測試

### T2: Release Regression（< 60 min）

**Release 前跑一次** — 完整回歸。

哪些測試該進 T2？
- ✅ 所有 unit + UI + integration test
- ✅ 邊界 case
- ✅ 慢測試（> 10 秒）

### T3: Manual / On-demand

**人工或特殊狀況觸發** — 沒辦法 / 不該自動化的。

哪些算 T3？
- ✅ 探索性測試
- ✅ 視覺驗證
- ✅ a11y 測試（VoiceOver / TalkBack 互動）
- ✅ 真實裝置 UX 測試

---

## 🎯 分層的「五大評分標準」

skill 對每個測試檔評分（1-5 分），按權重加總：

| 標準 | 權重 | 5 分 | 1 分 |
|------|------|------|------|
| **Criticality（重要性）** | 30% | 登入、支付、首頁 | 視覺裝飾、邊角 case |
| **Speed（速度）** | 25% | 純邏輯，< 1 秒 | I/O 依賴，> 10 秒 |
| **Stability（穩定性）** | 25% | 確定性 | 有 `sleep()`、依賴時序 |
| **Independence（獨立性）** | 10% | 沒共享狀態 | 用 singletons、有順序依賴 |
| **Coverage Value（覆蓋價值）** | 10% | 高流量功能 | 鮮少使用 |

**分層公式**：
- ≥ 4.0 → T0
- 3.0-3.9 → T1
- 2.0-2.9 → T2
- < 2.0 → T3

---

## 🎬 真實案例：100 個測試的分層結果

掃完後可能長這樣：

| 平台 | 總測試 | T0 | T1 | T2 | T3 |
|------|--------|-----|-----|-----|-----|
| iOS | 150 | 18 | 42 | 75 | 15 |
| Android | 100 | 15 | 30 | 45 | 10 |

**CI 時間估算**：
| 層 | 跑哪些 | 時間 |
|----|--------|------|
| T0 PR Smoke | iOS 18 + Android 15 = 33 | ~2 min |
| T1 Daily | + 72 個 = 105 | ~8 min |
| T2 Release | + 120 個 = 225 | ~50 min |

省下的 CI 時間（vs 全跑）：
- PR：30 min → 2 min（**省 93%**）
- Daily：每天本來不跑 → 8 min（新增 daily 守門）
- Release：50 min（vs 全跑 30 min）→ 全跑因為要全跑，這層沒省

整體：**每個 PR 省 28 min**，每月省幾百個 CI 小時。

---

## 🧪 skill 還會做什麼？

### 1. Flaky 風險報告

掃到下列 pattern 會標記為 flaky risk：
- `sleep(N)` / `Thread.sleep`
- `wait(...)` / `Thread.sleep` 沒對應條件
- 共享 mutable state
- 依賴外部時間 / 真實網路

→ 建議改成 `wait_for(condition)` / mock 網路。

### 2. CI 設定檔自動產出

依平台產對應檔案：

**iOS** — `.xctestplan`：
```json
{
  "testTargets": [
    {
      "selectedTests": ["LoginTests/testLogin", "PaymentTests/testCheckout"]
    }
  ]
}
```

**Android** — Gradle filter / `@Tag` / Suite。

### 3. 跨平台一致性檢查

確保 iOS / Android 在 T0 跑「同樣的核心流程」：
- 兩邊都有：登入 / 首頁 / 支付 ✅
- 只有 iOS：iCloud 同步 ⚠️ → 建議補 Android 對應測試

---

## ⚡ 什麼時候**該**用？

✅ 適合：
- CI 跑全部測試 > 15 min（PR 等很久）
- 有 flaky test 影響開發者信任
- 新測試持續加入但沒分層
- 想優化 CI 成本

## 🚫 什麼時候**不該**用？

❌ 不適合：
- 還沒有自動化測試（先用 `test-automation` 寫）
- 全部測試只有 < 30 個（手動分層更簡單）
- CI 已經 < 5 min（沒救可以救）

---

## 🎓 三個關鍵心法

### 1. 不是「把測試丟掉」，是「分批跑」

T3 不是「砍掉」這些測試，而是「不在 PR / Daily 跑」。
所有測試在 T2 Release 仍會跑一次。

### 2. T0 零容忍 flakiness

T0 是「PR 守門員」— 任何 flaky 進 T0 = 整個團隊每天被假警報煩。
寧可降到 T1，也不要硬留 T0 然後常 false fail。

### 3. 跨平台對齊比覆蓋率重要

iOS 跑了「登入」，Android 沒跑「登入」— 等於這個 critical flow 在 Android 沒守門。
**T0 必須兩個平台都有對應測試**。

---

## 🚀 從零開始的 4 步驟

### Step 1: 確認有自動化測試

確認專案有：
- iOS：`{ProjectName}Tests/` 或 `{ProjectName}UITests/`
- Android：`src/test/` 或 `src/androidTest/`

如果沒有，先跑 `/test-automation` 生成。

### Step 2: 跑 skill

```
/smoke-test-analyzer
```

skill 自動：
1. 掃描所有測試檔
2. 對每個檔評 5 維度分數
3. 分到 T0/T1/T2/T3
4. 產出建議報表

### Step 3: Review 分層結果

你會看到一個建議分層表，**人工檢視**：
- 你不同意？→ 直接告訴 skill 調整
- 同意？→ 進 Step 4

### Step 4: 套用 CI 設定

skill 產 `.xctestplan` / Gradle config，套到你的 CI workflow：

```yaml
# GitHub Actions 範例
- name: T0 PR Smoke
  run: xcodebuild test -testPlan T0-Smoke
  if: github.event_name == 'pull_request'

- name: T1 Daily Smoke
  run: xcodebuild test -testPlan T1-Daily
  if: github.event_name == 'schedule'
```

---

## 📚 進一步閱讀

- [smoke-test-analyzer SKILL](./SKILL.md) — 本 skill 完整流程
- [references/scoring-heuristics.md](./references/scoring-heuristics.md) — 五大評分標準詳解
- [references/ios-config.md](./references/ios-config.md) — iOS xctestplan 範本
- [references/android-config.md](./references/android-config.md) — Android Gradle filter 範本

## 🎯 一句話複述

**「掃描你的測試，分到 T0(PR)/T1(daily)/T2(release)/T3(manual)，自動產 CI 設定。PR 等待從 30 min → 3 min，CI 成本省 80%。」**
