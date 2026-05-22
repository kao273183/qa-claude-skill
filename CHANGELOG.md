# Changelog

## v1.4.0 — 2026-05-22

### Added

- 🌐 **简体中文支援** — 新增 `README.zh-CN.md`
  - 大陸用詞本地化（軟體 → 软件、檔案 → 文件、規格 → 规格 等）
  - 完整對應繁中版內容（亮點 / 15 個 skill / 快速開始 / 3 種模式 / 6 個 preset / 概念入門 / 工作流 / 兼容性 / CI / Roadmap）
  - README.md / README.zh-TW.md 頂部加 3 語言切換 link
  - i18n badge 從 `en | zh-TW` 升級為 `en | zh-TW | zh-CN`

### Removed

- 🧹 **ONBOARDING.md / ONBOARDING.en.md** — 從通用 repo 移除
  - 原因：通用 repo 保持「乾淨的通用版」原則
  - 內部 onboarding 將另出 uniopen 專屬版本（不放這個通用 repo）
  - 對外 onboarding 入口統一改用 README.* + INSTALL.md

---

## v1.3.0 — 2026-05-22

### Added

- 🪟 **Windows 原生支援** — 不再需要 WSL，PowerShell 5.1+ 直接跑
  - `install.ps1` — PowerShell 版安裝腳本，內建 `ConvertFrom-Json` 取代 jq
  - `uninstall.ps1` — 移除 + 還原 backup
  - `scripts/validate-config.ps1` — 7 階段校驗（與 .sh 版功能對等）
  - 對應 `$env:USERPROFILE\.claude\skills\`（取代 `$HOME/.claude/skills/`）
  - 同樣支援 `$env:CLAUDE_SKILLS_DIR` 環境變數覆寫
  - 同樣 30 個變數渲染（{{JIRA_PROJECT_KEY}} 等）

- 📖 **Windows 安裝指南** ([`docs/install-windows.md`](docs/install-windows.md))
  - 3 種安裝方式對照（PowerShell 原生 / Git Bash / WSL）
  - 執行策略阻擋 (`ExecutionPolicy`) 處理
  - Dry-run 預覽 + 移除 + 校驗 指令
  - 5 個 Windows 專屬疑難排解
  - Windows CI runner 範例（GitHub Actions + GitLab CI）

### Changed

- README 將 OS 相容性從「macOS / Linux (Windows: WSL)」更新為「macOS / Linux / Windows native」
- INSTALL.md 拆 macOS/Linux 與 Windows 指令對照

---

## v1.2.0 — 2026-05-21

### Added

- 🚀 **CI/CD 整合範本** — 支援 3 大主流平台 × 3 種典型工作流（共 9 個範本檔）
  - **GitHub Actions** (`templates/ci/github-actions/`):
    * `pr-validate-config.yml` — PR 時自動校驗 config + dry-run install
    * `weekly-mutation-testing.yml` — 週跑 mutation testing + Slack 通知
    * `release-regression-publish.yml` — tag push 時自動上傳 S3 + 重建 dashboard
  - **GitLab CI** (`templates/ci/gitlab-ci/.gitlab-ci.yml`):
    * 整合 3 個 job 對應上述 workflow
    * 用 `rules:` 條件分流
  - **CircleCI** (`templates/ci/circleci/config.yml`):
    * 對應 3 個 job + workflow 觸發條件
    * 用 orbs（aws-cli + python）簡化

- 📖 **完整 CI 整合指南** ([`docs/ci-integration.md`](docs/ci-integration.md))
  - 3 種典型工作流解釋（PR 校驗 / 週跑 mutation / Release 發布）
  - 各平台安裝步驟（GitHub Actions / GitLab CI / CircleCI）
  - Secrets 管理（6 種 secret × 取得方式 × 設定步驟）
  - 排程設定（GitHub yml-based / GitLab UI-based / CircleCI workflow）
  - 客製化建議（mutation score 目標、failure 行為、matrix 多模組）
  - Troubleshooting（5 個常見問題 + 解法）

### Changed

- README Roadmap 標記 #2 為完成

---

## v1.1.0 — 2026-05-21

### Added

- 🧪 **Built-in config validator** (`scripts/validate-config.sh`)
  - 7 階段校驗：JSON syntax → 必填欄位 → Enum 值 → Pattern → Mode 一致性 → 跨欄位依賴 → 選填欄位提示
  - 整合進 `install.sh`，安裝前先過 validator
  - 也可獨立使用：`./scripts/validate-config.sh [config-path]`
  - 退出碼：0 = 通過、1 = 失敗、2 = usage error
  - 彩色輸出 + 詳細錯誤訊息（含修正提示）

- 📦 **3 個新場景 presets**
  - `startup.json` — 小型新創（< 10 人），Web 啟用、Slack channel only、BE pytest off
  - `enterprise.json` — 大型企業 + 5 個 team boards、4 瀏覽器、三方審查啟用、AWS S3 dashboard、BE pytest + mutation + property test 全套
  - `government.json` — 政府/金融/醫療高合規場景、預設 markdown-only、強制 a11y、on-prem JIRA、無 Slack / Google / AWS

- 🌐 **Web 平台支援**（自 4 個 skill 擴充）
  - test-master：Web 平台偵測 + Web 測試類型表（E2E / Component / Visual / Cross-browser / Responsive / API）
  - test-automation：新增 `web-patterns.md`（610 行）支援 4 種框架（Playwright / Cypress / Selenium / Vitest）
  - test-review：code-patterns 加 TypeScript 範例（Playwright / Cypress / Vitest）+ Web 專屬 anti-patterns 4 種
  - regression-test：平台 dropdown 加 Web / Web (Chrome) / Web (Safari) / All

- 📚 **4 篇中文概念入門導讀**
  - `property-based-test-gen/concept-zh.md`
  - `mutation-testing/concept-zh.md`
  - `speckit-to-tc/concept-zh.md`
  - `smoke-test-analyzer/concept-zh.md`

- 📝 **README 改寫**
  - 改為英文主版 + `README.zh-TW.md` 繁中可切換
  - 加 5 個 shields.io badges
  - 風格參考 mk-qa-master

### Changed

- `install.sh` 把校驗邏輯抽到獨立 `scripts/validate-config.sh`（保留 inline 簡化版 fallback）

### Fixed

- N/A

---

## v1.0.0 — 2026-05-21

首版發布。從個人 QA workspace 抽離出的通用版本。

### 包含

15 個 QA 專業 Skill：

**測試設計（8 個）**
- `test-master` — 完整測試計劃生成（原生 iOS/Android）
- `flutter-test-master` — Flutter 三層測試規劃
- `test-review` — TC 與測試程式碼審查（10 維度）
- `regression-test` — Release 回歸測試計劃
- `speckit-to-tc` — Spec Kit → TC 草稿
- `tc-version-diff` — TC 版本差異 + 補測清單
- `sheet-md-sync` — Google Sheet ↔ Markdown 雙向同步
- `smoke-test-analyzer` — Daily Smoke CI 測試篩選

**自動化（3 個）**
- `test-automation` — iOS XCUITest / Android Espresso 腳本
- `flutter-test-automation` — Flutter Dart 三層測試腳本
- `tc-to-pytest` — 白箱 TC → pytest 三件套

**Bug 管理（1 個）**
- `bug-report` — RIDER 格式 Bug 報告 + JIRA 自動建單

**品質量化（2 個）**
- `mutation-testing` — mutmut 變異測試
- `property-based-test-gen` — hypothesis fuzz test

**報告發布（1 個）**
- `publish-regression` — 回歸報告發布到 S3 Dashboard

### 與個人版的差異

- ✅ 15 個 skill 中性化處理：移除 UOP / nuion / unipcsc / Articuno-Zapdos-Moltres 等專屬語境
- ✅ 所有硬編碼抽到 `config.json`：JIRA / Slack / Google Drive / 平台預設 / Backend pytest / S3 Dashboard
- ✅ 三種模式：`full-mcp` / `partial-mcp` / `markdown-only`
- ✅ 每個 skill 提供 `modules/{config-loader, markdown-fallback}.md` 可插拔架構
- ✅ test-review code-patterns 從只有 Swift 擴充為 Swift + Kotlin + Dart + Python
- ✅ 中英雙語版（每個 skill 有 SKILL.md + SKILL.en.md）
- ✅ 一鍵 install.sh / uninstall.sh

### 排除（不納入通用版）

- ❌ `outsource-bug-report` — 個人專屬批次流程，通用化價值低

### 已知限制

- `sheet-md-sync` 在 `markdown-only` 模式下不啟用（skill 本身就是 Sheet ↔ md 同步）
- `publish-regression` 在 `mode = markdown-only` 下只產 .md summary，不上傳 S3
- Flutter skill 需明確設定 `platforms.flutter.enabled = true` 才啟用
- BE 系列 skill（`tc-to-pytest` / `mutation-testing` / `property-based-test-gen`）需設定 `backend.pytest_enabled = true`

---

## 未來規劃

- [ ] Windows 原生支援（目前需用 WSL）
- [ ] CI/CD pipeline 整合範本（GitHub Actions / GitLab / CircleCI）
- [ ] 內建 schema 校驗（ajv-cli optional integration）
- [ ] 多語言擴充：日文 / 簡中
- [ ] 更多 preset 範例（小型 startup / 大企業 / 政府專案）
