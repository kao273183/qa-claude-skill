---
name: speckit-to-tc
description: 從 GitHub Spec Kit / SDD 規格文件（Jira ticket description / spec.md / api.md）一鍵草擬 BB+WB TC markdown 草稿，套 14 欄結構，自動歸位到指定 repo 對應目錄。當使用者提到「speckit close 了寫 TC / 從 spec 草 TC / 把這張規格 ticket 變 TC / draft TC from this spec」，或在 Jira 偵測到「speckit 規格制定」ticket close 時觸發。配套：test-review（審草稿）、test-master（深度設計）、tc-to-pytest（草稿 → pytest 三件套）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__atlassian__getJiraIssue
argument-hint: "[JIRA 票號 / spec 檔路徑 / ticket URL]"
---

# speckit-to-tc

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。
> 啟用條件：`config.speckit.enabled = true`。

## 適用場景

- ✅ Jira 上一個「spec 規格制定」ticket 剛 close
- ✅ 使用者手上有一份 `spec.md` / `api.md`，想快速產第一稿 TC
- ✅ 從規格 docx / wireframe 提煉 description 後想轉 TC

## 不適用場景

- ❌ spec 仍未定稿（要等 ticket close / spec freeze 後才跑）
- ❌ 純自動化腳本生成 → 用 `test-automation`
- ❌ 已有完整 TC、想升級 → 用 `test-review` + `test-master`

## Phase 1: 取得 spec 來源

依 argument 類型判斷輸入：

| 輸入 | 動作 |
|------|------|
| Jira 票號（如 `{{JIRA_PROJECT_KEY}}-XXXX`）| 用 `mcp__atlassian__getJiraIssue` 或 curl + Atlassian PAT 抓 description |
| 本地 spec 檔（如 `<repo>/feature/spec.md`）| 用 Read 直接讀 |
| ticket URL | 從 URL 抽 key 然後同上 |
| 沒給 → 互動式詢問 | 「請給我 ticket key / spec 檔路徑 / 直接貼 spec 內容」 |

**抓 Jira description 的標準 curl**：
```bash
curl -s -G "{{JIRA_INSTANCE_URL}}/rest/api/3/issue/<KEY>" \
  --data-urlencode "fields=summary,description,parent,status,assignee,attachment" \
  -u "$ATLASSIAN_EMAIL:$ATLASSIAN_TOKEN" \
  -H "Accept: application/json"
```

**處理 ADF 格式 description**：Atlassian description 通常是 Atlassian Document Format JSON。先轉成 markdown／plain text 再給後續分析。簡易處理：遞迴拉 `text` 欄位。

## Phase 2: 功能歸位（決定輸出路徑）

從 `config.speckit.feature_routing` 讀路徑對應規則：

```json
{
  "speckit": {
    "enabled": true,
    "repo_root": "~/Desktop/your-spec-repo",
    "feature_routing": [
      { "keywords": ["集章", "stamp", "NFC"], "path": "love/stamp/", "epic": "{{JIRA_PROJECT_KEY}}-XXXX" },
      { "keywords": ["健康", "步數", "health", "HealthKit"], "path": "peace/health/", "epic": "{{JIRA_PROJECT_KEY}}-YYYY" },
      { "keywords": ["錢包", "wallet", "payment"], "path": "love/wallet/", "epic": "{{JIRA_PROJECT_KEY}}-ZZZZ" }
    ],
    "fallback": "ask_user"
  }
}
```

依 summary / description 關鍵字 match `feature_routing[].keywords`，決定 `<repo_root>/<path>` 為輸出目錄；都不 match → 跳出問使用者。

**檔案命名**：`tc-be-{KEY}-draft.md`（如 `tc-be-{{JIRA_PROJECT_KEY}}-1234-draft.md`）
**狀態 metadata**：`Draft v0.1 — pending review`

## Phase 3: 讀既有上下文（Cross-reference）

**必讀（如存在）**：
- 同目錄 `spec.md`（產品規格）
- 同目錄 `api.md`（API 契約）
- repo 根 `tc-index.md`（命名規則 + Drive folder + 既有 TC）
- 同目錄已上 Sheet 的 TC markdown

讀完之後應該知道：
- 這個 ticket 對應哪個功能模組
- 既有 spec / api 已涵蓋什麼
- 之前該團 TC 用過什麼 ID 命名規則
- 該團是 Web / Native / Flutter / BE-only？

## Phase 4: 草擬 TC

### 結構（14 欄 A-N，跟通用模板對齊）

| 欄 | 名稱 | 範例值 |
|---|------|--------|
| A | ID | `BB-{FEATURE}-001` / `WB-{FEATURE}-W001` |
| B | Phase | `Feature Done` |
| C | 測試結果 | `Not Run` |
| D | 測試結論 | (留空) |
| E | 測試標題 | 「批次上傳 PNG 檔名對應 ID 成功」 |
| F | 測試分類 | 9 種黑箱 / 6 種白箱（見下） |
| G | 優先度 | P0 / P1 / P2 |
| H | 平台 | Web / iOS / Android / Both / BE-only |
| I | 前置條件 | 「CMS 已登入；批次包 ZIP < 10MB」 |
| J | 步驟 | 編號列點 |
| K | 預期結果 | **可驗證**，不能寫「應該正確」 |
| L | 自動化建議 | Y / N + 工具 |
| M | 備註 | 對應 spec 章節 / pytest test_name |
| N | 留空 | (Sheet 用) |

