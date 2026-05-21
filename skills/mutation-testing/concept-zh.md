# 一文搞懂 mutation-testing

> 給第一次聽到「變異測試」的 QA / 工程師看的快速導讀。
> 看完就知道「為什麼行覆蓋率 100% 也不夠」。

---

## 🎯 一句話總結

> **「故意改壞你的程式碼，看你的 TC 抓不抓得到。抓得到 = 強；抓不到 = 假覆蓋。」**

mutation-testing 用來**量化你的 TC 真實強度**，回答一個問題：
「我的 TC 真的能抓 bug 嗎，還是只是看起來覆蓋率高？」

---

## 🆚 跟你熟悉的「行覆蓋率」差在哪？

### 行覆蓋率（Line Coverage）— 你目前在追的指標

```python
def is_within_100m(distance):
    return distance < 100          # ← 這行被執行過 ✅

def test_within_100m():
    assert is_within_100m(50) == True   # ← 跑過上面那行
```

報告說：**Line Coverage = 100%** 🎉

問題：**這只回答「程式碼有沒有跑」，沒回答「TC 真的能抓 bug 嗎」**。

### Mutation Testing — 真實壓力測試

工具會**故意改壞你的程式碼**：

```python
# 原版
def is_within_100m(distance):
    return distance < 100

# Mutation #1: 改成 <=
def is_within_100m(distance):
    return distance <= 100   # ← 故意改壞

# Mutation #2: 改成 >
def is_within_100m(distance):
    return distance > 100    # ← 故意改壞

# Mutation #3: 改數字
def is_within_100m(distance):
    return distance < 99     # ← 故意改壞
```

然後每改一個 mutation 都跑一次你的 pytest，看 TC 能不能抓到：

- ✅ **Killed**：你的 TC FAIL 了 → TC 有抓到 = 好
- 🔴 **Survived**：你的 TC 全 PASS → TC 沒抓到 = **弱點！**

---

## 🎬 真實案例：100% Line Coverage 也可能漏

假設你的 code：
```python
def is_within_100m(distance):
    return distance < 100
```

你的 TC：
```python
def test_within_100m():
    assert is_within_100m(50) == True
    assert is_within_100m(150) == False
```

Line coverage：**100%** ✅

### mutmut 跑變異測試：

| Mutation | 結果 | 為什麼 |
|----------|------|--------|
| `< 100` → `<= 100` | 🔴 Survived | TC 沒測 100.0 整數值 |
| `< 100` → `> 100` | ✅ Killed | TC 50 會抓到 |
| `100` → `99` | ✅ Killed | TC 50 會抓到（剛好邊界） |
| `100` → `101` | 🔴 Survived | TC 50 / 150 都不會踩這個區間 |

→ **Mutation Score = 50%**（4 個 mutation 抓到 2 個）
→ 結論：**你的 TC 雖然 100% line coverage，但其實只抓到 50% 的潛在 bug**

---

## 🔑 關鍵指標：Mutation Score

```
Mutation Score = Killed / (Killed + Survived) × 100%
```

| 分數 | 等級 | 建議 |
|------|------|------|
| ≥ 95% | 🟢 Critical 模組必達 | 反作弊 / 金流 / 認證 |
| ≥ 80% | 🟢 一般模組目標 | 大部分業務邏輯 |
| 60-80% | 🟡 不夠強 | 該補測 |
| < 60% | 🔴 假覆蓋警告 | TC 有跑但抓不到 bug |

---

## 🤝 跟 property-based-test-gen 怎麼搭

兩個工具互補：

| 工具 | 角色 | 比喻 |
|------|------|------|
| **mutation-testing** | 找漏點 | **偵測機**：「`<` 改成 `<=`，TC 抓得到嗎？」抓不到 = 漏點 |
| **property-based-test-gen** | 封死漏點 | **機槍**：「給我 0~99.99 範圍，丟 200 個 input 全部驗過」 |

### 完整 BE 品質提升流程

```
1. 你寫 example pytest（baseline）
   ↓
2. mutation-testing 跑 → 找到 "100.0 沒人測到"（survived mutation）
   ↓
3. property-based-test-gen 補 @given(d=floats(0, 100)) 200 examples
   ↓
4. 重跑 mutation-testing → 之前 survived 的現在 killed ✅
   ↓
5. Mutation Score 從 50% → 90%
   ↓
6. 可以安心發版
```

---

