---
name: mutation-testing
description: 用 mutmut 對 BE Python 程式碼做變異測試，量化「TC 真的能抓 bug 嗎」。把存活的 mutation 對應回 TC ID，列出哪些 TC 弱、該補什麼斷言。當使用者提到「mutation testing / 變異測試 / TC 真實覆蓋 / 我的測試夠不夠強 / mutmut / 量化 TC 品質」，或想驗證 pytest 是否真的能 catch bug 時觸發。配套：tc-to-pytest（產 pytest）、test-review（傳統審查）、tc-version-diff（升版時確認新 TC 真有強化）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[pytest 目標 dir / test 檔路徑] [--config | --run | --report]"
---

# mutation-testing

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。
> 啟用條件：`config.backend.pytest_enabled = true` 且 `backend.mutation.enabled = true`。

## 為什麼要這個 skill

行覆蓋率（line coverage）只回答「程式碼有沒有被執行到」，不回答「**TC 真的能抓出 bug 嗎**」。

例：
```python
def is_within_100m(distance):
    return distance < 100   # ← 改成 distance <= 100，TC 會抓到嗎？

def test_within_100m():
    assert is_within_100m(50) is True   # 沒測 boundary → 改成 <= 也通過
```

行覆蓋率 100%，但 mutation `<` → `<=` 存活 = TC 沒真正驗證邊界。

→ Mutation testing 揭露這種「**假覆蓋**」。

## 適用場景

- ✅ pytest 已寫，想驗 TC 嚴格度
- ✅ Sprint 結束想量化「這版 TC 強度比上版高嗎」
- ✅ Critical 模組（反作弊 / 邊界判斷 / 信任度評分）特別想驗
- ✅ `test-review` 打分 90+ 但想 double-check 是否真強

## 不適用場景

- ❌ 沒 pytest（先用 `tc-to-pytest` 產）
- ❌ pytest 還沒跑通（先讓 baseline pass）
- ❌ Sheet TC（mutation 測 source code，不測規格）
- ❌ Flutter / Dart / Swift（mutmut 是 Python only；其他語言用 stryker / pitest）

## 對齊基準

- **目標 codebase**：`{{PYTEST_PROJECT_ROOT}}` 與其覆蓋的 BE source code
- **工具**：`mutmut` (Python)
- **產出 root**：`~/.local/share/qa-mutation/{feature}/`

## Phase 1: 設定（首次跑）

`--config` 模式：

1. 檢查 `mutmut` 是否裝：`mutmut --version`，沒裝就裝 `pip install mutmut`
2. 在 pytest 專案 root 建 `setup.cfg` 或 `pyproject.toml` 的 mutmut 段：

```toml
[tool.mutmut]
paths_to_mutate = "src/{feature}/"
runner = "pytest tests/test_{feature}_api.py -x -q"
backup = false
tests_dir = "tests/"
```

3. 確保 `pytest` 跑得通（baseline 全 PASS 才有意義）
4. 加 mutmut 到 `requirements-dev.txt`

互動式問使用者：
- 哪個 module / dir 要測？（focus 在 critical 邏輯，不要全打）
- 估時：若 source 1000 行 → mutmut 大約 30-60 min（每個 mutation 跑一次 pytest）

## Phase 2: 跑（`--run`）

```bash
mutmut run --paths-to-mutate=src/{feature}/{critical_module}.py
mutmut results       # 列出 survived / killed / suspicious / timeout
mutmut html          # HTML report
```

**結果分類**：
- ✅ Killed: TC 抓到（好）
- 🔴 Survived: mutation 沒被任何 TC 抓到（弱點）
- ⏱️ Timeout: mutation 害測試 hang
- ❓ Suspicious: 可疑（行為不確定）

## Phase 3: 對應回 TC ID（`--report`）

每個 survived mutation：
1. 找出 mutation 影響的 source 檔 + 行號
2. grep pytest test 檔的 docstring（「對應 TC: WB-XXX-XXX」）找哪些 test cover 該 source
3. 列出「對應的 TC ID + 為什麼沒抓到」

報告寫到 `~/.local/share/qa-mutation/{feature}/report-{date}.md`：

