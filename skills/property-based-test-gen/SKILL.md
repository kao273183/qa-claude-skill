---
name: property-based-test-gen
description: 從 TC 的邊界欄位（前置 / 預期）+ 既有 pytest，產生 hypothesis 的 @given strategies，把 example-based test 升級成 fuzz test。每條 property test 跑 100+ input 自動探邊界 bug，跟 mutation-testing 互補（mutation 找漏點 / property 用 fuzz 封死）。當使用者提到「property-based testing / hypothesis / fuzz test / 隨機 input 測 / 邊界自動掃 / 把 example test 變 property test」，或剛跑完 mutation-testing 看到 boundary survived 想補強時觸發。配套：tc-to-pytest（前置 example test）、mutation-testing（找漏點）、test-review（驗 strategy 合理）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[pytest 檔路徑 / 模組名] [--from-tc <Sheet>] [--from-mutation-report <path>]"
---

# property-based-test-gen

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。
> 啟用條件：`backend.pytest_enabled = true` 且 `backend.property_based.enabled = true`。

> 💡 **第一次聽到 property-based testing？** 先看 [`concept-zh.md`](./concept-zh.md) 中文入門導讀（5 分鐘看完搞懂概念）。

## 為什麼要這個 skill

**Example-based test**（你現在的 pytest）= 寫死 1-2 個 input + 預期值。
- 易讀、跑很快
- 但 boundary / 邊角 case 容易漏
- 100% line coverage 也可能漏 off-by-one

**Property-based test**（hypothesis）= 給 input 範圍 + 不變的 property，工具隨機生成 100+ 個 input 自動跑。
- 自動找邊界（fp 誤差、NaN、Infinity、極大/極小、空字串、空陣列）
- shrink 機制：找到 fail input 後自動縮到最小 reproducer
- 跟既有 example test **共存**，不取代

→ 這個 skill 把既有 pytest 升級加 property test，主要對 critical 邏輯。

## 適用場景

- ✅ BE pytest 已寫，想升級加 fuzz（反作弊 / 邊界 / 範圍）
- ✅ 跑完 `/mutation-testing` 看到 boundary survived，想用 fuzz 封死
- ✅ Sprint review 後 critical 模組要強化

## 不適用場景

- ❌ 純 schema 驗證 / status code 檢查（example test 就夠）
- ❌ UI / Flutter / Swift 測試（hypothesis 是 Python only；JS 用 fast-check / Dart 用 glados）
- ❌ 有 IO 副作用（call API / 寫 DB）的 test（fuzz 會打爆 BE）→ 改 fuzz pure function only
- ❌ 沒明確 property 可寫 → 維持 example test

## 對齊基準

- **目標 codebase**：`{{PYTEST_PROJECT_ROOT}}`
- **核心套件**：`hypothesis`（pip install hypothesis）
- **輸出位置**：`tests/test_<feature>_property.py`（跟 example test 並存，不混在同檔）
- **對齊**：每條 property test 的 docstring 寫對應「strengthens TC: WB-XXX-XXX」（雙向 traceability）

## Phase 1: 取輸入

| Argument | 動作 |
|----------|------|
| pytest 檔路徑 | 讀檔，挑 critical function 升級 |
| 模組名 | 從 `tc-index.md` 找對應 Sheet + pytest 檔 |
| `--from-tc <Sheet>` | 額外讀 Sheet 的「前置 / 預期」欄找邊界描述 |
| `--from-mutation-report <path>` | 讀 mutation-testing report 的 survived 列表，**直接針對 survived 點產 property test** |

## Phase 2: 找 critical function

不是每個 function 都值得 property test。挑這些：

| 類別 | 範例 | 為什麼 |
|------|------|--------|
| **數值邊界** | `is_within_100m(distance)` | off-by-one 易漏 |
| **範圍判斷** | `compute_trust_level(...)` | 多分支 |
| **數值上限** | `is_daily_step_within_cap(steps, trust_level)` | 上限隨等級變 |
| **編碼/解碼可逆** | `encode_token` / `decode_token` | round-trip 必須一致 |
| **集合操作** | `merge_logs(...)` | 順序 / 重複處理 |
| **狀態機** | 挑戰 join → progress | 序列 invariant |

