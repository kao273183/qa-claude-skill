---
name: flaky-test-hunter
description: 從 CI 跑歷史紀錄統計每個測試的失敗率，識別 flaky test（重跑就過的不穩定測試）、給出修復建議、自動標記到 quarantine（隔離區）讓 CI 不被假失敗阻擋。支援 GitHub Actions / GitLab CI / CircleCI / Jenkins JUnit XML / pytest-xdist 失敗紀錄。當使用者提到「flaky test / 不穩定測試 / 假失敗 / retry 才過 / CI 不穩 / quarantine test / 隔離測試 / 找出 flaky / 修 flaky」時觸發。配套：smoke-test-analyzer（flaky 不該進 T0）、test-review（審 flaky pattern）、bug-report（追 flaky bug）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[CI 紀錄路徑 / GitHub workflow 名稱] [--days=N] [--threshold=X%]"
---

# flaky-test-hunter

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。

## 為什麼需要這個 skill

Flaky test 是 CI 信任度殺手：
- 工程師看到紅燈第一反應是「應該又是 flaky，按 retry」
- 久了真實 bug 也被當 flaky 忽略
- 浪費 CI 時間（重跑成本）
- 工程師對自動化測試失去信心 → 開始 skip

→ 這個 skill **量化哪些測試在 flaky、給數據說服團隊修**。

## 適用場景

- ✅ CI 有歷史紀錄（GitHub Actions / GitLab / CircleCI 至少跑 1 個月）
- ✅ 開始懷疑某些測試「隨機 fail」
- ✅ Release 前想清理 flaky 避免假警報
- ✅ 想把 flaky 自動移到 quarantine（隔離區）

## 不適用場景

- ❌ 沒 CI 歷史 / 剛起步 — 先累積數據
- ❌ 全部測試都 flaky — 系統性問題，不是個別 fix
- ❌ Manual test 不穩 — 跟程式碼 flaky 是不同問題

## 執行流程

### Phase 1: 收集 CI 失敗紀錄

支援來源：

| CI 平台 | 取得方式 |
|---------|---------|
| **GitHub Actions** | `gh run list --workflow=ci.yml --json` + `gh run view <id>` |
| **GitLab CI** | `glab ci list` + GitLab API |
| **CircleCI** | CircleCI API |
| **Jenkins** | JUnit XML 直接讀 |
| **pytest local** | `pytest --json-report` 連續跑 N 次 |

預設讀過去 `{{FLAKY_DAYS}}` 天（預設 30 天）的紀錄。

### Phase 2: 計算每個測試的 flakiness score

```
flakiness_score = (failures_in_passing_runs / total_runs) × 100%
```

Flakiness 定義：
- **Stable**: 0% flakiness（每次都 pass）
- **Stable-fail**: 失敗率 > 80% 且每次都 fail（真實 bug，不是 flaky）
- **Flaky**: 失敗率 1-80%（時 pass 時 fail）

只列出 **Flaky** 區間的測試。

### Phase 3: 分類 flaky 嚴重度

| 分類 | Flakiness | 處理建議 |
|------|-----------|---------|
| 🔴 **High flaky** | > 30% | 立刻 quarantine + 修 |
| 🟡 **Medium flaky** | 10-30% | 排程修，先進 quarantine |
| 🟢 **Low flaky** | 1-10% | 監控，看是否持續惡化 |

### Phase 4: 識別 flaky 根因 pattern

掃描 flaky test 的程式碼，找常見問題：

