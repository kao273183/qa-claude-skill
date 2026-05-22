# 歡迎使用 QA Claude Skill 👋

這是一個可配置的 **15 個 QA Skill** 套件，給 Claude Code 使用，覆蓋完整測試生命週期 — 從規格解析到上線發布。

> 🌐 [English version](ONBOARDING.en.md) 也有英文版

---

## 🎯 5 分鐘做什麼

1. **挑一個 preset**（依你的團隊規模 / 工具棧）
2. **填入你的 ID**（JIRA / Slack / Google）
3. **跑 `install.sh`**（Windows 用 `.\install.ps1`）
4. **試試看一個 skill** — `/test-master` 或 `/bug-report`

就這樣。15 個 skill 會依你有什麼工具自動降級運作。

---

## 📦 套件包含

| 類別 | Skills |
|------|--------|
| **測試設計**（8 個）| test-master / flutter-test-master / test-review / regression-test / speckit-to-tc / tc-version-diff / sheet-md-sync / smoke-test-analyzer |
| **自動化**（3 個）| test-automation / flutter-test-automation / tc-to-pytest |
| **Bug 管理**（1 個）| bug-report |
| **品質量化**（2 個）| mutation-testing / property-based-test-gen |
| **報告發布**（1 個）| publish-regression |

完整速查：[docs/skill-index.md](docs/skill-index.md)

---

## 🚀 快速開始（3 個指令）

```bash
# 1. 挑一個 preset
cp config/presets/markdown-only.json config/config.json   # 最簡單，零外部依賴

# 2. 編輯（至少填：jira.project_key + jira.instance_url）
vim config/config.json

# 3. 安裝
./install.sh        # macOS / Linux
.\install.ps1       # Windows PowerShell
```

之後在 Claude Code 內輸入：
```
幫我規劃登入功能的測試計劃
```

`test-master` skill 就會啟動，引導你建立完整測試計劃。

---

## 🎛 挑你的模式

| 你的情境 | 用 mode | 用 preset |
|---------|---------|-----------|
| 有 JIRA + Slack + Google MCP | `full-mcp` | `config/presets/full-stack.json` |
| 只有 JIRA | `partial-mcp` | `config/presets/jira-only.json` |
| 單人開發 / 沒 MCP | `markdown-only` | `config/presets/markdown-only.json` |
| 新創團隊 < 10 人 | `partial-mcp` | `config/presets/startup.json` |
| 大企業 > 100 人 | `full-mcp` | `config/presets/enterprise.json` |
| 政府 / 高合規 | `markdown-only` | `config/presets/government.json` |

---

## 🧠 概念入門（5 分鐘中文導讀）

陌生的測試概念都有新手友善的導讀：

- 💥 [**Property-based testing**](skills/property-based-test-gen/concept-zh.md) — 為什麼 fuzz 200 個 input 比寫 2 個 example 強
- 🧬 [**變異測試（Mutation testing）**](skills/mutation-testing/concept-zh.md) — 為什麼行覆蓋率 100% 也不夠
- 📋 [**規格驅動開發（Spec Kit）**](skills/speckit-to-tc/concept-zh.md) — 為什麼規格 ticket → 30 秒草擬 TC 是可能的
- 🎯 [**測試分層（T0/T1/T2/T3）**](skills/smoke-test-analyzer/concept-zh.md) — 為什麼不該每次 PR 都跑全部測試

---

## 🌊 試試看典型工作流

### 工作流 1：寫第一份 Bug 報告

在 Claude Code 內輸入：
```
我要開單 — 安卓登入畫面會 crash
```

`bug-report` skill 啟動 → 引導你按 RIDER 格式填 → 自動建 JIRA ticket → 發 Slack 通知。

### 工作流 2：為新功能規劃測試

```
規劃個人資料編輯功能的測試（暱稱 / 頭像 / 簡介）
```

`test-master` 自動生成：
- `test-strategy.md` 測試策略
- 黑箱 + 白箱測試案例（Google Sheet 或 .md）
- 覆蓋缺口分析
- 自動化路線圖
- 探索性測試指引

### 工作流 3：審查現有 TC 品質

```
審查這份測試案例 — <Google Sheet URL>
```

`test-review` 按 10 維度打分，列出 Critical / Major / Minor 問題。

---

## 🔧 常用指令

```bash
# 不安裝，先校驗 config
./scripts/validate-config.sh

# Dry-run（不動 ~/.claude/skills/）
CLAUDE_SKILLS_DIR=/tmp/preview ./install.sh

# 移除 + 還原 backup
./uninstall.sh
```

Windows 對應：
```powershell
.\scripts\validate-config.ps1
$env:CLAUDE_SKILLS_DIR = "C:\temp\preview"; .\install.ps1
.\uninstall.ps1
```

---

## 📚 進階閱讀

- [README.md](README.md) — 完整概覽
- [INSTALL.md](INSTALL.md) — 一步一步安裝指南
- [docs/customization-guide.md](docs/customization-guide.md) — 28 個變數完整說明
- [docs/workflow-diagrams.md](docs/workflow-diagrams.md) — 5 個 Skill 串接圖
- [docs/ci-integration.md](docs/ci-integration.md) — GitHub Actions / GitLab CI / CircleCI 範本
- [docs/install-windows.md](docs/install-windows.md) — Windows 專用安裝
- [docs/migration-from-personal.md](docs/migration-from-personal.md) — 從個人版（含硬編碼 ID）遷移

---

## 🤝 需要協助？

- 🐛 發現 bug？開 issue
- 💡 有想法？見 [CONTRIBUTING.md](CONTRIBUTING.md)
- 📖 想新增 skill？參考既有 skill 的結構（`skills/bug-report/` 最完整）

---

<p align="center">
  Made with ❤️ for QA teams who want to focus on quality, not paperwork.
</p>
