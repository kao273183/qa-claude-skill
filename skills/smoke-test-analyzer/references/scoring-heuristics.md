# Smoke Suitability Scoring Heuristics

Detailed signals for each scoring criteria. Read test file code to verify — don't rely on file names alone.

## Criticality (30%)

Score by what the test covers:

| Score | What It Tests | Path Signals |
|-------|---------------|--------------|
| 5 | Login, Auth, Home, Launch, Payment, DeepLink | `Login`, `Auth`, `Home`, `Launch`, `AppRouter`, `DeepLink`, `Splash` |
| 4 | ViewModel, Store, UseCase, Repository | `*ViewModel*`, `*Store*`, `*UseCase*` |
| 3 | Model, Helper, Utility, Extension | `*Model*`, `*Helper*`, `*Utils*` |
| 2 | Configuration, formatting, cosmetic | `*Config*`, `*Formatter*` |
| 1 | Edge case, rarely-used feature, animation | Niche features |

## Speed (25%)

| Score | iOS Signals | Android Signals |
|-------|-------------|-----------------|
| 5 | `@Test` pure logic, no async | `@Test` with mockk, no Android context |
| 4 | Stubbed network, fast async | `runTest {}` with TestDispatcher |
| 3 | Multiple stubs, moderate setup | `@Test` with Room in-memory DB |
| 2 | `XCUIApplication` UI test | Espresso `onView` |
| 1 | `sleep()` > 3s, real I/O | `Thread.sleep()` > 3s, real network |

## Stability (25%)

| Score | iOS Signals | Android Signals |
|-------|-------------|-----------------|
| 5 | Pure input/output, deterministic | Pure function + mockk |
| 4 | Stubbed dependencies, controlled state | Controlled dispatchers |
| 3 | `waitForExistence` with reasonable timeout | `IdlingResource` properly configured |
| 2 | `Date()` / `Calendar` dependency | `System.currentTimeMillis()` / `LocalDate.now()` |
| 1 | `sleep()` hardcoded, timing-sensitive | `Thread.sleep()`, missing `IdlingResource` |

## Independence (10%)

| Score | iOS Signals | Android Signals |
|-------|-------------|-----------------|
| 5 | `makeSUT()` pattern, fresh state per test | `@Before` creates fresh mocks |
| 4 | setUp/tearDown clean state | `@Rule` with clean setup |
| 3 | Shared fixture but no ordering | Shared test data but no ordering |
| 2 | Depends on login state | Depends on specific Intent |
| 1 | `UserDefaults`, singletons, shared DB | `SharedPreferences`, static state |

## Coverage Value (10%)

| Score | Description |
|-------|-------------|
| 5 | Tests code path used by > 80% of users daily |
| 4 | Tests code path used weekly by most users |
| 3 | Tests code path used by specific user segment |
| 2 | Tests internal tooling or admin features |
| 1 | Tests deprecated or rarely-accessed feature |

## Flaky Risk Flags

When scanning, flag these patterns for the flaky report:

| Pattern | iOS | Android | Suggestion |
|---------|-----|---------|------------|
| Hardcoded delay | `sleep()`, `Thread.sleep` | `Thread.sleep()`, bare `delay()` | Use expectations / IdlingResource |
| Time-sensitive | `Date()`, `Calendar.current` | `System.currentTimeMillis()` | Inject clock / time provider |
| Short UI timeout | `waitForExistence(timeout: 2)` | `onView` without idle sync | Increase timeout / add IdlingResource |
| Shared state | `UserDefaults.standard` writes | `SharedPreferences` writes | Isolate with makeSUT / fresh context |
| Non-deterministic | `arc4random`, `.shuffled()` | `Random()`, `shuffle()` | Seed or mock random source |
