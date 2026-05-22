<h1 align="center">QA Claude Skill</h1>

<p align="center">
  <em>24 production-grade QA workflow skills for Claude Code — from spec to release.</em>
</p>

<p align="center">
  <strong>English</strong> · <a href="README.zh-TW.md">繁體中文</a> · <a href="README.zh-CN.md">简体中文</a>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT" /></a>
  <img src="https://img.shields.io/badge/skills-24-2563EB" alt="24 skills" />
  <img src="https://img.shields.io/badge/Claude%20Code-Compatible-7C3AED?logo=anthropic&logoColor=white" alt="Claude Code Compatible" />
  <img src="https://img.shields.io/badge/Mode-full--mcp%20%7C%20partial--mcp%20%7C%20markdown--only-10B981" alt="3 modes" />
  <img src="https://img.shields.io/badge/i18n-en%20%7C%20zh--TW%20%7C%20zh--CN-FB923C" alt="Multilingual" />
  <a href="https://www.buymeacoffee.com/minikao"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Support-FFDD00?logo=buy-me-a-coffee&logoColor=black" alt="Buy Me a Coffee" /></a>
</p>

> A configurable suite of **24 QA skills** for [Claude Code](https://claude.ai/code), covering the
> full test lifecycle: **spec → TC → automation → performance → security → review → regression → publish**.
> Extracted from a personal QA workspace and generalized via `config.json` —
> drop in your team's IDs and it works in any team, any tool stack.

---

## ✨ Highlights

- 🧪 **Full lifecycle coverage** — Spec parsing, TC design, automation generation, code review, regression planning, bug filing, mutation testing, and dashboard publishing
- 🔌 **Tool-agnostic via 3 modes** — `full-mcp` (Atlassian + Slack + Google) / `partial-mcp` (degrade gracefully when tools missing) / `markdown-only` (zero external dependencies)
- 🌐 **Bilingual** — Every skill ships with `SKILL.md` (zh-TW) + `SKILL.en.md`; 4 concept guides in 繁中 for unfamiliar topics
- 📦 **One-config customization** — 28 variables in `config.json` cover JIRA / Slack / Google / iOS / Android / BE pytest / AWS dashboard
- 🧩 **Pluggable modules** — Each skill has `modules/{config-loader, jira/slack-integration, markdown-fallback}.md` for clean separation
- 🚀 **One-command install** — `./install.sh` validates config, renders 28 placeholders, backs up existing skills, installs to `~/.claude/skills/`
- 🇹🇼 **Designed in Taiwan, ready for global teams** — Includes a11y mandatory checks (Dynamic Type / TalkBack / contrast) and cross-platform pairing baked into every skill

---

## 📦 What's in the box

24 skills across 7 categories:

### Test Design (8)

| Skill | Purpose |
|-------|---------|
| [`test-master`](skills/test-master/) | Full test plan + black-box/white-box TC generation (native iOS/Android + **Web**) |
| [`flutter-test-master`](skills/flutter-test-master/) | Flutter 3-tier pyramid (Unit/Widget/Integration) + Golden + Platform Channel |
| [`test-review`](skills/test-review/) | TC + code review on 10 weighted dimensions; supports Swift/Kotlin/Dart/Python |
| [`regression-test`](skills/regression-test/) | Release-level cross-platform regression plans (JIRA + historical bug analysis) |
| [`speckit-to-tc`](skills/speckit-to-tc/) | Spec Kit / SDD spec → 14-column BB+WB TC draft |
| [`tc-version-diff`](skills/tc-version-diff/) | Diff TC versions; produce changelog + retest checklist |
| [`sheet-md-sync`](skills/sheet-md-sync/) | Two-way sync between Google Sheet ↔ Markdown (for git diff / PR review) |
| [`smoke-test-analyzer`](skills/smoke-test-analyzer/) | Tier existing automated tests into T0/T1/T2/T3 + generate CI configs |

### Automation (3)

| Skill | Purpose |
|-------|---------|
| [`test-automation`](skills/test-automation/) | iOS (Swift Testing + XCUITest) / Android (JUnit + Espresso + Mockk) / **Web (Playwright + Cypress + Selenium/WebdriverIO + Vitest)** script generation |
| [`flutter-test-automation`](skills/flutter-test-automation/) | Dart automation scripts (flutter_test / integration_test / Patrol / Golden) |
| [`tc-to-pytest`](skills/tc-to-pytest/) | White-box API TC → pytest-api-kit triplet (`schemas.py` + `conftest.py` + `tests/test_*_api.py`) |

### Bug Management (1)

| Skill | Purpose |
|-------|---------|
| [`bug-report`](skills/bug-report/) | RIDER-format bug reports + auto-create JIRA + Slack notification + cross-platform pairing |

### Quality Quantification (2)

| Skill | Purpose |
|-------|---------|
| [`mutation-testing`](skills/mutation-testing/) | mutmut mutation testing — quantify TC strength beyond line coverage |
| [`property-based-test-gen`](skills/property-based-test-gen/) | Generate hypothesis @given strategies to auto-explore boundary bugs |

### Reporting (1)

| Skill | Purpose |
|-------|---------|
| [`publish-regression`](skills/publish-regression/) | Publish manual regression reports to S3 + invalidate CloudFront + Slack notification |

### Performance & Security (3) — ✨ NEW in v1.5.0

| Skill | Purpose |
|-------|---------|
| [`performance-test-gen`](skills/performance-test-gen/) | k6 / JMeter / Locust load test scripts + SLA thresholds + ramp-up curves + CI integration |
| [`security-scan`](skills/security-scan/) | SAST (Semgrep) + DAST (OWASP ZAP) + SCA (Snyk/Trivy) + Secret scan (gitleaks) — unified CVSS report |
| [`api-contract-test`](skills/api-contract-test/) | Pact / Schemathesis / Spring Cloud Contract — catch microservice breaking changes at PR time |

### CI Health (2) — ✨ NEW in v1.5.0

| Skill | Purpose |
|-------|---------|
| [`visual-regression-gen`](skills/visual-regression-gen/) | Playwright snapshot / Percy / Chromatic / BackstopJS — auto-mask dynamic elements |
| [`flaky-test-hunter`](skills/flaky-test-hunter/) | Analyze CI history → identify flaky tests → suggest fixes + auto-quarantine |

### Quality Specialties (4) — ✨ NEW in v1.6.0

| Skill | Purpose |
|-------|---------|
| [`a11y-audit`](skills/a11y-audit/) | Deep accessibility audit (Lighthouse / axe / iOS Inspector / Android Scanner) — WCAG 2.1/2.2 AA scored report |
| [`localization-test`](skills/localization-test/) | i18n/l10n verification — missing translations / string overflow / RTL / format / pluralization / locale switch |
| [`push-notification-test`](skills/push-notification-test/) | APNs / FCM / Web Push — 8 test scenarios (delivery / click / deep link / permission / batch perf) |
| [`test-data-factory`](skills/test-data-factory/) | Cross-platform unified fixtures (Swift / Kotlin / Dart / TypeScript / Python) — one schema → 5 factories aligned |

> 💡 **First time hearing of mutation testing / property-based testing / spec-driven dev / test tiering?**
> Each has a 5-minute Chinese intro at `skills/<name>/concept-zh.md`. See [Concept Guides](#-concept-guides).

---

## 🚀 Quick start

```bash
# 1. Clone
git clone https://github.com/kao273183/qa-claude-skill.git ~/Desktop/QA_Claude_Skill
cd ~/Desktop/QA_Claude_Skill

# 2. Create your config
cp config/config.example.json config/config.json

# 3. Fill in the 4 minimum fields:
#    - jira.instance_url
#    - jira.project_key
#    - platforms.ios.default_device
#    - platforms.android.default_device

# 4. Install (renders 28 placeholders → ~/.claude/skills/)
./install.sh

# 5. In Claude Code, try a trigger phrase:
#    "Generate test plan for feature X"
#    "Write a bug report for this crash"
#    "Review these test cases"
```

### Dry-run before installing

```bash
CLAUDE_SKILLS_DIR=/tmp/preview ./install.sh
ls /tmp/preview/   # 24 skill directories
grep -r '{{' /tmp/preview/ | grep -v '變數'   # should be empty
```

---

## 🎛 The 3 modes

Each skill works in all 3 modes; pick the one that matches your team's tooling:

| Mode | When to use | Behavior |
|------|-------------|----------|
| `full-mcp` | You have Atlassian + Slack + Google Workspace MCPs installed | Auto-creates tickets, sends Slack notifications, writes Sheets |
| `partial-mcp` | Some MCPs missing | Uses MCPs when available, falls back to Markdown otherwise |
| `markdown-only` | Solo developer / no MCP / pure documentation flow | Zero external calls; produces `.md` reports under `.claude/testing/` |

3 ready-to-use presets ship in [`config/presets/`](config/presets/) — copy one and edit:

```bash
cp config/presets/full-stack.json     config/config.json   # All MCPs
cp config/presets/jira-only.json      config/config.json   # JIRA only
cp config/presets/markdown-only.json  config/config.json   # Pure docs
```

---

## ⚙️ Customization

Three layers of configurability:

1. **`config.json`** — 28 variables. See [docs/customization-guide.md](docs/customization-guide.md) for the full mapping.
2. **`config/presets/`** — 3 starter scenarios (full-stack / jira-only / markdown-only)
3. **Per-skill modules** — Each skill has `modules/markdown-fallback.md` defining degraded behavior

### Example configurations

- 🏢 [Large team — ACME Corp](examples/jira-acme-corp/config.json) — Full JIRA + Slack + Google + AWS dashboard
- 👤 [Solo developer](examples/solo-developer/config.json) — Pure Markdown, no external deps

---

## 🧩 Architecture

Each skill follows the same pluggable structure:

```
skills/<skill-name>/
├── SKILL.md                          ← Main spec (zh-TW)
├── SKILL.en.md                       ← English mirror
├── concept-zh.md                     ← Beginner intro (for unfamiliar topics)
├── examples.md                       ← 3-5 real usage scenarios
├── templates.md / patterns.md        ← Templates / code patterns
└── modules/                          ← Pluggable integrations
    ├── config-loader.md              ← Load config.json values
    ├── jira-integration.md           ← (optional) JIRA MCP calls
    ├── slack-integration.md          ← (optional) Slack MCP calls
    └── markdown-fallback.md          ← Pure Markdown degradation path
```

This means:
- **Removing JIRA?** Delete `modules/jira-integration.md` references — Slack still works.
- **No Google?** Switch to `markdown-only` mode — every skill stays functional.
- **Adding a new tool integration?** Add `modules/<your-tool>.md` and reference it from `SKILL.md`.

---

## 📖 Concept Guides

For unfamiliar testing concepts, ship-in 繁中 quick reads (5 min each):

| Concept | What's it about | Guide |
|---------|-----------------|-------|
| **Property-based testing** | Why fuzzing 200 inputs beats writing 2 examples | [property-based-test-gen/concept-zh.md](skills/property-based-test-gen/concept-zh.md) |
| **Mutation testing** | Why 100% line coverage isn't enough | [mutation-testing/concept-zh.md](skills/mutation-testing/concept-zh.md) |
| **Spec-Driven Dev (Spec Kit)** | Why spec ticket → 30-second TC draft is possible | [speckit-to-tc/concept-zh.md](skills/speckit-to-tc/concept-zh.md) |
| **Test tiering (T0/T1/T2/T3)** | Why running all tests on every PR is wasteful | [smoke-test-analyzer/concept-zh.md](skills/smoke-test-analyzer/concept-zh.md) |

---

## 🌊 Typical workflows

See [docs/workflow-diagrams.md](docs/workflow-diagrams.md) for ASCII diagrams of:

1. **Spec → Release pipeline (BE feature)** — `speckit-to-tc` → `test-review` → `sheet-md-sync` → `tc-to-pytest` → `mutation-testing` → `property-based-test-gen`
2. **Pre-release prep (mobile)** — `test-master` → `test-automation` → `smoke-test-analyzer` → `regression-test` → `bug-report` → `publish-regression`
3. **TC version bump** — `test-master --quick` → `test-review` → `tc-version-diff` → `tc-to-pytest --incremental`
4. **Markdown-only flow (solo dev)** — All skills produce `.md` under `.claude/testing/`
5. **Tri-party review** — Claude + Codex + Gemini reviewing the same TC, with weighted consensus

---

## 🧰 Compatibility

| What | Requirements |
|------|--------------|
| **Claude Code** | Latest (skills are first-class) |
| **OS** | macOS / Linux / **Windows native (v1.3.0+)** — see [docs/install-windows.md](docs/install-windows.md) |
| **MCP servers (optional)** | atlassian, slack, google-workspace, mcp-google-full, mcp-context-mode |
| **Required CLI tools** | `bash`, `jq`, `git` |
| **Optional CLI tools** | `gh` (GitHub Actions), `aws` (S3 publish), `python3` + `pytest` (BE skills), `flutter` (Flutter skills), `xcodebuild` (iOS), Gradle (Android) |

---

## 🗺 Roadmap

See [ROADMAP.md](ROADMAP.md) for the full picture — what's shipped, what's planned, and what we're explicitly not doing.

**Highlights of what's next**:
- 9 more skills (test-impact-analyzer, oauth-flow-test, payment-test, graphql-test, llm-quality-eval, ...)
- Japanese translation
- Video walkthrough + demo GIF

Want to influence priority? Open a [GitHub Discussion](https://github.com/kao273183/qa-claude-skill/discussions/categories/ideas).

## 🔒 Security

Found a vulnerability? See [SECURITY.md](SECURITY.md) — preferred channel is GitHub Security Advisory.

---

## 🤝 Contributing

PRs welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- How to add a new skill
- How to contribute translations
- How to modify existing skills
- PR checklist

---

## 📝 License & Trademark

**Dual-licensed software** — see [LICENSE](LICENSE) for full details:

| Use Case | License |
|----------|---------|
| 🟢 Personal / education / research / non-profit / evaluation (< 30 days) | [MIT](licenses/MIT.md) (free) |
| 🟢 Open-source contributions to this repo | [MIT](licenses/MIT.md) (free) |
| 🔴 For-profit organization internal use | [Commercial](licenses/COMMERCIAL.md) (paid) |
| 🔴 Bundling in paid product / SaaS / consulting | [Commercial](licenses/COMMERCIAL.md) (paid) |

For commercial licensing, open a [GitHub Issue with `commercial-license` label](licenses/COMMERCIAL.md#step-1-open-a-github-issue).

**Trademark**: "QA Claude Skill" is a trademark of Jack Kao — see [TRADEMARK.md](TRADEMARK.md) for usage rules. The MIT/Commercial license grants source-code rights, **not** trademark rights. You may not name a fork "QA Claude Skill X" without permission.

> This is a **community / personal project** for [Claude Code](https://claude.ai/code) users — NOT an official Anthropic product.

---

## ☕ Support

If this project saves your QA team time, consider buying me a coffee — it keeps the project iterating:

<p align="center">
  <a href="https://buymeacoffee.com/minikao">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me a Coffee" width="200" />
  </a>
</p>

Or just give the repo a ⭐ — it costs nothing and helps others find it.

---

<p align="center">
  Made with ❤️ for QA teams who want to focus on quality, not paperwork.
</p>
