# JIRA Integration Module

> 僅在 `config.mode != markdown-only` 且 atlassian MCP 可用時使用。

## 1. 查重（Phase 2）

```python
# 同 parent 下的 Bug
jql_1 = f'project = {JIRA_PROJECT_KEY} AND parent = {parent_key} AND issuetype = Bug ORDER BY created DESC'

# 全專案近期同關鍵字
jql_2 = f'project = {JIRA_PROJECT_KEY} AND summary ~ "{keyword}" AND status != Done ORDER BY created DESC'
```

呼叫：`mcp__atlassian__searchJiraIssuesUsingJql(jql=...)`

判讀規則：
- summary 與目前問題 cosine similarity > 0.8 → 視為相同，加 comment 到舊 ticket
- 0.5 < similarity < 0.8 → 視為類似，新 ticket 中 `## 參考資料` 列出舊 ticket
- < 0.5 → 直接新建

## 2. 建立 Ticket（Phase 4）

```python
mcp__atlassian__createJiraIssue(
    projectKey="{{JIRA_PROJECT_KEY}}",
    issueType={"id": "{{JIRA_BUG_ISSUE_TYPE_ID}}"},
    summary=rider["bug_summary"],
    description=render_rider_description(rider),
    priority=PRIORITY_MAPPING[rider["severity"]],
    customFields={
        "{{JIRA_REVIEWER_FIELD}}": "{{JIRA_REVIEWER_ACCOUNT_ID}}",
    },
    parent=parent_key,
)
```

> 若 `{{JIRA_REVIEWER_ACCOUNT_ID}}` 為空，省略 `customFields` 中的對應 entry。

## 3. 附件處理

JIRA MCP 不支援檔案上傳，走以下流程：

```python
# 1) 上傳到 Google Drive
file_url = mcp__google__uploadFileToDrive(
    file_path=local_path,
    folder_id="{{GDRIVE_QA_FOLDER_ID}}",
    name=f"{ticket_key}_{description}.{ext}",
)

# 2) 設為任何人可看
mcp__google__set_drive_file_permissions(file_id=..., link_sharing="reader")

# 3) Comment 貼連結
mcp__atlassian__addCommentToJiraIssue(
    issueKey=ticket_key,
    body=f"📎 附件：{file_url}",
)
```

## 4. 跨平台配對（auto_cross_platform_check = true）

若 iOS Bug 確認 Android 也有：
```python
android_ticket = create_ticket(platform="Android", ...)
mcp__atlassian__createIssueLink(
    inwardIssue=ios_ticket,
    outwardIssue=android_ticket,
    type="Relates",
)
```

## 5. 錯誤處理

| 錯誤 | 處理 |
|------|------|
| MCP 不可用 | 降級到 `modules/markdown-fallback.md` |
| 401 / 403 | 提醒使用者重新驗證 atlassian MCP |
| 欄位 ID 錯誤 | 用 `getJiraIssueTypeMetaWithFields` 重抓 |
| Rate limit | exponential backoff (1s, 2s, 4s, max 3 次) |
