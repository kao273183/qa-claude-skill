---
name: test-review
description: 審查測試案例或測試程式碼的完整性、品質和有效性，確保符合資深測試工程師標準。支援審查黑箱/白箱測試用例（Google Sheet 或 Markdown）和測試程式碼（Swift / Kotlin / Dart / Python）。當使用者提到「審查測試」、「review 測試案例」、「檢查測試覆蓋」、「測試品質」、「test review」，或提供 Google Sheet 測試用例連結要求審查，或指定測試檔案要求 code review 時使用。即使使用者只是說「幫我看一下這些測試」或「這些 TC 有沒有問題」，也應觸發。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__readSpreadsheet, mcp__google__getSpreadsheetInfo, mcp__google__writeSpreadsheet
argument-hint: "[測試檔案路徑 或 Google Sheet URL 或 Markdown 路徑]"
---

# test-review

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**，載入組織設定。
> 若 `config.json` 不存在或 `mode = markdown-only`，跳過所有 google MCP 呼叫並走 [`modules/markdown-fallback.md`](./modules/markdown-fallback.md)。

## 審查類型自動偵測

| 輸入 | 審查類型 |
|------|---------|
| Google Sheet URL | 讀取 Sheet 名稱，自動判定黑箱/白箱/雙重審查 |
| 測試程式碼路徑（`.swift` / `.kt` / `.dart` / `.py`） | 測試程式碼審查 |
| Markdown 路徑（含測試表格） | Markdown TC 審查 |
| 無參數 | 互動式詢問審查類型 |

## 審查標準

### 黑箱測試案例審查

| 維度 | 檢查重點 |
|------|---------|
| **完整性 (30分)** | 冒煙 4 階段 + Happy Path + 邊界條件 + 錯誤處理 + 生命週期 + 跨平台 |
| **清晰性 (20分)** | 標題描述行為+預期、前置條件明確、步驟可執行、預期結果可驗證 |
| **可重現性 (15分)** | 步驟完整無遺漏、環境資訊齊全、測試數據明確 |
| **優先級 (15分)** | P0/P1/P2 分級合理、冒煙測試全為 P0 |
| **自動化策略 (20分)** | ROI 評估準確、Flaky 風險評估、維護成本考量 |

### 白箱測試案例審查

| 維度 | 檢查重點 |
|------|---------|
| **完整性 (30分)** | 6 分類覆蓋（效能/安全/記憶體/並發/API/內部狀態） |
| **工具標註 (20分)** | 工具明確（Instruments/Charles/TSAN）、設定步驟、驗證標準 |
| **可量化性 (15分)** | 效能基線/閾值、Pass/Fail 標準、重複執行次數 |
| **優先級 (15分)** | 安全性為 P0、記憶體 P0/P1 |
| **自動化策略 (20分)** | CI 整合方案、Mock Server、TSAN CI、記憶體自動化 |

### 測試程式碼審查

| 維度 | 檢查重點 |
|------|---------|
| **結構 (20分)** | AAA Pattern、單一職責、獨立性 |
| **命名 (15分)** | 描述行為+預期、一致性 |
| **Mock 策略 (20分)** | Protocol-based、合理範圍、不 over-mock |
| **斷言 (20分)** | 語意化、明確驗證具體值、錯誤訊息 |
| **可讀性 (15分)** | 易理解、註解適當 |
| **並發安全 (10分)** | Actor 使用、TSAN 兼容 |

程式碼 Good/Bad patterns 參考 [`code-patterns.md`](./code-patterns.md)（含 Swift、Kotlin、Dart、Python 範例）

## 輸出格式

生成審查報告到 `.claude/testing/reviews/`。報告模板見 [`report-templates.md`](./report-templates.md)。

報告包含：
- 總體評分（X/100）
- 優點清單
- 問題清單（Critical / Major / Minor）
- 覆蓋缺口分析
- 改進建議（立即/短期/長期）
- 風險評估矩陣
- 測試成熟度評估（Level 1-5）

## 執行流程

### Phase 0: 需求主題識別（最重要）
1. 從 Spreadsheet 標題（或 Markdown frontmatter `feature:`）提取**需求主題**
   - 範例：「會員系統 - 測試案例」→ 主題 = 會員系統
