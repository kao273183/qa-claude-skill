# 一文搞懂 property-based-test-gen

> 給第一次聽到「property-based testing」的 QA / 工程師看的快速導讀。
> 看完就知道「這 skill 在幹嘛 / 為什麼要用 / 什麼時候用」。

---

## 🎯 一句話總結

> **「你寫規則，工具自動生成 100~1000 個 input 來試。專門用來抓邊界 bug。」**

特別適合 QA 想驗「我的 TC 邊界覆蓋是不是真的夠」的時候。

---

## 🆚 跟你熟悉的測試差在哪？

### 一般的測試（Example-based）— 你現在寫的這種

```python
def test_within_100m():
    assert is_within_100m(50) == True    # 寫死 input=50
    assert is_within_100m(150) == False  # 寫死 input=150
```

**問題**：你選的 input 不一定能抓到 bug。
- 你選 50 / 150，但實際 bug 在 100.0 整數邊界
- 你選整數，但 bug 在浮點誤差 99.999999
- 你沒測 NaN / Infinity / 負數

### Property-based test — hypothesis 工具做的事

```python
@given(d=st.floats(min_value=0, max_value=99.99))   # ← 給範圍，不給具體值
def test_within_100m_property(d):
    assert is_within_100m(d) == True   # ← 寫「規則」：任何 0~99.99 都該 True
```

hypothesis 看到這個會**自動丟 200 個隨機 input** 進去測：
- 試 `0`, `50`, `99`, `99.9`, `99.99`...
- 試特殊值：`0.000001`, `99.999999`
- **自動找出最小可重現 bug 的 input**

---

## 🎬 真實案例：100m 邊界判斷

假設你寫的程式碼是：

```python
def is_within_100m(distance):
    return distance <= 100   # ← 注意這裡是 <=，spec 其實是 <
```

### 用 Example test 會發生什麼？

你寫了：
```python
def test_within_100m():
    assert is_within_100m(50) == True
    assert is_within_100m(150) == False
```

結果：兩個 input 全 PASS ✅
**→ Bug 還在**（spec 說「距離 < 100m」，code 寫成 `<= 100`）

### 用 Property test 會發生什麼？

```python
@given(d=st.floats(min_value=0, max_value=99.99))
def test_within_100m_property(d):
    assert is_within_100m(d) == True
```

hypothesis 自動試到 `distance = 100.0` 整數值 — 立刻 FAIL ❌

```
Falsifying example: test_within_100m_property(
    d=100.0,
)
```

→ 你立刻知道有 off-by-one bug，連「最小可重現 input」都自動算出來了。

---

## 🪄 hypothesis 最強的功能：自動 shrink

當 hypothesis 找到 fail 的 input，會**自動縮到最小可重現的 input**。

例如它一開始亂試到 `d = 100.0000000001` fail 了，它會繼續縮：
- 試 `d = 100.0` → 也 fail
- 試 `d = 99.999...` → pass
- 結論：**最小可重現 input = 100.0**

```
Falsifying example: test_within_100m_property(
    d=100.0,
)
```

→ 你**不用猜「到底哪個 input 壞掉」**，hypothesis 直接告訴你。

對比 example test：如果你的測試亂跑找到 fail，你還得手動 debug 找最小 case。

---

## 🧪 hypothesis 還能驗什麼？

不只是數字邊界，凡是「有不變規則」的功能都適合：

### 1. 數值範圍
```python
# Invariant: trust_level 永遠在 0~5
@given(...)
def test_trust_level_always_in_range(source, history, manual):
    level = compute_trust_level(source, history, manual)
    assert 0 <= level <= 5
```

### 2. 編碼/解碼可逆（round-trip）
```python
# Invariant: encode → decode 必須得到原始值
@given(token=st.text(min_size=1, max_size=100))
def test_encode_decode_roundtrip(token):
    assert decode(encode(token)) == token
```

### 3. 集合操作（順序、重複）
```python
# Invariant: 排序後再 reverse = 原本反向排序
@given(arr=st.lists(st.integers()))
def test_sort_reverse(arr):
    assert sorted(arr, reverse=True) == sorted(arr)[::-1]
```

### 4. 狀態機（序列 invariant）
```python
# Invariant: 已 join 的 challenge 必有 progress 紀錄
class ChallengeStateMachine(RuleBasedStateMachine):
    @rule(cid=st.integers())
    def join(self, cid): ...

    @invariant()
    def joined_have_progress(self):
        for cid in self.joined:
            assert cid in self.progress
```