| Pattern | 範例 | 修復方向 |
|---------|------|---------|
| **Hard-coded sleep** | `Thread.sleep(2000)` / `await delay(2000)` | 改 `waitFor(condition)` |
| **依賴時序** | `expect(time.now() - start < 1000)` | 改 deterministic time / clock injection |
| **共享狀態** | 全域 singleton 累積 | 每 test setUp/tearDown 重置 |
| **依賴外部網路** | call real API | Mock HTTP boundary |
| **隨機資料** | `Math.random()` 沒固定 seed | 固定 seed / faker.seed() |
| **DB race condition** | 平行測試讀寫同 row | 用 unique key / transaction |
| **動畫 / 過場** | `cy.contains("Welcome")` 但動畫沒完 | `cy.get(...).should("be.visible")` |
| **non-deterministic 順序** | `expect(arr).toEqual([1,2,3])` 但實際 order 不定 | 用 `arrayContaining` |
| **Memory / 資源洩漏** | 跑久了變慢 | 每 N test 重啟 worker |

### Phase 5: 產出報告

寫到 `~/.local/share/qa-flaky/{repo}/report-{date}.md`：

```markdown
# Flaky Test Report · my-app · 2026-05-22

## 📊 整體
- 分析期間: 過去 30 天 (n=842 runs)
- 總測試數: 1247
- Stable: 1186 (95.1%)
- Flaky: 42 (3.4%)
- Stable-fail: 19 (真實 bug，不是 flaky)

**Flakiness Score**: 3.4% （目標 < 2%）

## 🔴 High flaky (> 30%)

### #1 `LoginUITests.testRetryAfterFailure` (Flakiness: 47%)
- 平台: iOS
- 失敗次數: 23 / 49 runs
- 最近失敗: 2026-05-21
- **疑似根因**: `Thread.sleep(2000)` (line 42) + 依賴後台 token expiry
- **建議修復**:
  1. 改用 `expect(element).toExist()` 等待條件
  2. 注入 fake clock，控制 token expiry
- **隔離**: 加 `@QuarantineFlaky` annotation，CI 標 warning 不阻擋

### #2 `WebSocketTest.testReconnect` (Flakiness: 35%)
- 平台: Backend
- ...

## 🟡 Medium flaky (10-30%)
[10 條...]

## 🟢 Low flaky (1-10%)
[30 條...]

## 📋 自動化處理建議

立刻動作:
- [ ] Quarantine 8 條 High flaky (PR: feature/quarantine-flaky)
- [ ] 建 8 個 JIRA ticket 追蹤修復（用 bug-report skill）

中期動作:
- [ ] 設 CI gate: flakiness > 30% 自動標 quarantine
- [ ] 把 Quarantine 區獨立成 nightly job，不阻 PR

## 📈 趨勢

- 上次報告 (2026-04): 5.1% flakiness
- 這次:                3.4% (-1.7% 改善 ✅)
```

### Phase 6: 自動處理選項

互動式問使用者：
- 要不要對 High flaky 加 `@Disabled` / `@QuarantineFlaky` annotation？
- 要不要建 JIRA ticket（用 `bug-report` skill）追蹤修復？
- 要不要產 PR 把 flaky 移到隔離區？

預設**不主動修改測試碼**，只給建議。

## ⚠️ 安全護欄

- ❌ 不主動 disable test（必使用者明確同意）
- ❌ 不對 stable-fail（真實 bug）標 flaky
- ✅ Quarantine 標記必含 "must-fix-by: YYYY-MM-DD" 避免被忘記
- ✅ 報告寫 `~/.local/share/qa-flaky/`，不污染 repo

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `flaky_hunter.ci_platform` | CI 平台類型 | 偵測 `.github/workflows/` 等推斷 |
| `flaky_hunter.lookback_days` | 分析天數 | 預設 30 |
| `flaky_hunter.flaky_threshold` | 標 flaky 起始失敗率 | 預設 1% |
| `flaky_hunter.high_flaky_threshold` | 高嚴重度標準 | 預設 30% |

## 配套整合

```
持續看到 CI 不穩
   ↓
/flaky-test-hunter
   ↓ 報告找出 42 條 flaky
   ↓
互動式 → 對 8 條 High flaky 加 @Quarantine
   ↓
/bug-report → 為 8 條建 JIRA ticket
   ↓
修復後重跑 /flaky-test-hunter → 看 score 是否降
```

## 範例

詳見 [`examples.md`](./examples.md)
