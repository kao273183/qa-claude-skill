---
name: tc-to-pytest
description: Convert white-box API verification TCs (Google Sheet or markdown) into a pytest-api-kit triplet (schemas.py + conftest fixture + tests/test_<feature>_api.py). Trigger phrases — "TC to pytest", "Sheet to test code", "white-box TC → pytest", "generate API tests from TC". Pair with speckit-to-tc (upstream), test-review (validate), test-automation (frontend).
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[Sheet URL / local TC markdown path / feature module]"
---

# tc-to-pytest (English)

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first**.
> Activation: `config.backend.pytest_enabled = true` and `backend.pytest_project_root` set.

## Use When
- Sheet TC ready, need pytest scaffolding
- `speckit-to-tc` draft → convert WB section
- Adding new BE feature pytest skeleton

## Don't Use For
- Black-box UI / a11y / cross-platform (use `test-automation`)
- TC not yet finalized
- Pure perf / stress (use Locust/JMeter)

## Config Source

Reads `config.json#backend`:
```json
{
  "backend": {
    "pytest_enabled": true,
    "pytest_project_root": "~/Desktop/your_pytest_repo",
    "client_naming": "<feature>_client + <feature>_auth_client",
    "schema_dsl": "S DSL (custom)"
  }
}
```

## Workflow

### Phase 1: TC source
Google Sheet URL / local md / module name → fetch WB rows.

### Phase 2: Filter WB rows
Keep only: API verification, security, boundary, concurrency. Skip pure perf/memory/state.

### Phase 3: Extract 4 elements
- HTTP method + endpoint (from steps/notes)
- Request params (from steps)
- Status code expectation
- Response schema

### Phase 4: Generate Triplet

**① `utils/schemas.py`** — symbol per response shape:
```python
HEALTH_STEPS_SYNC = S.object({
    "today_steps": S.integer(min=0),
    "trust_level": S.integer(min=0, max=5),
})
```

**② `conftest.py`** — client fixture:
```python
@pytest.fixture(scope="session")
def health_client(config):
    return APIClient(base_url=config["health_url"])
```

**③ `tests/test_<feature>_api.py`** — one fn per TC:
```python
def test_steps_sync_unauth_rejected(health_client):
    """對應 TC: WB-HEALTH-XXX"""
    resp = health_client.post("/api/v1/health/steps/sync", json={...})
    assert resp.status_code in (401, 403)
```

### Phase 5: Traceability report
Print `pytest_fn ↔ TC_ID` mapping, list unmapped TCs.

## Safety
- ✅ Write only to `{{PYTEST_PROJECT_ROOT}}/{schemas,conftest,tests/test_*}`
- ❌ Don't touch `env.yaml` (private secrets) / Dockerfile / CI workflows
- ❌ Don't auto-run pytest or commit
- ⚠️ Unclear TC → skip, mark TODO

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `backend.pytest_enabled` | Activates skill | Skill off |
| `backend.pytest_project_root` | Triplet location | Ask interactively |
| `backend.client_naming` | Fixture naming | Default `<feature>_client` |
| `backend.schema_dsl` | Schema definition style | Default plain dict |
