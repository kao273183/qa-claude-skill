# Roadmap

The plan for what's coming, what's done, and what we're explicitly **not** doing.

This is a living document — feel free to suggest priorities via [GitHub Discussions](https://github.com/kao273183/qa-claude-skill/discussions) or [Issues](https://github.com/kao273183/qa-claude-skill/issues).

---

## ✅ Shipped

### Core infrastructure

- [x] **Schema validation** — `scripts/validate-config.sh` (v1.1.0)
- [x] **6 ready-to-use presets** — full-stack / jira-only / markdown-only / startup / enterprise / government (v1.1.0)
- [x] **CI/CD integration templates** — GitHub Actions / GitLab CI / CircleCI (v1.2.0)
- [x] **Windows native support** — PowerShell scripts, no WSL needed (v1.3.0)
- [x] **Web platform support** — Playwright / Cypress / Selenium / Vitest (v1.3.0)
- [x] **Multilingual** — English / 繁體中文 / 简体中文 (v1.4.0)
- [x] **Dual License** — MIT (non-commercial) + Commercial (v1.6.1)
- [x] **Trademark protection** — TRADEMARK.md (v1.6.2)
- [x] **Public repo** with git history cleaned (v1.6.2)

### Skills (24 total)

#### Test Design (8)
test-master · flutter-test-master · test-review · regression-test · speckit-to-tc · tc-version-diff · sheet-md-sync · smoke-test-analyzer

#### Automation (3)
test-automation · flutter-test-automation · tc-to-pytest

#### Bug Management (1)
bug-report

#### Quality Quantification (2)
mutation-testing · property-based-test-gen

#### Reporting (1)
publish-regression

#### Performance & Security (3) — v1.5.0
performance-test-gen · security-scan · api-contract-test

#### CI Health (2) — v1.5.0
visual-regression-gen · flaky-test-hunter

#### Quality Specialties (4) — v1.6.0
a11y-audit · localization-test · push-notification-test · test-data-factory

---

## 🚧 In progress

*(currently nothing actively being worked on — suggestions welcome)*

---

## 📋 Planned (next 3 months)

### Skills

#### High CP value (medium effort)

- [ ] **`test-impact-analyzer`** — Analyze which tests are affected by code changes; cut CI time
- [ ] **`oauth-flow-test`** — OAuth 2.0 / OIDC / SSO flow testing templates
- [ ] **`websocket-realtime-test`** — WebSocket / SSE / SignalR realtime testing
- [ ] **`db-migration-test`** — Flyway / Liquibase / Alembic migration validation

#### Industry-specific

- [ ] **`payment-test`** — In-app purchase / Stripe / Apple Pay / subscription testing
- [ ] **`graphql-test`** — GraphQL schema-driven testing + N+1 query detection
- [ ] **`chaos-test-plan`** — Chaos Monkey / Litmus for distributed systems
- [ ] **`watch-tv-test`** — watchOS / tvOS / visionOS test planning
- [ ] **`llm-quality-eval`** — AI/LLM app quality (hallucination / cost / latency)

### Platform & docs

- [ ] **Japanese translation** — `README.ja.md`
- [ ] **Video walkthrough** — Loom / YouTube screencast of a typical workflow
- [ ] **Demo GIF in README** — visual quick-look of a skill in action
- [ ] **Skill index by use case** — "I'm doing X, which skill?"

---

## 💭 Considering (no commitment)

These are interesting but unclear ROI / need community feedback:

- [ ] **Web UI for config editing** — visual editor for `config.json` (1-2 days work; needs validation that users actually want it)
- [ ] **Plugin marketplace integration** — submit to MCP server registries / Claude Code skill catalog
- [ ] **Slack bot wrapper** — trigger skills from Slack instead of Claude Code
- [ ] **VS Code extension** — IDE integration for skill triggers
- [ ] **More language support** — 한국어 / Português / Deutsch

---

## ❌ Explicitly not doing

We deliberately decided **against** these, with reasoning:

### Skill telemetry / usage analytics

**Decision**: removed from roadmap (was v1.0.0 placeholder).

**Why not**:
- Skills are markdown — no execution hook to insert telemetry calls
- Privacy consent + backend maintenance cost > value
- Open-source telemetry historically draws backlash
- GitHub Insights / Issues / surveys are cheaper alternatives

### Cloud-hosted SaaS version

**Decision**: stay self-hosted only.

**Why not**:
- Defeats the "drop into ~/.claude/skills/" simplicity
- Locks customers in (not aligned with MIT spirit)
- Maintenance load is full-time job
- Commercial License covers enterprise needs without SaaS

### Forking the official Anthropic Claude Code

**Decision**: stay as a separate skill suite.

**Why not**:
- This is a community project; not official
- Forking would create namespace confusion
- Anthropic should own Claude Code direction

---

## 🤝 How to influence the roadmap

The roadmap is shaped by:

1. **Direct user requests** — open a [GitHub Discussion](https://github.com/kao273183/qa-claude-skill/discussions/categories/ideas) with the `idea` category
2. **Bug reports that reveal missing features** — file an issue
3. **PRs** — if you build it, we're more likely to ship it
4. **Commercial customers** — paid customers can request prioritization (see [LICENSE-COMMERCIAL.md](LICENSE-COMMERCIAL.md))
5. **Conference talks / blog posts I write** — sometimes ideas emerge from explaining concepts

If you want to **vote** on existing items, leave a 👍 reaction on the corresponding issue.

---

## 📅 Release cadence

- **Patch releases** (v1.6.x → v1.6.y) — bugfixes / docs / small improvements (as needed)
- **Minor releases** (v1.6 → v1.7) — new skills, new presets, new features (typically every 2-4 weeks)
- **Major releases** (v1 → v2) — breaking changes (rare; only when config schema needs to evolve incompatibly)

Follow [Releases](https://github.com/kao273183/qa-claude-skill/releases) for notifications.

---

*Last updated: 2026-05-22 · Maintained by Jack Kao*
