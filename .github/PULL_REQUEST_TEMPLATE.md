<!--
Thanks for the PR! Please fill out the sections below.
Delete sections that don't apply.
-->

## What does this PR do?

<!-- One-line summary -->

## Type

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 🚀 New skill (added a new skill under `skills/`)
- [ ] 💥 Breaking change (fix or feature that changes existing behavior)
- [ ] 📖 Documentation update
- [ ] 🧹 Refactor / cleanup (no functional change)
- [ ] 🌐 Translation
- [ ] 🔧 Config / preset update
- [ ] 🛡 Security fix
- [ ] 🧪 Test addition / improvement

## Related issue

<!-- e.g. Closes #42 / Refs #17 / "No related issue, ad-hoc improvement" -->

## Changes

<!-- What changed concretely? File-by-file is fine if helpful. -->

-
-
-

## Pre-merge checklist

### Required

- [ ] I ran `./scripts/validate-config.sh config/config.example.json` — passes
- [ ] I ran `CLAUDE_SKILLS_DIR=/tmp/preview ./install.sh` — 0 unresolved `{{vars}}`
- [ ] I did not commit `config/config.json` or any real tokens / IDs
- [ ] My commit messages follow the existing convention (English / 繁中 both OK)

### If adding a new skill

- [ ] `SKILL.md` (zh-TW) + `SKILL.en.md` both present
- [ ] `examples.md` with at least 3 usage scenarios
- [ ] `modules/config-loader.md` + `modules/markdown-fallback.md` (copy from existing skill)
- [ ] Listed in README × 3 languages
- [ ] Added entry to `CHANGELOG.md`
- [ ] Concept introduction (`concept-zh.md`) if the topic is unfamiliar to most QA folks
- [ ] Added to `ROADMAP.md` (moved from "Planned" to "Shipped" if applicable)

### If translating

- [ ] Used proper local terminology (e.g. 軟體 for zh-TW vs 软件 for zh-CN)
- [ ] Links work in both directions
- [ ] Original meaning preserved (no paraphrasing that changes intent)

### If touching install scripts

- [ ] Both `install.sh` (bash) and `install.ps1` (PowerShell) updated equivalently
- [ ] Tested on macOS / Linux (bash) **and** Windows (PowerShell) if reasonable
- [ ] Added new `{{VAR_NAME}}` to both renderers if introducing a new template variable

### If updating config schema

- [ ] Updated `config/config.example.json`
- [ ] Updated `config/config.schema.json`
- [ ] Updated `scripts/validate-config.sh` and `.ps1` validators if new fields are required
- [ ] Updated `docs/customization-guide.md` variable table

## How to verify

<!-- Steps a reviewer can run to verify your change works -->

```bash
# Example:
cp config/config.example.json config/config.json
CLAUDE_SKILLS_DIR=/tmp/test ./install.sh
ls /tmp/test/{new-skill-name}/
```

## Screenshots / Demo (optional)

<!-- Drag images here, or paste a terminal recording if helpful -->

## Notes for reviewer

<!-- Anything to call out — edge cases, design decisions, alternative approaches considered -->
