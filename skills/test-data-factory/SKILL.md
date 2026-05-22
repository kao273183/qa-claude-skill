---
name: test-data-factory
description: 跨平台統一的 test data 生成策略。整合 Faker / Bogus / factory_bot / @faker-js/faker 等主流 fake data library，跨 iOS / Android / Flutter / Web / pytest 維持一致 fixture 命名。解決「我們有 5 個專案各寫一套 mock user」的混亂。當使用者提到「test data / fixture / faker / mock data / factory / 假資料 / 測試資料 / Bogus / FactoryBot」時觸發。配套：test-automation（用 factory 產測試資料）、tc-to-pytest（白箱 API test fixture）、property-based-test-gen（fuzz 配 deterministic seed）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[Entity 名 (User/Order/...)] [--platform=ios|android|flutter|web|pytest|all]"
---

# test-data-factory

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。

## 為什麼需要這個 skill

**痛點場景**：
- iOS 團隊寫 `MockUser.fake()`
- Android 團隊寫 `User.dummy()`
- BE 團隊寫 `pytest fixture user_factory`
- Web 團隊寫 `userFixture.json`
- → 4 套 mock user，欄位不一致，跨平台 bug 漏抓

**這個 skill 做什麼**：
- 定義**統一的 entity schema**（一份 source of truth）
- 為每個平台**自動產對應的 factory**
- 確保 `MockUser` 跟 `user_factory` 跟 `userFixture` **欄位完全對齊**
- 提供 deterministic seed（重現性）+ random seed（fuzz）

## 適用場景

- ✅ 多平台 App（iOS + Android + Web + BE）共用同 entity
- ✅ 想做跨平台 contract test 但 mock 資料不一致
- ✅ Property-based test 需要 deterministic + fuzz data
- ✅ 新團隊成員不知道怎麼生 test data

## 不適用場景

- ❌ 單平台單一 entity — 直接寫死即可
- ❌ Pure UI snapshot test — visual-regression-gen 處理

## 主流 library 對照

| 平台 | Library | 範例 |
|------|---------|------|
| **iOS Swift** | 手寫 / fakery (社群) | `Fake.email()` |
| **Android Kotlin** | jFairy / kotlin-faker | `Faker().internet().emailAddress()` |
| **Flutter / Dart** | faker (pub.dev) | `faker.internet.email()` |
| **Web JS/TS** | @faker-js/faker | `faker.internet.email()` |
| **Python** | Faker | `Faker().email()` |
| **Java / Kotlin BE** | Java Faker / Datafaker | `new Faker().internet().emailAddress()` |
| **C# / .NET** | Bogus | `new Faker().Internet.Email()` |
| **Ruby** | factory_bot + Faker | `Faker::Internet.email` |

## 執行流程

### Phase 1: 定義 entity schema（一次性）

寫到 `config.test_data_factory.entities`：

```json
{
  "test_data_factory": {
    "entities": [
      {
        "name": "User",
        "fields": {
          "id":         { "type": "uuid",   "seed": "user_id" },
          "email":      { "type": "email" },
          "name":       { "type": "name" },
          "age":        { "type": "int", "min": 18, "max": 99 },
          "trust_level": { "type": "int", "min": 0, "max": 5 },
          "created_at": { "type": "datetime", "format": "iso8601" }
        }
      },
      {
        "name": "Order",
        "fields": {
          "id":         { "type": "uuid" },
          "user_id":    { "ref": "User.id" },
          "amount":     { "type": "decimal", "min": 0, "max": 10000 },
          "status":     { "type": "enum", "values": ["pending", "paid", "shipped"] }
        }
      }
    ]
  }
}
```

### Phase 2: 為各平台產 factory

#### Swift（iOS）

```swift
// Tests/Fakes/UserFactory.swift
import Foundation

struct UserFactory {
    static func make(
        id: String = UUID().uuidString,
        email: String = "user\(Int.random(in: 1...9999))@example.com",
        name: String = "Test User",
        age: Int = 25,
        trustLevel: Int = 3,
        createdAt: Date = Date()
    ) -> User {
        return User(id: id, email: email, name: name, age: age, trustLevel: trustLevel, createdAt: createdAt)
    }

    static func validUser() -> User { make() }
    static func highTrust() -> User { make(trustLevel: 5) }
    static func minor() -> User { make(age: 17) }   // age < 18 boundary
}
```

#### Kotlin（Android）

