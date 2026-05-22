---
name: test-data-factory
description: Cross-platform unified test data strategy. Integrates Faker / Bogus / factory_bot / @faker-js/faker. Keeps fixture naming consistent across iOS / Android / Flutter / Web / pytest. Solves "we have 5 projects each writing their own mock user" mess. Trigger phrases — "test data", "fixture", "faker", "mock data", "factory", "fake data", "Bogus", "FactoryBot".
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[Entity name (User/Order/...)] [--platform=ios|android|flutter|web|pytest|all]"
---

# test-data-factory (English)

> ⚙️ Read [`modules/config-loader.md`](./modules/config-loader.md) first.

## Pain Point

- iOS team writes `MockUser.fake()`
- Android team writes `User.dummy()`
- Backend writes `pytest fixture user_factory`
- Web writes `userFixture.json`

→ 4 mock-user implementations, inconsistent fields, cross-platform bugs slip through.

## This Skill
- Defines **unified entity schema** (single source of truth)
- Auto-generates **per-platform factories**
- Ensures fields align across all platforms
- Provides deterministic + random seed support

## When to Use
- Multi-platform app sharing entities
- Want cross-platform contract test but mock data inconsistent
- Property-based test needs deterministic + fuzz data
- New team members need consistent test data

## Library Mapping

| Platform | Library |
|----------|---------|
| iOS Swift | Hand-written / fakery |
| Android Kotlin | kotlin-faker / jFairy |
| Flutter Dart | faker (pub.dev) |
| Web JS/TS | @faker-js/faker |
| Python | Faker |
| Java/Kotlin BE | Java Faker / Datafaker |
| C# / .NET | Bogus |
| Ruby | factory_bot + Faker |

## Workflow

### Phase 1: Define entity schema (once)

In `config.test_data_factory.entities`:
```json
{
  "entities": [{
    "name": "User",
    "fields": {
      "id": { "type": "uuid" },
      "email": { "type": "email" },
      "age": { "type": "int", "min": 18, "max": 99 },
      "trust_level": { "type": "int", "min": 0, "max": 5 }
    }
  }]
}
```

### Phase 2: Generate per-platform factories

Each platform gets matching factory with same field names + types.

### Phase 3: Seed management
Deterministic seed for property tests + bug reproducibility.

### Phase 4: Required variants
Each entity must provide:
- `validX()` — happy path
- Business variants: `highTrust() / minor() / blocked()`
- Boundary: `minAge() / maxAge() / emptyName()`

### Phase 5: Schema verification
`qa-data-factory verify --entity=User` cross-platform diff detection.

## Safety
- ❌ Faker shouldn't generate real human names/emails (privacy)
- ✅ Use example.com / `test@test.com` domain
- ⚠️ Never use Faker in production seed (data contamination)

## Config Dependencies

| Key | Purpose |
|-----|---------|
| `test_data_factory.entities` | Entity schema definitions |
| `test_data_factory.default_seed` | Deterministic seed |
| `test_data_factory.email_domain` | Default "example.com" |
| `test_data_factory.platforms` | All enabled by default |
