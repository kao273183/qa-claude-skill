# 安裝指南

## 系統需求

- macOS / Linux（Windows 可用 WSL）
- `bash` ≥ 4.0
- `jq` ≥ 1.6（macOS 內建已足；Linux 用 `apt install jq`）
- Claude Code CLI

## 三步驟安裝

### 1. 複製 config 範本

```bash
cd ~/Desktop/QA_Claude_Skill
cp config/config.example.json config/config.json
```

### 2. 編輯 config

最少填這 4 個欄位：

```json
{
  "jira": {
    "instance_url": "https://your-company.atlassian.net",
    "project_key": "YOUR_PROJECT"
  },
  "platforms": {
    "ios": { "default_device": "iPhone 15 Pro", "default_os_version": "iOS 17.5" },
    "android": { "default_device": "Pixel 8", "default_os_version": "Android 14" }
  }
}
```

詳細欄位說明見 [`docs/customization-guide.md`](./docs/customization-guide.md)。

### 3. 跑安裝

```bash
./install.sh
```

腳本會：
- 渲染 `{{變數}}` 替換成你 config.json 的值
- 把 `skills/*` 複製到 `~/.claude/skills/`
- 備份既有同名 skill 到 `~/.claude/skills.backup-{時間戳}/`
- 警告未填寫的選填欄位（對應功能會降級）

## 驗證

```bash
# Dry-run（不動 ~/.claude）：
CLAUDE_SKILLS_DIR=/tmp/preview ./install.sh
ls /tmp/preview/   # 應該有 15 個 skill 資料夾
```

在 Claude Code 中：
```
/test-master "假設一個新功能：使用者編輯個人資料"
```

如果 skill 載入正常，會開始引導你建立測試計劃。

## 還原

如果有問題：

```bash
./uninstall.sh
```

會：
- 移除已安裝的 15 個 skill
- 可選還原最新一次 backup

## 進階情境

### 想預覽通用版會渲染成什麼樣

```bash
CLAUDE_SKILLS_DIR=/tmp/preview ./install.sh
open /tmp/preview/test-master/SKILL.md
```

### 想用既有 preset 而非自寫 config

```bash
# 工具棧 presets
cp config/presets/full-stack.json     config/config.json   # 大團隊（JIRA + Slack + Google）
cp config/presets/jira-only.json      config/config.json   # 只 JIRA
cp config/presets/markdown-only.json  config/config.json   # 純文件

# 場景 presets (v1.1.0+)
cp config/presets/startup.json        config/config.json   # 新創團隊 < 10 人
cp config/presets/enterprise.json     config/config.json   # 大型企業 + 5 個 team boards
cp config/presets/government.json     config/config.json   # 政府 / 高合規 / on-prem
```

然後再填入專屬 ID 即可。

### 校驗 config（不安裝）

```bash
./scripts/validate-config.sh                              # 驗 config/config.json
./scripts/validate-config.sh config/presets/startup.json  # 驗指定檔案
```

校驗器會檢查：
- JSON syntax
- 必填欄位
- Enum 值（mode / default_drive / language.primary / report_pipeline.type）
- Pattern 規則（project_key 全大寫 / reviewer_field 是 customfield_NNNNN / URL 格式）
- Mode 一致性（markdown-only 應無 IDs / full-mcp 應有 IDs）
- 跨欄位依賴（mutation 需要 pytest / publish s3_cloudfront 需要 bucket）
- 選填但建議的欄位

### 我已經用過個人版（含 UOP 等硬編碼），怎麼遷移？

見 [`docs/migration-from-personal.md`](./docs/migration-from-personal.md)。

## 疑難排解

| 症狀 | 處理 |
|------|------|
| `jq: command not found` | `brew install jq` |
| `Missing required field` | 至少填 `jira.instance_url` / `jira.project_key` / `platforms.ios.default_device` / `platforms.android.default_device` |
| skills 沒出現在 Claude Code | 重啟 Claude Code 或 `/clear` |
| `{{變數}}` 沒被替換 | 確認 `config.json` 對應路徑有值，再重跑 `./install.sh` |
| 覆蓋了我重要的 skill 怎麼辦 | 看 `~/.claude/skills.backup-{時間戳}/`，可手動還原或跑 `./uninstall.sh` |
