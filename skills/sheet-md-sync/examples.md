# sheet-md-sync 範例

## 範例 1：Sheet → md（最常見）

**情境**：健康 TC 在 Sheet 上跑了一個 sprint，team 改了不少。想拉一份最新 mirror commit 進 repo。

**輸入**：
```
/sheet-md-sync https://docs.google.com/spreadsheets/d/1bChwqYWoVEEZvuCaImX2_uNXDNgO9sNKgehNq5gpRCo/edit
```

**自動行為**：
1. 沒給 md path → 從 `tc-index.md` 找對應的 md（健康 → `peace/health/tc-phase1.md`）
2. 讀 Sheet 三個分頁（status / Black-box / White-box）
3. 寫 `peace/health/tc-phase1.md`（覆蓋舊鏡像）
4. 更新 `tc-index.md` 對應 row 的 last_synced + Drive 連結
5. Slack 通知

**Output**：
```
✅ Sheet → md 同步完成
- BB: 90 條
- WB: 43 條
- 寫到: peace/health/tc-phase1.md
- 上次同步: 2026-04-29 → 本次 2026-05-15
- Sheet revision: r45
- tc-index.md: 已更新

下一步建議：
1. git diff 看變化
2. PR 跟 spec.md 一起 review
3. 對應 pytest 升版？跑 `/tc-to-pytest health --incremental`
```

---

## 範例 2：md → Sheet（首次發布）

**情境**：剛跑完 `/speckit-to-tc UOP-7320`，產出 `love/stamp/tc-be-UOP-7320-draft.md`。review 修完想正式上 Sheet。

**輸入**：
```
/sheet-md-sync love/stamp/tc-be-UOP-7320-draft.md --to-sheet
```

**互動式確認**：
```
即將執行 md → Sheet：
- 來源: love/stamp/tc-be-UOP-7320-draft.md (BB 12 / WB 18)
- 動作: 從 [Template] 複製 → 命名「UOP-7281 集章 CMS 入口頁 Phase 1 TC」
- 放到: 喜樂團 folder（待補 folder ID）
- 寫入 BB 12 row + WB 18 row + status metadata

確認執行？(y/n)
```

User 回 `y` → skill：
1. 用 mcp-google-full copy template
2. rename + move
3. batchUpdate BB / WB
4. status sheet 寫 v0.1 / 2026-05-15 / Jack
5. 在 md frontmatter 補 `sheet_url: ...`
6. 更新 `tc-index.md` 加新 row

**Output**：
```
✅ md → Sheet 完成
- 新 Sheet: https://docs.google.com/spreadsheets/d/.../edit
- BB 上推: 12 條
- WB 上推: 18 條
- md frontmatter 已補 sheet_url
- tc-index.md 已更新（喜樂 → 集章 row 新增）

下一步：
1. 檢查 Sheet 排版（特別是 13 欄是否對齊）
2. 改檔名 draft → 正式版
3. WB 自動化部分跑 `/tc-to-pytest love/stamp/tc-be-UOP-7320-draft.md`
```

---

## 範例 3：--sync 雙向比對

**情境**：md 跟 Sheet 都有改動，不知道誰新。

**輸入**：
```
/sheet-md-sync peace/health/tc-phase1.md --sync
```

**Output**：
```
🔄 雙向 diff（不寫任何邊）

| 項目 | Sheet | md |
|------|-------|----|
| 最後改 | 2026-05-05 14:00 (revision r47) | 2026-05-04 09:30 (commit eac829c) |
| BB | 92 | 90 |
| WB | 43 | 43 |

## Sheet 比 md 新
新增 2 條 BB（Sheet 上加，md 沒）：
- BB-HEALTH-091 健康挑戰參與率 P1 [Both]
- BB-HEALTH-092 推播通知重複防治 P1 [Both]

修改 1 條（同 ID 但內容變）：
- BB-HEALTH-045 預期結果欄改（Sheet 較新）

## md 比 Sheet 新
無

## 衝突
無

→ 建議方向：`--to-md`（拉 Sheet 最新）
要執行嗎？(y/n)
```

---

## 範例 4：批次同步多個 feature

**輸入**：
```
/sheet-md-sync --all
```

**自動行為**：
1. 讀 `tc-index.md` 列出所有有 Drive link 的 TC
2. 對每個跑 `--sync` 雙向比對
3. 產一份 dashboard：

```
🔄 批次比對結果

| Feature | Sheet vs md 落差 | 建議 |
|---------|------------------|------|
| 旗艦館 Phase 1 Web (UOP-7264) | Sheet +3 BB | --to-md |
| 健康 Phase 1 (UOP-7279) | 同步 | 無動作 |
| 集章（UOP-7281） | md 不存在 | 等 Sheet 建立後 --to-md |
| 錢包（UOP-7282） | 兩邊都不存在 | 等 spec |

要逐一執行 --to-md 嗎？(y/n/select)
```

---

## 範例 5：CI 整合（每天自動鏡像）

**情境**：把 Sheet → md sync 加入 daily.sh，每天 16:00 跑完 Jira daily 後一併把 Sheet 鏡像 commit。

**做法**：在 `~/bin/uniopen-jira-daily.sh` 末尾加：
```bash
# 同步當天的 TC sheet 到 repo md
for feature in flagship health stamp; do
  ~/.claude/skills/sheet-md-sync/SKILL.md ... # 透過 claude headless 觸發
done
cd ~/Desktop/uniopen-peace-and-love
git diff --stat peace/ love/  # 顯示變化
```

可選：自動 commit + push（給 user 控制）。

---

## 反例：什麼時候不用這個 skill

❌ 只是想看 Sheet 內容 → 直接打開 Sheet 看
❌ Sheet 跟 md 都還在劇變 → 等 freeze 才 sync
❌ Sheet 沒 finalize → 不要鏡像進 repo（會誤導後續 reviewer）
❌ 兩個 Sheet 之間 diff（不是 Sheet ↔ md）→ 用 `tc-version-diff`
❌ 純查看「最近改了什麼」→ 用 Sheet 內建版本歷史

---

## 已驗證的 use case

- 健康 v0.3 上 Sheet（用 `mcp-google-full/scripts/health-tc-v0.3.js`）：md → Sheet 的 prototype，本 skill 把這 pattern 制度化
- 旗艦館 v0.2（用 `flagship-tc-update-apollo.js`）：同上

對應 memory：
- `reference_jira_daily_automation.md` 提及 mcp-google-full 是 user 自寫
- `tc-index.md` 是 sync 的命名規則來源
