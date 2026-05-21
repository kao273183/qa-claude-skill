# tc-version-diff 範例

## 範例 1：健康 v0.2 → v0.3 對比

**輸入**：
```
/tc-version-diff health v0.2 v0.3
```

（單一模組 + 兩個版本號 → skill 自動從 `tc-index.md` 找 Sheet → Drive revision API 抓兩版快照）

**已知對比**（來自實際 health-tc-v0.3.js 紀錄）：
- v0.2: BB 79 / WB 33 = 112 條（v0.2 自評 89 分）
- v0.3: BB 90 / WB 43 = 133 條（v0.3 自評 93 分）
- 淨變動：+11 BB / +10 WB

**輸出檔案**：`peace-and-love/.claude/testing/features/health/tc-changelog-v0.2-v0.3.md`

**內容摘要**：
```markdown
## 🆕 Added · 21 條

### Black-box +11
- BB-HEALTH-086 相容：iOS 16 [P1] [iOS]
- BB-HEALTH-087 相容：iOS 17 [P1] [iOS]
- BB-HEALTH-088 相容：Android 11（API 30）[P1] [Android]
- BB-HEALTH-089 相容：Android 12（API 31，Health Connect 切點）[P0] [Android]
- BB-HEALTH-090 相容：Android 13（API 33，Health Connect 預裝）[P1] [Android]
（OS 中間版本相容性 5 條 + 其他 6 條）

### White-box +10
- WB-HEALTH-035 步數 sync 未授權 401 防偽 [P0] [Both] [Y/pytest]
- WB-HEALTH-036 GET /steps/range 7 天範圍 schema [P1] [Both] [Y/pytest]
- WB-HEALTH-037 GET /stores/seven-eleven 全台列表 ≥ 5000 家 [P1]
- WB-HEALTH-038 GET /stores/nearby 距離排序 [P1]
- WB-HEALTH-039 POST /checkins 超過 100m 拒絕 [P0]
- WB-HEALTH-040 挑戰 join → progress 一致性 [P0]
- WB-HEALTH-041 POST /rewards/claim 未達成獎勵應拒絕 [P0]
- WB-HEALTH-042 POST /privacy/data-export async job pattern [P1]
- WB-HEALTH-043 Isolate raw_data 處理並發安全 [P1]

## 📋 補測清單

P0 必跑（5 條）：
- BB-HEALTH-089 Android 12 切點 → 45 min
- WB-HEALTH-035 步數 sync unauth → pytest 自動 / 1 min
- WB-HEALTH-039 打卡超過 100m → pytest 自動
- WB-HEALTH-040 join → progress → pytest 自動
- WB-HEALTH-041 reward claim 未達成 → pytest 自動

P1 重要（16 條）：列表略

**總估時**：手動 4 人時 + pytest 自動 ~20 min CI

## 🔗 對應 pytest

WB-HEALTH-035 ↔ test_steps_sync_unauth_rejected
WB-HEALTH-036 ↔ test_range_7days
... (24/24 雙向對齊)

→ `HEALTH_API_LIVE=1 pytest tests/test_health_api.py -v`
```

**Slack 通知**：
```
🔄 TC 升版 health v0.2 → v0.3
🆕 +21 · ✏️ 0 Modified · 🗑️ 0 Removed
❗ 補測必跑：21 條（含 P0 5 條）
🔗 changelog: ~/Desktop/uniopen-peace-and-love/.claude/testing/features/health/tc-changelog-v0.2-v0.3.md
```

---

## 範例 2：旗艦館 v0.1 → v0.2 對比

**情境**：旗艦館 v0.1 (51 條 / 65 分) → v0.2 (63 條 / 75 分)，主要修 Critical 1 + Major 7。

**輸入**：
```
/tc-version-diff flagship v0.1 v0.2
```

**重點輸出**：
```markdown
## ✏️ Modified · 8 條（皆 v0.1 review 後修）

### 🔴 高影響（必重測）
- BB-FLAG-007（旗艦館首頁載入）：預期結果從「應正確顯示」→「cold start ≤3s + 60fps + 模組依序載入」
- BB-FLAG-015（地圖載入）：預期結果加「≤2s + 60fps」量化

### 🟡 中影響
- WB-FLAG-W003：步驟改（補上 GraphQL response cache miss 驗證）
- BB-FLAG-021：自動化欄改 N → Y（決定用 Patrol）

### 🟢 低影響
- 標題微調 4 條

## 🆕 Added · 12 條
- 補性能相關 4 條（cold start / 同步 / 地圖 / battery）
- 補錯誤處理 5 條
- 補 a11y 字級放大 3 條（v0.1 漏）

## 📋 補測清單

**P0 重跑**：8 條（含 5 條 Modified 高影響 + 3 條 Added 性能）
- W2 之前確認 PM/CheJu finalize 性能標準後才有意義跑
- 5/17 TC ready deadline 倒數 N 天

→ 對齊 `project_flagship_phase1_timeline.md` 5/17 deadline
```

---

## 範例 3：互動式（不確定版本）

**輸入**：
```
/tc-version-diff
```

**互動**：
```
請給我 TC 來源：

(a) Sheet URL 兩個（v_old + v_new）
(b) markdown 檔兩個
(c) 單一模組名 + 版本號（如 `health v0.2 v0.3`）
(d) 從 status sheet 自動找最近兩版（給我 Sheet URL）
```

User 回 (d) + Sheet URL → skill 從 status 分頁讀「審查紀錄」表 → 找最後兩 row → 對應的版本 → 抓 Drive revision → 對比。

---

## 範例 4：升版同步 pytest

**情境**：剛跑完 `/tc-version-diff health v0.2 v0.3` → changelog 顯示 WB +8 條全有 pytest 對齊備註。

**接續**：
```
/tc-to-pytest health --incremental
```

→ tc-to-pytest 讀 v0.3 sheet 的「自動化=Y」row → 比對 `tests/test_health_api.py` 已存在 → 只 append 缺的 8 條。

兩 skill 接續使用，達成 TC ↔ pytest 雙向對齊永遠是最新版。

---

## 反例：什麼時候不用這個 skill

❌ TC 全新（v0.1 first draft，沒 v0.0 可比）→ 用 test-master 從零生
❌ 完全 rewrite（檔名都換了）→ 不是 diff，是新版
❌ 純文字錯字 / 格式調 → 直接改 sheet，沒 changelog 必要
❌ 跨功能模組合併（如「集章 + 錢包」變單一 sheet）→ 用人工檢查比較直接

---

## 已驗證的 use case（健康 v0.2 → v0.3）

- 5/5 自動化跑完，產出 21 條補測 + pytest 24/24 對齊
- status sheet「審查紀錄」自動加一 row
- 對應 memory `project_health_phase1_tasks.md` 已標記 v0.3 升版證據
- pytest CI 跑完反映在 dashboard

對應 memory：`project_health_v6_spec.md` + `feedback_be_api_test_pattern.md`
