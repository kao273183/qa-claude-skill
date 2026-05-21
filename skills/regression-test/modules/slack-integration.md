# Slack Integration Module

> 僅在 `config.mode != markdown-only` 且 slack MCP 可用時使用。

## 通知規則來源

從 `config.json` 讀取：
```json
{
  "slack": {
    "user_id": "{{SLACK_USER_ID}}",
    "bug_channel_id": "{{SLACK_BUG_CHANNEL_ID}}",
    "notification_rules": {
      "bug_report": ["dm", "channel"]
    }
  }
}
```

## 發送邏輯

```python
rules = config["slack"]["notification_rules"]["bug_report"]

if "dm" in rules and SLACK_USER_ID:
    send_dm(SLACK_USER_ID, message)

if "channel" in rules and SLACK_BUG_CHANNEL_ID:
    send_channel(SLACK_BUG_CHANNEL_ID, message)
```

## 訊息模板

### DM 模板

```
🐛 新 Bug Ticket 已建立

[<{{JIRA_INSTANCE_URL}}/browse/{ticket_key}|{ticket_key}>] {summary}

• 嚴重度：{severity} ({jira_priority})
• 平台：{platform}
• 環境：{environment}
• 報告者：<@{SLACK_USER_ID}>

Root Cause 摘要：
{root_cause_summary}

請追蹤後續修復狀態。
```

### Channel 模板

```
🐛 *新 Bug Ticket*

<{{JIRA_INSTANCE_URL}}/browse/{ticket_key}|{ticket_key}> {summary}

| 嚴重度 | 平台 | 影響範圍 |
|--------|------|---------|
| {severity} | {platform} | {impact} |

cc <@{SLACK_USER_ID}>
```

## 批次模式（從 Sheet 來的多個 Bug）

只在最後發 1 次彙總通知：

```
📊 Bug 批次處理完成

來源 Sheet：{sheet_url}
新建：{new_count} | 跳過（已有 ticket）：{skipped_count}

新建 Tickets：
1. <{{JIRA_INSTANCE_URL}}/browse/{key1}|{key1}> - {title1}
2. <{{JIRA_INSTANCE_URL}}/browse/{key2}|{key2}> - {title2}
...
```

## 缺值降級

| 缺漏 | 行為 |
|------|------|
| `SLACK_USER_ID` 空 | DM 跳過 |
| `SLACK_BUG_CHANNEL_ID` 空 | Channel 跳過 |
| 兩個都空 | 完全跳過 Slack，僅本地輸出 Markdown 摘要 |
| `notification_rules.bug_report = []` | 完全跳過（即使 ID 有設） |
