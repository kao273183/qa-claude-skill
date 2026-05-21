# CI/CD 整合指南

把 QA Claude Skill 整合到你的 CI/CD pipeline。範本支援 **GitHub Actions / GitLab CI / CircleCI**。

[English version coming soon]

---

## 🎯 三種典型 CI/CD 工作流

### 1️⃣ PR / MR 校驗（每次 commit）

**目標**：當 `config/**/*.json` 或 `scripts/validate-config.sh` 改動時，自動跑校驗器，避免錯誤 config 被合進 main branch。

**好處**：
- 抓 typo（`mode = "fulll-mcp"` → 立刻 fail）
- 確保新加的 preset 符合 schema
- dry-run install.sh，確認所有 `{{變數}}` 都能渲染

**範本**：
- GitHub Actions: [`templates/ci/github-actions/pr-validate-config.yml`](../templates/ci/github-actions/pr-validate-config.yml)
- GitLab CI: [`templates/ci/gitlab-ci/.gitlab-ci.yml`](../templates/ci/gitlab-ci/.gitlab-ci.yml) (job: `validate-config`)
- CircleCI: [`templates/ci/circleci/config.yml`](../templates/ci/circleci/config.yml) (job: `validate-config`)

### 2️⃣ Weekly Mutation Testing（每週排程）

**目標**：每週日凌晨對 critical 模組跑 mutation testing，量化 TC 真實強度趨勢。

**好處**：
- 量化「這版 TC 比上版強嗎」
- 找出 survived mutations → 對應補測清單
- 慢測試不阻擋 PR，但定期守門

**範本**：
- GitHub Actions: [`templates/ci/github-actions/weekly-mutation-testing.yml`](../templates/ci/github-actions/weekly-mutation-testing.yml)
- GitLab CI: 同上 .gitlab-ci.yml (job: `weekly-mutation`)
- CircleCI: 同上 .circleci/config.yml (job: `weekly-mutation`)

**前置條件**：`config.backend.pytest_enabled = true` 且 `backend.mutation.enabled = true`

### 3️⃣ Release Regression Publish（tag 觸發）

**目標**：當推送 `vX.Y.Z` tag 時，從 Google Sheet 抓回歸測試結果 → 生 HTML → 上 S3 → 重建 dashboard → 發 Slack。

**好處**：
- Release 後團隊立刻看到 dashboard 更新
- 完全自動化，不用 QA 手動發
- 跨版本回歸數據可追蹤

**範本**：
- GitHub Actions: [`templates/ci/github-actions/release-regression-publish.yml`](../templates/ci/github-actions/release-regression-publish.yml)
- GitLab CI: 同上 .gitlab-ci.yml (job: `release-publish`)
- CircleCI: 同上 .circleci/config.yml (job: `release-publish`)

**前置條件**：
- `config.publish_regression.enabled = true`
- `config.publish_regression.report_pipeline.type = "s3_cloudfront"`

---

## 🚀 安裝步驟

### GitHub Actions

```bash
# 1. 在你的 repo 根目錄建 .github/workflows/
mkdir -p .github/workflows

# 2. 複製想用的範本
cp ~/Desktop/QA_Claude_Skill/templates/ci/github-actions/*.yml .github/workflows/

# 3. 在 GitHub repo Settings → Secrets and variables → Actions 加入需要的 secrets
#    詳見下方「Secrets 管理」
```

### GitLab CI

```bash
# 1. 複製範本到 repo 根目錄
cp ~/Desktop/QA_Claude_Skill/templates/ci/gitlab-ci/.gitlab-ci.yml ./

# 2. 在 GitLab Settings → CI/CD → Variables 加入 secrets
#    詳見下方「Secrets 管理」

# 3. 若要啟用 weekly schedule：
#    Settings → CI/CD → Schedules → New schedule
#    Cron: 0 16 * * 0
#    Variables: JOB_TYPE=mutation
```

### CircleCI

```bash
# 1. 複製範本到 repo 根目錄
mkdir -p .circleci
cp ~/Desktop/QA_Claude_Skill/templates/ci/circleci/config.yml .circleci/

# 2. 在 CircleCI Project Settings → Environment Variables 加入 secrets
#    GOOGLE_SERVICE_ACCOUNT_JSON 要 base64 encode：
#    base64 -i credentials.json | pbcopy
```

---

## 🔐 Secrets 管理

3 個工作流需要的 secrets 對照：

| Secret | validate-config | weekly-mutation | release-publish | 範例值 |
|--------|:---------------:|:---------------:|:---------------:|--------|
| `SLACK_WEBHOOK_URL` | — | optional | optional | `https://hooks.slack.com/services/T0/B0/XXX` |
| `AWS_ACCESS_KEY_ID` | — | — | **required** | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | — | — | **required** | `xxx...` |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | — | — | **required** | JSON 內容（GitLab/CircleCI base64） |
| `DEFAULT_REGRESSION_SHEET_ID` | — | — | optional | `1abc...XYZ` |
| `JIRA_API_TOKEN` | — | optional | optional | `ATATT...` (給 atlassian MCP) |

### GitHub Actions Secrets 加入步驟

1. Repo → Settings → Secrets and variables → Actions
2. 點 "New repository secret"
3. Name 對應上表，Value 貼 secret 值
4. 重複 4-5 次

### GitLab CI Variables 加入步驟

