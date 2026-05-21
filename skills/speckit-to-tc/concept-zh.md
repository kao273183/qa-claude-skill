# 一文搞懂 speckit-to-tc

> 給第一次聽到「Spec Kit」「SDD」的 QA / PM 看的快速導讀。
> 看完就知道「為什麼規格寫好後可以一鍵變 TC」。

---

## 🎯 一句話總結

> **「PM 寫完規格 ticket → 自動草擬 25 條 BB+WB TC（含 a11y）→ 你 review 後上 Sheet。」**

把「讀 spec → 想 TC → 打字」這個耗時 4-8 小時的活，壓縮成「跑 skill → review → 上 Sheet」30 分鐘。

---

## 🆚 跟你熟悉的「手寫 TC」流程差在哪？

### 傳統流程

```
PM 寫 spec ticket（4 hr）
   ↓
QA 讀 spec（30 min）
   ↓
QA 想 TC：
   • Smoke 要幾條？
   • 邊界要哪些？
   • 錯誤處理列哪些？
   • a11y 加幾條？
   • 跨平台要不要分？
   ↓
QA 一條一條打字（4-8 hr）
   ↓
QA 整理上 Google Sheet
   ↓
讓 QA Lead review（再來回 2-3 輪）
```

**痛點**：
- 慢（半天到一天）
- 容易漏（a11y 通常被忘）
- 不一致（每個 QA 寫的格式不同）

### 用 speckit-to-tc

```
PM 寫 spec ticket
   ↓
QA: /speckit-to-tc {{JIRA_PROJECT_KEY}}-XXXX
   ↓
30 秒後產出 tc-be-XXXX-draft.md
   • BB 10 條（含 a11y 4 條）
   • WB 15 條（含 BE API 12 條）
   • 自動歸位到對應 repo 目錄
   ↓
QA review + 補完缺漏（30 min）
   ↓
正式上 Sheet
```

**省了**：4-7 小時的人力。

---

## 🤔 那「Spec Kit / SDD」是什麼？

### GitHub Spec Kit

GitHub 推出的「規格驅動開發」工具集：
- 一份 `spec.md` 描述產品需求（人類可讀）
- 一份 `api.md` 描述 API 契約（機器可解析）
- AI agent / 工具可以讀這些檔案，自動產生：
  - 程式碼骨架
  - 測試案例
  - 文件

### SDD（Spec-Driven Development）

「Spec-Driven Development」的縮寫，核心理念：

> **「先把規格寫清楚，再開始 coding / testing。」**

跟 TDD（Test-Driven Development）的差別：
- TDD：先寫 test，再寫 code
- SDD：先寫 spec，再寫 test 和 code

實務上 SDD 跟 TDD 不衝突，常常**先 SDD 寫規格 → 用規格產 TDD 的 test → 再 coding**。

---

## 🎬 真實案例：集章 NFC 打卡功能

### Step 1: PM 寫 Jira ticket

ticket `{{JIRA_PROJECT_KEY}}-7320`：
```
標題：[集章] NFC 打卡核心功能

Description:
1. 使用者進到合作門市
2. 把手機靠近收銀台 NFC tag
3. 系統判定距離 < 100m
4. 寫入打卡紀錄
5. 顯示集章成功動畫

API: POST /api/v1/stamp/checkin
- request: { tag_id, lat, lng, timestamp }
- response 200: { success, stamp_count }
- response 4xx: 距離超過 / tag 無效 / 重複打卡
```

### Step 2: 跑 skill

```
/speckit-to-tc {{JIRA_PROJECT_KEY}}-7320
```

skill 做的事：
1. 用 atlassian MCP 抓 ticket description
2. 解析 summary → match `feature_routing` → 集章模組 → 輸出到 `<repo>/love/stamp/`
3. 讀同目錄 `spec.md` + `api.md` 補上下文
4. 草擬 25 條 TC，按 14 欄結構

### Step 3: 輸出檔 `tc-be-{{JIRA_PROJECT_KEY}}-7320-draft.md`

```markdown
---
ticket: {{JIRA_PROJECT_KEY}}-7320
spec_source: love/stamp/spec.md (§NFC 打卡)
draft_version: v0.1
status: pending review
---

## Black-box (BB) — 10 條

| ID | 標題 | 分類 | 優先度 | 平台 |
|----|------|------|--------|------|
| BB-STAMP-001 | NFC 打卡成功 | 冒煙-F1 | P0 | Both |
| BB-STAMP-002 | NFC 打卡距離超過 100m 拒絕 | 異常/邊界 | P0 | Both |
| BB-STAMP-003 | NFC 打卡 tag 無效 | 錯誤處理 | P1 | Both |
| BB-STAMP-A11Y-01 | 字級放大時打卡成功動畫文字不破版 | a11y | P1 | Both |
| BB-STAMP-A11Y-02 | VoiceOver 讀取打卡狀態正確 | a11y | P2 | iOS |
| BB-STAMP-A11Y-03 | TalkBack 讀取打卡狀態正確 | a11y | P2 | Android |
| BB-STAMP-A11Y-04 | 觸控目標 ≥ 44pt / 48dp | a11y | P2 | Both |
...

## White-box (WB) — 15 條

| ID | 標題 | 分類 | 優先度 | 平台 |
|----|------|------|--------|------|
| WB-STAMP-001 | POST /checkin schema 驗證 | API 驗證 | P0 | BE-only |
| WB-STAMP-002 | POST /checkin 401 未授權 | 安全 | P0 | BE-only |
| WB-STAMP-003 | POST /checkin distance > 100 → 4xx | API 驗證 | P0 | BE-only |
| WB-STAMP-004 | POST /checkin 重複打卡 → 409 | API 驗證 | P1 | BE-only |
...
```