2. **整份審查必須以需求主題為中心**，不是以底層程式碼模組為中心
3. 覆蓋缺口分析 = 從需求功能出發（「會員系統還缺什麼場景？」），不是從程式碼檔案出發
4. 如果有相關 JIRA / 簡報 / PRD，優先用需求文件理解功能範圍
5. 程式碼只作為**輔助驗證**（確認 TC 的技術細節是否正確），不作為審查的主要框架

**禁止的模式：**
- ❌ 以程式碼檔案為維度做 Coverage Gap（如「LoginView.swift 0 TC」）
- ❌ 用程式碼內部命名替代需求描述（如「AuthError.tokenExpired」→ 應說「Token 過期場景」）
- ❌ 建議的新 TC 引用內部類別名/方法名（黑箱 TC 不應出現程式碼細節）

**正確的模式：**
- ✅ 以使用者功能為維度做 Coverage Gap（如「登入流程」「會員資料編輯」）
- ✅ 用需求語言描述缺口（如「缺少 Token 過期後的使用者體驗驗證」）
- ✅ 白箱 TC 可引用技術細節，但仍以功能模組分組（如「認證模組」而非「AuthRepository.swift」）

### Phase 1: 偵測輸入類型
- Google Sheet URL → 讀 Sheet 名稱
- 測試程式碼路徑 → 程式碼審查
- Markdown 路徑 → Markdown TC 審查
- 無參數 → 互動式詢問

### Phase 2: 讀取並理解需求範圍
- 讀取 Sheet/檔案 標題和所有 TC
- 從 TC 內容歸納出功能模組清單（使用者視角）
- 可選：搜尋相關程式碼（`{{IOS_REPO}}` / `{{ANDROID_REPO}}`）作為輔助驗證

### Phase 3: 依審查標準逐項評分

### Phase 4: 生成審查報告
- 覆蓋缺口以**功能模組**分組（非程式碼檔案）
- 改進建議用需求語言描述

### Phase 5: 回寫審查分數到 status sheet（僅 Google Sheet 審查）

> 若 `mode = markdown-only` 或無 google MCP，改寫入 `.claude/testing/reviews/{name}-summary.md` 索引檔。

審查完成後，自動將評分寫入該 Spreadsheet 的 `status` sheet「審查紀錄」區塊。

**寫入位置：** status sheet 最後一個區塊之後

**寫入欄位（A-G）：**

| 欄 | 內容 | 範例 |
|----|------|------|
| A | 審查日期 | 2026-03-16 |
| B | 審查者 | Claude test-review |
| C | 評分 | 78 |
| D | Critical | 3 |
| E | Major | 5 |
| F | Minor | 4 |
| G | 備註 | 缺整合冒煙、Token 過期場景 |

**寫入邏輯：**
1. 讀取 status sheet，找到「審查紀錄」section header 的位置
2. 如果不存在，在 sheet 最後新增「審查紀錄」section（header + 欄位標題 + 10 空行 + 綜合評分行）
3. 找到第一個空的審查資料行，寫入本次審查結果
4. 更新綜合評分（所有非空評分的平均值）

**綜合評分公式：** `=IFERROR(AVERAGE(C{first_data}:C{last_data}), "")`

**格式規範：**
- Section header: `#366092` bg, white bold
- 欄位標題行: bold, `#D6E4F0` bg（淺藍）
- 評分欄: 置中對齊
- 綜合評分行: bold, `#E8F5E9` bg（淺綠）

**雙重審查（BB + WB）：** 寫入兩行，審查者分別標記：
- `Claude test-review (BB)` — 黑箱評分
- `Claude test-review (WB)` — 白箱評分

**多方審查（Claude / Codex / Gemini / 人工）：** 若 `review_protocol.tri_party_enabled = true`，三方各自寫一行，共享綜合評分。

### Phase 6: 詢問後續
- 生成缺失 TC？修正 Sheet/Markdown？建立改進 Task？

## 整合其他 Skill

- 發現缺口 → `test-automation` skill 生成測試程式碼
- 發現測試失敗 → `bug-report` skill 生成 Bug 報告
- 需要完整測試計劃 → `test-master` skill

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `mode = markdown-only` | 全程模式 | 不呼叫 google MCP，改讀寫本地 .md |
| `review_protocol.tri_party_enabled` | 啟用三方審查回寫 | 只寫單行 Claude 審查 |
| `review_protocol.dimensions` | 評分維度數量 | 預設 10 |
| `platforms.{ios,android}.repo` | 輔助驗證 | 跳過程式碼比對 |

## 範例

詳見 [`examples.md`](./examples.md)
