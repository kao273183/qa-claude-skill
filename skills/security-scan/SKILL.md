---
name: security-scan
description: 整合主流安全掃描工具（SAST / DAST / SCA / Secret scan）到 CI pipeline，自動生成安全 TC、產出含 CVSS 評分的安全報告。支援 Semgrep / Snyk / OWASP ZAP / Trivy / gitleaks / Bandit。當使用者提到「安全掃描 / SAST / DAST / SCA / Semgrep / Snyk / OWASP ZAP / Trivy / 漏洞掃描 / CVE / 安全測試 / 合規測試」時觸發。配套：test-master（規劃 security TC）、bug-report（追安全漏洞）、regression-test（release 前安全回歸）。
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[掃描目標 / 專案路徑] [--type=sast|dast|sca|secret] [--severity=high|critical]"
---

# security-scan

> ⚙️ **執行前先讀 [`modules/config-loader.md`](./modules/config-loader.md)**。
> 啟用條件：`config.security_scan.enabled = true`。

## 為什麼需要

合規剛需：
- ISO 27001 / SOC 2 / PCI-DSS 都要求定期安全掃描
- 政府專案必跑 OWASP ZAP / 弱點掃描
- 金融 / 醫療必跑 SCA（檢查依賴漏洞）

且**安全 bug 比功能 bug 貴 100×** — 上線後才發現代價極大。

## 安全測試的 4 大類

| 類型 | 全名 | 掃描對象 | 工具範例 |
|------|------|---------|---------|
| **SAST** | Static Application Security Testing | 原始碼 | Semgrep / SonarQube / CodeQL / Bandit |
| **DAST** | Dynamic Application Security Testing | 跑起來的應用 | OWASP ZAP / Burp Suite |
| **SCA** | Software Composition Analysis | 第三方依賴 | Snyk / Trivy / OSV-Scanner / Dependabot |
| **Secret Scan** | 找硬編碼的 API key / token | git 歷史 | gitleaks / TruffleHog |

## 適用場景

- ✅ 上 production 前必跑（每 release）
- ✅ 合規場景（PCI-DSS / SOC 2 / ISO 27001）
- ✅ Open source 專案（接受 PR 前先 scan）
- ✅ 微服務多 repo / 多依賴

## 不適用場景

- ❌ 純 prototype / hackathon
- ❌ 已有專業滲透測試廠商 — 此 skill 是 baseline，不取代專業
- ❌ 沒有合規需求 + 內網應用 — CP 值不高

## 執行流程

### Phase 1: 偵測語言 / 框架

| 偵測 | 推薦工具 |
|------|---------|
| `package.json` (Node) | Snyk + Semgrep |
| `requirements.txt` / `pyproject.toml` (Python) | Bandit + Semgrep + Snyk |
| `pom.xml` / `build.gradle` (Java/Kotlin) | OWASP Dependency-Check + Semgrep |
| `Cargo.toml` (Rust) | cargo-audit |
| `go.mod` (Go) | govulncheck + Semgrep |
| `*.swift` (iOS) | xcodebuild static analyzer + Semgrep |
| Dockerfile | Trivy + Hadolint |
| `.tf` (Terraform) | tfsec / Checkov |

### Phase 2: 跑 4 大類掃描

#### SAST: Semgrep (跨語言)

```yaml
# .semgrep.yml
rules:
  - id: hardcoded-jwt-secret
    pattern: |
      JWT_SECRET = "..."
    severity: ERROR
    message: JWT secret should be from env var
```

```bash
semgrep --config=auto --severity=ERROR --output=semgrep-report.json
```

#### SCA: Snyk

```bash
snyk test --severity-threshold=high --json > snyk-report.json
```

或 Trivy（Container + dependencies）：
```bash
trivy fs . --severity HIGH,CRITICAL --format json --output trivy-report.json
```

#### DAST: OWASP ZAP

```bash
docker run -v $(pwd):/zap/wrk/:rw \
  -t owasp/zap2docker-stable \
  zap-baseline.py -t https://uat.example.com \
                  -J zap-report.json
```

> ⚠️ DAST **絕對不對 production 跑**。

#### Secret Scan: gitleaks

```bash
gitleaks detect --source . --report-format json --report-path gitleaks-report.json
```

