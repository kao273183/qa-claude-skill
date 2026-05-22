# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported |
|---------|-----------|
| 1.6.x   | ✅ |
| 1.5.x   | ✅ |
| 1.4.x   | ⚠️ Critical fixes only |
| 1.3.x   | ⚠️ Critical fixes only |
| < 1.3   | ❌ Please upgrade |

## Reporting a Vulnerability

### 🔒 Private disclosure (preferred)

For any **non-public** security issue, please use **GitHub Security Advisories**:

1. Go to https://github.com/kao273183/qa-claude-skill/security/advisories/new
2. Fill in the form with:
   - Description of the vulnerability
   - Steps to reproduce
   - Affected versions
   - Suggested fix (if any)
3. Submit — only the maintainer and you will see this initially

This is the **preferred channel** because it keeps the issue private until a fix is available.

### Public discussion (for non-sensitive issues)

If the issue is **not sensitive** (e.g. a hardening suggestion, a config validation gap, a documentation issue), you can also:

- Open a regular [GitHub Issue](https://github.com/kao273183/qa-claude-skill/issues/new) with the `security` label
- Or start a [GitHub Discussion](https://github.com/kao273183/qa-claude-skill/discussions) in the "Security" category

## Response Timeline

| Stage | Target |
|-------|--------|
| Acknowledgement | Within **2 business days** |
| Initial assessment + severity | Within **5 business days** |
| Fix release (Critical) | Within **7 days** of confirmation |
| Fix release (High) | Within **30 days** of confirmation |
| Fix release (Medium/Low) | Next minor release |
| Public disclosure | After fix is released + 7 days grace period |

## In Scope

Security issues we care about:

### 🔴 Critical

- **Arbitrary code execution** via `install.sh` / `install.ps1` (e.g. malicious `config.json` triggers shell injection)
- **Credential exfiltration** — any skill leaking JIRA tokens, AWS keys, etc. without user consent
- **Path traversal** in install scripts (e.g. `CLAUDE_SKILLS_DIR=../../../etc/passwd`)
- **Prompt injection** in skill markdown that could exfiltrate user data via Claude Code MCP calls

### 🟡 High

- Validator bypass (`scripts/validate-config.sh` fails to catch malformed input that downstream skills can't handle safely)
- Insecure defaults in any preset
- Sensitive data written to logs (e.g. tokens echoed)
- Race conditions in `install.sh` backup/restore logic

### 🟢 Medium

- Outdated example dependencies (e.g. Playwright version in `web-patterns.md` with known CVE)
- Insufficient documentation about secure configuration
- Missing input sanitization in templates

### 🔵 Low

- Hardening suggestions (e.g. add additional config validation checks)
- Missing security headers in CI/CD templates

## Out of Scope

Issues we will **not** treat as security vulnerabilities:

- **Issues with Claude Code itself** — report to Anthropic, not us
- **Issues with MCP servers** (atlassian, slack, google-workspace) — report to those projects
- **Issues with downstream tools** (k6, mutmut, OWASP ZAP, etc.) — report to those projects
- **User misconfiguration** (e.g. accidentally committing `config.json` with real tokens — see `.gitignore`)
- **Social engineering** of project maintainers
- **Theoretical vulnerabilities** without a working PoC
- **Best-practice suggestions** that aren't actual vulnerabilities (file as a regular feature request)

## Acknowledgements

We thank the following researchers and contributors for responsibly disclosing issues:

<!-- Add names here as reports come in -->
*(No reports yet — be the first!)*

If you'd like to be credited, include your preferred handle / name in the report. If you prefer to stay anonymous, that's fine too.

## Security best practices for users

When you adopt this skill suite, please:

1. **Never commit `config/config.json`** — it's gitignored by default; verify before pushing
2. **Use GitHub Secrets / Vault for tokens** — don't paste real JIRA / Slack / AWS tokens in plain text
3. **Run `scripts/validate-config.sh` before installing** — catches misconfigurations
4. **Review pull requests carefully** — especially changes to `install.sh`, `install.ps1`, and skill markdown
5. **Keep dependencies updated** — particularly Python (`pytest`, `mutmut`, `hypothesis`) and Node (Playwright, Cypress)
6. **For commercial deployments** — see the [Commercial License](LICENSE-COMMERCIAL.md) FAQ for hardening guidance

## Updates to this policy

This security policy may be updated. Significant changes will be announced in the [release notes](https://github.com/kao273183/qa-claude-skill/releases).

Last updated: 2026-05-22