```kotlin
// app/src/test/java/UserFactory.kt
import io.github.serpro69.kfaker.Faker

object UserFactory {
    private val faker = Faker()

    fun make(
        id: String = faker.random.nextUUID(),
        email: String = faker.internet.email(),
        name: String = faker.name.name(),
        age: Int = faker.random.nextInt(18..99),
        trustLevel: Int = faker.random.nextInt(0..5),
        createdAt: Instant = Instant.now()
    ) = User(id, email, name, age, trustLevel, createdAt)

    fun validUser() = make()
    fun highTrust() = make(trustLevel = 5)
    fun minor() = make(age = 17)
}
```

#### Dart（Flutter）

```dart
// test/fakes/user_factory.dart
import 'package:faker/faker.dart';

class UserFactory {
  static User make({
    String? id,
    String? email,
    String? name,
    int? age,
    int? trustLevel,
    DateTime? createdAt,
  }) {
    final faker = Faker();
    return User(
      id: id ?? faker.guid.guid(),
      email: email ?? faker.internet.email(),
      name: name ?? faker.person.name(),
      age: age ?? faker.randomGenerator.integer(99, min: 18),
      trustLevel: trustLevel ?? faker.randomGenerator.integer(5),
      createdAt: createdAt ?? faker.date.dateTime(),
    );
  }

  static User validUser() => make();
  static User highTrust() => make(trustLevel: 5);
  static User minor() => make(age: 17);
}
```

#### TypeScript（Web）

```typescript
// tests/factories/user.factory.ts
import { faker } from '@faker-js/faker';

export interface UserOverrides extends Partial<User> {}

export class UserFactory {
  static make(overrides: UserOverrides = {}): User {
    return {
      id:          faker.string.uuid(),
      email:       faker.internet.email(),
      name:        faker.person.fullName(),
      age:         faker.number.int({ min: 18, max: 99 }),
      trustLevel:  faker.number.int({ min: 0, max: 5 }),
      createdAt:   faker.date.past().toISOString(),
      ...overrides,
    };
  }

  static validUser = () => this.make();
  static highTrust = () => this.make({ trustLevel: 5 });
  static minor     = () => this.make({ age: 17 });
}
```

#### Python（pytest）

```python
# tests/factories/user.py
from faker import Faker
from datetime import datetime, timezone

fake = Faker()

def make_user(**overrides):
    """User factory aligned with iOS/Android/Web."""
    defaults = {
        "id":          fake.uuid4(),
        "email":       fake.email(),
        "name":        fake.name(),
        "age":         fake.random_int(18, 99),
        "trust_level": fake.random_int(0, 5),
        "created_at":  datetime.now(timezone.utc).isoformat(),
    }
    return {**defaults, **overrides}

def valid_user(): return make_user()
def high_trust(): return make_user(trust_level=5)
def minor():      return make_user(age=17)
```

### Phase 3: Seed 管理（重現性）

對 property-based test / regression test：

```typescript
// 重現特定 seed
faker.seed(12345);
const user = UserFactory.make();   // 永遠生同樣 user
```

→ Bug 報告含「seed=12345」就能完美重現。

### Phase 4: 預設 variants（命名規範）

對每個 entity 強制提供：
- `validX()` — 一切正常
- `highTrust() / minor() / blocked()` — 業務變體
- 邊界：`minAge() / maxAge() / emptyName()`

確保跨平台**所有人都用同樣 variant 名**。

### Phase 5: Contract 驗證

跑「跨平台 schema diff」：

```bash
qa-data-factory verify --entity=User
```

→ 偵測：
- iOS Factory 多了 `phone_number`（其他平台沒）
- Python factory `age` 沒邊界檢查（其他都有）
- Web factory 用 `id` (string)，Android 用 `id` (UUID)

## ⚠️ 安全護欄

- ❌ Faker 預設**不該**生真實人姓名 / Email（隱私）
- ✅ 用 example.com / `test@test.com` domain
- ⚠️ Production seed 資料庫**絕不用** Faker（避免混入 prod data）

## 設定依賴

| 設定 Key | 用途 | 預設 |
|---------|------|------|
| `test_data_factory.entities` | Entity schema 定義 | [] |
| `test_data_factory.default_seed` | Property test deterministic seed | null (random) |
| `test_data_factory.email_domain` | Email faker 用的 domain | example.com |
| `test_data_factory.platforms` | 要生 factory 的平台 | all enabled |

## 配套整合

```
1. 定 entity schema（config.json）
2. /test-data-factory User --platform=all
   → 各平台同時生 factory
3. iOS / Android / Web / pytest 都 import 對應 factory
4. property-based-test-gen 用 deterministic seed
5. CI 跑 verify 確保 schema 一致
```

## 範例

詳見 [`examples.md`](./examples.md)
