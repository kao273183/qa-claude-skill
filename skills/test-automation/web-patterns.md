# Web Test Automation Patterns

對應 `platforms.web.frameworks.primary` 設定，本套件支援 4 種主流 Web 測試框架。
每個 pattern 都對齊 `test-automation` 的核心原則：
- TC ID 在註釋中（雙向 traceability）
- Page Object Model（不在 test body 寫 raw locator）
- 用 `data-testid` 或 `accessibility role` 作 locator，不依賴動態 class / text
- AAA / Given-When-Then 結構

---

## 框架選擇對照

| 框架 | 適合情境 | 套件生態 | 速度 | 跨瀏覽器 |
|------|---------|---------|------|---------|
| **Playwright** (primary 推薦) | 跨瀏覽器、Component test、Visual regression、API | npm + python | 快 | Chromium / WebKit / Firefox |
| **Cypress** | SPA-heavy 專案、開發者友善、互動式 debug | npm | 中 | Chromium + Firefox（Webkit experimental） |
| **Selenium / WebdriverIO** | 企業 / 政府專案、多語言支援、Legacy 系統 | Java / Python / JS | 慢 | 全 |
| **Vitest / Jest** | Unit / Hook / Pure function test | npm | 極快 | (N/A — Node only) |

---

## 1️⃣ Playwright Pattern

### Page Object（POM）— 推薦

```typescript
// e2e/pages/LoginPage.ts
import { Page, Locator, expect } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.getByTestId('login-email');           // ⭐ 用 data-testid
    this.passwordInput = page.getByTestId('login-password');
    this.submitButton = page.getByRole('button', { name: 'Login' });  // ⭐ 或用 a11y role
    this.errorMessage = page.getByTestId('login-error');
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  async expectError(message: string) {
    await expect(this.errorMessage).toHaveText(message);
  }
}
```

### Test file

```typescript
// e2e/tests/login.spec.ts
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';

test.describe('Login flow', () => {

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

  test('TC: BB-AUTH-002 invalid password should show error', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('test@example.com', 'wrong-password');
    await loginPage.expectError('密碼錯誤');
  });
});
```

### Cross-browser config

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'webkit',   use: { ...devices['Desktop Safari'] } },
    { name: 'firefox',  use: { ...devices['Desktop Firefox'] } },
    // 行動端 viewport
    { name: 'mobile-chrome', use: { ...devices['Pixel 5'] } },
    { name: 'mobile-safari', use: { ...devices['iPhone 13'] } },
  ],
  use: {
    baseURL: process.env.BASE_URL || 'https://uat.example.com',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
});
```

跑指定瀏覽器：
```bash
npx playwright test --project=chromium
npx playwright test --project=webkit
npx playwright test                    # 全部跑
```

### Component Test（Playwright Component）

```typescript
// LoginForm.spec.tsx
import { test, expect } from '@playwright/experimental-ct-react';
import { LoginForm } from './LoginForm';

test('TC: COMP-AUTH-001 submit button disabled when email empty', async ({ mount }) => {
  const component = await mount(<LoginForm />);
  const submit = component.getByRole('button', { name: 'Login' });
  await expect(submit).toBeDisabled();
});
```

### Visual Regression（Playwright snapshot）

```typescript
test('TC: VR-HOME-001 home page visual snapshot', async ({ page }) => {
  await page.goto('/home');
  await expect(page).toHaveScreenshot('home.png', {
    maxDiffPixelRatio: 0.02,  // 容忍 2% 像素差異
  });
});
```

### API Test（在 E2E 中順便驗 API）

```typescript
test('TC: API-PRODUCT-001 product list returns 200', async ({ request }) => {
  const response = await request.get('/api/v1/products');
  expect(response.status()).toBe(200);
  const json = await response.json();
  expect(json.products).toBeInstanceOf(Array);
});
```

---

## 2️⃣ Cypress Pattern

### Page Object（cy.commands）

```javascript
// cypress/support/pages/LoginPage.js
Cypress.Commands.add('loginAs', (email, password) => {
  cy.visit('/login');
  cy.getByTestId('login-email').type(email);
  cy.getByTestId('login-password').type(password);
  cy.getByRole('button', { name: 'Login' }).click();
});
```

### Test file

```javascript
// cypress/e2e/login.cy.js
describe('Login flow', () => {

  it('TC: BB-AUTH-001 valid credentials should redirect to home', () => {
    cy.loginAs('test@example.com', 'password123');
    cy.url().should('include', '/home');
    cy.getByTestId('welcome-banner').should('be.visible');
  });

  it('TC: BB-AUTH-002 invalid password should show error', () => {
    cy.loginAs('test@example.com', 'wrong-password');
    cy.getByTestId('login-error').should('contain', '密碼錯誤');
  });
});
```

### Component Test（Cypress Component）

```javascript
// LoginForm.cy.jsx
import LoginForm from './LoginForm';

