---
name: security-scan
description: Integrate mainstream security scan tools (SAST/DAST/SCA/Secret scan) into CI. Auto-generate security TCs, produce CVSS-scored security reports. Supports Semgrep / Snyk / OWASP ZAP / Trivy / gitleaks / Bandit. Trigger phrases — "security scan", "SAST", "DAST", "SCA", "Semgrep", "Snyk", "OWASP ZAP", "Trivy", "vulnerability scan", "CVE", "security test", "compliance test".
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[scan target / project path] [--type=sast|dast|sca|secret] [--severity=high|critical]"
---

# security-scan (English)

> ⚙️ Read [`modules/config-loader.md`](./modules/config-loader.md) first.
> Activation: `config.security_scan.enabled = true`.

## Why

Compliance mandate: ISO 27001 / SOC 2 / PCI-DSS / OWASP all require periodic scans. Security bugs are **100× more expensive** than functional bugs.

## The 4 Categories

| Type | Full Name | Target | Tools |
|------|-----------|--------|-------|
| **SAST** | Static Application Security Testing | Source code | Semgrep / SonarQube / CodeQL / Bandit |
| **DAST** | Dynamic Application Security Testing | Running app | OWASP ZAP / Burp Suite |
| **SCA** | Software Composition Analysis | Dependencies | Snyk / Trivy / OSV-Scanner / Dependabot |
| **Secret Scan** | Hardcoded credentials | Git history | gitleaks / TruffleHog |

## When to Use
- Pre-release (every release)
- Compliance (PCI-DSS / SOC 2 / ISO 27001)
- Open-source projects (pre-PR-merge gate)
- Microservices with many dependencies

## Workflow

### Phase 1: Detect language/framework
- `package.json` → Snyk + Semgrep
- `requirements.txt` → Bandit + Semgrep + Snyk
- `pom.xml` → OWASP Dependency-Check + Semgrep
- `Dockerfile` → Trivy + Hadolint
- `*.tf` → tfsec / Checkov

### Phase 2: Run 4 categories

**SAST**: `semgrep --config=auto --severity=ERROR`
**SCA**: `snyk test --severity-threshold=high` / `trivy fs .`
**DAST**: `zap-baseline.py -t https://uat.example.com`  ⚠️ **Never production**
**Secret**: `gitleaks detect --source .`

### Phase 3: Unified report
Merge 4 JSON → `security-report.md` with CVSS scores, fix suggestions, JIRA ticket links.

### Phase 4: CI tier strategy

| Scan | When | Why |
|------|------|-----|
| Secret scan | Every PR | Fast, must block hardcoded tokens |
| SAST | Every PR | Fast static analysis |
| SCA | PR + nightly | Medium, dependency vulns |
| DAST | Nightly + pre-release | Slow, needs running app |

### Phase 5: Auto fix suggestions
Per finding: What / Where / Why bad / How to fix + code snippet / OWASP refs.

Optional: auto-create JIRA tickets via `bug-report` skill (priority = Highest for Critical).

## Safety
- ❌ **Never run DAST on production**
- ❌ Found tokens must NOT be committed (or pasted in chat)
- ✅ Critical findings auto-block PR merge
- ✅ Reports include CVSS + fix deadline
- ⚠️ If must ship before fix → risk acceptance document, PM/Security sign-off

## Config Dependencies

| Key | Purpose |
|-----|---------|
| `security_scan.enabled` | Activates skill |
| `security_scan.tools` | Which tools to enable |
| `security_scan.severity_threshold` | CI fail threshold |
| `security_scan.dast_target_url` | DAST target (must be staging) |