## 🧪 mutmut 會做哪些變異？

`mutmut` 對 Python 程式碼自動套用這些變異：

| 類型 | 範例 |
|------|------|
| **數字微調** | `100` → `99`、`100` → `101`、`0` → `1` |
| **比較運算子** | `<` → `<=`、`>` → `>=`、`==` → `!=` |
| **布林運算** | `and` → `or`、`not x` → `x` |
| **數學運算** | `+` → `-`、`*` → `/` |
| **常數替換** | `True` → `False`、`None` → `0` |
| **字串** | `""` → `"XX"` |

→ 這些變異**剛好是程式設計師常犯的 off-by-one / boolean flip / sign flip 錯誤**。

---

## ⚡ 什麼時候**該**用？

✅ 適合：
- BE pytest 已寫，想驗 TC 嚴格度
- Sprint 結束想量化「這版 TC 強度比上版高嗎」
- Critical 模組（反作弊 / 邊界判斷 / 金流）特別想驗
- `test-review` 打分 90+ 但想 double-check 是否真強

## 🚫 什麼時候**不該**用？

❌ 不適合：
- 沒 pytest（先用 `tc-to-pytest` 產）
- pytest 還沒跑通（baseline 必先全 PASS）
- Sheet TC（mutation 測 source code，不測規格）
- Flutter / Dart / Swift（mutmut 是 Python only；其他語言用 stryker / pitest）

---

## ⏱ 一個重要警告：很慢

mutation testing **比一般測試慢 100×+**：
- 每個 mutation 都要跑一次完整的 pytest
- 1000 行程式碼 = 約 142 個 mutation = pytest 跑 142 次

**CI 策略**：
| 何時跑 | 設定 |
|--------|------|
| 本機 dev | `mutmut run --paths-to-mutate=src/critical/` |
| 每次 PR | ❌ **不跑**（太慢） |
| Nightly / Weekly | ✅ 跑 |
| Release 前 | ✅ 跑（critical 模組） |

---

## 🎓 三個關鍵心法

### 1. Line Coverage 100% 是必要條件，**不是**充分條件

意思：行覆蓋率高不代表 TC 強。
- Line Coverage = 「程式碼有沒有被跑到」
- Mutation Score = 「TC 有沒有真的驗證行為」

100% line coverage + 50% mutation score → **TC 形同虛設**。

### 2. Survived ≠ 一定要補

不是每個 survived mutation 都該補，要看：
- 🔴 **必補**：critical 邏輯（反作弊、邊界、金流）
- 🟡 **可緩**：日誌訊息、字串樣板
- 🟢 **跳過**：等價變異（如 `x + 0` → `x - 0`）

### 3. Mutation Score 用來看「趨勢」，不是「絕對值」

絕對值看：80%? 90%? 但更重要的是**趨勢**：
- v0.2 Mutation Score = 65%
- v0.3 Mutation Score = 82%
- → **TC 真的有強化** ✅

可以拿去說服 PM「我的 TC 比上版強 17%」。

---

## 🚀 從零開始的 4 步驟

### Step 1: 確認你有 pytest baseline

```bash
pytest tests/  # 全 PASS 才能繼續
```

### Step 2: 設定 mutmut（透過 skill）

```
/mutation-testing health --config
```

skill 會幫你寫 `pyproject.toml`：
```toml
[tool.mutmut]
paths_to_mutate = "src/health/"
runner = "pytest tests/test_health_api.py -x -q"
```

### Step 3: 跑變異測試

```
/mutation-testing health --run
```

注意：可能要 10-60 分鐘（依 source 大小）。

### Step 4: 看報告 + 補測

```
/mutation-testing health --report
```

報告會列出 survived mutations + 對應 TC ID + 建議補測。

可選：用 `/property-based-test-gen --from-mutation-report` 自動針對 survived 點補 property test。

---

## 📚 進一步閱讀

- [mutmut 官方文件](https://mutmut.readthedocs.io/)
- [mutation-testing SKILL](./SKILL.md) — 本 skill 完整流程
- [mutation-testing 範例](./examples.md) — 3 個實際使用情境
- [property-based-test-gen concept](../property-based-test-gen/concept-zh.md) — 互補工具的入門

## 🎯 一句話複述

**「故意改壞你的 code，看 TC 抓不抓得到。Mutation Score 才是 TC 真實強度，行覆蓋率 100% 可能只是假覆蓋。」**
