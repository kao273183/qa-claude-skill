# performance-test-gen 範例

## 範例 1: 從 Sheet TC 生成 k6 腳本

```
User: /performance-test-gen https://docs.google.com/spreadsheets/d/xxx/edit
```

執行：
1. 讀 Sheet「Performance」分類 row
2. 為 5 個 endpoint 生成 k6 腳本
3. 推導 SLA：p95 < 1000ms / error < 1%
4. 設計 ramp-up (50 → 200 VUs)
5. 寫到 `tests/performance/*.k6.js`

跑：`k6 run tests/performance/login.k6.js -e BASE_URL=https://uat.example.com`

## 範例 2: 從 JIRA 票生成 Locust

```
User: /performance-test-gen {{JIRA_PROJECT_KEY}}-1234 --framework=locust
```

抓 JIRA description「驗證 1000 並發使用者下登入流暢」→
- concurrent VUs = 1000
- ramp-up 5 min
- 寫到 `tests/performance/login_locust.py`

## 範例 3: Spike Test

```
User: 模擬流量突增 — 0 → 5000 RPS in 10 seconds
```

→ k6 stages 設計成 spike model + 監控 error rate / 5xx 突增。

## 範例 4: 對比 v1 vs v2

```
User: /performance-test-gen --compare-baseline=baseline-v1.json
```

跑完跟 baseline 比較 → 報告「p95 從 800ms 升到 1200ms（+50%）」regression alert。
