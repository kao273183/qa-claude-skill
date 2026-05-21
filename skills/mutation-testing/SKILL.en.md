---
name: mutation-testing
description: Run mutmut against BE Python code to quantify "do my TCs actually catch bugs?". Maps surviving mutations back to TC IDs and identifies weak TCs and missing assertions. Trigger phrases — "mutation testing", "TC strength", "mutmut", "are my tests strong enough". Pair with tc-to-pytest (produce pytest), test-review (traditional review), tc-version-diff (verify version-bump strength).
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[pytest target dir / file path] [--config | --run | --report]"
---

# mutation-testing (English)

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first**.
> Activation: `backend.pytest_enabled = true` and `backend.mutation.enabled = true`.

## Why

Line coverage tells you the code ran. It doesn't tell you the TC catches bugs.

```python
def is_within_100m(d): return d < 100
def test_within_100m(): assert is_within_100m(50) is True
# Line coverage 100%, but `<` → `<=` mutation survives.
```

→ Mutation testing exposes this "fake coverage".

## Use When
- pytest ready, want to verify TC strength
- Critical modules (anti-cheat / boundaries / scoring)
- After `test-review` gave a high score — double-check

## Don't Use For
- No pytest yet (`tc-to-pytest` first)
- Pytest baseline failing
- Non-Python (use stryker / pitest for JS / Kotlin)

## Workflow

### Phase 1: Config (`--config`)
1. `pip install mutmut`
2. Add to `pyproject.toml`:
   ```toml
   [tool.mutmut]
   paths_to_mutate = "src/{feature}/"
   runner = "pytest tests/test_{feature}_api.py -x -q"
   ```
3. Verify baseline passes

### Phase 2: Run (`--run`)
```bash
mutmut run --paths-to-mutate=src/{feature}/{module}.py
mutmut results
mutmut html
```

Categories: Killed (good) / Survived (weak point) / Timeout / Suspicious.

### Phase 3: Map back to TCs (`--report`)

Write to `~/.local/share/qa-mutation/{feature}/report-{date}.md`:
- Survived mutations + line refs
- Corresponding TC IDs (via docstring grep)
- Recommended supplementary TC

### Phase 4: Supplement Loop

```
mutation report → /tc-to-pytest --incremental → re-run mutmut → score up
```

## Safety
- ✅ Local/dev only (slow — N × pytest runs)
- ✅ Reports under `~/.local/share/qa-mutation/`
- ❌ Don't run in CI per-PR (weekly or pre-release OK)
- ❌ Don't auto-modify source
- ❌ Don't auto-write pytest

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `backend.mutation.enabled` | Activates skill | Skill off |
| `backend.mutation.score_target` | Score goal | Default 80% (critical 95%) |
| `backend.pytest_project_root` | mutmut work dir | Ask interactively |