1. Project → Settings → CI/CD → Variables
2. 點 "Add variable"
3. **重要**：勾選 "Mask variable"（避免 log 洩漏）
4. **重要**：勾選 "Protect variable"（只給 protected branch/tag 用）
5. 若是 file 類（如 GOOGLE_SERVICE_ACCOUNT_JSON），Type 選 "File"

### CircleCI Variables 加入步驟

1. Project Settings → Environment Variables
2. 點 "Add Environment Variable"
3. 對應上表名稱 + 值
4. **重要**：CircleCI 不像 GitHub 自動 mask，記得 secret 不要在 echo 中印出

### 取得各種 token 的方式

| Token | 取得方式 |
|-------|---------|
| **Atlassian / JIRA API Token** | https://id.atlassian.com/manage-profile/security/api-tokens → Create API token |
| **Slack Webhook URL** | https://api.slack.com/messaging/webhooks → 建 incoming webhook 對應你的 channel |
| **AWS IAM Access Key** | IAM → Users → 你的 user → Security credentials → Create access key → CLI |
| **Google Service Account** | GCP Console → IAM & Admin → Service Accounts → 建 service account + JSON key → 在目標 Sheet 分享給 service account email（Editor 權限）|

---

## 📊 排程設定

### GitHub Actions

範本內已包含：
```yaml
on:
  schedule:
    - cron: '0 16 * * 0'   # 每週日 UTC 16:00 = 台北 00:00（週一）
```

調整 cron 規則：
- 每天凌晨：`0 16 * * *`
- 每月第一個週日：`0 16 1-7 * 0`
- 平日上班前：`0 0 * * 1-5`（UTC 00:00 = 台北 08:00）

### GitLab CI

GitLab CI 的 cron 設在 UI，不在 yml：
1. Project → CI/CD → Schedules → New schedule
2. Description: `Weekly Mutation Testing`
3. Interval Pattern: Custom → `0 16 * * 0`
4. Variables: `JOB_TYPE=mutation`、`PATHS_TO_MUTATE=src/your-module/`

### CircleCI

範本內：
```yaml
workflows:
  weekly-mutation:
    triggers:
      - schedule:
          cron: "0 16 * * 0"
```

---

## 🛠 客製化建議

### Mutation Score 目標

預設 80%，critical 模組 95%。在範本中修改：

```yaml
env:
  MUTATION_SCORE_TARGET: 80
  CRITICAL_SCORE_TARGET: 95
```

### 失敗時要不要阻擋

範本預設「warning」（不阻擋 release）。若想硬卡：

```yaml
- name: Fail if below target
  run: |
    if [ "$SCORE" -lt "$TARGET" ]; then
      exit 1   # ← 硬卡：< target 就 fail CI
    fi
```

### 自訂 mutation paths

每個模組分開跑（用 matrix）：

```yaml
strategy:
  matrix:
    module: [auth, payment, billing, notification]
steps:
  - name: Run mutmut on ${{ matrix.module }}
    run: mutmut run --paths-to-mutate="src/${{ matrix.module }}/"
```

### Release 觸發條件

預設：`v[0-9]+.[0-9]+.[0-9]+` 格式 tag（如 `v1.2.3`、`v1.2.3-rc1`）。

若你的 tag 格式不同（如 `release-2026-Q1`），改：

```yaml
on:
  push:
    tags:
      - 'release-*'
```

---

## 🐛 Troubleshooting

### 1. `validate-config.sh` 在 CI 跑不起來

```
./scripts/validate-config.sh: line 25: jq: command not found
```

→ 範本內有 `apt-get install -y jq`（或 alpine 對應 `apk add jq`）。確認被執行。

### 2. CircleCI base64 解碼失敗

```
base64: invalid input
```

→ GOOGLE_SERVICE_ACCOUNT_JSON 環境變數值要先 base64 encode：
```bash
base64 -i credentials.json | pbcopy   # macOS
base64 -w 0 credentials.json          # Linux
```

### 3. GitLab CI 不認 schedule

`Schedule did not trigger any pipeline`

→ 確認：
- Schedule 設定中變數 `JOB_TYPE=mutation` 有設
- yml 中 `rules:` 條件 `$JOB_TYPE == 'mutation'` 對應
- Schedule 用的 branch 是 `main` 或 protected

### 4. GitHub Actions 太貴

跑 mutation testing 1-2 小時，GitHub Actions free tier 用得快。建議：
- 只在 critical 模組跑（不要全 repo）
- 改週跑（per-PR 跑會破產）
- 移到 self-hosted runner（如果有閒置機器）

### 5. AWS CloudFront invalidation 失敗

```
An error occurred (AccessDenied) when calling the CreateInvalidation operation
```

→ AWS IAM user 需要 `cloudfront:CreateInvalidation` 權限。最小權限：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "cloudfront:CreateInvalidation"
      ],
      "Resource": [
        "arn:aws:s3:::your-bucket/*",
        "arn:aws:cloudfront::*:distribution/EXXXXX"
      ]
    }
  ]
}
```

---

## 🔗 相關文件

- [INSTALL.md](../INSTALL.md) — 套件本身的安裝指南
- [customization-guide.md](./customization-guide.md) — config.json 客製化
- [workflow-diagrams.md](./workflow-diagrams.md) — Skill 之間的串接圖

---

## 💡 進階：把 QA Claude Skill 本身的 repo 也跑 CI

如果你 fork 了這個 repo 並做自己的客製化，也可以跑 CI 自我校驗。可以複製 `templates/ci/github-actions/pr-validate-config.yml` 到 `.github/workflows/`，就會在每個 PR 對 config 改動跑校驗。
