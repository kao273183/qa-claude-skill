---
name: performance-test-gen
description: 從測試用例（Google Sheet TC / JIRA 票號 / 功能描述）生成壓力測試腳本，支援 k6 / JMeter / Locust 三大主流框架。自動推導 SLA threshold（p95 / p99 / error rate）、繪 ramp-up 曲線、整合 CI。當使用者提到「效能測試 / 壓力測試 / load test / stress test / k6 / JMeter / Locust / SLA 驗證 / p95 / TTFB 測試 / API 壓力」時觸發。配套：test-master（規劃 perf TC）、tc-to-pytest（功能 API test）、test-review（審 perf 腳本）、smoke-test-analyzer（perf 不該每次跑）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__readSpreadsheet, mcp__atlassian__getJiraIssue
argument-hint: "[Sheet URL / JIRA 票號 / 功能描述] [--framework=k6|jmeter|locust]"
---

# performance-test-gen

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。
> 啟用條件：`config.performance.enabled = true`。

## 適用場景

- ✅ 已有 API 規格 / 想驗 SLA（p95 < 200ms / error rate < 0.1%）
- ✅ Release 前壓測 critical endpoint（登入 / 結帳 / 搜尋）
- ✅ 容量規劃：給多少 RPS / concurrent users 服務還活著
- ✅ Migration 前後對比：新版比舊版慢還是快

## 不適用場景

- ❌ Unit / UI 功能測試 — 用 `test-automation`
- ❌ 沒 spec 就要壓 — 先用 `test-master` 規劃
- ❌ 業務邏輯正確性驗證 — 用 `tc-to-pytest`

## 框架選擇對照

| 框架 | 適合 | 語言 | 學習曲線 | CI 整合 |
|------|------|------|---------|---------|
| **k6**（推薦）| 現代 API 壓測、雲端 | JavaScript | 低 | 極好 |
| **Locust** | Python 後端團隊 | Python | 低 | 好 |
| **JMeter** | 企業 / 政府、複雜 GUI 流程 | XML / Java | 高 | 中 |

預設用 `{{PERF_PRIMARY_FRAMEWORK}}`（從 config 讀），可用 `--framework=` 覆寫。

## 執行流程

### Phase 1: 取 TC 來源
- Google Sheet URL → 篩出「效能測試 / Performance」分類
- JIRA 票號 → 從 description 推 SLA
- 功能描述 → 互動式問清楚 endpoint / 預期 RPS / SLA

### Phase 2: 推導 SLA threshold

從 TC 「預期結果」欄推：

| 預期描述 | SLA |
|---------|-----|
| 「2 秒內回應」 | p95 < 2000ms |
| 「快」 | p95 < 500ms（互動式問清楚）|
| 「不會 timeout」 | error_rate < 0.1% |
| 「並發 1000 user」 | concurrent VUs = 1000 |
| 「每秒 500 個請求」 | RPS = 500 |

**預設 SLA**（沒明寫時）：
- p95 < 1000ms
- p99 < 3000ms
- error rate < 1%
- success rate > 99%

### Phase 3: 生成腳本

#### k6 範例

```javascript
// tests/performance/login.k6.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 50 },   // ramp-up to 50 VUs
    { duration: '2m',  target: 50 },   // stay at 50
    { duration: '30s', target: 200 },  // spike to 200
    { duration: '1m',  target: 200 },  // stay
    { duration: '30s', target: 0 },    // ramp-down
  ],
  thresholds: {
    http_req_duration:   ['p(95)<1000', 'p(99)<3000'],
    http_req_failed:     ['rate<0.01'],
    http_reqs:           ['rate>100'],  // RPS > 100
  },
};

// 對應 TC: WB-PERF-001
export default function () {
  const res = http.post(`${__ENV.BASE_URL}/api/v1/auth/login`, {
    email: `user${__VU}@example.com`,
    password: 'test-password',
  });
  check(res, {
    'status is 200':           (r) => r.status === 200,
    'response time < 1000ms':  (r) => r.timings.duration < 1000,
    'returns token':           (r) => r.json('token') !== undefined,
  });
  sleep(1);
}
```

#### Locust 範例

```python
# tests/performance/login_locust.py
from locust import HttpUser, task, between

class LoginUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def login(self):
        """對應 TC: WB-PERF-001（登入壓測）"""
        with self.client.post(
            "/api/v1/auth/login",
            json={"email": f"user{self.user_id}@example.com", "password": "test"},
            catch_response=True,
        ) as resp:
            if resp.status_code != 200:
                resp.failure(f"Status {resp.status_code}")
            elif resp.elapsed.total_seconds() > 1.0:
                resp.failure("Response > 1s")
```

#### JMeter 範例

XML-based，生成 `.jmx` 檔（略，內容詳見 [`templates.md`](./templates.md)）。

### Phase 4: Ramp-up 曲線設計

依「容量驗證 vs 找崩潰點」決定模型：

| 目的 | 模型 | k6 stages |
|------|------|-----------|
| **Smoke** | 1-5 VUs / 1 min | 找配置錯誤 |
| **Load** | 預期 peak / 10 min | 驗 SLA |
| **Stress** | 1.5× peak / 30 min | 找早期警訊 |
| **Spike** | 0 → 10× peak in 10s | 流量突增測試 |
| **Soak** | peak × 4-12 hr | memory leak / connection pool |

### Phase 5: CI 整合

寫 `templates/ci/github-actions/perf-nightly.yml`（範本見 [`templates.md`](./templates.md)）：

```yaml
# 每日凌晨跑 Load test
schedule:
  - cron: '0 18 * * *'  # UTC 18:00 = 台北 02:00
```

⚠️ **不在 PR 跑** — 太慢、太貴、太吵。

### Phase 6: 結果分析

跑完後產報告：
- p50 / p95 / p99 latency
- error rate
- RPS 達成 vs 目標
- ✅ PASS / ❌ FAIL（依 thresholds）
- 與上次跑比對（regression detection）

## ⚠️ 安全護欄

- ❌ **絕對不對 production 跑 Stress / Spike**（會打掛）
- ❌ **絕對不在無人監控時跑大型壓測**
- ✅ 預設 `BASE_URL` 必須是 staging / UAT
- ✅ 報告含「測試環境」欄位，明確標示
- ⚠️ 跑前必有 PM / SRE 同意

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `performance.enabled` | 啟用此 skill | skill 不啟用 |
| `performance.primary_framework` | 預設框架 | k6 |
| `performance.default_sla` | 預設 SLA 數值 | p95<1000 / error<1% |
| `performance.base_url_uat` | 預設 base URL | 互動式問 |

## 範例

詳見 [`examples.md`](./examples.md)
