---
name: api-contract-test
description: Generate contract test scripts for microservices / multi-frontend-backend setups. Supports Pact (consumer-driven), Schemathesis (schema-driven OpenAPI fuzz), Spring Cloud Contract. Ensures Provider changes don't break Consumers and Consumer expectations are still met. Trigger phrases — "contract test", "Pact", "Schemathesis", "consumer-driven", "provider verification", "API breaking change", "OpenAPI fuzz", "microservices testing".
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[OpenAPI URL / Provider name / Consumer name] [--tool=pact|schemathesis|spring-cloud]"
---

# api-contract-test (English)

> ⚙️ Read [`modules/config-loader.md`](./modules/config-loader.md) first.

## Why

**Problem**:
- Backend renames `/api/v1/users` field → all clients break
- Microservice A upgrades → B suddenly 503

**E2E tests are insufficient**: slow, flaky, find issues post-deploy.

**Contract tests**:
- Consumer writes "what I expect from Provider"
- Provider verifies it meets all contracts
- **Breaking changes caught at PR time**

## When to Use
- Microservice architecture (>3 services)
- Backend + multiple clients (iOS / Android / Web / 3rd party)
- Public APIs for partners
- Want to speed up E2E

## Tool Picker

| Tool | Philosophy | Best for |
|------|-----------|----------|
| **Pact** (default) | Consumer-driven | Cross-team multi-consumer |
| **Schemathesis** | Schema-driven (OpenAPI fuzz) | Already have OpenAPI |
| **Spring Cloud Contract** | Java ecosystem | Java/Kotlin microservices |

## Workflow

### Phase 1: Identify Consumer-Provider relationships
From `config.contract_test.relationships`.

### Phase 2: Consumer-side contract (Pact example)

```typescript
const provider = new PactV3({ consumer: 'ios-app', provider: 'user-service' });

await provider
  .given('user 123 exists')
  .uponReceiving('a request for user 123')
  .withRequest({ method: 'GET', path: '/api/v1/users/123' })
  .willRespondWith({
    status: 200,
    body: {
      id: MatchersV3.integer(123),
      email: MatchersV3.regex(/^[^@]+@[^@]+$/, 'test@example.com'),
      created_at: MatchersV3.iso8601DateTime(),
    },
  });
```

Produces `pacts/ios-app-user-service.json`.

### Phase 3: Provider-side verification

```python
verifier.verify_pacts(
    './pacts/ios-app-user-service.json',
    './pacts/web-app-user-service.json',
    provider_states_setup_url='http://localhost:8080/_pact/setup',
)
```

Provider CI fetches all consumer pacts → fails if any unmet.

### Phase 4: Provider State setup
```python
@app.route('/_pact/setup', methods=['POST'])
def setup_state():
    if request.json['state'] == 'user 123 exists':
        db.create_user(id=123, ...)
```

### Phase 5: Pact Broker integration (recommended)

```bash
# Consumer publish
pact-broker publish pacts/ --broker-base-url=$PACT_BROKER_URL

# Provider check before deploy
pact-broker can-i-deploy --pacticipant=user-service --version=$GIT_SHA --to-environment=production
```

### Phase 6: Schemathesis (schema-driven supplement)

```bash
schemathesis run https://api.example.com/openapi.json --checks all
```

### Phase 7: CI integration
- Consumer CI: generate + publish pacts
- Provider CI: pull + verify + can-i-deploy

## Safety
- ❌ Never run Schemathesis fuzz on production
- ✅ Provider state setup endpoint must be test-env only
- ⚠️ Set timeout on verification (don't block Provider CI)

## Config Dependencies

| Key | Purpose |
|-----|---------|
| `contract_test.enabled` | Activates skill |
| `contract_test.primary_tool` | pact / schemathesis / spring-cloud |
| `contract_test.relationships` | Consumer/Provider mapping |
| `contract_test.pact_broker_url` | Broker URL (optional) |
