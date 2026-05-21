<h1 align="center">QA Claude Skill</h1>

<p align="center">
  <em>給 Claude Code 用的 15 個生產級 QA 工作流 Skill — 從規格到上線一條龍。</em>
</p>

<p align="center">
  <a href="README.md">English</a> · <strong>繁體中文</strong>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT" /></a>
  <img src="https://img.shields.io/badge/skills-15-2563EB" alt="15 個 skill" />
  <img src="https://img.shields.io/badge/Claude%20Code-Compatible-7C3AED?logo=anthropic&logoColor=white" alt="Claude Code 相容" />
  <img src="https://img.shields.io/badge/Mode-full--mcp%20%7C%20partial--mcp%20%7C%20markdown--only-10B981" alt="3 種模式" />
  <img src="https://img.shields.io/badge/i18n-en%20%7C%20zh--TW-FB923C" alt="雙語" />
</p>

> 一個可配置的 **15 個 QA Skill** 套件，給 [Claude Code](https://claude.ai/code) 使用，
> 覆蓋完整測試生命週期：**規格 → TC → 自動化 → 審查 → 回歸 → 發布**。
> 從個人 QA workspace 抽離並透過 `config.json` 通用化 —
> 換上你團隊的 ID 就能套用到任何團隊、任何工具棧。

---

## ✨ 設計亮點

- 🧪 **完整生命週期覆蓋** — 規格解析、TC 設計、自動化生成、程式碼審查、回歸計劃、Bug 開單、變異測試、報告發布
- 🔌 **工具獨立的 3 種模式** — `full-mcp`（Atlassian + Slack + Google）/ `partial-mcp`（缺工具自動降級）/ `markdown-only`（零外部依賴）
- 🌐 **中英雙語** — 每個 skill 含 `SKILL.md`（繁中）+ `SKILL.en.md`；陌生概念另有 4 篇中文入門
- 📦 **單一 config 配置** — 28 個變數涵蓋 JIRA / Slack / Google / iOS / Android / BE pytest / AWS dashboard
- 🧩 **可插拔模組** — 每個 skill 內建 `modules/{config-loader, jira/slack-integration, markdown-fallback}.md` 清晰分離
- 🚀 **一鍵安裝** — `./install.sh` 自動校驗 config、渲染 28 個變數、備份既有 skill、安裝到 `~/.claude/skills/`
- 🇹🇼 **台灣設計、全球可用** — 每個 skill 都內建 a11y 必檢項（Dynamic Type / TalkBack / 對比度）和跨平台配對機制

---

## 📦 套件包含

15 個 Skill 分 5 類：

### 測試設計（8 個）

| Skill | 用途 |
|-------|------|
| [`test-master`](skills/test-master/) | 完整測試計劃 + 黑箱/白箱 TC 生成（原生 iOS/Android）|
| [`flutter-test-master`](skills/flutter-test-master/) | Flutter 三層測試金字塔（Unit/Widget/Integration）+ Golden + Platform Channel |
| [`test-review`](skills/test-review/) | TC + 程式碼審查（10 維度加權評分）；支援 Swift/Kotlin/Dart/Python |
| [`regression-test`](skills/regression-test/) | Release 級跨平台回歸測試計劃（JIRA + 歷史 Bug 分析）|
| [`speckit-to-tc`](skills/speckit-to-tc/) | Spec Kit / SDD 規格 → 14 欄黑白箱 TC 草稿 |
| [`tc-version-diff`](skills/tc-version-diff/) | TC 版本差異比對；產 changelog + 補測清單 |
| [`sheet-md-sync`](skills/sheet-md-sync/) | Google Sheet ↔ Markdown 雙向同步（讓 TC 能進 git diff / PR review）|
| [`smoke-test-analyzer`](skills/smoke-test-analyzer/) | 把現有自動化測試分到 T0/T1/T2/T3 + 產 CI 設定檔 |

### 自動化（3 個）

| Skill | 用途 |
|-------|------|
| [`test-automation`](skills/test-automation/) | iOS（Swift Testing + XCUITest）/ Android（JUnit + Espresso + Mockk）腳本生成 |
| [`flutter-test-automation`](skills/flutter-test-automation/) | Dart 自動化腳本（flutter_test / integration_test / Patrol / Golden）|
| [`tc-to-pytest`](skills/tc-to-pytest/) | 白箱 API TC → pytest-api-kit 三件套（`schemas.py` + `conftest.py` + `tests/test_*_api.py`）|

### Bug 管理（1 個）

| Skill | 用途 |
|-------|------|
| [`bug-report`](skills/bug-report/) | RIDER 格式 Bug 報告 + 自動建 JIRA + Slack 通知 + 跨平台配對 |

### 品質量化（2 個）

| Skill | 用途 |
|-------|------|
| [`mutation-testing`](skills/mutation-testing/) | mutmut 變異測試 — 量化 TC 真實強度（不是只看行覆蓋率）|
| [`property-based-test-gen`](skills/property-based-test-gen/) | 生成 hypothesis @given 策略，自動探索邊界 bug |

### 報告發布（1 個）

| Skill | 用途 |
|-------|------|
| [`publish-regression`](skills/publish-regression/) | 手動回歸測試報告發布到 S3 + CloudFront 失效 + Slack 通知 |

> 💡 **第一次聽到變異測試 / property-based testing / 規格驅動開發 / 測試分層？**
> 每個概念有 5 分鐘中文入門：`skills/<name>/concept-zh.md`，見[概念入門](#-概念入門)。

---

## 🚀 快速開始

```bash
# 1. Clone
git clone https://github.com/kao273183/qa-claude-skill.git ~/Desktop/QA_Claude_Skill
cd ~/Desktop/QA_Claude_Skill

# 2. 建立你的 config
cp config/config.example.json config/config.json

# 3. 填入最少 4 個必要欄位：
#    - jira.instance_url
#    - jira.project_key
#    - platforms.ios.default_device
#    - platforms.android.default_device

# 4. 安裝（渲染 28 個變數 → ~/.claude/skills/）
./install.sh

# 5. 在 Claude Code 中試試觸發詞：
#    「幫我規劃 X 功能的測試計劃」
#    「我要開 Bug 單」
#    「審查這份測試案例」
```

### 安裝前 Dry-run 預覽

```bash
CLAUDE_SKILLS_DIR=/tmp/preview ./install.sh
ls /tmp/preview/   # 應該有 15 個 skill 資料夾
grep -r '{{' /tmp/preview/ | grep -v '變數'   # 應該為空（變數全解析）
```

---

## 🎛 3 種運作模式

每個 skill 都支援 3 種模式，依你團隊的工具現況選一個：

| 模式 | 適用情境 | 行為 |
|------|---------|------|
| `full-mcp` | 你有 Atlassian + Slack + Google Workspace MCP | 自動建 ticket、發 Slack、寫 Sheet |
| `partial-mcp` | 部分 MCP 缺漏 | 有 MCP 就用，沒有就走 Markdown |
| `markdown-only` | 單人開發者 / 無 MCP / 純文件流 | 完全不呼叫外部，產出 `.md` 到 `.claude/testing/` |

3 個預設 preset 在 [`config/presets/`](config/presets/) 可直接複製套用：

```bash
cp config/presets/full-stack.json     config/config.json   # 全套 MCP
cp config/presets/jira-only.json      config/config.json   # 只用 JIRA
cp config/presets/markdown-only.json  config/config.json   # 純文件
```

---

## ⚙️ 客製化

三層客製化可選：

1. **`config.json`** — 28 個變數。完整對照表見 [docs/customization-guide.md](docs/customization-guide.md)
2. **`config/presets/`** — 3 種預設情境（full-stack / jira-only / markdown-only）
3. **每個 skill 的 modules** — 每個 skill 有 `modules/markdown-fallback.md` 定義降級行為

### 範例配置

- 🏢 [大型團隊 — ACME Corp](examples/jira-acme-corp/config.json) — JIRA + Slack + Google + AWS dashboard 全套
- 👤 [單人開發者](examples/solo-developer/config.json) — 純 Markdown，無外部依賴

### 從個人版（含 UOP / 公司專屬 ID）遷移？

完整對照表見 [docs/migration-from-personal.md](docs/migration-from-personal.md)。

---

## 🧩 架構設計

每個 skill 遵循相同的可插拔結構：

```
skills/<skill-name>/
├── SKILL.md                          ← 主檔（繁中）
├── SKILL.en.md                       ← 英文版
├── concept-zh.md                     ← 新手入門（陌生概念才有）
├── examples.md                       ← 3-5 個實際使用情境
├── templates.md / patterns.md        ← 範本 / 程式碼 pattern
└── modules/                          ← 可插拔整合
    ├── config-loader.md              ← 載入 config.json 設定
    ├── jira-integration.md           ← (可選) JIRA MCP 呼叫
    ├── slack-integration.md          ← (可選) Slack MCP 呼叫
    └── markdown-fallback.md          ← 純 Markdown 降級路徑
```

意思是：
- **要移除 JIRA 整合？** 刪掉 `modules/jira-integration.md` 引用 — Slack 仍可用
- **沒有 Google？** 切到 `markdown-only` 模式 — 所有 skill 仍能跑
- **想加新工具整合？** 新增 `modules/<your-tool>.md` 並在 `SKILL.md` 引用

---

## 📖 概念入門

陌生的測試概念都有 5 分鐘中文導讀：

| 概念 | 講什麼 | 連結 |
|------|--------|------|
| **Property-based testing** | 為什麼 fuzz 200 個 input 比寫 2 個 example 強 | [property-based-test-gen/concept-zh.md](skills/property-based-test-gen/concept-zh.md) |
| **變異測試（Mutation testing）** | 為什麼行覆蓋率 100% 也不夠 | [mutation-testing/concept-zh.md](skills/mutation-testing/concept-zh.md) |
| **規格驅動開發（Spec Kit）** | 為什麼規格 ticket → 30 秒草擬 TC 是可能的 | [speckit-to-tc/concept-zh.md](skills/speckit-to-tc/concept-zh.md) |
| **測試分層 T0/T1/T2/T3** | 為什麼不該每次 PR 都跑全部測試 | [smoke-test-analyzer/concept-zh.md](skills/smoke-test-analyzer/concept-zh.md) |

---

## 🌊 典型工作流

[docs/workflow-diagrams.md](docs/workflow-diagrams.md) 收錄 5 個 ASCII 串接圖：

1. **規格 → 上線 pipeline（BE 功能）** — `speckit-to-tc` → `test-review` → `sheet-md-sync` → `tc-to-pytest` → `mutation-testing` → `property-based-test-gen`
2. **Release 前準備（行動端）** — `test-master` → `test-automation` → `smoke-test-analyzer` → `regression-test` → `bug-report` → `publish-regression`
3. **TC 版本升級** — `test-master --quick` → `test-review` → `tc-version-diff` → `tc-to-pytest --incremental`
4. **Markdown-only 流程（單人）** — 所有 skill 寫 `.md` 到 `.claude/testing/`
5. **三方審查** — Claude + Codex + Gemini 同時審查一份 TC，加權合議

---

## 🧰 相容性

| 項目 | 需求 |
|------|------|
| **Claude Code** | 最新版（skills 是一級公民） |
| **OS** | macOS / Linux（Windows: 使用 WSL）|
| **MCP servers（選用）** | atlassian, slack, google-workspace, mcp-google-full, mcp-context-mode |
| **必要 CLI 工具** | `bash`, `jq`, `git` |
| **選用 CLI 工具** | `gh`（GitHub Actions）, `aws`（S3 publish）, `python3` + `pytest`（BE skills）, `flutter`（Flutter skills）, `xcodebuild`（iOS）, Gradle（Android）|

---

## 🗺 Roadmap

- [ ] Windows 原生支援（目前需用 WSL）
- [ ] CI/CD pipeline 整合範本（GitHub Actions / GitLab / CircleCI）
- [ ] 內建 `ajv-cli` schema 校驗
- [ ] 多語言擴充：日本語 / 简体中文
- [ ] 更多 preset：新創 / 企業 / 政府
- [ ] Config 編輯 Web UI
- [ ] Skill 遙測（匿名統計，優化預設值）

---

## 🤝 貢獻

歡迎 PR！見 [CONTRIBUTING.md](CONTRIBUTING.md)：
- 如何新增 skill
- 如何貢獻翻譯
- 如何修改既有 skill
- PR 檢查表

---

## 📝 授權

[MIT](LICENSE) — 自由使用、修改、分發。歡迎 attribution。

## 🙏 致謝

本套件抽離自 Jack Kao 自 2025 起持續迭代的個人 Claude Code QA workspace。
感謝原版迭代過程中協作的工程師、測試夥伴與 AI 夥伴（Claude / Codex / Gemini）。

---

<p align="center">
  Made with ❤️ for QA teams who want to focus on quality, not paperwork.
</p>
