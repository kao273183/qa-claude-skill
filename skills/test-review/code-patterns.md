# Test Review Code Patterns

Good vs bad patterns reference for test code review across **Swift / Kotlin / Dart / Python / TypeScript (Playwright + Cypress + Vitest)**.

---

## Test Structure (AAA Pattern)

### Swift
```swift
// ✅ Good: Clear AAA pattern
@Test("login with valid credentials should return success")
func testLoginWithValidCredentials() async throws {
    // Arrange
    let mockService = MockAuthService(result: .success(mockToken))
    let useCase = LoginFlowUseCase(authService: mockService)

    // Act
    let result = await useCase.login(email: "test@example.com", password: "password123")

    // Assert
    #expect(result.isSuccess)
    #expect(mockService.loginCallCount == 1)
}

// ❌ Bad: No clear structure, unclear purpose
@Test("test")
func test1() {
    // Mixed logic, impossible to understand
}
```

### Kotlin
```kotlin
// ✅ Good
@Test
fun `login with valid credentials should return success`() = runTest {
    // Arrange
    val mockService = mockk<AuthService> {
        coEvery { login(any(), any()) } returns Result.success(mockToken)
    }
    val useCase = LoginFlowUseCase(mockService)

    // Act
    val result = useCase.login("test@example.com", "password123")

    // Assert
    assertTrue(result.isSuccess)
    coVerify(exactly = 1) { mockService.login(any(), any()) }
}
```

### Dart / Flutter
```dart
// ✅ Good
test('login with valid credentials should return success', () async {
  // Arrange
  final mockService = MockAuthService();
  when(() => mockService.login(any(), any()))
      .thenAnswer((_) async => Result.success(mockToken));
  final useCase = LoginFlowUseCase(mockService);

  // Act
  final result = await useCase.login('test@example.com', 'password123');

  // Assert
  expect(result.isSuccess, isTrue);
  verify(() => mockService.login(any(), any())).called(1);
});
```

### Python (pytest)
```python
# ✅ Good
def test_login_with_valid_credentials_should_return_success(mocker):
    # Arrange
    mock_service = mocker.Mock(spec=AuthService)
    mock_service.login.return_value = Result.success(mock_token)
    use_case = LoginFlowUseCase(mock_service)

    # Act
    result = use_case.login('test@example.com', 'password123')

    # Assert
    assert result.is_success
    mock_service.login.assert_called_once_with('test@example.com', 'password123')
```

### TypeScript — Playwright E2E
```typescript
// ✅ Good: Page Object + 穩定 locator + AAA
test('TC: BB-AUTH-001 valid credentials should redirect to home', async ({ page }) => {
  // Arrange
  const loginPage = new LoginPage(page);
  await loginPage.goto();

  // Act
  await loginPage.login('test@example.com', 'password123');

  // Assert
  await expect(page).toHaveURL('/home');
  await expect(page.getByTestId('welcome-banner')).toBeVisible();
});

// ❌ Bad: 沒 Page Object、用 CSS class locator、無斷言
test('test1', async ({ page }) => {
  await page.goto('/login');
  await page.locator('.input.email').fill('test');
  await page.locator('.btn-primary').click();
  // 沒 assert，PASS 也沒意義
});
```

### TypeScript — Cypress
```javascript
// ✅ Good: 用 data-testid，斷言明確
it('TC: BB-AUTH-001 valid credentials should redirect to home', () => {
  cy.loginAs('test@example.com', 'password123');
  cy.url().should('include', '/home');
  cy.getByTestId('welcome-banner').should('be.visible');
});

// ❌ Bad: 依賴文字內容 locator、過度 wait
it('test', () => {
  cy.visit('/login');
  cy.wait(3000);   // ⚠️ hard-coded wait，flaky 來源
  cy.contains('登入').click();   // ⚠️ 文案改了就壞
});
```

### TypeScript — Vitest / Jest (Unit)
```typescript
// ✅ Good
import { describe, it, expect } from 'vitest';

it('TC: UT-CART-001 addItem increases count', () => {
  const cart = new Cart();
  cart.addItem({ id: 1, qty: 2 });
  expect(cart.count).toBe(2);
});
```

---

## Mock/Stub Strategy

```swift
// ✅ Good: Clear, controllable, protocol-based
class MockAuthService: AuthServiceProtocol {
    var result: Result<Token, Error>?
    var loginCallCount = 0

    func login(email: String, password: String) async throws -> Token {
        loginCallCount += 1
        return try result!.get()
    }
}

// ❌ Bad: Over-mocked, disconnected from real behavior
class OverMockedService {
    // mocks all internal implementation details
    // tests become useless
}
```

