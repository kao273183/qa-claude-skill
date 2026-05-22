---
name: a11y-audit
description: Independent accessibility audit for web/iOS/Android apps. Integrates Lighthouse / axe-core / iOS Accessibility Inspector / Android Accessibility Scanner. Outputs WCAG 2.1 AA scored report, CVSS-like severity, fix suggestions with code snippets. Trigger phrases — "a11y audit", "accessibility audit", "WCAG", "Lighthouse a11y", "axe-core", "VoiceOver check", "TalkBack check", "a11y score".
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[URL / app platform / component path] [--standard=WCAG21AA|WCAG22AA|Section508]"
---

# a11y-audit (English)

> ⚙️ Read [`modules/config-loader.md`](./modules/config-loader.md) first.

## Why

`test-master`'s built-in a11y checks are **planning reminders** (add 4 a11y TCs per UI feature). A real audit needs: tool runs, parsing, WCAG mapping, code-level fix suggestions. This skill does the deep audit.

## When to Use
- Government / finance / healthcare — WCAG 2.1 AA required by law
- Pre-release a11y gate
- Post-design-revamp systematic check
- Compliance evidence (GDPR / ADA / EU EAA)

## Tools by Platform

| Platform | Tool | Standard |
|----------|------|----------|
| Web | Lighthouse / axe-core / WAVE | WCAG 2.1/2.2 |
| iOS | Accessibility Inspector (Xcode) | Apple HIG |
| Android | Accessibility Scanner | Material a11y |
| Flutter | Flutter Inspector + axe-core (Web mode) | WCAG + Material |

## WCAG 2.1 AA Principles

| Principle | Sample Criteria | Tool detectable |
|-----------|----------------|----------------|
| Perceivable | 1.4.3 contrast / 1.4.4 text resize | ✅ axe/Lighthouse |
| Operable | 2.1.1 keyboard / 2.5.5 touch targets | ✅ Mostly |
| Understandable | 3.1.1 language / 3.3.1 error messages | ⚠️ Partial |
| Robust | 4.1.2 a11y API name+role+value | ✅ axe |

## Workflow

### Phase 1: Detect platform + tools

### Phase 2: Run tools
- **Web**: `lighthouse --only-categories=accessibility` or axe-core via Playwright
- **iOS**: `app.performAccessibilityAudit()` in XCUI
- **Android**: `AccessibilityChecks.enable()` in Espresso

### Phase 3: Unified report
Merged JSON → `a11y-audit-report.md` with WCAG mapping, fix code snippets, OWASP-style severity (Critical/Serious/Moderate/Minor).

### Phase 4: Manual augmentation
Tools detect ~40% of WCAG. Skill auto-generates manual checklist for: screen reader reading order, keyboard tab order, dynamic type layout, dark mode contrast, motion sensitivity.

### Phase 5: Auto-ticket
Interactive prompt to create JIRA Critical tickets via `bug-report` skill.

## Safety
- ❌ Don't claim tools detect 100% (explicit "tooling detects ~40% of WCAG")
- ✅ Report includes "manual verification" section
- ✅ Critical findings auto-propose as P0 tickets

## Config Dependencies

| Key | Purpose |
|-----|---------|
| `a11y_audit.standard` | WCAG21AA / WCAG22AA / Section508 |
| `a11y_audit.lighthouse_threshold` | Default 90 |
| `a11y_audit.tools` | axe / lighthouse / wave |
| `workflow.auto_a11y_pairing` | Auto-pair iOS+Android a11y bugs |