不挑的：純 IO / call BE / 純配置讀寫 / 純驗 schema。

## Phase 3: 推 invariant

每個挑出來的 function，從 spec / TC / docstring 推「不變的規則」。範例：

### `is_within_100m(distance: float) -> bool`

來自：spec §X.X + WB-{FEATURE}-039

Invariants：
1. `distance < 100` → 必 True
2. `distance > 100` → 必 False
3. `distance == 100` → 看 spec（這是 boundary，spec 必須明指）
4. `distance < 0` → 應 raise（GPS 不可能負）
5. NaN / Infinity → 應 raise（防偽）

### `compute_trust_level(source, history_anomaly, manual_overrides) -> int`

Invariants：
1. result always in `0..5`
2. source 是 watch / phone / manual 不同對映
3. `history_anomaly >= 3` → trust_level <= 2
4. `manual_overrides > 0` → trust_level == 0

### `is_daily_step_within_cap(steps, trust_level) -> bool`

Invariants：
1. `trust_level == 5` → cap 80000
2. `trust_level == 0` → cap 25000
3. cap 隨 trust_level **單調遞增**
4. steps < 0 → raise

## Phase 4: 產 hypothesis @given strategy

寫到 `tests/test_<feature>_property.py`：

```python
"""
Property-based tests for <feature> critical functions.
跟 test_<feature>_api.py example test 並存，**不取代** — fuzz 補強邊界。

跑：
  {FEATURE}_API_LIVE=1 pytest tests/test_<feature>_property.py -v --hypothesis-show-statistics

慢執行（每條 ~100+ examples），不適合每次 PR 跑；建議週跑或 release 前。
"""
import math
import pytest
from hypothesis import given, settings, strategies as st, assume, HealthCheck
from src.{feature}.checkin import is_within_100m
from src.{feature}.anti_cheat import compute_trust_level, is_daily_step_within_cap


# ─── is_within_100m ───────────────────────────────────────────

@given(d=st.floats(min_value=0, max_value=99.99, allow_nan=False, allow_infinity=False))
@settings(max_examples=200)
def test_within_100m_property(d):
    """
    Strengthens TC: WB-{FEATURE}-039（打卡 100m 內）
    Invariant: distance ∈ [0, 100) → True
    """
    assert is_within_100m(d) is True


@given(d=st.floats(min_value=100.01, max_value=99999, allow_nan=False, allow_infinity=False))
@settings(max_examples=200)
def test_outside_100m_property(d):
    """
    Strengthens TC: WB-{FEATURE}-039（打卡 100m 外）
    Invariant: distance ∈ (100, ∞) → False
    """
    assert is_within_100m(d) is False


@given(d=st.one_of(
    st.just(float("nan")),
    st.just(float("inf")),
    st.just(float("-inf")),
    st.floats(max_value=-0.01),
))
def test_invalid_distance_property(d):
    """
    Strengthens TC: WB-{FEATURE}-039 邊界（NaN / Infinity / 負）
    Invariant: 無效輸入 → ValueError
    """
    with pytest.raises((ValueError, AssertionError)):
        is_within_100m(d)


# ─── compute_trust_level ──────────────────────────────────────

@given(
    source=st.sampled_from(["apple_watch", "iphone", "android", "manual", "unknown"]),
    history_anomaly=st.integers(min_value=0, max_value=10),
    manual_overrides=st.integers(min_value=0, max_value=10),
)
@settings(max_examples=300)
def test_trust_level_in_range(source, history_anomaly, manual_overrides):
    """
    Strengthens TC: WB-{FEATURE}-024
    Invariant: result always in 0..5
    """
    level = compute_trust_level(source, history_anomaly, manual_overrides)
    assert 0 <= level <= 5
```

## Phase 5: settings 與 CI 整合

property test **比 example test 慢 100×+**。CI 策略：

