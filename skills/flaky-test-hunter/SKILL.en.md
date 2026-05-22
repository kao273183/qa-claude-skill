---
name: flaky-test-hunter
description: Analyze CI run history to compute per-test flakiness scores, identify flaky tests (pass after retry), suggest fixes, and auto-quarantine. Supports GitHub Actions / GitLab CI / CircleCI / Jenkins JUnit XML / pytest-xdist. Trigger phrases — "flaky test", "unstable test", "false failure", "retry passed", "CI unstable", "quarantine test", "find flaky".
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[CI history path / GitHub workflow name] [--days=N] [--threshold=X%]"
---

# flaky-test-hunter (English)

> ⚙️ Read [`modules/config-loader.md`](./modules/config-loader.md) first.

## Why

Flaky tests destroy CI trust:
- Engineers ignore red builds ("probably flaky, hit retry")
- Real bugs get treated as flakiness
- Wasted CI minutes
- Loss of confidence in test automation

This skill **quantifies which tests are flaky with data**.

## When to Use
- CI has history (>1 month of runs)
- Suspecting some tests "randomly fail"
- Pre-release cleanup of flakiness
- Want auto-quarantine

## Workflow

### Phase 1: Collect CI failure history

| CI Platform | Source |
|-------------|--------|
| GitHub Actions | `gh run list --workflow=ci.yml --json` |
| GitLab CI | `glab ci list` + API |
| CircleCI | CircleCI API |
| Jenkins | JUnit XML |
| pytest local | `pytest --json-report` × N |

Default lookback: 30 days.

### Phase 2: Compute flakiness

```
flakiness = (failures_in_passing_runs / total_runs) × 100%
```

- 0%: Stable
- 1-80%: Flaky
- >80%: Stable-fail (real bug, not flaky)

### Phase 3: Severity bucketing

| Severity | Threshold | Action |
|----------|-----------|--------|
| 🔴 High | > 30% | Quarantine + fix |
| 🟡 Medium | 10-30% | Schedule fix + quarantine |
| 🟢 Low | 1-10% | Monitor |

### Phase 4: Identify root-cause patterns

| Pattern | Example | Fix |
|---------|---------|-----|
| Hard-coded sleep | `Thread.sleep(2000)` | `waitFor(condition)` |
| Time dependency | `time.now()` | Clock injection |
| Shared state | global singleton | setUp/tearDown reset |
| Real network | call real API | Mock HTTP |
| Random data | `Math.random()` | Fixed seed |
| DB race | concurrent same row | Unique key / transaction |
| Animation timing | `cy.contains("X")` mid-animation | `cy.get(...).should("be.visible")` |
| Non-deterministic order | `toEqual([1,2,3])` | `arrayContaining` |
| Memory leak | slower over time | Restart worker per N |

### Phase 5: Report
Written to `~/.local/share/qa-flaky/{repo}/report-{date}.md`:
- Overall flakiness %
- High/Medium/Low flaky lists
- Root cause hypothesis per test
- Auto-quarantine recommendations

### Phase 6: Auto-actions
Interactive prompts:
- Quarantine High flaky? (`@QuarantineFlaky` annotation)
- Create JIRA tickets? (via `bug-report` skill)
- Generate PR moving flaky to quarantine?

**Default: don't modify test code without explicit consent.**

## Safety
- ❌ Never auto-disable tests without consent
- ❌ Never mark stable-fail (real bugs) as flaky
- ✅ Quarantine marker must include "must-fix-by: YYYY-MM-DD"
- ✅ Reports under `~/.local/share/qa-flaky/`, not in repo

## Config Dependencies

| Key | Purpose |
|-----|---------|
| `flaky_hunter.ci_platform` | Auto-detected |
| `flaky_hunter.lookback_days` | Default 30 |
| `flaky_hunter.flaky_threshold` | Default 1% |
| `flaky_hunter.high_flaky_threshold` | Default 30% |
