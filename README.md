# QA Claude Skill — 通用 QA 工作流 Skill 套件

> A portable, configurable QA skill suite for Claude Code.
> 從個人版本（含 JIRA UOP / Slack / Google Drive 等硬編碼）抽離出的通用版本，套用 `config.json` 後即可在任何團隊使用。

[English version](./README.en.md)

---

## 🎯 套件包含

15 個 QA 專業 Skill，覆蓋從規格到自動化的完整測試生命週期：

| 類別 | Skill | 用途 |
|------|-------|------|
| **測試設計** | `test-master` | 完整測試計劃 + 黑箱/白箱 TC 生成（原生 iOS/Android） |
| | `flutter-test-master` | Flutter 三層測試（Unit/Widget/Integration）+ Golden |
| | `test-review` | TC 與測試程式碼審查（10 維度評分） |
| | `regression-test` | Release 跨平台回歸測試計劃 |
| | `speckit-to-tc` | Spec Kit / SDD 規格 → TC 草稿 |
| | `tc-version-diff` | TC 版本差異 + 補測清單 |
| | `sheet-md-sync` | Google Sheet ↔ Markdown 雙向同步 |
| | `smoke-test-analyzer` | Daily Smoke CI 測試篩選 |
| **自動化** | `test-automation` | iOS (XCUITest) / Android (Espresso) |
| | `flutter-test-automation` | Flutter Dart 自動化腳本 |
| | `tc-to-pytest` | 白箱 API TC → pytest 三件套 |
| **Bug 管理** | `bug-report` | RIDER 格式 Bug 報告 + JIRA 自動建單 |
| **品質量化** | `mutation-testing` | mutmut 變異測試 |
| | `property-based-test-gen` | hypothesis property-based / fuzz test |
| **報告發布** | `publish-regression` | 回歸報告發布至 S3 Dashboard |

---

## 🚀 快速開始

### 1. 複製設定範本

```bash
cd ~/Desktop/QA_Claude_Skill
cp config/config.example.json config/config.json
```

### 2. 填入你的組織資訊

打開 `config/config.json`，至少填入：

```json
{
  "jira": {
    "instance_url": "https://your-company.atlassian.net",
    "project_key": "YOUR_PROJECT",
    "reviewer_account_id": "你的 Atlassian Account ID"
  },
  "slack": {
    "user_id": "你的 Slack User ID（用於 DM）",
    "bug_channel_id": "Bug 通知頻道 ID"
  }
}
```

詳細欄位說明見 [`docs/customization-guide.md`](./docs/customization-guide.md)。

### 3. 安裝到 Claude Code

```bash
./install.sh
```

腳本會：
- 把 `skills/*` 套用 config.json 後複製到 `~/.claude/skills/`
- 備份你現有的同名 skill 到 `~/.claude/skills.backup-{時間戳}/`
- 提示尚未填寫的設定欄位

### 4. 驗證

在 Claude Code 中輸入 `/test-master` 或任一觸發詞，確認 Skill 正常載入。

---

## 🧩 工具整合模式

每個 Skill 支援 3 種運作模式，由 `config.json#mode` 控制：

| 模式 | 適用場景 | 行為 |
|------|---------|------|
| `full-mcp` | 你有 atlassian/slack/google MCP | 自動建單、發通知、寫 Sheet |
| `partial-mcp` | 只有部分工具 | 有 MCP 就用，沒有就走 Markdown fallback |
| `markdown-only` | 純文件輸出 | 不呼叫任何 MCP，產出 `.md` 報告 |

預設範本見 `config/presets/`。

---

## 📂 目錄結構

```
QA_Claude_Skill/
├── README.md                  ← 中文總覽（本檔案）
├── README.en.md               ← English overview
├── INSTALL.md                 ← 安裝指南
├── install.sh                 ← 一鍵安裝
├── uninstall.sh               ← 移除已安裝的 skill
├── config/
│   ├── config.example.json    ← 設定範本（複製為 config.json）
│   ├── config.schema.json     ← JSON Schema 校驗
│   └── presets/               ← 預設情境
│       ├── full-stack.json    ← JIRA + Slack + Google 全套
│       ├── jira-only.json     ← 只用 JIRA
│       └── markdown-only.json ← 純文件
├── skills/                    ← 16 個通用化 Skill
│   └── {skill-name}/
│       ├── SKILL.md           ← 繁中（含 {{變數}} 佔位符）
│       ├── SKILL.en.md        ← 英文版
│       ├── templates.md       ← 範本檔
│       ├── modules/           ← 可插拔整合
│       │   ├── jira-integration.md
│       │   ├── slack-integration.md
│       │   └── markdown-fallback.md
│       └── ...
├── docs/
│   ├── customization-guide.md ← 替換變數教學
│   ├── skill-index.md         ← 觸發詞速查
│   ├── workflow-diagrams.md   ← Skill 串接圖
│   └── migration-from-personal.md
└── examples/
    ├── jira-acme-corp/        ← 虛構公司範例
    └── solo-developer/        ← 單人開發者最小配置
```

---

## 🔧 變數佔位符對照表

通用化主要替換以下 4 大類：

| 類別 | 變數 | 用途 |
|------|------|------|
| **JIRA** | `{{JIRA_PROJECT_KEY}}` | 專案 Key（如 `PROJ`） |
| | `{{JIRA_INSTANCE_URL}}` | Atlassian 實例 URL |
| | `{{JIRA_REVIEWER_ACCOUNT_ID}}` | 驗收者 Account ID |
| | `{{JIRA_REVIEWER_FIELD}}` | 自訂欄位 ID（如 `customfield_10045`） |
| | `{{JIRA_BUG_ISSUE_TYPE_ID}}` | Bug Issue Type ID |
| **Slack** | `{{SLACK_USER_ID}}` | DM 通知對象 |
| | `{{SLACK_BUG_CHANNEL_ID}}` | Bug Channel |
| **Google** | `{{GSHEET_TC_TEMPLATE_ID}}` | TC 模板 Sheet ID |
| | `{{GDRIVE_QA_FOLDER_ID}}` | QA 測試用例資料夾 ID |
| | `{{GSHEET_RELEASE_SCHEDULE_ID}}` | Release Schedule Sheet ID |
| **平台預設** | `{{IOS_DEFAULT_DEVICE}}` | 預設 iOS 測試裝置 |
| | `{{IOS_DEFAULT_VERSION}}` | 預設 iOS 版本 |
| | `{{ANDROID_DEFAULT_DEVICE}}` | 預設 Android 測試裝置 |
| | `{{ANDROID_DEFAULT_VERSION}}` | 預設 Android 版本 |
| | `{{MIN_IOS_VERSION}}` | App 最低 iOS 支援 |
| | `{{MIN_ANDROID_API}}` | App 最低 Android API |
| | `{{IOS_REPO}}` | iOS GitHub repo（`org/repo`） |
| | `{{ANDROID_REPO}}` | Android GitHub repo |

完整列表見 `config/config.schema.json`。

---

## 📝 授權

MIT License — 自由使用、修改、分發。

## 🙏 致謝

本套件抽離自 Jack Kao 的個人 Claude Code QA workspace，感謝原版迭代過程中協作的工程師、測試夥伴與 AI 夥伴（Claude / Codex / Gemini）。
