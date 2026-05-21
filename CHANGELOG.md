# Changelog

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
