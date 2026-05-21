---
name: sheet-md-sync
description: TC Google Sheet ↔ 本地 markdown 雙向同步。把 Sheet 轉成可進 repo 的 markdown（給 git diff / version control / PR review），或把本地草稿 markdown 上 Sheet（首次發布）。當使用者提到「Sheet 變 md / md 上 Sheet / TC 進 repo / commit 到 git / 對齊 sheet 跟 markdown / sync sheet」時觸發。配套：speckit-to-tc（產生 md 草稿）、tc-to-pytest（從 md/sheet 同步 pytest）、tc-version-diff（兩版本對比）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__readSpreadsheet, mcp__google__getSpreadsheetInfo, mcp__google__writeSpreadsheet, mcp__google__copyFile, mcp__google__moveFile
argument-hint: "[Sheet URL 或本地 md 路徑] [--to-md | --to-sheet | --sync]"
---

# sheet-md-sync

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。
> 啟用條件：`mode != markdown-only`（此 skill 本身就是 Sheet ↔ md 同步，markdown-only 下無意義）。

## 為什麼要這個 skill

TC source-of-truth 通常在 Google Sheet，但：

- Sheet 沒 git diff / 沒 PR review / 沒 history line
- repo 內 markdown 才能進 PR、跟 `spec.md` / `api.md` 一起 review
- 兩邊不同步 → spec ↔ TC 對不上

→ **本 skill 解決雙邊同步**，不取代任何一邊。

## 適用場景

- ✅ Sheet 上 finalize 了，想 commit 一份 md 進 repo（Sheet → md）
- ✅ 本地草稿（`speckit-to-tc` 產出的 `tc-be-XXX-draft.md`）想正式上 Sheet（md → Sheet）
- ✅ 例行同步：Sheet 跟 md 比對，找差異
- ✅ Sprint review 後想看「Sheet 改了什麼但 md 還沒同步」

## 不適用場景

- ❌ 只是想看 Sheet 內容 → 直接打開 Sheet
- ❌ Sheet 跟 md 都還在劇變中 → 等任一邊 freeze 再同步
- ❌ 想 diff 兩個 Sheet 版本 → 用 `tc-version-diff`，不是這個

## Phase 1: 取輸入 + 判斷方向

| Argument 類型 | 預設方向 |
|--------------|---------|
| Sheet URL only | `--to-md`（拉下來成 md） |
| md path only | `--to-sheet`（推上 Sheet；要先確認是新建還是更新） |
| 兩者都給 | `--sync`（雙向比對） |
| `--to-md` 強制 | Sheet → md，覆蓋本地 |
| `--to-sheet` 強制 | md → Sheet，覆蓋雲端（**問使用者確認**） |
| `--sync` | 顯示 diff，讓使用者決議 |

預設**不破壞性**：對齊衝突時優先停下來問。

## Phase 2: 取兩邊資料

### 從 Sheet 讀

使用 google MCP `readSpreadsheet`：
```python
mcp__google__readSpreadsheet(
    spreadsheetId="<ID>",
    range="Test Cases (Black-box)!A1:N200",
)
```

### 從本地 md 讀

Read `tc-{feature}-{phase}.md`（如 `tc-web-phase1.md`），抽出：
- frontmatter metadata
- `## Black-box (BB)` 段的 markdown table
- `## White-box (WB)` 段的 markdown table

兩段 table 對齊 14 欄結構（與 `config.test_case_format.columns` 一致）。

## Phase 3: 同步規則

### Sheet → md

寫到 repo 的對應 `<feature>/tc-<phase>.md`（依 `tc-index.md` 命名規則）：

```markdown
---
sheet_url: https://docs.google.com/spreadsheets/d/.../edit
sheet_id: 1bChwq...
last_synced: 2026-MM-DD HH:MM
synced_by: sheet-md-sync skill
direction: sheet → md
sheet_revision: <Drive revision id>
---

# {{JIRA_PROJECT_KEY}}-XXXX 健康 Phase 1 TC（Sheet 鏡像）

> **這份是 Sheet 的鏡像**，source of truth 在 Sheet。修改請直接動 Sheet 後重 sync。
> 對應 spec：`peace/health/spec.md`
> 對應 pytest：`{{PYTEST_PROJECT_ROOT}}/tests/test_health_api.py`

## Black-box (BB) — 90 條

| ID | Phase | 結果 | 結論 | 標題 | 分類 | 優先度 | 平台 | 前置 | 步驟 | 預期 | 自動化 | 備註 | JIRA |
|----|-------|------|------|------|------|--------|------|------|------|------|--------|------|------|
| BB-HEALTH-001 | Feature Done | Pass | | 步數讀取（iOS HealthKit）| 冒煙-F1 | P0 | iOS | ... | ... | ... | Y | ... | |
...

## White-box (WB) — 43 條

...

## Status sheet 摘要
...
```

