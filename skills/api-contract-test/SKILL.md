---
name: api-contract-test
description: 為微服務 / 多前後端架構生成 Contract Test（契約測試）腳本，支援 Pact（consumer-driven）/ Schemathesis（schema-driven OpenAPI fuzz）/ Spring Cloud Contract。確保 Provider 改 API 時 Consumer 不會壞、Consumer 改用法時 Provider 仍滿足契約。當使用者提到「contract test / 契約測試 / Pact / Schemathesis / consumer-driven / provider verification / API breaking change / OpenAPI fuzz / microservices 測試」時觸發。配套：tc-to-pytest（傳統 API test）、test-master（規劃 contract TC）、test-review（審契約覆蓋）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[OpenAPI URL / Provider 服務名 / Consumer 服務名] [--tool=pact|schemathesis|spring-cloud]"
---

# api-contract-test

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。

## 為什麼需要 Contract Test

**問題場景**：
- Backend 改了 `/api/v1/users` 的 response field 名稱 → Mobile / Web 全壞
- Frontend 假設 `created_at` 是 ISO 8601 → Backend 改成 unix timestamp → 全壞
- Microservice A 升版 → Microservice B 突然 503

**傳統 E2E test 不夠**：
- 跑得慢、不穩
- 找到問題太晚（上線後才知道）
- 跨團隊難協調

**Contract Test 解法**：
- Consumer 寫「我預期 Provider 回傳什麼」契約
- Provider 自動驗證自己滿足契約
- **PR 時就抓到 breaking change**（不用等 E2E）

## 適用場景

- ✅ 微服務架構（> 3 個 service）
- ✅ Backend + 多 client（iOS / Android / Web / 第三方）
- ✅ 有公開 API 供合作夥伴 / 第三方使用
- ✅ 想加速 E2E（部分驗證搬到 contract test）

## 不適用場景

- ❌ 單體應用 / Monolith — 不需要
- ❌ Provider 已凍結不會改 — 寫了沒用
- ❌ API spec 還劇變中 — 等穩定再寫

## 工具選擇

| 工具 | 哲學 | 適合 |
|------|------|------|
| **Pact**（推薦）| Consumer-driven | 多 Consumer / Provider 跨團隊 |
| **Schemathesis** | Schema-driven（從 OpenAPI 自動 fuzz）| 已有 OpenAPI spec |
| **Spring Cloud Contract** | Java 生態 | Java/Kotlin Microservices |

預設 `{{CONTRACT_PRIMARY_TOOL}}`（從 config 讀），可用 `--tool=` 覆寫。

## 執行流程

### Phase 1: 識別 Consumer / Provider 關係

從 `config.contract_test.relationships`（或互動式問）：

```json
{
  "contract_test": {
    "relationships": [
      { "consumer": "ios-app",     "provider": "user-service" },
      { "consumer": "ios-app",     "provider": "payment-service" },
      { "consumer": "web-app",     "provider": "user-service" },
      { "consumer": "partner-api", "provider": "user-service" }
    ]
  }
}
```

### Phase 2: Consumer-Side 寫契約（Pact 範例）

```typescript
// ios-app/tests/contract/userService.pact.test.ts
import { PactV3, MatchersV3 } from '@pact-foundation/pact';

const provider = new PactV3({
  consumer: 'ios-app',
  provider: 'user-service',
});

describe('UserService contract', () => {
  it('TC: CT-USER-001 GET /users/:id returns user', async () => {
    await provider
      .given('user 123 exists')
      .uponReceiving('a request for user 123')
      .withRequest({
        method: 'GET',
        path: '/api/v1/users/123',
        headers: { Authorization: MatchersV3.like('Bearer xxx') },
      })
      .willRespondWith({
        status: 200,
        body: {
          id:         MatchersV3.integer(123),
          name:       MatchersV3.string('Test User'),
          email:      MatchersV3.regex(/^[^@]+@[^@]+\.[^@]+$/, 'test@example.com'),
          created_at: MatchersV3.iso8601DateTime(),  // ← 明確要求 ISO 8601
          trust_level: MatchersV3.integer(MatchersV3.like(0), { min: 0, max: 5 }),
        },
      })
      .executeTest(async (mockServer) => {
        const userService = new UserService(mockServer.url);
        const user = await userService.fetch(123);
        expect(user.id).toBe(123);
      });
  });
});
```

→ 跑完產出 `pacts/ios-app-user-service.json` 契約檔。

### Phase 3: Provider-Side 驗證

```python
# user-service/tests/contract/verify_pact.py
from pact import Verifier

verifier = Verifier(provider='user-service', provider_base_url='http://localhost:8080')

verifier.verify_pacts(
    './pacts/ios-app-user-service.json',
    './pacts/web-app-user-service.json',
    './pacts/partner-api-user-service.json',
    provider_states_setup_url='http://localhost:8080/_pact/setup',
)
```

Provider CI 跑：
- 抓所有 Consumer 的契約檔（從 Pact Broker / git）
- 對自己跑驗證
- ❌ 任何契約不滿足 → CI fail

### Phase 4: Provider State 設定

Consumer 期望「`user 123 exists`」狀態：

```python
# user-service/tests/contract/state_setup.py
@app.route('/_pact/setup', methods=['POST'])
def setup_state():
    state = request.json['state']
    if state == 'user 123 exists':
        db.create_user(id=123, name='Test User', email='test@example.com')
    elif state == 'no users exist':
        db.clear_users()
    return '', 200
```

### Phase 5: Pact Broker 整合（可選但推薦）

```bash
# Consumer publish
pact-broker publish pacts/ \
  --broker-base-url=$PACT_BROKER_URL \
  --consumer-app-version=$GIT_SHA

# Provider check before deploy
pact-broker can-i-deploy \
  --pacticipant=user-service --version=$GIT_SHA \
  --to-environment=production
```

→ Provider 要上 prod 前先問 broker：「我的版本對所有 Consumer 都安全嗎？」

### Phase 6: Schemathesis（schema-driven 補強）

如果有 OpenAPI spec，自動 fuzz：

```bash
schemathesis run https://api.example.com/openapi.json \
  --checks all \
  --hypothesis-max-examples=100
```

驗證：
- 所有 endpoint 對 random input 都不會回 500
- Response 都符合宣告的 schema
- Status code conformance

### Phase 7: CI 整合

兩段：
1. **Consumer CI**: 生 pact + publish 到 Broker
2. **Provider CI**: pull pacts + verify + can-i-deploy

範本見 [`templates.md`](./templates.md)。

## ⚠️ 安全護欄

- ❌ 不對 production 跑 schemathesis fuzz（會打掛）
- ✅ 預設用 staging / UAT 環境
- ✅ Pact verification 必設 timeout（不能讓 Consumer 卡死 Provider CI）
- ⚠️ Provider state setup endpoint **僅 test 環境開啟**，prod 必關

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `contract_test.enabled` | 啟用此 skill | skill 不啟用 |
| `contract_test.primary_tool` | 預設工具 | pact |
| `contract_test.relationships` | Consumer/Provider 對應 | 互動式問 |
| `contract_test.pact_broker_url` | Pact Broker 位址 | 不用 broker，pact 走 git |

## 範例

詳見 [`examples.md`](./examples.md)
