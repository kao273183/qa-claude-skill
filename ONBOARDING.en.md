# Welcome to QA Claude Skill 👋

Hi! This is a configurable suite of **15 QA skills** for Claude Code, covering the full test lifecycle — from spec parsing to release publishing.

## 🎯 What you'll do in 5 minutes

1. **Pick a preset** that matches your team
2. **Fill in your IDs** (JIRA / Slack / Google)
3. **Run `install.sh`** (or `.\install.ps1` on Windows)
4. **Try a skill** — `/test-master` or `/bug-report`

That's it. The 15 skills will degrade gracefully based on what tools you have.

---

## 📦 What's inside

| Category | Skills |
|----------|--------|
| **Test Design** (8) | test-master / flutter-test-master / test-review / regression-test / speckit-to-tc / tc-version-diff / sheet-md-sync / smoke-test-analyzer |
| **Automation** (3) | test-automation / flutter-test-automation / tc-to-pytest |
| **Bug Management** (1) | bug-report |
| **Quality Quantification** (2) | mutation-testing / property-based-test-gen |
| **Reporting** (1) | publish-regression |

Full reference: [docs/skill-index.md](docs/skill-index.md)

---

## 🚀 Quick start (3 commands)

```bash
# 1. Pick a preset
cp config/presets/markdown-only.json config/config.json   # 最簡單，零外部依賴

# 2. Edit (at minimum: jira.project_key + jira.instance_url)
vim config/config.json

# 3. Install
./install.sh        # macOS / Linux
.\install.ps1       # Windows PowerShell
```

Now in Claude Code, type:
```
Generate test plan for a login feature
```

The `test-master` skill will activate and walk you through.

---

## 🎛 Pick your mode

| Your situation | Use mode | Preset |
|---------------|----------|--------|
| Have JIRA + Slack + Google MCPs | `full-mcp` | `config/presets/full-stack.json` |
| Have only JIRA | `partial-mcp` | `config/presets/jira-only.json` |
| Solo developer / no MCPs | `markdown-only` | `config/presets/markdown-only.json` |
| Startup team < 10 ppl | `partial-mcp` | `config/presets/startup.json` |
| Enterprise team > 100 ppl | `full-mcp` | `config/presets/enterprise.json` |
| Government / high-compliance | `markdown-only` | `config/presets/government.json` |

---

## 🧠 Concept primers (5-min reads, 繁中)

Unfamiliar with these testing concepts? Each has a beginner-friendly intro:

- 💥 [**Property-based testing**](skills/property-based-test-gen/concept-zh.md) — Why fuzzing 200 inputs beats writing 2 examples
- 🧬 [**Mutation testing**](skills/mutation-testing/concept-zh.md) — Why 100% line coverage isn't enough
- 📋 [**Spec-Driven Dev (Spec Kit)**](skills/speckit-to-tc/concept-zh.md) — Why spec ticket → 30-second TC draft is possible
- 🎯 [**Test tiering (T0/T1/T2/T3)**](skills/smoke-test-analyzer/concept-zh.md) — Why running all tests on every PR is wasteful

---

## 🌊 Try a workflow

### Workflow 1: Write your first bug report

In Claude Code:
```
I want to file a bug — the login screen crashes on Android
```

The `bug-report` skill activates, walks you through RIDER format, and creates the JIRA ticket.

### Workflow 2: Generate test plan for a new feature

```
Generate test plan for: User can edit profile (name, avatar, bio)
```

`test-master` creates:
- `test-strategy.md`
- Black-box + White-box test cases (Google Sheet or .md)
- Coverage gap analysis
- Automation roadmap
- Exploratory testing guide

### Workflow 3: Review existing TC quality

```
Review these test cases — <Google Sheet URL>
```

`test-review` scores on 10 dimensions, identifies Critical / Major / Minor issues.

---

## 🔧 Useful commands

```bash
# Validate config without installing
./scripts/validate-config.sh

# Dry-run (don't touch ~/.claude/skills/)
CLAUDE_SKILLS_DIR=/tmp/preview ./install.sh

# Uninstall + restore backup
./uninstall.sh
```

---

## 📚 Deep dives

- [README.md](README.md) — Full overview
- [INSTALL.md](INSTALL.md) — Installation step-by-step
- [docs/customization-guide.md](docs/customization-guide.md) — All 28 variables explained
- [docs/workflow-diagrams.md](docs/workflow-diagrams.md) — Skill chain visualizations
- [docs/ci-integration.md](docs/ci-integration.md) — GitHub Actions / GitLab CI / CircleCI templates
- [docs/install-windows.md](docs/install-windows.md) — Windows-specific install
- [docs/migration-from-personal.md](docs/migration-from-personal.md) — Migrating from a personal version with hardcoded IDs

---

## 🤝 Need help?

- 🐛 Found a bug? Open an issue
- 💡 Have an idea? See [CONTRIBUTING.md](CONTRIBUTING.md)
- 📖 Want to add a new skill? `skills/_template/` has the structure

---

<p align="center">
  Made with ❤️ for QA teams who want to focus on quality, not paperwork.
</p>