| 何時跑 | 設定 |
|--------|------|
| 本機 dev | `pytest tests/test_*_property.py -v` |
| PR CI | **不跑**（太慢） |
| Nightly / Weekly | `pytest --hypothesis-profile=ci` |
| Release 前 | `pytest --hypothesis-profile=thorough -v --hypothesis-show-statistics` |

`conftest.py` 加 hypothesis profile：
```python
from hypothesis import settings, HealthCheck

settings.register_profile("ci", max_examples=100, deadline=None)
settings.register_profile("thorough", max_examples=1000, deadline=None,
                          suppress_health_check=[HealthCheck.too_slow])
settings.register_profile("dev", max_examples=50)
```

## Phase 6: 失敗 reproducer

hypothesis 的殺手級功能：找到 fail input 自動 **shrink** 到最小 reproducer。

```
Falsifying example: test_within_100m_property(
    d=100.0,
)
```

→ 100.0 是 boundary，spec 沒說該 True 還是 False。fail = bug 找到了。
→ 立即回 spec / PM 問清楚，補 example test 寫死該 case 結果。
→ 加進 hypothesis 的 `@example(d=100.0)` 當 regression case。

## ⚠️ 安全護欄

- ✅ 只 Write `tests/test_<feature>_property.py`（新檔，**不混 example test**）
- ✅ docstring 一定要寫「Strengthens TC: WB-XXX」對應雙向 traceability
- ✅ 預設 max_examples = 200（夠 fuzz / 不太慢）
- ❌ 不動 example test（保留 PR CI 跑得起來）
- ❌ 不對有 IO 副作用的 function 跑 fuzz（會打爆 UAT）
- ❌ 不在每次 PR CI 跑（指引週跑）
- ⚠️ 如果 fuzz 找出 fail，**先停**回 spec / PM 釐清是不是 bug

## Statful 測試（進階）

對序列 / 狀態機 invariant：

```python
from hypothesis.stateful import RuleBasedStateMachine, rule, invariant

class ChallengeStateMachine(RuleBasedStateMachine):
    """
    Strengthens TC: WB-{FEATURE}-040 + 041（挑戰 join → progress 一致）
    """
    def __init__(self):
        super().__init__()
        self.joined = set()
        self.progress = {}

    @rule(challenge_id=st.integers(min_value=1, max_value=100))
    def join(self, challenge_id):
        if challenge_id not in self.joined:
            self.joined.add(challenge_id)
            self.progress[challenge_id] = 0

    @rule(challenge_id=st.integers(min_value=1, max_value=100), steps=st.integers(min_value=1, max_value=10000))
    def add_steps(self, challenge_id, steps):
        if challenge_id in self.joined:
            self.progress[challenge_id] += steps

    @invariant()
    def joined_have_progress(self):
        for cid in self.joined:
            assert cid in self.progress

    @invariant()
    def unjoined_no_progress(self):
        for cid in self.progress:
            assert cid in self.joined

TestChallengeStateMachine = ChallengeStateMachine.TestCase
```

## 配套整合

```
寫好 example pytest
   ↓ /tc-to-pytest                       baseline N 條
   ↓ pytest baseline pass
   ↓ /mutation-testing                   找 survived（boundary 弱點）
mutation report 提示「distance 100.0 沒測」
   ↓ /property-based-test-gen <pytest> --from-mutation-report <report>
產 property test 補強
   ↓ pytest tests/test_*_property.py     跑 fuzz 找邊界 bug
   ↓ 找到 fail → 回 spec / PM 釐清
   ↓ 加 @example regression case
   ↓ /mutation-testing                   重跑驗 score 升
release-ready
```

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `backend.pytest_enabled` | 啟用條件 | skill 不啟用 |
| `backend.property_based.enabled` | 啟用此 skill | skill 不啟用 |
| `backend.property_based.default_max_examples` | hypothesis 預設 | 預設 200 |
| `backend.pytest_project_root` | 寫入位置 | 互動式詢問 |

## 範例

詳見 [`examples.md`](./examples.md)
