# Markdown Fallback Module

> 當以下任一條件成立時走此模組：
> - `config.mode = markdown-only`
> - atlassian MCP 不可用或回傳錯誤
> - 使用者明確要求「不要建 JIRA」

## 輸出位置

`./bugs/bug-{YYYY-MM-DD}-{slug}.md`

- `{slug}` = bug 標題的 kebab-case 前 5 個字
- 若目錄不存在 → 自動建立 `./bugs/`

## 檔案模板

```markdown
---
bug_id: BUG-{ISO8601-timestamp}
title: {Bug 標題}
severity: {Blocker|Critical|Major|Minor}
platform: {iOS|Android|Both}
environment: {Production|Staging|UAT}
status: open
created_at: {ISO8601}
created_by: {使用者，從 git config 或 $USER}
related_test_case: {TC-ID 若有}
suggested_priority: {Highest|High|Medium|Low}
---

# {Bug 標題}

## 重現步驟

**前置條件：**
{conditions}

**步驟：**
{numbered steps}

## 預期 vs 實際

**預期：**
{expected}

**實際：**
{actual}

## 環境

- 平台：{platform}
- 裝置：{device}
- OS 版本：{os_version}
- App 版本：{app_version}
- 環境：{environment}

## 影響範圍

- 嚴重度：{severity}
- 影響使用者：{user_scope}
- 影響功能：{features}

## Root Cause 分析

{rca_content}

## 附件

{attachments_list}

## 跨平台

另一平台是否重現：{cross_platform_status}

## 後續行動

- [ ] 此 .md 檔附到 PR 或 Email 給負責工程師
- [ ] 修復後執行 `test-master` 補充防護測試
- [ ] 若後續組織有導入 JIRA，可重跑此 skill 自動建單
```

## 索引檔

每次產出時更新 `./bugs/INDEX.md`：

```markdown
# Bug Reports Index

| Date | ID | Severity | Title | Status |
|------|----|----------|-------|--------|
| 2026-05-21 | BUG-... | Critical | 編輯個人資料時 App 當機 | open |
| 2026-05-20 | BUG-... | Major | 圖片載入失敗 | resolved |
```

## 與後續流程的銜接

1. **手動轉 JIRA**：未來若有 JIRA，可用 `bug-report --import ./bugs/{file}.md` 重跑批次建單
2. **批次 Email**：可用任何 markdown-to-email 工具寄出
3. **PR 描述**：直接複製內容貼到 PR description

## 跨平台 Pairing（即使在 markdown-only 模式）

若 `workflow.auto_cross_platform_check = true`：
- 產出兩個檔案：`bug-...-ios.md` 與 `bug-...-android.md`
- 在 frontmatter 用 `related_bug:` 互相 reference