> Kotlin equivalent: `mockk<Interface>` or `MockK` annotations.
> Dart: `mocktail` or `mockito` with `Fake` classes preferred for repositories.
> Python: `pytest-mock` for collaborators, `responses` for HTTP.

---

## Assertion Quality

### Swift
```swift
// ✅ Good: Semantic, specific
#expect(user.isLoggedIn == true)
#expect(viewModel.errorMessage == "密碼錯誤")
#expect(throws: NetworkError.timeout) {
    try await service.fetchData()
}

// ❌ Bad: Vague, meaningless
#expect(result != nil)
#expect(true)
```

### Kotlin
```kotlin
// ✅ Good
assertEquals("密碼錯誤", viewModel.errorMessage)
assertThrows<NetworkException.Timeout> {
    runBlocking { service.fetchData() }
}

// ❌ Bad
assertNotNull(result)
assertTrue(true)
```

### Dart
```dart
// ✅ Good
expect(user.isLoggedIn, isTrue);
expect(viewModel.errorMessage, equals('密碼錯誤'));
expect(() => service.fetchData(), throwsA(isA<NetworkException>()));

// ❌ Bad
expect(result, isNotNull);
```

### Python
```python
# ✅ Good
assert user.is_logged_in is True
assert view_model.error_message == "密碼錯誤"
with pytest.raises(NetworkError, match="timeout"):
    service.fetch_data()

# ❌ Bad
assert result is not None
assert True
```

---

## Concurrency Safety

### Swift
```swift
// ✅ Good: Uses async/await and actor
@Test("concurrent access should not cause race condition")
func testConcurrentAccess() async throws {
    let store = ChatListStore()

    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<100 {
            group.addTask { await store.increment() }
        }
    }

    let count = await store.count
    #expect(count == 100)
}

// ❌ Bad: Unprotected shared state, unreliable sleep
func testConcurrent() {
    var count = 0
    DispatchQueue.concurrentPerform(iterations: 100) { _ in
        count += 1  // ⚠️ Race condition
    }
    Thread.sleep(forTimeInterval: 1)  // ❌ Unreliable wait
}
```

### Kotlin (coroutines)
```kotlin
// ✅ Good
@Test
fun `concurrent access should not cause race condition`() = runTest {
    val store = ChatListStore()
    val jobs = (1..100).map { launch { store.increment() } }
    jobs.joinAll()
    assertEquals(100, store.count)
}
```

### Dart
```dart
// ✅ Good
test('concurrent access should not cause race condition', () async {
  final store = ChatListStore();
  await Future.wait(List.generate(100, (_) => store.increment()));
  expect(store.count, equals(100));
});
```

---

## Test Data

```swift
// ✅ Good: Clear, meaningful
let mockUser = User(
    id: "test-user-123",
    name: "Test User",
    email: "test@example.com"
)

// ❌ Bad: Magic numbers, unclear
let user = User(id: "1", name: "A", email: "a")
```

Use **builders** or **fixtures** for shared test data; never copy-paste literals across test methods.

---

## Cross-platform anti-patterns

| Smell | Why bad | Better |
|-------|---------|--------|
| `Thread.sleep(1.0)` / `await Future.delayed(...)` / `cy.wait(3000)` | Flaky waits | Wait for a condition (state poll, expectation) |
| Reading from real network in unit test | Slow + flaky | Mock HTTP boundary |
| Asserting against UI text in business-logic test | Tightly coupled to copy | Assert on state/model |
| Mocking your own DTO/data class | Mocking value objects | Use real instances |
| One test verifying 5 things | Hard to diagnose | Split into focused tests |
| **Web 專屬**: `page.locator('.btn-primary')` CSS class | UI 改了測試就壞 | `page.getByTestId('submit')` / `page.getByRole('button')` |
| **Web 專屬**: `cy.contains('登入').click()` 文字 locator | 翻譯 / 文案改了就壞 | `cy.getByTestId('login-btn')` |
| **Web 專屬**: 真實 API call in E2E test | 慢 + 環境不穩 | Playwright `route.fulfill()` / Cypress `cy.intercept()` |
| **Web 專屬**: 沒設 baseURL 寫死 `https://prod.example.com` | 環境硬編碼 | `playwright.config.ts` 從 `process.env.BASE_URL` 抓 |
