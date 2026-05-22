# Config Loader（執行前先讀此檔）

每個 Skill 啟動時必須先載入 `config.json`，把組織設定帶入後續流程。

## 載入順序

1. 嘗試讀 `$HOME/.claude/qa-skill-config.json`（全域設定）
2. 若不存在，嘗試讀當前 repo 根目錄的 `.qa-skill-config.json`
3. 都不存在 → fallback 到 `markdown-only` 模式

> 安裝腳本 `install.sh` 會在渲染 skill 時把 `{{變數}}` 直接替換成 `config.json` 中的值。本檔僅描述執行期再次校驗的邏輯。

## 必要欄位校驗

```python
required = [
    "jira.instance_url",
    "jira.project_key",
    "platforms.ios.default_device",
    "platforms.android.default_device",
]
```

若有任何欄位空字串 → 警告使用者「對應功能將降級」。

## 模式判定

| `config.mode` | 行為 |
|---------------|------|
| `full-mcp` | 全程使用 atlassian/slack/google MCP |
| `partial-mcp` | 每個 MCP 呼叫前 try/except，失敗則降級 |
| `markdown-only` | 完全不呼叫 MCP，所有輸出寫入本地 `.md` |

## 變數查詢表

執行期可參考的變數（已由 install.sh 渲染成實際值）：

| 變數 | 來源 | 範例 |
|------|------|------|
| `{{JIRA_PROJECT_KEY}}` | `jira.project_key` | `PROJ` |
| `{{JIRA_INSTANCE_URL}}` | `jira.instance_url` | `https://company.atlassian.net` |
| `{{JIRA_REVIEWER_ACCOUNT_ID}}` | `jira.reviewer_account_id` | `712020:abc...` |
| `{{JIRA_REVIEWER_FIELD}}` | `jira.reviewer_field` | `customfield_10045` |
| `{{JIRA_BUG_ISSUE_TYPE_ID}}` | `jira.bug_issue_type_id` | `10046` |
| `{{SLACK_USER_ID}}` | `slack.user_id` | `U0XXX` |
| `{{SLACK_BUG_CHANNEL_ID}}` | `slack.bug_channel_id` | `C0YYY` |
| `{{IOS_DEFAULT_DEVICE}}` | `platforms.ios.default_device` | `iPhone 15 Pro` |
| `{{IOS_DEFAULT_VERSION}}` | `platforms.ios.default_os_version` | `iOS 17.5` |
| `{{ANDROID_DEFAULT_DEVICE}}` | `platforms.android.default_device` | `Pixel 8` |
| `{{ANDROID_DEFAULT_VERSION}}` | `platforms.android.default_os_version` | `Android 14` |
| `{{IOS_REPO}}` | `platforms.ios.repo` | `org/ios-app` |
| `{{ANDROID_REPO}}` | `platforms.android.repo` | `org/android-app` |

## 缺值降級規則

| 缺漏的設定 | 降級行為 |
|-----------|---------|
| `jira.reviewer_account_id` | 建 ticket 時不設驗收者 |
| `slack.user_id` | 不發 DM、只發 channel |
| `slack.bug_channel_id` | 不發 channel、只發 DM |
| 兩個 Slack ID 都缺 | 完全跳過 Slack 通知 |
| `google.qa_tc_folder_id` | Sheet 批次模式不可用 |
| `platforms.ios.repo` | 跳過 iOS 版本→分支查找 |
| `platforms.android.repo` | 跳過 Android 版本→分支查找 |
