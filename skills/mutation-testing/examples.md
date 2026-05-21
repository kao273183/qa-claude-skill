# mutation-testing 範例

## 範例 1: 首次設定（critical 模組）

```
User: /mutation-testing health --config
```

執行：
1. 檢查 mutmut 是否裝（沒裝就裝）
2. 寫入 `pyproject.toml` 的 `[tool.mutmut]`：
   ```toml
   paths_to_mutate = "src/health/anti_cheat.py"
   runner = "pytest tests/test_health_api.py -x -q"
   ```
3. 確認 baseline pytest 全 PASS
4. 估時：source 200 行 → ~10 min

## 範例 2: 跑變異 + 產報告

```
User: /mutation-testing health --run
User: /mutation-testing health --report
```

輸出：
```
✅ Mutation 完成 · health · 2026-MM-DD

📊 統計：
- Mutation 總數: 142
- Killed: 118 (83%)
- Survived: 22 (15.5%)

🔴 高嚴重 Survived:
#1 anti_cheat.py:42 `trust_level >= 4` → `> 4`
   對應 WB-HEALTH-024，建議補 boundary 4/5 case
#2 checkin.py:18 `distance > 100` → `>= 100`
   對應 WB-HEALTH-039，建議補 100.0 整數 case

📋 補測清單寫到 ~/.local/share/qa-mutation/health/report-2026-05-21.md

下一步：
/tc-to-pytest health --incremental
```

## 範例 3: 升版前驗證強度

```
User: 健康 v0.3 升版後，TC 真的更強嗎？
       → /mutation-testing health --run
```

對比：
- v0.2 mutation score: 76%
- v0.3 mutation score: 89% (+13%)
- 結論：TC 強度上升，可發版
