# iOS 自動化測試 Patterns

## Unit Test（Swift Testing + UniTesting）

遵循專案既有的 unit-test skill pattern。

### 結構

```swift
import Testing
import UniTesting
@testable import union

// TC-IOM-015: Cookie 過期後重新載入 WebView
@MainActor
struct IOMCookieExpirationTests {

    // MARK: - Stubs

    enum Stubs {
        static let expiredCookie = IOMCookie(name: "session", value: "", expiry: Date.distantPast)
        static let validCookie = IOMCookie(name: "session", value: "abc123", expiry: Date.distantFuture)
    }

    // MARK: - SUT Factory

    private func makeSUT() -> (IOMCookieManager, StubCookieStore) {
        let store = StubCookieStore()
        let sut = IOMCookieManager(store: store)
        return (sut, store)
    }

    // MARK: - Tests

    @Test("Cookie 過期時應觸發重新載入")
    func cookieExpiration_triggersReload() async {
        // Given (前置條件 from Column I)
        let (sut, store) = makeSUT()
        store.stubbedCookies = [Stubs.expiredCookie]

        // When (測試步驟 from Column J)
        let shouldReload = await sut.checkAndRefreshIfNeeded()

        // Then (預期結果 from Column K)
        #expect(shouldReload == true)
        #expect(store.refreshCallCount == 1)
    }
}
```

### 關鍵規則
- `struct` 基底，不用 `class`
- `makeSUT()` 回傳 tuple `(SUT, StubType)`
- `Stubs` enum 集中測試資料
- 每個 test 獨立 stub（並發安全）
- `@MainActor` 用於 ViewModel 測試
- 註釋標記原始 TC ID

## UI Test（XCUITest + Page Object Model）

### Page Object 結構

```swift
import XCTest

// MARK: - Page Objects

final class HomePage: BasePage {
    // Elements
    private lazy var bannerView = app.otherElements["home_banner"]
    private lazy var exploreTab = app.tabBars.buttons["探索"]
    private lazy var socialTab = app.tabBars.buttons["社群"]
    private lazy var messageTab = app.tabBars.buttons["訊息"]
    private lazy var profileTab = app.tabBars.buttons["我的"]

    // Actions
    @discardableResult
    func tapExploreTab() -> ExplorePage {
        exploreTab.tap()
        return ExplorePage(app: app)
    }

    @discardableResult
    func tapProfileTab() -> ProfilePage {
        profileTab.tap()
        return ProfilePage(app: app)
    }

    // Verifications
    func verifyBannerVisible() -> Self {
        XCTAssertTrue(bannerView.waitForExistence(timeout: 5), "首頁 Banner 應該可見")
        return self
    }
}
```

### BasePage

```swift
class BasePage {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // 共用等待方法
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        element.waitForExistence(timeout: timeout)
    }
}
```

### UI Test 結構

```swift
import XCTest

// TC-IOM-001 ~ TC-IOM-003: 冒煙測試 - App 啟動與 Tab 導航
final class SmokeNavigationUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITest"]
    }

    // TC-IOM-001: 訪客模式啟動應顯示首頁
    func testAppLaunch_GuestMode_ShowsHomePage() {
        // Given: 訪客模式（未登入）
        app.launchArguments.append("-GuestMode")
        app.launch()

        // When & Then: 首頁應該顯示
        HomePage(app: app)
            .verifyBannerVisible()
    }

    // TC-IOM-002: 登入使用者 Tab 導航
    func testLoggedInTabNavigation_AllTabs() {
        // Given: 已登入使用者
        app.launchArguments.append("-LoggedIn")
        app.launch()

        // When: 依序切換所有 Tab
        // Then: 每個 Tab 頁面正確顯示
        let home = HomePage(app: app)
        home.tapExploreTab()
            .verifyPageLoaded()

        home.tapProfileTab()
            .verifyAvatarVisible()
    }
}
```

### Page Object 設計原則

1. **一個頁面一個 Page Object** — 不要把多個頁面的元素混在一起
2. **Action 回傳下一個 Page** — `tapLogin() -> LoginPage`，支援鏈式呼叫
3. **Verification 回傳 self** — `verifyTitle() -> Self`，可繼續鏈式操作
4. **Element 用 lazy var** — 避免頁面未載入就查找元素
5. **使用 accessibilityIdentifier** — 不依賴文字（會隨語系變動）
6. **等待機制** — 所有斷言前用 `waitForExistence`，不用 `sleep`

### 命名慣例

```
檔案：{Feature}UITests.swift（測試）、{Page}Page.swift（Page Object）
類別：{Feature}UITests（繼承 XCTestCase）
方法：test{場景}_{動作}_{預期}()
目錄：unionUITests/PageObjects/、unionUITests/TestCase/
```

### 從 TC 欄位對應到程式碼

| TC 欄位 | 對應位置 |
|---------|---------|
| Column A (ID) | 方法前的 `// TC-XXX-NNN` 註釋 |
| Column E (標題) | 方法名 + `/// ` doc comment |
| Column F (分類) | 測試類別分組 |
| Column G (優先度) | P0 = Smoke suite, P1 = Regression suite |
| Column I (前置條件) | `setUp()` 或 test 開頭的 Given 區塊 |
| Column J (步驟) | test body 的 When 區塊 |
| Column K (預期) | assertions 的 Then 區塊 |
| Column H (平台) | 只生成 iOS 標記的和 Both 的 |
