---
name: localization-test
description: Dedicated i18n/l10n test workflow. Verifies missing translations, string length overflow (German often breaks), RTL languages (Arabic, Hebrew), date/number/currency format, locale switch without restart, pluralization rules. Trigger phrases — "localization", "i18n", "l10n", "multilingual test", "translation test", "RTL test", "string overflow", "locale switch", "Arabic test", "missing translations".
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[locale list / translation files path] [--check=missing|length|rtl|format|all]"
---

# localization-test (English)

> ⚙️ Read [`modules/config-loader.md`](./modules/config-loader.md) first.

## Common Multilingual App Bugs
- **Missing translations** → English fallback in non-English UI
- **String overflow** → German is +30% length, breaks buttons
- **RTL rendering** → Arabic/Hebrew should mirror entire layout
- **Format errors** → Date 03/05 means Mar 5 (US) vs May 3 (EU)
- **Pluralization** → "1 item / 2 items" fails in Russian (3 plural forms)
- **Locale switch** → Switched locale but some pages didn't update

## When to Use
- App in ≥ 3 markets/languages
- Pre-launch overseas
- Adding new language (baseline check)

## 6 Check Dimensions

### 1. Translation completeness
Diff resource files across locales.

### 2. String length overflow

| Language | Relative to English |
|----------|---------------------|
| German | +30% |
| French | +20% |
| Spanish | +25% |
| Japanese | -40% |
| Chinese | -50% |
| Arabic | +5% |

### 3. RTL rendering
For ar/he/fa/ur: layout mirrors, text aligns right, but numbers/English stay LTR, icons don't flip.

### 4. Date/Number/Currency format
Check usage of Intl.DateTimeFormat / Intl.NumberFormat with locale.

### 5. Pluralization rules
Avoid `count > 1 ? 'items' : 'item'` — use i18n library.

### 6. Locale switch without restart
Verify all open pages update, no token reset.

## Workflow

### Phase 1: Detect i18n framework
i18next / react-i18next / Flutter intl / NSLocalizedString / Android strings.xml

### Phase 2: Run 6 checks per locale

### Phase 3: Unified report
Missing keys / overflow elements / RTL issues / format issues / pluralization issues / switch issues.

## Safety
- ❌ Don't evaluate translation quality (linguist's job)
- ✅ Only report structural issues
- ✅ Visual regression needs baselines first

## Config Dependencies

| Key | Purpose |
|-----|---------|
| `localization.supported_locales` | Locale list |
| `localization.base_locale` | Default "en" |
| `localization.translation_files_pattern` | Resource file glob |
| `localization.rtl_locales` | Default ["ar", "he", "fa"] |
