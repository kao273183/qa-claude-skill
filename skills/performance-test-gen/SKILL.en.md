---
name: performance-test-gen
description: Generate load/stress test scripts (k6 / JMeter / Locust) from test cases. Auto-derives SLA thresholds (p95/p99/error rate), designs ramp-up curves, integrates CI. Trigger phrases — "performance test", "load test", "stress test", "k6", "JMeter", "Locust", "SLA verification", "API pressure test".
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__readSpreadsheet, mcp__atlassian__getJiraIssue
argument-hint: "[Sheet URL / JIRA key / feature] [--framework=k6|jmeter|locust]"
---

# performance-test-gen (English)

> ⚙️ Read [`modules/config-loader.md`](./modules/config-loader.md) first.
> Activation: `config.performance.enabled = true`.

## When to Use
- API spec exists; want to verify SLA (p95 < 200ms / error < 0.1%)
- Pre-release pressure test on critical endpoints
- Capacity planning
- Pre/post migration comparison

## Don't Use For
- Unit/UI functional test (use `test-automation`)
- No spec yet (use `test-master` first)
- Business logic correctness (use `tc-to-pytest`)

## Framework Picker

| Framework | Best for | Language | Learning curve |
|-----------|----------|----------|---------------|
| **k6** (default) | Modern API, cloud | JavaScript | Low |
| **Locust** | Python backend teams | Python | Low |
| **JMeter** | Enterprise/government, GUI flows | XML/Java | High |

## Workflow

### Phase 1: TC Source
Sheet / JIRA / feature description → filter "Performance" category.

### Phase 2: Derive SLA
From expected results: "2s response" → p95 < 2000ms. Default: p95 < 1000ms, error < 1%.

### Phase 3: Generate Scripts

**k6 example**:
```javascript
export const options = {
  stages: [
    { duration: '30s', target: 50 },
    { duration: '2m',  target: 50 },
    { duration: '30s', target: 200 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000', 'p(99)<3000'],
    http_req_failed:   ['rate<0.01'],
  },
};
```

**Locust example**:
```python
class LoginUser(HttpUser):
    @task
    def login(self):
        self.client.post("/api/v1/auth/login", json={...})
```

### Phase 4: Ramp-up Models
- **Smoke**: 1-5 VUs / 1 min
- **Load**: peak / 10 min (verify SLA)
- **Stress**: 1.5× peak / 30 min
- **Spike**: 0 → 10× peak / 10s
- **Soak**: peak × 4-12 hr (memory leak)

### Phase 5: CI Integration
**Not in PR** (too slow). Nightly cron.

### Phase 6: Result Analysis
p50/p95/p99 latency, error rate, RPS vs target, PASS/FAIL by thresholds, regression detection.

## Safety
- ❌ **Never run Stress/Spike on production**
- ✅ Default `BASE_URL` must be staging/UAT
- ⚠️ Requires PM/SRE approval before large runs

## Config Dependencies

| Key | Purpose |
|-----|---------|
| `performance.enabled` | Activates skill |
| `performance.primary_framework` | k6 / locust / jmeter |
| `performance.default_sla` | Default SLA values |
| `performance.base_url_uat` | Default base URL |