```markdown
# Mutation Report · {feature} · 2026-MM-DD

## 📊 整體
- Mutation 總數: 142
- Killed: 118 (83%)
- Survived: 22 (15.5%)
- Timeout/Suspicious: 2

**Mutation Score**: 83%（目標 ≥ 80%；Critical 模組 ≥ 95%）

## 🔴 Survived（按嚴重度排）

### 🔴 高嚴重（critical 邏輯，必補）

#### #1 反作弊信任度判斷
- 檔案: `src/{feature}/anti_cheat.py:42`
- Mutation: `if trust_level >= 4:` → `if trust_level > 4:`
- 影響: trust=4 沒被歸為「高信任」可能放行作弊資料
- **對應 TC**:
  - WB-{FEATURE}-024（5 級信任度判定 schema 對齊）→ 沒驗 boundary 4
  - WB-{FEATURE}-025（manual 拒絕邏輯）→ 沒覆蓋 trust=4 case
- **建議**: 補一條 `test_anti_cheat_trust_boundary_4_5`，明確驗 trust=4 跟 5 的差異

#### #2 100m 邊界
- 檔案: `src/{feature}/checkin.py:18`
- Mutation: `if distance > 100:` → `if distance >= 100:`
- **對應 TC**: BB-{FEATURE}-039 + WB-{FEATURE}-039 都有，但只測 50m / 150m，沒測 100m 整數
- **建議**: 加 boundary 100.0 / 99.99 / 100.01 三個 case

## 📋 補測清單

| 補測 ID | 對應 source | 對應原 TC | 預估 |
|---------|-------------|-----------|------|
| WB-{FEATURE}-024-x（升版補強）| anti_cheat.py:42 | WB-{FEATURE}-024 | 30 min |
| WB-{FEATURE}-039-x | checkin.py:18 | WB-{FEATURE}-039 | 20 min |

## 📈 跟上次比

- 上次 mutation score: 76%
- 這次: 83%（+7%，TC 強度上升）

## 下一步建議

1. 補補強 case（focus critical / 高嚴重）
2. 跑 `/tc-to-pytest <feature> --incremental` 同步 pytest
3. 重跑 mutmut 驗 score 是否升到 ≥ 90%
4. 回填 TC Sheet 的「備註欄」加 mutation_score
```

## Phase 4: 補測整合

報告產完後可選：
- 自動提示跑 `/tc-to-pytest <feature> --incremental` 加補強 case
- 在原 TC Sheet 的「備註欄」追加 `[mutation: killed/survived]` 標記
- 把 Mutation Score 加進 `tc-index.md` 的監控欄

## ⚠️ 安全護欄

- ✅ 只在 dev / local 跑（mutmut 會跑 N×pytest 次，慢且耗 CPU）
- ✅ 報告寫到 `~/.local/share/qa-mutation/`，不污染 repo
- ❌ 不在 CI 跑（太慢 / 不穩 / 對 PR 沒立即價值；可週跑或 release 前跑）
- ❌ 不主動修 source code（mutmut 只是評估，不改你的 code）
- ❌ 不主動補 pytest（給建議，使用者 review 後跑 `tc-to-pytest`）

## 設定建議

| Feature 類型 | 範圍範例 | 預估時長 | Mutation Score 目標 |
|------------|---------|---------|---------------------|
| 反作弊邏輯 | `src/health/anti_cheat.py` | ~10 min | ≥ 95%（critical） |
| 邊界判斷 | `src/health/checkin.py` | ~5 min | ≥ 95% |
| 數值計算 | `src/health/steps.py` | ~15 min | ≥ 90% |
| CMS 入口 | `src/stamp/cms/` | ~30 min | ≥ 80% |
| GraphQL 中介層 | 不適用（邏輯薄）| — | — |

## 配套整合

```
有 pytest 後想驗 TC 強度
   ↓ /mutation-testing {feature} --config （首次設定）
   ↓ /mutation-testing {feature} --run （跑變異）
   ↓ /mutation-testing {feature} --report （產 markdown）
報告找出 Survived
   ↓ 補測建議
   ↓ /tc-to-pytest {feature} --incremental（補 pytest）
   ↓ /mutation-testing {feature} --run（再驗）
直到 Mutation Score 達標
```

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `backend.pytest_enabled` | 啟用條件 | skill 不啟用 |
| `backend.mutation.enabled` | 啟用此 skill | skill 不啟用 |
| `backend.mutation.score_target` | Score 目標 | 預設 80%（critical 95%） |
| `backend.pytest_project_root` | mutmut 工作目錄 | 互動式詢問 |

## 範例

詳見 [`examples.md`](./examples.md)

## 替代工具（其他語言）

| 語言 | 工具 | 成熟度 |
|------|------|--------|
| Python | `mutmut`（本 skill 預設） | 成熟 |
| Kotlin / Java | `Pitest` | 成熟 |
| JavaScript / TypeScript | `Stryker.js` | 成熟 |
| Swift | `muter`（停更）/ Stryker.swift | 不穩 |
| Dart / Flutter | `mutation_test`（社群實驗）| 實驗 |
| Go | `gomutate` | 不穩 |

→ 本 skill focus Python；其他語言不在範圍內。