---

## 🤝 跟 mutation-testing 怎麼搭

兩個工具互補，不是取代：

| 工具 | 角色 | 比喻 |
|------|------|------|
| **mutation-testing** | 找漏點 | 偵測機：「`<` 改成 `<=`，你的 TC 抓得到嗎？」抓不到 → 漏點 |
| **property-based-test-gen** | 封死漏點 | 機槍：「給我 0~99.99 範圍，丟 200 個 input 全部驗過」 |

### 完整流程

```
1. 你寫 example pytest
   ↓
2. mutation-testing 跑 → 找到 "100.0 沒人測到"（survived mutation）
   ↓
3. property-based-test-gen 補 @given(d=floats(0, 100)) 200 examples
   ↓
4. 重跑 mutation-testing → 之前 survived 的現在 killed ✅
```

---

## ⚡ 什麼時候**該**用？

✅ 適合：
- BE pytest 已寫，想升級加 fuzz（反作弊 / 邊界 / 範圍）
- 跑完 `mutation-testing` 看到 boundary survived，想用 fuzz 封死
- Sprint review 後 critical 模組要強化（如 spec 改了 100m → 50m）
- 純邏輯 function（不打 API / 不寫 DB）

## 🚫 什麼時候**不該**用？

❌ 不適合：
- 純 schema 驗證 / status code 檢查（example test 就夠，沒有「範圍」可 fuzz）
- UI / Flutter / Swift 測試（hypothesis 是 Python only）
- 有 IO 副作用（call API / 寫 DB）的 function（fuzz 會打爆 BE）
- 沒明確 property 可寫（你看了 spec 也想不出 invariant）→ 維持 example test

---

## 🎓 三個關鍵心法

### 1. 「規則」比「答案」重要

Example test 寫的是「給 input X，答案是 Y」。
Property test 寫的是「任何符合條件的 input，都該滿足規則 P」。

範例：
- ❌ 寫死：`assert add(2, 3) == 5`（這只是一個 example）
- ✅ 寫規則：`assert add(a, b) == add(b, a)`（**任何** a, b 都該滿足交換律）

### 2. hypothesis 不取代 example test，是**補強**

- Example test 跑得快 → 留在 PR CI
- Property test 跑很慢（每條 200 examples）→ 改成 nightly / 週跑 / release 前跑
- 兩種 test **並存**，**不**互相取代

### 3. fuzz 找到 fail 不一定是 bug

可能是 spec 沒講清楚：
- `is_within_100m(100.0)` 該 True 還 False？spec 沒明寫
- → 回 spec / PM 釐清 → 補 `@example(d=100.0)` 寫死 regression case

---

## 🚀 從零開始的 5 步驟

如果你想自己寫一條 property test：

### Step 1: 挑一個適合的 function

選有「不變規則」的 — 邊界、範圍、編碼解碼、單調性。

❌ 不適合：`fetch_user_from_api(id)`（有 IO 副作用）
✅ 適合：`is_valid_phone_number(s)`（純邏輯，可驗 format invariant）

### Step 2: 寫出 invariant

問自己：「不管 input 是什麼，這 function 都該滿足什麼規則？」

範例（電話號碼驗證）：
- 全是數字 + 長度 10 → 必 True
- 含字母 → 必 False
- 空字串 → 必 False
- 長度超過 20 → 必 False

### Step 3: 用 strategies 描述 input 範圍

```python
from hypothesis import given, strategies as st

@given(s=st.text(alphabet="0123456789", min_size=10, max_size=10))
def test_valid_format(s):
    assert is_valid_phone_number(s) == True
```

### Step 4: 跑跑看

```bash
pytest tests/test_phone_property.py -v --hypothesis-show-statistics
```

hypothesis 會自動丟 100~200 個 input 進去測。

### Step 5: 處理 fail（如果有）

如果 fail：
1. 看 `Falsifying example:` 找最小 input
2. 確認是 bug 還是 spec 不明
3. 修 code 或寫 `@example(...)` regression case

---

## 📚 進一步閱讀

- [hypothesis 官方文件](https://hypothesis.readthedocs.io/)
- [property-based-test-gen SKILL](./SKILL.md) — 本 skill 完整流程
- [property-based-test-gen 範例](./examples.md) — 3 個實際使用情境

## 🎯 一句話複述

**「你寫規則，hypothesis 自動生成 200 個 input 來驗。專抓邊界 bug，跟 mutation-testing 配對使用，封死『假覆蓋』漏洞。」**
