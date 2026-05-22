# Markdown Fallback Module (test-master)

> 當以下任一條件成立時走此模組：
> - `config.mode = markdown-only`
> - google MCP 不可用或回傳錯誤
> - 使用者明確要求「不要建 Google Sheet」

## 輸出位置

`.claude/testing/features/{feature-name}/`

## 檔案組

```
.claude/testing/features/{feature-name}/
├── test-strategy.md
├── test-cases-blackbox.md       ← 取代 Google Sheet
├── test-cases-whitebox.md       ← 取代 Google Sheet
├── coverage-gaps.md
├── automation-plan.md
├── exploratory-guide.md
└── INDEX.md                     ← 此 feature 的入口
```

## test-cases-{type}.md 結構（取代 Sheet）

每個檔案頭部 frontmatter + 一個 Markdown 表格：

```markdown
---
feature: {feature-name}
type: blackbox | whitebox
generated_at: {ISO8601}
total: {N}
priority_breakdown:
  P0: {n}
  P1: {n}
  P2: {n}
platform_breakdown:
  iOS: {n}
  Android: {n}
  Both: {n}
---

# 測試用例 — {feature} ({type})

| ID | Phase | 結果 | 結論 | 標題 | 分類 | 優先度 | 平台 | 前置條件 | 步驟 | 預期結果 | 自動化 | 備註 | JIRA |
|----|-------|------|------|------|------|--------|------|---------|------|---------|--------|------|------|
| BB-XXX-001 | Feature Done | | | ... | 冒煙-Feature Done | P0 | Both | ... | ... | ... | Y | | |
```

## 與 Sheet 模式的等價性

| Sheet 操作 | Markdown 等價 |
|-----------|--------------|
| 複製模板 | 用內建表格頭建檔 |
| 寫入 TC | 追加表格列 |
| 上傳 QA-TC 資料夾 | 寫入 `.claude/testing/features/{name}/` |
| Status sheet 統計 | frontmatter `priority_breakdown` / `platform_breakdown` |
| HYPERLINK JIRA | 純文字 ticket key（無連結） |

## INDEX.md 模板

每次產出時更新 `.claude/testing/features/INDEX.md`：

```markdown
# Test Plans Index

| Feature | Created | Cases (BB/WB) | Status |
|---------|---------|---------------|--------|
| profile-edit | 2026-05-21 | 32/12 | draft |
| brand-calendar | 2026-05-15 | 28/8 | reviewed |
```

## 與後續流程的銜接

1. **手動轉 Google Sheet**：未來若啟用 full-mcp，可用 `test-master --import .claude/testing/features/{name}/` 重跑批次上傳
2. **PR 描述**：直接把 strategy / coverage-gaps 內容貼到 PR
3. **Review**：對 markdown 表格走 `test-review` skill 同樣可用