it('TC: COMP-AUTH-001 submit button disabled when email empty', () => {
  cy.mount(<LoginForm />);
  cy.findByRole('button', { name: 'Login' }).should('be.disabled');
});
```

### API Test

```javascript
it('TC: API-PRODUCT-001 product list returns 200', () => {
  cy.request('/api/v1/products').then((response) => {
    expect(response.status).to.eq(200);
    expect(response.body.products).to.be.an('array');
  });
});
```

---

## 3️⃣ Selenium / WebdriverIO Pattern

### Page Object（WebdriverIO）

```typescript
// test/pageobjects/LoginPage.ts
class LoginPage {
  get emailInput()    { return $('[data-testid="login-email"]'); }
  get passwordInput() { return $('[data-testid="login-password"]'); }
  get submitButton()  { return $('[data-testid="login-submit"]'); }

  async open() {
    await browser.url('/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.setValue(email);
    await this.passwordInput.setValue(password);
    await this.submitButton.click();
  }
}

export default new LoginPage();
```

### Test file (Mocha-style)

```typescript
import LoginPage from '../pageobjects/LoginPage';
import { expect } from '@wdio/globals';

describe('Login flow', () => {
  it('TC: BB-AUTH-001 valid credentials should redirect to home', async () => {
    await LoginPage.open();
    await LoginPage.login('test@example.com', 'password123');
    await expect(browser).toHaveUrlContaining('/home');
  });
});
```

---

## 4️⃣ Unit Test（Vitest / Jest）

### Pure function test

```typescript
// utils/formatCurrency.test.ts
import { describe, it, expect } from 'vitest';
import { formatCurrency } from './formatCurrency';

describe('formatCurrency', () => {
  it('TC: UT-FORMAT-001 formats integer with thousand separator', () => {
    expect(formatCurrency(1000)).toBe('$1,000');
  });

  it('TC: UT-FORMAT-002 handles negative numbers', () => {
    expect(formatCurrency(-500)).toBe('-$500');
  });
});
```

### React Hook test

```typescript
// hooks/useCart.test.ts
import { renderHook, act } from '@testing-library/react';
import { useCart } from './useCart';

it('TC: UT-CART-001 addItem increases count', () => {
  const { result } = renderHook(() => useCart());
  act(() => result.current.addItem({ id: 1, qty: 2 }));
  expect(result.current.count).toBe(2);
});
```

---

## 🔑 Locator 優先順序（4 種框架通用）

從穩定到不穩定排序：

1. **`data-testid`** — 最穩定，純為測試而生，不會因為 UI 改而動
2. **A11y role + name** — 穩定，且還能驗證 a11y 是否正確
3. **`aria-label` / `id` 屬性** — 穩定，但跟業務邏輯有耦合
4. **CSS class / 文字內容** — 不穩定，UI 改了測試就壞

```typescript
// ✅ 推薦
page.getByTestId('submit-button')
page.getByRole('button', { name: 'Submit' })

// ⚠️ 可接受
page.locator('[aria-label="Submit"]')
page.locator('#submit-btn')

// ❌ 避免
page.locator('.btn.btn-primary.large')   // class 改了就壞
page.locator('text=Submit')              // 翻譯 / 文案改了就壞
```

---

## 🎯 Web 特有挑戰與對策

| 挑戰 | 對策 |
|------|------|
| **網路慢 / API 不穩** | Mock 網路（Playwright route / MSW / cy.intercept），不要打真實 API |
| **動畫導致 flaky** | `await page.waitForLoadState('networkidle')` / `cy.wait()` 改用 `cy.get(...).should(...)` |
| **第三方 iframe（payment）** | Playwright `frameLocator()` / Cypress `iframe` plugin |
| **跨域 CORS** | 用測試環境 base_url，避免本地對 production 跨域 |
| **Session / Cookie 持久化** | `storageState` (Playwright) / `cy.session()` |
| **時區 / Locale 差異** | `BROWSER_TZ=Asia/Taipei npx playwright test` |
| **行動端 viewport** | Playwright `devices['Pixel 5']` / Cypress `cy.viewport(375, 667)` |

---

## 📊 框架選型決策樹

```
專案是 SPA-heavy 且開發者主導測試？
  ↓ Yes
  → Cypress

需要跨瀏覽器（Chromium/Webkit/Firefox）測試？
  ↓ Yes
  → Playwright（多 project 一鍵跑）

需要 Visual Regression？
  ↓ Yes
  → Playwright snapshot / Percy / Chromatic

只測 Pure function / React Hook，不啟動瀏覽器？
  ↓ Yes
  → Vitest（Vite 專案）/ Jest

企業專案、多語言支援、legacy 系統？
  ↓ Yes
  → Selenium / WebdriverIO

無特殊偏好？
  ↓
  → Playwright（綜合最佳）
```

---

## 🔗 對齊既有 skill

- **Locator 穩定性** → `test-review` 的 code-patterns 會看 locator 選擇
- **TC ID traceability** → `tc-version-diff` 升版時可對應
- **Cross-browser 分層** → `smoke-test-analyzer` 把 Chrome 跑全部、其他瀏覽器只跑 T0/T1
- **Visual Regression 基線** → 在 git ignored snapshots 上跑（不 commit baselines）
