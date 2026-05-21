# Android 自動化測試 Patterns

## Unit Test（JUnit + Mockk）

### 結構

```kotlin
import io.mockk.*
import org.junit.jupiter.api.*
import org.junit.jupiter.api.Assertions.*

// TC-IOM-015: Cookie 過期後重新載入 WebView
class IOMCookieExpirationTest {

    // Stubs
    private val expiredCookie = IOMCookie(name = "session", value = "", expiry = Date(0))
    private val validCookie = IOMCookie(name = "session", value = "abc123", expiry = Date(Long.MAX_VALUE))

    private lateinit var mockStore: CookieStore
    private lateinit var sut: IOMCookieManager

    @BeforeEach
    fun setUp() {
        mockStore = mockk(relaxed = true)
        sut = IOMCookieManager(store = mockStore)
    }

    @Test
    fun `Cookie 過期時應觸發重新載入`() {
        // Given (前置條件 from Column I)
        every { mockStore.getCookies() } returns listOf(expiredCookie)

        // When (測試步驟 from Column J)
        val shouldReload = sut.checkAndRefreshIfNeeded()

        // Then (預期結果 from Column K)
        assertTrue(shouldReload)
        verify(exactly = 1) { mockStore.refresh() }
    }
}
```

### 關鍵規則
- JUnit 5（`@Test` from `org.junit.jupiter.api`）
- Mockk 做 mock/stub（`mockk()`, `every {}`, `verify {}`）
- `@BeforeEach` 初始化，每個測試獨立
- 反引號方法名用中文描述行為
- Coroutine test 用 `runTest {}` + `TestDispatcher`

### Coroutine Test

```kotlin
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.StandardTestDispatcher

class LoginViewModelTest {

    private val testDispatcher = StandardTestDispatcher()

    @Test
    fun `登入成功應更新 UI 狀態`() = runTest(testDispatcher) {
        // Given
        val mockRepo = mockk<AuthRepository>()
        coEvery { mockRepo.login(any(), any()) } returns Result.success(User("test"))
        val viewModel = LoginViewModel(mockRepo, testDispatcher)

        // When
        viewModel.login("user@test.com", "password")
        advanceUntilIdle()

        // Then
        assertEquals(LoginState.Success, viewModel.uiState.value)
    }
}
```

## UI Test（Espresso + Page Object Model）

### Page Object 結構

```kotlin
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.action.ViewActions.*
import androidx.test.espresso.assertion.ViewAssertions.*
import androidx.test.espresso.matcher.ViewMatchers.*

class HomePage(private val rule: ActivityScenarioRule<MainActivity>) {

    // Actions
    fun tapExploreTab(): ExplorePage {
        onView(withId(R.id.tab_explore)).perform(click())
        return ExplorePage(rule)
    }

    fun tapProfileTab(): ProfilePage {
        onView(withId(R.id.tab_profile)).perform(click())
        return ProfilePage(rule)
    }

    // Verifications
    fun verifyBannerVisible(): HomePage {
        onView(withId(R.id.home_banner))
            .check(matches(isDisplayed()))
        return this
    }
}
```

### UI Test 結構

```kotlin
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

// TC-IOM-001 ~ TC-IOM-003: 冒煙測試 - App 啟動與 Tab 導航
@RunWith(AndroidJUnit4::class)
class SmokeNavigationUITest {

    @get:Rule
    val activityRule = ActivityScenarioRule(MainActivity::class.java)

    // TC-IOM-001: 訪客模式啟動應顯示首頁
    @Test
    fun appLaunch_guestMode_showsHomePage() {
        // Given: 訪客模式（未登入）
        // When & Then: 首頁應該顯示
        HomePage(activityRule)
            .verifyBannerVisible()
    }

    // TC-IOM-002: 登入使用者 Tab 導航
    @Test
    fun loggedInTabNavigation_allTabs() {
        // Given: 已登入使用者（test account injected via TestRunner）

        // When: 依序切換所有 Tab
        // Then: 每個 Tab 頁面正確顯示
        val home = HomePage(activityRule)
        home.tapExploreTab()
            .verifyPageLoaded()

        home.tapProfileTab()
            .verifyAvatarVisible()
    }
}
```

### Espresso 常用 Pattern

```kotlin
// 等待元素出現（替代 sleep）
fun waitForView(viewId: Int, timeout: Long = 5000) {
    val endTime = System.currentTimeMillis() + timeout
    while (System.currentTimeMillis() < endTime) {
        try {
            onView(withId(viewId)).check(matches(isDisplayed()))
            return
        } catch (e: Exception) {
            Thread.sleep(100)
        }
    }
    throw AssertionError("View $viewId not found within ${timeout}ms")
}

// RecyclerView 操作
onView(withId(R.id.recycler_view))
    .perform(RecyclerViewActions.scrollToPosition<RecyclerView.ViewHolder>(5))
    .perform(RecyclerViewActions.actionOnItemAtPosition<RecyclerView.ViewHolder>(5, click()))

// Intent 驗證
Intents.intended(hasComponent(DetailActivity::class.java.name))
```

### Page Object 設計原則

1. **一個頁面一個 Page Object** — Activity/Fragment 對應一個 Page class
2. **Action 回傳下一個 Page** — `tapLogin(): LoginPage`
3. **Verification 回傳 self** — `verifyTitle(): HomePage`
4. **使用 R.id** — 不依賴文字（用 `withId()` 優先於 `withText()`）
5. **等待機制** — 用 IdlingResource 或自定義 waitForView，不用 `Thread.sleep`

### 命名慣例

```
檔案：{Feature}UITest.kt（測試）、{Page}Page.kt（Page Object）
類別：{Feature}UITest
方法：{場景}_{動作}_{預期}()
目錄：app/src/androidTest/java/.../pageobjects/、app/src/androidTest/java/.../tests/
```

### 從 TC 欄位對應到程式碼

| TC 欄位 | 對應位置 |
|---------|---------|
| Column A (ID) | 方法前的 `// TC-XXX-NNN` 註釋 |
| Column E (標題) | 方法名 + KDoc comment |
| Column F (分類) | 測試類別分組 |
| Column G (優先度) | P0 = Smoke suite, P1 = Regression suite |
| Column I (前置條件) | `@Before` 或 test 開頭的 Given 區塊 |
| Column J (步驟) | test body 的 When 區塊 |
| Column K (預期) | assertions 的 Then 區塊 |
| Column H (平台) | 只生成 Android 標記的和 Both 的 |
