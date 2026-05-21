# property-based-test-gen 範例

## 範例 1: 從既有 pytest 升級

```
User: /property-based-test-gen tests/test_health_api.py
```

執行：
1. 讀 `test_health_api.py`，找出 critical function：
   - `is_within_100m()`（boundary）
   - `compute_trust_level()`（範圍判斷）
   - `is_daily_step_within_cap()`（單調遞增）
2. 從 docstring / spec 推 invariants
3. 寫到 `tests/test_health_property.py`
4. 印 strategy 預覽：
   ```
   ✅ 產出 6 條 property test，補強 4 條 example test
   - test_within_100m_property → strengthens WB-HEALTH-039
   - test_outside_100m_property → strengthens WB-HEALTH-039
   - test_invalid_distance_property → strengthens WB-HEALTH-039
   - test_trust_level_in_range → strengthens WB-HEALTH-024
   - test_high_anomaly_caps_trust → strengthens WB-HEALTH-024
   - test_manual_override_zeros_trust → strengthens WB-HEALTH-025
   ```

## 範例 2: 從 mutation report 針對性補強

```
User: /property-based-test-gen tests/test_health_api.py \
        --from-mutation-report ~/.local/share/qa-mutation/health/report-2026-05-21.md
```

執行：
1. 讀 mutation report 的 Survived 列表
2. 只為 Survived 點對應的 function 產 property test
3. 寫對應 strategy，明確覆蓋 mutation 點

## 範例 3: hypothesis 找出真實 bug

```
$ pytest tests/test_health_property.py -v

FAILED test_within_100m_property
Falsifying example: test_within_100m_property(d=100.0)

→ spec 沒明確說 distance == 100.0 該 True 還是 False
→ 立即向 PM 釐清
→ 補 example test：@example(d=100.0) + 寫死預期值
→ 視作 regression case
```
