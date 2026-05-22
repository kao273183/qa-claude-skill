# security-scan 範例

## 範例 1: 全套 4 類掃描

```
User: /security-scan
```

執行（偵測 Node.js 專案）：
1. SAST: `semgrep --config=auto`
2. SCA: `snyk test --severity-threshold=high`
3. Secret: `gitleaks detect`
4. DAST: 跳過（沒設 `dast_target_url`）

報告：1 Critical / 7 High / 22 Medium / 8 Low → 寫 `security-report.md`

## 範例 2: 只跑 Secret + SAST（PR 用快版）

```
User: /security-scan --type=sast,secret
```

執行：
- 只跑 Semgrep + gitleaks（< 3 min）
- 適合 PR check
- 結果直接 inline 到 PR comment

## 範例 3: DAST nightly

```
User: /security-scan --type=dast --target=https://uat.example.com
```

執行（互動式確認非 production）：
1. 啟動 docker OWASP ZAP
2. 對 UAT 跑 baseline scan
3. 產報告 + 4 個 Medium finding
4. 自動建 JIRA Security ticket（HIGH 以上）

## 範例 4: Critical 找到 → 自動 PR fix

```
Bot: Snyk 找到 Critical:
  - CVE-2024-XXXXX in lodash@4.17.20
  - CVSS: 9.8
  - Fix: upgrade to lodash@4.17.21

要建 PR 修嗎? (y/n)
User: y

→ 自動跑 `npm install lodash@4.17.21`
→ 重跑 test
→ 開 PR feature/fix-cve-2024-xxxxx
→ PR description 含 CVE link + CVSS + impact
```

## 範例 5: 合規場景 — government preset

```
config.security_scan.severity_threshold = "medium"
```

→ Medium 以上即阻 PR
→ 月跑完整 4 類掃描
→ 報告自動寫 audit log（給合規稽核用）
