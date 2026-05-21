# speckit-to-tc 範例

## 範例 1: 從 Jira ticket 草擬

```
User: /speckit-to-tc {{JIRA_PROJECT_KEY}}-7320
```

執行：
1. 用 atlassian MCP 抓 `{{JIRA_PROJECT_KEY}}-7320` description
2. 解析 summary，match `feature_routing` → 集章模組 → 輸出到 `<repo>/love/stamp/`
3. 讀同目錄 `spec.md` + `api.md` 補上下文
4. 草擬 BB（10 條，含 4 條 a11y）+ WB（15 條，BE API 占多）
5. 寫到 `tc-be-{{JIRA_PROJECT_KEY}}-7320-draft.md`，狀態標 `pending review`

## 範例 2: 從本地 spec 檔

```
User: /speckit-to-tc ~/Desktop/repo/feature/spec.md
```

執行：
1. Read spec.md
2. 從內容推 feature 模組（必要時詢問）
3. 同上 Phase 4~5

## 範例 3: 草稿 → review → 上 Sheet

```
User: /speckit-to-tc {{JIRA_PROJECT_KEY}}-7320

Bot: ✅ 草擬完成 → tc-be-{{JIRA_PROJECT_KEY}}-7320-draft.md
     - BB 10 條（其中 a11y 4 條）
     - WB 15 條（其中 BE API 驗證 12 條）

下一步建議：
1. 你 review 草稿
2. /test-review tc-be-{{JIRA_PROJECT_KEY}}-7320-draft.md
3. 通過後上 Sheet：/sheet-md-sync ... --upload
4. BE 部分跑：/tc-to-pytest tc-be-{{JIRA_PROJECT_KEY}}-7320-draft.md
```

## 範例 4: 全新 feature（無對應 routing）

```
User: /speckit-to-tc {{JIRA_PROJECT_KEY}}-9999

Bot: 偵測到 ticket "[新功能] AR 試穿"，但 feature_routing 沒對應規則。

請選擇輸出目錄：
  1. 新增 routing 規則到 config（建議）
  2. 直接指定路徑（一次性）
  3. 取消
```