放在 repo 內依 `tc-index.md` 規範路徑。

### md → Sheet

兩種子情境：

**a. Sheet 還沒建（首次發布）**：
1. 用 google MCP `copyFile` 從模板複製：模板 ID = `{{GSHEET_TC_TEMPLATE_ID}}`
2. 改名「`<Epic>` `<功能>` Phase X TC」
3. 移到對應 team folder（從 `config.jira.boards[].drive_folder_id` 取，或預設 `{{GDRIVE_QA_FOLDER_ID}}`）
4. 把 md table 內容用 `writeSpreadsheet` 寫進 BB / WB 兩 sheet
5. status sheet 寫 metadata（測試版本 / 日期 / 測試人員）
6. 在 md frontmatter 補上 `sheet_url`

**b. Sheet 已存在（更新）**：
1. 比對：Sheet ID set vs md ID set
2. 列出新增 / 移除 / 修改 row
3. **必停下來問使用者確認**才執行（避免覆蓋雲端）
4. 用 `writeSpreadsheet` 只動變化 row
5. status sheet 加一筆「sheet-md-sync」紀錄

### --sync（雙向比對）

不寫任何邊，產一份 diff report：

```markdown
# sheet-md-sync diff · 2026-MM-DD HH:MM

| 比較項目 | Sheet | md |
|---------|-------|-----|
| 最後修改 | 2026-MM-DD HH:MM (Sheet revision rX) | 2026-MM-DD HH:MM (git commit abcXXX) |
| BB 條數 | 90 | 79 |
| WB 條數 | 43 | 33 |

## ⚠️ Sheet 比 md 新（11 條 BB / 10 條 WB）
建議：跑 `/sheet-md-sync <md path> --to-md`

## 🆕 md 比 Sheet 新（2 條 BB）
- BB-HEALTH-XXX 待加入 Sheet

## 衝突（同 ID 但內容不同）
- BB-HEALTH-012 預期結果欄不同
  Sheet: "200 + schema XXX"
  md:    "應該成功"
  → 看哪邊比較新，決定方向
```

## Phase 4: tc-index.md 自動更新

每次 sync 完，更新 repo 根的 `tc-index.md`（若存在）：
- 對應 row 的「狀態」欄改 🟢 已上 Sheet
- 「Drive 連結」欄補上 Sheet URL
- 加 `last_synced` 時間戳

## Phase 5: 通知

依 `slack.notification_rules.sheet_md_sync`（若未定義則跳過）：

```
🔄 *sheet-md-sync · {feature}*
Sheet → md：拉下 +N row，更新 K row
md → Sheet：上推 J row（已確認）
路徑：`<feature>/tc-phase1.md`
```

## ⚠️ 安全護欄

- ✅ 只動 `tc-{feature}-{phase}.md` + `tc-index.md`
- ✅ `md → Sheet` **必先互動確認**才動
- ✅ md 是 Sheet 鏡像時，frontmatter 寫明 source of truth 在 Sheet
- ❌ 不主動 commit / push（讓使用者控制）
- ❌ 不動 Sheet 的 status 分頁的「審查紀錄」（那是 `test-review` 管的）
- ❌ Sheet 跟 md 衝突時**不自動決議**，停下問使用者

## 配套整合

```
spec ticket close
   ↓ /speckit-to-tc
tc-be-{key}-draft.md
   ↓ review + 補完
finalize draft
   ↓ /sheet-md-sync <draft.md> --to-sheet
正式上 Sheet
   ↓ Sprint 跑、發現缺
   ↓ /test-master --mode=quick 補新 TC（直接動 Sheet）
   ↓ /sheet-md-sync <sheet> --to-md
md mirror 同步
   ↓ git commit + PR
版本控管
```

兩邊永遠對齊：
- **Sheet** = source of truth（QA 日常工作場）
- **md** = git diff 用（PR review / 跟 `spec.md` 對齊）

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `google.tc_template_id` | 首次建 Sheet 的模板 | `createSpreadsheet` 從零 |
| `google.qa_tc_folder_id` | 預設 team folder | 互動式詢問 |
| `jira.boards[].drive_folder_id` | 各 team 專屬 folder | 用 `qa_tc_folder_id` |
| `mode = markdown-only` | 全程模式 | **此 skill 不啟用** |

## 範例

詳見 [`examples.md`](./examples.md)
