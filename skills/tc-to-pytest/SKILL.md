---
name: tc-to-pytest
description: 把 Google Sheet 或 markdown TC（白箱 API 驗證類）轉成 pytest-api-kit 三件套（schemas.py + conftest fixture + tests/test_*.py）。當使用者提到「TC 轉 pytest / Sheet 變測試碼 / 把白箱 TC 變 pytest / generate API tests from TC」，或拿到 speckit-to-tc 草稿 + 要寫 BE 測試碼時觸發。配套：speckit-to-tc（前置）、test-review（驗證）、test-automation（前端自動化）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[Sheet URL / 本地 TC markdown 路徑 / 功能模組名]"
---

# tc-to-pytest

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。
> 啟用條件：`config.backend.pytest_enabled = true` 且 `config.backend.pytest_project_root` 已設定。

## 適用場景

- ✅ 已有 Sheet TC（白箱 API 驗證類），要產對應 pytest test 檔
- ✅ `speckit-to-tc` 草擬完 draft markdown，要把 WB 區塊轉 pytest
- ✅ 想新增 BE feature 的 pytest 測試骨架

## 不適用場景

- ❌ Black-box UI / a11y / 跨平台 — 那是 `test-automation` 範疇
- ❌ Sheet 還沒 finalize（會生空殼）
- ❌ 純效能基準 / 壓測 — 用 Locust / JMeter

## 設定來源

從 `config.json#backend` 讀：

```json
{
  "backend": {
    "pytest_enabled": true,
    "pytest_project_root": "~/Desktop/your_pytest_repo",
    "pytest_kit_pattern": "schemas.py + conftest.py + tests/test_<feature>_api.py",
    "client_naming": "<feature>_client + <feature>_auth_client",
    "schema_dsl": "S DSL (custom)",
    "feature_modules": ["health", "stamp", "wallet"]
  }
}
```

**三件套位置（依 `pytest_project_root`）**：
```
{{PYTEST_PROJECT_ROOT}}/
├── utils/schemas.py            # ① schema 定義
├── conftest.py                 # ② client fixture
└── tests/test_<feature>_api.py # ③ 測試函式
```

## Phase 1: 取 TC 來源

| 輸入 | 動作 |
|------|------|
| Google Sheet URL | 用 google MCP 讀 sheet；只挑「White-box / 白箱」分頁 |
| 本地 markdown 檔 | Read，抓 `## White-box (WB)` 段的 markdown table |
| 功能模組名（如 `health` / `stamp`）| 從 `tc-index.md`（若存在）找對應 Sheet 連結 |
| 沒給 → 互動式詢問 | 「請給 Sheet URL / 草稿 markdown 路徑 / 模組名」 |

## Phase 2: 篩 WB API 驗證 row

從所有 WB row 中**只挑**這些分類：

| 分類 | pytest 對應方式 |
|------|---------------|
| API 驗證 / API 驗證測試 | `test_<intent>` 直接寫 |
| 安全（auth/token/SQL inject）| `test_<intent>_unauth_rejected` 等 |
| 邊界（schema/range）| `test_<intent>_boundary` |
| 並發 | `pytest-xdist` 標 `@pytest.mark.parallel` |

**跳過**：純效能（cold start / TTFB）、純記憶體 leak、純內部狀態。

## Phase 3: 抽取每條 TC 的 4 要素

| 要素 | 從哪欄抽 |
|------|---------|
| HTTP method + endpoint | 步驟 / 備註欄找 `GET /api/v1/...` |
| Request 參數 | 步驟欄 |
| Status code 期望 | 預期欄找 `200` / `401` / `4xx` |
| Response schema | 預期欄找 schema 描述 |

**對齊規則**：每條 TC 的 ID（如 `WB-{FEATURE}-XXX`）→ pytest test function 開頭 docstring 寫對應 ID（雙向 traceability）。

## Phase 4: 生成三件套

### ① `utils/schemas.py` — schema 定義

對每個 unique response shape 加一個 symbol（以 S DSL 為例）：

```python
HEALTH_STEPS_SYNC = S.object({
    "synced_at": S.string(format="datetime"),
    "today_steps": S.integer(min=0),
    "trust_level": S.integer(min=0, max=5),
    "raw_archive_id": S.string(),
})
```

**命名規則**：`<FEATURE>_<ENDPOINT_INTENT>` 全大寫底線。

**避免重複**：先 Read 既有 `utils/schemas.py`，已存在就重用，不重複定義。

### ② `conftest.py` — fixture

每個新 feature 加一組 client fixture（依 `client_naming` 規則）：

```python
@pytest.fixture(scope="session")
def health_client(config):
    client = APIClient(base_url=config["health_url"])
    return client

@pytest.fixture(scope="session")
def health_auth_client(health_client, uat_token):
    health_client.set_default_headers({"Authorization": f"Bearer {uat_token}"})
    return health_client
```