### Step 4: 後續

```
✅ 草擬完成 → tc-be-{{JIRA_PROJECT_KEY}}-7320-draft.md
- BB 10 條（其中 a11y 4 條）
- WB 15 條（其中 BE API 驗證 12 條）

下一步建議：
1. 你 review 草稿
2. /test-review tc-be-{{JIRA_PROJECT_KEY}}-7320-draft.md
3. 通過後上 Sheet：/sheet-md-sync ... --upload
4. BE 部分跑：/tc-to-pytest tc-be-{{JIRA_PROJECT_KEY}}-7320-draft.md
```

---

## 🧩 它依靠什麼運作？

### 1. feature_routing 規則

設定在 `config.json`：
```json
{
  "speckit": {
    "feature_routing": [
      { "keywords": ["集章", "stamp", "NFC"], "path": "love/stamp/" },
      { "keywords": ["健康", "步數", "health"], "path": "peace/health/" }
    ]
  }
}
```

skill 看 ticket summary → match keywords → 自動歸位到對應目錄。

### 2. 14 欄 TC 結構

跟通用模板對齊：A: ID / B: Phase / ... / N: JIRA。

### 3. 9 種 BB + 6 種 WB 分類

確保覆蓋全面：
- BB：冒煙 / 功能 / 邊界 / 錯誤 / 生命週期 / 跨平台 / E2E / 效能 / **a11y**
- WB：API / 效能 / 安全 / 記憶體 / 並發 / 內部狀態

### 4. a11y 強制 4 條（若啟用 auto_a11y_pairing）

每份 TC 都自動加：
- 字級放大 iOS
- 字級放大 Android
- VoiceOver / TalkBack
- 觸控目標 + 對比度

---

## ⚡ 什麼時候**該**用？

✅ 適合：
- Jira「規格制定」ticket 剛 close
- 拿到 spec.md / api.md 想快速產第一稿
- PM 給規格 docx / wireframe，已提煉成 description
- 想對齊整個團隊的 TC 格式

## 🚫 什麼時候**不該**用？

❌ 不適合：
- Spec 仍未定稿（要等 ticket close / spec freeze 後才跑）
- 純自動化腳本生成 → 用 `test-automation`
- 已有完整 TC、想升級 → 用 `test-review` + `test-master`
- 規格只有口頭討論、沒寫成文字 → 先讓 PM 寫

---

## 🎓 三個關鍵心法

### 1. Draft only — 草稿是起點，不是終點

skill 產出的是 **draft v0.1**，不是 final TC：
- 機器擅長「覆蓋分類完整性」
- 但 spec 沒講清楚的場景，機器只會標 `uncovered`，不會編造
- 你還是要 review、補缺漏、跟 PM 對齊

### 2. feature_routing 自動歸位

不會問你「要放哪個目錄」，而是看 keywords 自動判斷：
- 看到「集章 / stamp / NFC」→ 放 `love/stamp/`
- 看到「健康 / 步數 / health」→ 放 `peace/health/`

新功能要記得在 `config.json` 加 routing 規則。

### 3. Black-box 不引用程式碼細節

BB TC 是給「使用者視角」的：
- ❌ 不要：「verify CookieManager.refresh() returns valid token」
- ✅ 應該：「重新登入後 30 秒內應該能進入會員頁」

WB TC 才能引用技術細節（API endpoint / class / method）。

---

## 🚀 從零開始的 4 步驟

### Step 1: 設定 feature_routing

在 `config.json` 加：
```json
{
  "speckit": {
    "enabled": true,
    "repo_root": "~/Desktop/your-spec-repo",
    "feature_routing": [
      { "keywords": ["你的關鍵字"], "path": "your/path/" }
    ]
  }
}
```

### Step 2: 確認規格存在

- 方式 A：Jira ticket（含 description）
- 方式 B：spec.md 檔案
- 方式 C：直接貼規格內容到對話

### Step 3: 跑 skill

```
/speckit-to-tc {{JIRA_PROJECT_KEY}}-XXXX
# 或
/speckit-to-tc path/to/spec.md
```

### Step 4: Review + 後續流程

1. 看 draft 草稿
2. 補上 spec 沒講清楚的場景（standardize uncovered）
3. `/test-review` 跑審查
4. 正式上 Sheet（用 `/sheet-md-sync --to-sheet`）
5. BE 部分轉 pytest（用 `/tc-to-pytest`）

---

## 📚 進一步閱讀

- [GitHub Spec Kit](https://github.com/github/spec-kit)
- [speckit-to-tc SKILL](./SKILL.md) — 本 skill 完整流程
- [speckit-to-tc 範例](./examples.md) — 4 個實際使用情境
- [Skill 串接圖](../../docs/workflow-diagrams.md) — 跟其他 skill 怎麼串

## 🎯 一句話複述

**「PM 寫好 spec ticket → 30 秒草擬 25 條 TC（含 a11y 必檢項）→ 你 review 後正式上 Sheet。把 4-8 hr 的 TC 撰寫壓成 30 min。」**
