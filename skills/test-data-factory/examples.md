# test-data-factory 範例

## 範例 1: 從 config 生 User factory 給 5 平台

```
User: /test-data-factory User --platform=all
```

執行：
1. 讀 `config.test_data_factory.entities[].User`
2. 為每平台產 factory：
   - iOS: `Tests/Fakes/UserFactory.swift`
   - Android: `app/src/test/java/.../UserFactory.kt`
   - Flutter: `test/fakes/user_factory.dart`
   - Web: `tests/factories/user.factory.ts`
   - Python: `tests/factories/user.py`

3. 所有 factory 共用同欄位 + 同 variants（validUser / highTrust / minor）

## 範例 2: 新增 Order entity

```
User: 加 Order entity，含 user_id ref + amount + status
```

執行：
1. 互動式問清楚欄位類型
2. 寫入 `config.test_data_factory.entities`
3. 跑 `/test-data-factory Order --platform=all`
4. 自動產 5 平台 factory，user_id 用 reference（呼叫 UserFactory.make().id）

## 範例 3: 跨平台 schema 驗證

```
User: /test-data-factory verify --entity=User
```

執行：
1. 解析 5 平台的 UserFactory
2. 對比每個 field
3. 找到不一致：
   ⚠️ iOS UserFactory 有 `phoneNumber` 欄位（其他平台沒）
   ⚠️ Python factory `age` 沒 boundary（其他平台有 18-99）
   ⚠️ Web factory id type 是 string（Android 是 UUID）

→ 提示修復方向

## 範例 4: Deterministic seed 重現 bug

Bug ticket 含 `seed=12345`：

```typescript
// 重現 bug
faker.seed(12345);
const user = UserFactory.make();
// → 永遠生同樣 user，可重現 bug
```

→ Property-based test fail 找到 falsifying example → seed 寫進 ticket → 開發者 100% 重現。

## 範例 5: 邊界 variant

```typescript
UserFactory.minor()      // age = 17（最小邊界 - 1）
UserFactory.maxAge()     // age = 99
UserFactory.emptyName()  // name = ""
UserFactory.longEmail()  // email > 254 chars (RFC 上限)
UserFactory.unicode()    // 各種 emoji / 多語 / RTL 字
```

→ 加進 boundary test，配合 property-based-test-gen 一起壓邊界。
