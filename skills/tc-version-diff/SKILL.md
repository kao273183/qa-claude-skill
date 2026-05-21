---
name: tc-version-diff
description: 比對兩個 TC 版本（v0.x → v0.y）的差異，產 changelog + 補測清單 + 自動更新 status sheet 的審查紀錄。當使用者提到「TC 版本 diff / TC 升版 / 比對 v0.2 v0.3 / 哪些 TC 要重跑 / 補測清單」，或剛 review 完一份 TC 升版本（看到「v0.3 補 8 條」這種訊息）時觸發。配套：test-review（升版前審）、test-master（升版時擴張）、tc-to-pytest（API TC 升版同步 pytest）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__readSpreadsheet, mcp__google__getSpreadsheetInfo, mcp__google__writeSpreadsheet
argument-hint: "[v_old Sheet/檔] [v_new Sheet/檔] / 或單一 Sheet（自動從 status sheet 找最近兩版）"
---

# tc-version-diff

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。
> 若 `mode = markdown-only`，跳過 Sheet 操作，純比對兩個 markdown 檔。

## 適用場景

- ✅ TC 從 v0.2 升 v0.3，要產 changelog
- ✅ Sprint review 後規格變動，TC 要回頭比對影響哪些 row
- ✅ Release 前確認「上次回歸後新增/改動的 TC 有沒有都 cover」
- ✅ Sheet status 分頁的「審查紀錄」區塊要自動寫入版本對照

## 不適用場景

- ❌ 完全新版（v0.1 first draft）→ 沒前一版可比，用 `test-master` 從零生
- ❌ 跨功能模組大重組 → 用 `test-master` 升級流程
- ❌ 純文字錯字修 → 不需要這個 skill，直接改

## Phase 1: 取兩版來源

| 輸入 | 動作 |
|------|------|
| 兩個 Sheet URL | 都用 google MCP `readSpreadsheet` 抓 |
| 兩個 markdown 檔 | Read 兩份 |
| 單一 Sheet → 自動找前一版 | 從 status 分頁的「審查紀錄」表撈最近兩個 row 的「測試版本」欄 |
| 單一模組名 + 版本號 | 從 `tc-index.md`（若存在）找 Sheet → Drive revision API 抓兩個快照 |

> Drive revision 抓法依 google MCP 版本而定；如無，互動式請使用者提供 export 的兩個檔。

## Phase 2: 建立 ID-key 對照

從兩版各抽出所有 TC row，建 dict：`{id: row_data}`。
忽略空行、status 分頁。
分 BB / WB 兩個 sheet 分別處理。

## Phase 3: 分類差異

| 類型 | 判斷 | 影響 |
|------|------|------|
| 🆕 **Added** | id 在 v_new 但不在 v_old | 補測必跑 |
| 🗑️ **Removed** | id 在 v_old 但不在 v_new | 看是否真的不需要了，還是被改 ID |
| ✏️ **Modified** | id 同但內容變 | 看哪欄變決定影響 |
| ✅ **Unchanged** | 完全相同 | 已測過免重測 |

**Modified 細分**（依「哪欄變」歸類）：

| 變動欄 | 影響等級 | 補測決策 |
|--------|---------|---------|
| 標題 / 備註 | 🟢 低 | 不需重測，僅文字 |
| 步驟 J | 🟡 中 | 重測（步驟變了） |
| **預期結果 K** | 🔴 高 | **必重測**（驗收標準變了） |
| 優先度 G | 🟡 中 | P 升級 → 必跑；P 降級 → 可緩 |
| 自動化 L | 🟢 低 | 標 N→Y 不影響跑；標 Y→N 看為什麼 |
| 平台 H | 🔴 高 | 平台拓寬要補跑新平台 |
| 分類 F | 🟡 中 | 分類重歸位通常不影響跑 |
| 前置 I | 🟡 中 | 前置變了要驗環境 |

## Phase 4: 產 changelog

寫到 `<repo>/<feature>/tc-changelog-v{old}-v{new}.md`：