### 黑箱分類（9 種，每類 N 條依風險評估）

1. **冒煙-Feature Done**：F1/F2/F3/F4 四階段 smoke
2. **功能測試**：happy path / 變體
3. **異常/邊界測試**：空值 / 超長 / 特殊字元 / 大檔
4. **錯誤處理**：401 / 403 / 500 / 網路斷
5. **生命週期**：背景前景切換 / 殺 App / 殺 process
6. **跨平台 / 相容性**：OS 版本 / 機型 / 主流瀏覽器
7. **端對端**：跨模組整合
8. **效能（黑箱角度）**：使用者感知（loading 不過 N 秒）
9. **a11y**：字級放大 / VoiceOver / TalkBack / 對比 / 觸控目標 / Reduce Motion

### 白箱分類（6 種）

1. **API 驗證**：endpoint / status code / schema / 邊界
2. **效能基準**：cold start / TTFB / 60fps
3. **安全**：未授權 / token 偽造 / SQL inject / XSS
4. **記憶體**：leak / OOM / image cache 上限
5. **並發**：race condition / TSAN / Isolate 安全
6. **內部狀態**：狀態機 / 快取一致性

### a11y 強制 4 條（每份 TC 都要）

> 若 `config.workflow.auto_a11y_pairing = true` 才強制。

- 字級放大 iOS（Dynamic Type 最大）
- 字級放大 Android（fontScale 最大）
- VoiceOver / TalkBack 讀取順序
- 觸控目標 ≥ 44×44 pt / 48×48 dp + 對比度

### BE-only 功能特化

如果 ticket 是 BE API（如「[BE][CMS] 基礎 API」），白箱占比拉高：
- BB 30% / WB 70%
- 平台欄全 `BE-only`
- 自動化建議全 `Y`（套 pytest-api-kit）
- 對齊 `tc-to-pytest` skill

## Phase 5: 寫檔

1. 寫到 `tc-be-{KEY}-draft.md`，放對應目錄（依 `feature_routing` 決定）
2. 開頭 metadata block：

```markdown
---
ticket: {{JIRA_PROJECT_KEY}}-XXXX
spec_source: <repo>/feature/spec.md (§3 入口頁)
draft_version: v0.1
draft_date: 2026-MM-DD
status: pending review
output_target: Google Sheet（待人工搬上去）或 mode=markdown-only 下保留 .md
generated_by: speckit-to-tc skill
---
```

3. 兩段：`## Black-box (BB)` + `## White-box (WB)`，每條 TC 用 markdown table
4. 最後一段 `## 設計依據` 列出參考的 spec 章節

## Phase 6: 後續建議（stdout 印給使用者）

```
✅ 草擬完成 → tc-be-{{JIRA_PROJECT_KEY}}-XXXX-draft.md
- BB N 條（其中 a11y N 條）
- WB N 條（其中 BE API 驗證 N 條）
- 主要 cover：[列 3-5 個 highlight]
- 未 cover / 不確定：[列 spec 沒講清楚的議題]

下一步建議：
1. 你 review 草稿（uncovered 議題回 PM 釐清）
2. 跑 test-review 對草稿打分（找 critical/major 缺口）
3. 通過後人工搬到 Google Sheet（命名照 tc-index.md 規範）
4. 對應 BE API 部分跑 tc-to-pytest
```

## ⚠️ 安全護欄

- ✅ 只 Write 到 `tc-be-{KEY}-draft.md`，**不動其他檔**
- ❌ 不主動上 Google Sheet（draft only，使用者手動搬，或啟用 `sheet-md-sync` 自動同步）
- ❌ 不主動 commit / push（draft 留著等 review）
- ❌ 不要編造 spec 沒寫的功能（uncovered 就標 uncovered）
- ⚠️ ADF 解析失敗時 fallback to plain text 而不是亂猜

## 配套整合

- 跑完後使用者通常會手動跑 `test-review`（自動）或 `test-master --mode=deep`（升級）
- 要把草稿正式上 Sheet → 用 `sheet-md-sync` skill（如已建）
- BE API 部分要轉 pytest → 用 `tc-to-pytest` skill

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `speckit.enabled` | 啟用此 skill | skill 不啟用 |
| `speckit.repo_root` | 草稿輸出 repo root | 互動式詢問 |
| `speckit.feature_routing` | 功能歸位規則 | fallback 詢問使用者 |
| `jira.instance_url` | 抓 Jira ticket | 改用 spec 檔路徑 |
| `workflow.auto_a11y_pairing` | a11y 強制 4 條 | 改為可選 |

## 範例

詳見 [`examples.md`](./examples.md)
