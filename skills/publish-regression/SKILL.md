---
name: publish-regression
description: >
  Publish manual regression test reports to S3 dashboard. Reads test results from a Google Sheet,
  generates an HTML report and summary JSON, uploads to S3, rebuilds the index dashboard, and
  invalidates CloudFront cache. Use when the user says "publish regression", "upload regression report",
  "publish manual test", "push regression to S3", "update dashboard", or mentions publishing/uploading
  regression test results to the dashboard. Also trigger when the user has finished manual regression
  testing and wants to make results visible on the team dashboard.
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__readSpreadsheet, mcp__google__getSpreadsheetInfo
argument-hint: "[Google Sheet URL / Version] [--env=uat|staging|prod]"
---

# Publish Regression Test Report

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first**.
> 啟用條件：`config.publish_regression.enabled = true`，且需設定 `publish_regression.report_pipeline` 區段。
> 若 `mode = markdown-only` 或 AWS 未設定 → 走 [`modules/markdown-fallback.md`](./modules/markdown-fallback.md)，只產 HTML 不上傳。

Automates: Google Sheet → HTML report → S3 → Dashboard index → CDN invalidation.

## Required Config

```json
{
  "publish_regression": {
    "enabled": true,
    "html_generator_script": "<path to generate_manual_html.py>",
    "index_generator_script": "<path to generate_index_html.py>",
    "report_pipeline": {
      "type": "s3_cloudfront",
      "s3_bucket": "your-bucket-name",
      "s3_region": "ap-northeast-1",
      "s3_prefix": "pytest-reports/",
      "cloudfront_distribution_id": "EXXXXXXXX",
      "dashboard_url": "https://your-distribution.cloudfront.net/index.html",
      "report_url_template": "http://{bucket}.s3-website-{region}.amazonaws.com/{prefix}manual-{env}-{version}/{timestamp}/report.html"
    },
    "default_env": "uat",
    "naming_pattern": "manual-{env}-{version}"
  }
}
```

替代方案：使用者可改用 `report_pipeline.type = "local_html"`（只產 HTML 本地保存，不上傳）。

## Prerequisites

- AWS CLI configured with access to the configured bucket
- Google MCP connected
- HTML generator script available at `publish_regression.html_generator_script`

## Required Input

從 args 或互動式取得：
1. **Google Sheet ID** — the spreadsheet containing regression test results
2. **Sheet name** — the tab name (e.g. "regression test cases")
3. **Version** — the app version (e.g. "1.8.0")
4. **Environment** — defaults to `publish_regression.default_env`（預設 `uat`）

## Execution Flow

### Step 1: Read test data from Google Sheet

Use `mcp__google__readSpreadsheet` to read all rows.

The sheet format has 15 columns (A-O，同 `regression-test` skill 的格式)：
- A: ID, B: Area, C: Type, D: Title, E: Platform, F: Priority, G: Risk, H: Precondition, I: Steps, J: Expected, K: iOS Result, L: Android Result, M: Time, N: JIRA, O: Notes

Skip rows where column A is empty (separator/summary rows).

### Step 2: Build input JSON

Create a JSON file at `/tmp/manual_input_{version}.json`：

```json
{
  "version": "1.8.0",
  "env": "uat",
  "sheet_url": "https://docs.google.com/spreadsheets/d/{sheet_id}",
  "sheet_name": "sheet tab name",
  "cases": [
    {
      "id": "RT-001",
      "area": "Auth/SSO",
      "type": "Smoke Test",
      "title": "SSO login test",
      "platform": "Both",
      "priority": "P0",
      "risk": "High",
      "precondition": "not logged in",
      "steps": "1. open app\n2. login",
      "expected": "login success",
      "ios_result": "Pass",
      "android_result": "Pass",
      "jira": "{{JIRA_PROJECT_KEY}}-XXXX"
    }
  ]
}
```

### Step 3: Generate report

```bash
HTML_GEN="{{PUBLISH_HTML_GENERATOR}}"
python3 "$HTML_GEN" /tmp/manual_input_{version}.json /tmp/manual_out/
```

Verify output shows non-zero case count.

### Step 4: Upload to S3

> 僅在 `report_pipeline.type = "s3_cloudfront"` 時執行。

```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
S3_BUCKET="<from config>"
S3_REGION="<from config>"
S3_PREFIX="<from config>"
S3_PATH="s3://${S3_BUCKET}/${S3_PREFIX}manual-{env}-{version}/${TIMESTAMP}"
aws s3 cp /tmp/manual_out/ "${S3_PATH}/" --recursive --region "${S3_REGION}"
```

The S3 path MUST follow the pattern `manual-{env}-{version}` for the index generator to parse correctly.

### Step 5: Rebuild index.html

```bash
INDEX_GEN="{{PUBLISH_INDEX_GENERATOR}}"
S3_BUCKET="<from config>" S3_PREFIX="<from config>" INDEX_OUTPUT="/tmp/index.html" \
python3 "$INDEX_GEN"
```

### Step 6: Upload index and invalidate CloudFront

```bash
aws s3 cp /tmp/index.html "s3://${S3_BUCKET}/index.html" \
  --content-type "text/html" --region "${S3_REGION}"

aws cloudfront create-invalidation \
  --distribution-id "<from config>" \
  --paths "/*" --no-cli-pager --output text > /dev/null
```

### Step 7: Report to user

Show:
- Total test cases
- iOS pass rate and count (passed/failed)
- Android pass rate and count (passed/failed)
- Number of failed cases
- S3 report URL（依 `report_pipeline.report_url_template` 渲染）
- Dashboard URL（從 `report_pipeline.dashboard_url`）
- Slack 通知（依 `slack.notification_rules.regression_published`）

## Local-only Mode

若 `report_pipeline.type = "local_html"`：
- 只跑 Step 1-3
- 報告寫到 `.claude/testing/regression/v{version}/report.html`
- 不上傳、不 invalidate
- 提示使用者：「若日後啟用 S3 pipeline，重跑此 skill 可自動上傳」

## Markdown-only Mode

`mode = markdown-only`：
- 略過所有 AWS 操作
- 跑 Step 1（讀 Sheet → 假設透過 cached export 或本地 CSV）
- 產 `.claude/testing/regression/v{version}/summary.md` 取代 HTML 報告

## Important Notes

- The Google Sheet may contain separator rows (empty ID, content like `=== Section ===`) and summary rows (content like `合計`). Always skip these.
- The HTML generator script expects the input JSON format described above. Do NOT pass `summary.json` as input — that's the output format.
- The report HTML includes a "back to dashboard" button (if dashboard configured).
- If the same version already exists on S3, the new upload creates a new timestamp folder alongside it. The index will show the latest one.

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `publish_regression.enabled` | Activates skill | Skill off |
| `publish_regression.html_generator_script` | HTML 產生器路徑 | Skill off |
| `publish_regression.report_pipeline.type` | 發布模式 | 預設 `local_html` |
| `publish_regression.report_pipeline.s3_*` | AWS S3 設定 | 改 `local_html` |
| `publish_regression.report_pipeline.cloudfront_distribution_id` | CDN | 跳過 invalidation |
| `slack.notification_rules.regression_published` | 通知 | 不發 Slack |

## 範例

詳見 [`examples.md`](./examples.md)