```markdown
# TC Changelog · {feature} v0.2 → v0.3

**生成日期**：2026-MM-DD
**對比基準**：BB v0.2 (79 條 / WB v0.2 33 條) → BB v0.3 (90 條 / WB v0.3 43 條)
**淨變動**：+11 BB / +10 WB / 修改 X / 移除 0

## 🆕 Added（補測必跑）

### Black-box (+11)
- BB-{FEATURE}-086 相容：iOS 16 [P1] [iOS]
- BB-{FEATURE}-087 相容：iOS 17 [P1] [iOS]
...

### White-box (+8)
- WB-{FEATURE}-035 步數 sync 未授權 401 防偽 [P0] [Both]
...

## ✏️ Modified（依影響等級）

### 🔴 高影響（**必重測**）
- BB-{FEATURE}-012：預期結果改（從「應該成功」→「200 + schema XXX」）
  - 改動原因：補強斷言（v0.2 review 找到 Critical#3）

### 🟡 中影響
- BB-{FEATURE}-023：步驟 J 改

### 🟢 低影響
- WB-{FEATURE}-005：標題微調

## 🗑️ Removed（0）

無移除。

## 📋 補測清單

| ID | 優先度 | 平台 | 估時 | 自動化 |
|----|-------|------|------|--------|
| BB-{FEATURE}-086 | P1 | iOS | 30 min | N |
| WB-{FEATURE}-035 | P0 | Both | 10 min | Y (pytest) |
...

**總估時**：M 人時（手動）+ K 自動化（CI 跑）

## 🔗 對應 pytest（如有）

如果 WB Modified / Added 有自動化，列出 pytest function 名：
- WB-{FEATURE}-035 → `tests/test_{feature}_api.py::test_steps_sync_unauth_rejected`

→ 跑 `{FEATURE}_API_LIVE=1 pytest -k "test_steps_sync_unauth_rejected or ..."`
```

## Phase 5: 自動寫 status sheet 審查紀錄

> 僅在 `mode != markdown-only` 且 google MCP 可用時執行。

如果輸入是 Sheet（不是純 markdown），呼叫 google MCP 寫入 status 分頁的「審查紀錄」表：

```
2026-MM-DD | tc-version-diff | — | — | — | — | v0.2 → v0.3 升版：+11 BB / +10 WB / Modified X / 補測 N 條
```

對應 status sheet 的「綜合評分」欄不動（這不是審查，是版本對照）。

## Phase 6: Slack 通知

依 `slack.notification_rules.tc_version_diff`（若未定義則跳過）：

```
:arrows_counterclockwise: *TC 升版 {feature} v0.2 → v0.3*
:new: +N · :memo: M Modified · :wastebasket: 0 Removed
:exclamation: *補測必跑*：N 條（含 P0 X 條）
:link: changelog: <local path>
```

## ⚠️ 安全護欄

- ✅ 只 Write `tc-changelog-*.md`（純 documentation）
- ✅ 寫 Sheet 限於 status 分頁的「審查紀錄」追加 row
- ❌ 不動 BB / WB 主分頁
- ❌ 不主動跑補測（使用者看 changelog 後決定）
- ❌ 不動 pytest 程式碼（要動用 `tc-to-pytest --incremental`）

## 配套整合

完整 升版 workflow：

```
1. spec 變動 / TC review 找到缺口
   ↓
2. test-master --mode=quick 補新 TC（v0.2 → v0.3）
   ↓
3. /test-review 跑審查（v0.3 自評）
   ↓
4. /tc-version-diff v0.2 v0.3 ← 本 skill
   ↓
5. /tc-to-pytest --incremental 同步 pytest 三件套
   ↓
6. 跑補測清單 + pytest，回填結果
   ↓
7. status sheet 自動更新（含本 skill 寫的版本紀錄）
```

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `mode = markdown-only` | 全程模式 | 只比對 .md，不寫 Sheet |
| `slack.notification_rules.tc_version_diff` | 通知設定 | 不發 Slack |

## 範例

詳見 [`examples.md`](./examples.md)
