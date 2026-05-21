---
name: test-review
description: Review test cases or test code for completeness, quality, and effectiveness — at senior QA engineer standards. Supports black-box/white-box test cases (Google Sheet or Markdown) and test code (Swift / Kotlin / Dart / Python). Trigger phrases — "review tests", "review test cases", "check test coverage", "test quality", "test review", or providing a Google Sheet URL / test file path for review.
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__readSpreadsheet, mcp__google__getSpreadsheetInfo, mcp__google__writeSpreadsheet
argument-hint: "[test file path OR Google Sheet URL OR Markdown path]"
---

# test-review (English)

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first** to load org settings.
> If `config.json` is missing or `mode = markdown-only`, skip all google MCP calls; see [`modules/markdown-fallback.md`](./modules/markdown-fallback.md).

## Input Auto-detection

| Input | Review type |
|-------|-------------|
| Google Sheet URL | Read sheet name, auto-pick BB / WB / dual review |
| Test file path (`.swift` / `.kt` / `.dart` / `.py`) | Test code review |
| Markdown path (with TC table) | Markdown TC review |
| No arg | Ask interactively |

## Review Standards

### Black-box Test Case Review

| Dimension | Focus |
|-----------|-------|
| **Completeness (30)** | Smoke 4-phase + happy path + boundary + error handling + lifecycle + cross-platform |
| **Clarity (20)** | Title states behavior+expectation, preconditions explicit, steps executable, expected results verifiable |
| **Reproducibility (15)** | No missing steps, env info complete, test data explicit |
| **Priority (15)** | P0/P1/P2 reasonable, smoke tests all P0 |
| **Automation (20)** | ROI assessment, flakiness risk, maintenance cost |

### White-box Test Case Review

| Dimension | Focus |
|-----------|-------|
| **Completeness (30)** | 6 categories (perf/security/memory/concurrency/API/internal state) |
| **Tool spec (20)** | Tools explicit (Instruments/Charles/TSAN), setup steps, criteria |
| **Quantifiable (15)** | Perf baseline/threshold, pass/fail criteria, repetition count |
| **Priority (15)** | Security P0, memory P0/P1 |
| **Automation (20)** | CI integration, mock server, TSAN CI, memory automation |

### Test Code Review

| Dimension | Focus |
|-----------|-------|
| **Structure (20)** | AAA pattern, single responsibility, independence |
| **Naming (15)** | Behavior+expectation, consistency |
| **Mock strategy (20)** | Protocol-based, reasonable scope, no over-mocking |
| **Assertions (20)** | Semantic, specific values, error messages |
| **Readability (15)** | Easy to understand, well-commented |
| **Concurrency (10)** | Actor usage, TSAN compatible |

Good/bad patterns: [`code-patterns.md`](./code-patterns.md) (Swift, Kotlin, Dart, Python samples).

## Output

Generates review reports under `.claude/testing/reviews/`. Templates: [`report-templates.md`](./report-templates.md).

Each report contains:
- Overall score (X/100)
- Strengths
- Issues (Critical / Major / Minor)
- Coverage gap analysis
- Recommendations (immediate / short-term / long-term)
- Risk matrix
- Test maturity (Level 1-5)

## Workflow

### Phase 0: Requirement Theme Identification (most important)

Pull the requirement theme from the Spreadsheet title or Markdown frontmatter `feature:`. **The whole review must center on the requirement**, not on code modules.

- ❌ Don't gap-analyze by code file ("LoginView.swift 0 TC")
- ❌ Don't use internal class names in BB TC suggestions
- ✅ Group gaps by user-facing feature ("login flow", "member edit")

### Phase 1: Input detection

### Phase 2: Read & scope

### Phase 3: Score by dimension

### Phase 4: Generate report

### Phase 5: Write back to status sheet (Google Sheet only)

If `review_protocol.tri_party_enabled = true`, write 3 rows (Claude / Codex / Gemini).

If `mode = markdown-only`, write to `.claude/testing/reviews/{name}-summary.md`.

### Phase 6: Ask follow-ups

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `mode = markdown-only` | Whole-skill mode | No google MCP; read/write local .md |
| `review_protocol.tri_party_enabled` | Tri-party review writeback | Single Claude-only row |
| `review_protocol.dimensions` | Scoring dimensions | Default 10 |
| `platforms.{ios,android}.repo` | Auxiliary code check | Skip code comparison |
