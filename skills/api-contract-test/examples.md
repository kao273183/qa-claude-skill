# api-contract-test 範例

## 範例 1: iOS App ↔ User Service Pact

```
User: /api-contract-test ios-app user-service
```

執行：
1. 從 `config.contract_test.relationships` 確認對應
2. 生成 Consumer 端 (`ios-app/tests/contract/userService.pact.test.ts`)
3. 生成 Provider 端 verification script (`user-service/tests/contract/verify_pact.py`)
4. 生成 provider state setup (`user-service/tests/contract/state_setup.py`)

下一步：跑 `npm test` 生成 `pacts/ios-app-user-service.json` → push 到 Pact Broker。

## 範例 2: Schemathesis OpenAPI fuzz

```
User: /api-contract-test https://api.example.com/openapi.json --tool=schemathesis
```

執行：
```bash
schemathesis run https://api.example.com/openapi.json \
  --checks all \
  --hypothesis-max-examples=100
```

找到：
- ⚠️ `POST /users` 用 random JSON → 500（schema 沒 cover）
- ⚠️ `GET /users/:id` 用 ID=-1 → 200（應該 400）

→ 建 JIRA contract violation ticket。

## 範例 3: 多 Consumer Provider verification

```
User: /api-contract-test --provider=user-service
```

Provider CI 拉所有 consumer 的 pact 來驗：
- ios-app-user-service.json ✅ Pass
- web-app-user-service.json ✅ Pass
- partner-api-user-service.json ❌ Fail (field `phone_number` 沒了)

→ Provider 別急著 deploy，先聯絡 partner-api 團隊。

## 範例 4: can-i-deploy 安全閘

```bash
pact-broker can-i-deploy \
  --pacticipant=user-service \
  --version=$GIT_SHA \
  --to-environment=production
```

→ Broker 回 "NO — partner-api 還沒 verify 你的版本"
→ Provider Deploy 被擋住，避免上線後爆 partner API。
