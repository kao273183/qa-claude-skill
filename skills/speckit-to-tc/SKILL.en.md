---
name: speckit-to-tc
description: From GitHub Spec Kit / SDD spec docs (Jira ticket description / spec.md / api.md), one-shot draft a BB+WB TC markdown using the 14-column structure and auto-place into the configured repo path. Trigger phrases — "draft TC from spec", "speckit closed, write TC", "convert this spec ticket to TC". Pair with test-review (validate draft), test-master (deep design), tc-to-pytest (draft → pytest triplet).
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__atlassian__getJiraIssue
argument-hint: "[JIRA key / spec file path / ticket URL]"
---

# speckit-to-tc (English)

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first**.
> Activation: `config.speckit.enabled = true`.

## Use When
- A "spec ticket" just closed
- You have `spec.md` / `api.md` and want a first-cut TC
- Distilling spec docx/wireframe descriptions into TC

## Don't Use For
- Spec not yet final
- Pure script generation (use `test-automation`)
- Already-complete TC — upgrade with `test-review` + `test-master`

## Workflow

### Phase 1: Get spec source
- Jira key → atlassian MCP / curl
- Local spec.md → Read
- URL → extract key

```bash
curl -s "{{JIRA_INSTANCE_URL}}/rest/api/3/issue/<KEY>" \
  -u "$ATLASSIAN_EMAIL:$ATLASSIAN_TOKEN" -H "Accept: application/json"
```

ADF descriptions → flatten to markdown (recurse over `text` fields).

### Phase 2: Feature routing

From `config.speckit.feature_routing`:
```json
{
  "feature_routing": [
    { "keywords": ["stamp", "NFC"], "path": "love/stamp/", "epic": "{{JIRA_PROJECT_KEY}}-XXXX" },
    { "keywords": ["health", "HealthKit"], "path": "peace/health/" }
  ],
  "fallback": "ask_user"
}
```

Output file: `tc-be-{KEY}-draft.md` in matched path.

### Phase 3: Read context
spec.md, api.md, tc-index.md, existing TC markdown.

### Phase 4: Draft TC

14 columns (A-N) matching the generic template. Categories:

**BB (9)**: Smoke 4-phase / Functional / Boundary/Exception / Error handling / Lifecycle / Cross-platform / E2E / Performance / a11y

**WB (6)**: API verification / Performance baseline / Security / Memory / Concurrency / Internal state

**a11y mandatory (4 per draft, when `workflow.auto_a11y_pairing = true`)**: Dynamic Type max / fontScale max / VoiceOver-TalkBack reading order / Touch targets + contrast.

**BE-only ticket**: BB 30% / WB 70%, platform = `BE-only`, automation = `Y`.

### Phase 5: Write
Frontmatter + `## Black-box (BB)` + `## White-box (WB)` + `## 設計依據`.

### Phase 6: Suggest next steps
1. Review draft
2. `/test-review tc-be-{KEY}-draft.md`
3. Upload to Sheet (`/sheet-md-sync` or manual)
4. BE part → `/tc-to-pytest`

## Safety
- ✅ Write only `tc-be-{KEY}-draft.md`
- ❌ No auto-upload to Sheet (draft only)
- ❌ No commit/push
- ❌ Don't invent uncovered features — mark them uncovered
- ⚠️ ADF parse fail → fallback to plain text, no guessing

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `speckit.enabled` | Activates skill | Skill off |
| `speckit.repo_root` | Draft output root | Ask interactively |
| `speckit.feature_routing` | Routing rules | Fallback ask |
| `jira.instance_url` | Fetch Jira ticket | Use local spec file |
| `workflow.auto_a11y_pairing` | a11y mandatory 4 | Make optional |
