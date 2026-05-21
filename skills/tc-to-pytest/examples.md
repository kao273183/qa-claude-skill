# tc-to-pytest 範例

## 範例 1: 從 Google Sheet 轉 pytest

```
User: /tc-to-pytest https://docs.google.com/spreadsheets/d/xxx/edit?gid=789
```

執行：
1. 讀 Sheet「White-box」分頁，找到 24 條 WB-HEALTH TC
2. 篩出 API 驗證類 18 條（其他效能/記憶體跳過）
3. 為每條抽 endpoint / status code / schema
4. 寫 18 個 pytest function 到 `{{PYTEST_PROJECT_ROOT}}/tests/test_health_api.py`
5. 補 `health_client` / `health_auth_client` fixture 到 `conftest.py`
6. 補 schema symbols 到 `utils/schemas.py`
7. 印雙向對齊報表

## 範例 2: 從 speckit-to-tc 草稿轉

```
User: /tc-to-pytest peace-and-love/peace/health/tc-be-{{JIRA_PROJECT_KEY}}-XXXX-draft.md
```

執行：
1. Read 草稿 markdown
2. 抓 `## White-box (WB)` 段的 table
3. 同上 Phase 2~5

## 範例 3: 完全新 feature

```
User: /tc-to-pytest wallet
```

執行：
1. 因 wallet 不在 `tc-index.md` 中 → 提示使用者：
   - 確認 base_url
   - 確認 auth 模式
   - 建議命名規則
2. 確認後產生：
   - `WALLET_API_LIVE` env var skip 邏輯
   - `wallet_client` fixture
   - `tests/test_wallet_api.py` 骨架
