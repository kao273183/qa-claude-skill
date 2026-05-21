---
name: property-based-test-gen
description: From TC boundary fields + existing pytest, generate hypothesis @given strategies — upgrading example-based tests to fuzz tests. Each property test runs 100+ inputs to auto-explore boundary bugs. Complements mutation-testing (mutation finds gaps, property closes them with fuzz). Trigger phrases — "property-based testing", "hypothesis", "fuzz test", "boundary scan", "example to property". Pair with tc-to-pytest (upstream), mutation-testing (finds gaps), test-review (validate strategy).
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[pytest path / module] [--from-tc <Sheet>] [--from-mutation-report <path>]"
---

# property-based-test-gen (English)

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first**.
> Activation: `backend.pytest_enabled = true` and `backend.property_based.enabled = true`.

## Why

Example-based tests pin 1-2 inputs. Boundary cases (off-by-one, NaN, Infinity, edge values) easily slip past 100% line coverage.

Property-based tests give a range + invariant; hypothesis generates 100+ inputs and shrinks failing input to a minimal reproducer.

## Use When
- BE pytest exists, want fuzz upgrade on critical logic
- After `/mutation-testing` shows boundary mutations surviving
- Sprint review identifies critical module to harden

## Don't Use For
- Pure schema / status code checks (example tests suffice)
- UI / Flutter / Swift (Python-only; use fast-check / glados elsewhere)
- IO-side-effect functions (fuzz would hammer BE)
- Functions with no invariant

## Workflow

### Phase 1: Input
- pytest path → find critical fns
- module name → resolve via `tc-index.md`
- `--from-mutation-report` → target survived points

### Phase 2: Pick critical fns
Numeric boundaries, range judgments, monotonic functions, encode/decode round-trips, set ops, state machines.

### Phase 3: Derive invariants from spec/TC/docstring

### Phase 4: Write `tests/test_<feature>_property.py`

```python
@given(d=st.floats(min_value=0, max_value=99.99, allow_nan=False, allow_infinity=False))
@settings(max_examples=200)
def test_within_100m_property(d):
    """Strengthens TC: WB-{FEATURE}-039"""
    assert is_within_100m(d) is True
```

### Phase 5: CI strategy
- PR CI: don't run (too slow)
- Nightly/weekly: `--hypothesis-profile=ci` (100 examples)
- Pre-release: `--hypothesis-profile=thorough` (1000)

### Phase 6: Shrink-to-reproducer
On fail, `Falsifying example:` shows minimal input → consult PM, add `@example(...)` regression case.

## Safety
- ✅ Write only `tests/test_<feature>_property.py` (separate file)
- ✅ Docstring "Strengthens TC: WB-XXX" for traceability
- ✅ Default `max_examples = 200`
- ❌ Don't touch example tests
- ❌ Don't fuzz IO-side-effect functions
- ❌ Don't enable in per-PR CI

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `backend.property_based.enabled` | Activates skill | Skill off |
| `backend.property_based.default_max_examples` | Hypothesis default | Default 200 |
| `backend.pytest_project_root` | Write location | Ask interactively |
