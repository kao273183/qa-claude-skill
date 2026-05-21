# QA Claude Skill — Portable QA Workflow Skills for Claude Code

> A configurable, reusable suite of 16 QA skills for Claude Code.
> Extracted from a personal workspace (with JIRA / Slack / Google Drive hardcoded) into a generic version — drop in your `config.json` and use in any team.

[中文版說明](./README.md)

---

## 🎯 What's Included

15 production-grade QA skills covering the full test lifecycle:

| Category | Skill | Purpose |
|----------|-------|---------|
| **Test Design** | `test-master` | Full test plan + black-box/white-box TC generation (native iOS/Android) |
| | `flutter-test-master` | Flutter three-layer (Unit/Widget/Integration) + Golden tests |
| | `test-review` | TC and test-code review (10-dimension scoring) |
| | `regression-test` | Release-level cross-platform regression plans |
| | `speckit-to-tc` | Spec Kit / SDD specs → TC drafts |
| | `tc-version-diff` | TC version diff + retest checklist |
| | `sheet-md-sync` | Google Sheet ↔ Markdown two-way sync |
| | `smoke-test-analyzer` | Daily Smoke CI test triage |
| **Automation** | `test-automation` | iOS (XCUITest) / Android (Espresso) automation |
| | `flutter-test-automation` | Flutter Dart automation scripts |
| | `tc-to-pytest` | White-box API TC → pytest scaffolding |
| **Bug Management** | `bug-report` | RIDER-format Bug reports + JIRA auto-creation |
| **Quality Quantification** | `mutation-testing` | mutmut mutation testing |
| | `property-based-test-gen` | hypothesis property-based / fuzz testing |
| **Reporting** | `publish-regression` | Publish regression reports to S3 dashboard |

---

## 🚀 Quick Start

### 1. Copy the config template

```bash
cd ~/Desktop/QA_Claude_Skill
cp config/config.example.json config/config.json
```

### 2. Fill in your org info

At minimum, set in `config/config.json`:

```json
{
  "jira": {
    "instance_url": "https://your-company.atlassian.net",
    "project_key": "YOUR_PROJECT",
    "reviewer_account_id": "Your Atlassian Account ID"
  },
  "slack": {
    "user_id": "Your Slack User ID (for DMs)",
    "bug_channel_id": "Bug channel ID"
  }
}
```

See [`docs/customization-guide.en.md`](./docs/customization-guide.en.md) for full field reference.

### 3. Install into Claude Code

```bash
./install.sh
```

The script will:
- Render `skills/*` with your config and copy to `~/.claude/skills/`
- Back up any existing same-named skills to `~/.claude/skills.backup-{timestamp}/`
- Warn about unfilled config fields

### 4. Verify

In Claude Code, type `/test-master` or any trigger phrase. The skill should load.

---

## 🧩 Tool Integration Modes

Each skill supports 3 modes via `config.json#mode`:

| Mode | When to use | Behavior |
|------|-------------|----------|
| `full-mcp` | You have atlassian/slack/google MCP installed | Auto-creates tickets, sends notifications, writes Sheets |
| `partial-mcp` | Some MCPs available | Uses MCP when present, falls back to Markdown otherwise |
| `markdown-only` | Pure document output | No MCP calls; produces `.md` reports |

Presets in `config/presets/`.

---

## 📂 Layout

See [README.md (Chinese)](./README.md) — directory structure identical.

---

## 📝 License

MIT — use, modify, redistribute freely.

## 🙏 Credits

Extracted from Jack Kao's personal Claude Code QA workspace. Thanks to the engineers, QA peers, and AI collaborators (Claude / Codex / Gemini) who shaped the original iterations.