### Phase 3: 統一報告格式

把 4 個 JSON 合併成統一 `security-report.md`：

```markdown
# Security Scan Report · my-app · 2026-05-22

## 📊 整體
- SAST (Semgrep):  3 HIGH / 12 MEDIUM / 8 LOW
- SCA (Snyk):      1 CRITICAL / 7 HIGH / 22 MEDIUM
- DAST (ZAP):      0 HIGH / 4 MEDIUM
- Secret scan:     0 found

**Risk Score**: 7/10 (1 Critical 拉高)

## 🔴 Critical / Must fix before release

### #1 Snyk: CVE-2024-XXXXX in `lodash@4.17.20`
- **CVSS**: 9.8 (Critical)
- **Type**: Prototype pollution
- **Fix**: upgrade to `lodash@4.17.21`
- **Impact**: All endpoints using lodash sort

### #2 Semgrep: SQL injection in `auth/login.py:42`
- **Severity**: ERROR
- **Code**: `db.execute(f"SELECT * FROM users WHERE email = '{email}'")`
- **Fix**: 用 parameterized query
- **Impact**: 完整資料庫存取

## 🟡 High / Should fix this sprint

[8 條...]

## 🟢 Medium / Backlog

[38 條...]

## 📋 自動化建議

立刻動作:
- [ ] Snyk Critical: 升級 lodash（PR feature/fix-cve-2024-xxxxx）
- [ ] Semgrep SQL injection: 改 parameterized query
- [ ] 建 2 個 JIRA Security ticket（high priority）

中期動作:
- [ ] CI gate: Critical / High 自動阻擋 merge
- [ ] 月跑一次完整掃描（cron）

## 📈 趨勢

- 上次掃描 (2026-04): 12 High / 1 Critical
- 這次:                7 High / 1 Critical (-5)
```

### Phase 4: CI 整合（4 種掃描分層）

| 掃描 | 何時跑 | 為什麼 |
|------|-------|--------|
| **Secret scan** | 每次 PR | 快，必擋硬編碼 token |
| **SAST (Semgrep)** | 每次 PR | 快，靜態分析 |
| **SCA (Snyk)** | 每次 PR + nightly | 中速，依賴漏洞 |
| **DAST (ZAP)** | nightly + release 前 | 慢，需要跑起來的應用 |

```yaml
# .github/workflows/security.yml
on:
  pull_request: {}
  schedule:
    - cron: '0 18 * * *'   # daily

jobs:
  fast-scans:
    if: github.event_name == 'pull_request'
    steps:
      - uses: gitleaks/gitleaks-action@v2
      - uses: returntocorp/semgrep-action@v1
      - uses: snyk/actions/node@master

  deep-scans:
    if: github.event_name == 'schedule'
    steps:
      - uses: zaproxy/action-baseline@v0.10.0
        with:
          target: 'https://uat.example.com'
```

### Phase 5: 修復建議自動產出

對每個 finding 生成：
1. **What**: 漏洞描述（CVE / CWE）
2. **Where**: 檔案 / 行數 / 依賴
3. **Why bad**: 攻擊場景
4. **How to fix**: 具體修法 + code snippet
5. **References**: OWASP / CWE 連結

可選：自動建 JIRA ticket（用 `bug-report` skill，priority = Highest for Critical）。

## ⚠️ 安全護欄

- ❌ DAST **絕對不對 production 跑**
- ❌ Secret scan 找到的 token **不能 commit 到 git**（也別貼到 chat）
- ✅ Critical finding **自動阻擋 PR merge**
- ✅ 報告含 CVSS 評分 + 修復截止日期
- ⚠️ 修復前若必須上線 → 寫 risk acceptance document，PM/Security 簽核

## 設定依賴

| 設定 Key | 用途 | 缺值時行為 |
|---------|------|-----------|
| `security_scan.enabled` | 啟用此 skill | skill 不啟用 |
| `security_scan.tools` | 啟用哪些工具 | 預設 semgrep + snyk + gitleaks |
| `security_scan.severity_threshold` | CI fail 的嚴重度門檻 | high |
| `security_scan.dast_target_url` | DAST 目標 | 互動式問（必 staging）|

## 範例

詳見 [`examples.md`](./examples.md)