**對齊**：跟既有 client fixture 同 pattern。**不重新定義** APIClient base class、不另外發明 auth 機制。

需要新 base_url 設定就**只動** `config/env.template.yaml` 加 key，不動 `env.yaml`（私有檔）。

### ③ `tests/test_<feature>_api.py` — 測試函式

每條 TC 對應一個 pytest function：

```python
def test_steps_sync_unauth_rejected(health_client):
    """
    對應 TC: WB-HEALTH-XXX（步數 sync 未授權 401 防偽）
    Spec: {{JIRA_PROJECT_KEY}}-XXXX
    """
    resp = health_client.post("/api/v1/health/steps/sync", json={"today_steps": 1000})
    assert resp.status_code in (401, 403), f"預期 401/403 got {resp.status_code}"
```

**強制元素**：
- docstring 第一行寫 `對應 TC: <ID>`（雙向 traceability）
- 用既有 `assert_*` helper（如有），別重發明
- schema 驗證統一 `from utils.schema import validate, S`
- skip 邏輯：feature 還沒部署 UAT → `pytestmark = pytest.mark.skipif(...)`

**function 命名範例**：
| TC ID + 標題 | pytest function name |
|--------|---------------------|
| WB-HEALTH-001 步數 sync 未授權 401 | `test_steps_sync_unauth_rejected` |
| WB-HEALTH-002 打卡超過 100m 拒絕 | `test_checkin_too_far_rejected` |
| WB-HEALTH-003 join → progress 一致 | `test_join_then_progress_consistent` |
| WB-STAMP-001 活動列表 200 | `test_activities_list_ok` |

intent-based 命名 > 純 ID 命名（ID 進 docstring 即可）。

## Phase 5: 雙向 traceability 報表

```
✅ 生成 X 條 pytest function；對應 X 條 WB TC

雙向對齊（pytest ↔ TC）：
test_steps_sync_unauth_rejected     ↔ WB-HEALTH-001
test_steps_range_7days_schema       ↔ WB-HEALTH-002
...

未對齊的 TC（需手動補或本 skill 不適用）：
WB-HEALTH-XXX 並發測試 → 標 @pytest.mark.parallel 但骨架待補
WB-HEALTH-XXX 效能基準 → Locust 範疇，不上 pytest

新增 schema symbols:
HEALTH_STEPS_SYNC / HEALTH_STEPS_RANGE / ...

新增 fixtures:
health_client / health_auth_client

下一步：
1. 你 review pytest（特別是 skip 條件、assert 嚴格度）
2. 部署到 UAT 後跑 `HEALTH_API_LIVE=1 pytest tests/test_health_api.py`
3. 跑 `pytest --collect-only` 確認 TC 雙向對齊
4. 在對應 TC Sheet 的「自動化」欄標 Y，「備註」欄寫 pytest function name
```

## ⚠️ 安全護欄

- ✅ 只 Write 到 `{{PYTEST_PROJECT_ROOT}}` 內三個目標檔
- ✅ Edit 既有檔時保留既有 import / fixture / schema，**只追加新項**
- ❌ 不動 `config/env.yaml`（私有 secrets）
- ❌ 不動 `Dockerfile` / `.github/workflows/`（CI 設定）
- ❌ 不主動跑 `pytest`（測試實際跑由使用者控制）
- ❌ 不主動 commit / push
- ⚠️ TC 沒寫清楚 endpoint / schema → **跳過該條，標 TODO**，不要編造

## BE feature 是新的（pytest 專案沒對應 client）

如果 feature 完全新，需要：
1. 加 `{FEATURE}_API_LIVE` env var + skip 邏輯
2. 加 `<feature>_client` fixture
3. 加 `tests/test_<feature>_api.py`
4. **建議跟使用者確認 base_url + auth 模式**才動工

## 配套整合

- 草稿 TC → 用 `speckit-to-tc` 先草，再用此 skill 把 WB 段轉 pytest
- 寫完 pytest → 用 `test-review` 審 pytest 程式碼品質
- 部署到 UAT → 使用者手動 `{FEATURE}_API_LIVE=1 pytest`
- 想驗 TC 抓 bug 能力 → 用 `mutation-testing`
- 想升級 boundary 覆蓋 → 用 `property-based-test-gen`

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `backend.pytest_enabled` | 啟用此 skill | 提示先設定 pytest project |
| `backend.pytest_project_root` | 三件套寫入位置 | 互動式詢問 |
| `backend.client_naming` | fixture 命名規則 | 預設 `<feature>_client` |
| `backend.schema_dsl` | schema 定義方式 | 預設純 dict（無 DSL） |

## 範例

詳見 [`examples.md`](./examples.md)
