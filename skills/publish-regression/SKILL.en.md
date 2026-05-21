---
name: publish-regression
description: Publish manual regression test reports to S3 dashboard. Reads test results from a Google Sheet, generates HTML report and summary JSON, uploads to S3, rebuilds the index dashboard, and invalidates CloudFront cache. Trigger phrases — "publish regression", "upload regression report", "publish manual test", "push regression to S3", "update dashboard".
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, mcp__google__readSpreadsheet, mcp__google__getSpreadsheetInfo
argument-hint: "[Google Sheet URL / Version] [--env=uat|staging|prod]"
---

# publish-regression (English)

> ⚙️ **Read [`modules/config-loader.md`](./modules/config-loader.md) first**.
> Activation: `config.publish_regression.enabled = true` AND `publish_regression.report_pipeline` configured.

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

Alternative: `report_pipeline.type = "local_html"` → HTML only, no upload.

## Prerequisites
- AWS CLI configured (only for `s3_cloudfront` mode)
- Google MCP connected
- HTML generator script available

## Workflow

### Step 1: Read Sheet via google MCP
15 columns A-O (same as `regression-test` format). Skip separator/summary rows.

### Step 2: Build input JSON at `/tmp/manual_input_{version}.json`

```json
{
  "version": "1.8.0",
  "env": "uat",
  "sheet_url": "...",
  "cases": [
    {"id": "RT-001", "area": "...", "type": "Smoke Test", "title": "...",
     "platform": "Both", "priority": "P0", "risk": "High",
     "steps": "...", "expected": "...",
     "ios_result": "Pass", "android_result": "Pass",
     "jira": "{{JIRA_PROJECT_KEY}}-XXXX"}
  ]
}
```

### Step 3: Generate HTML
```bash
python3 "{{PUBLISH_HTML_GENERATOR}}" /tmp/manual_input_{version}.json /tmp/manual_out/
```

### Step 4: S3 upload (s3_cloudfront mode)
```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
S3_PATH="s3://${S3_BUCKET}/${S3_PREFIX}manual-{env}-{version}/${TIMESTAMP}"
aws s3 cp /tmp/manual_out/ "${S3_PATH}/" --recursive --region "${S3_REGION}"
```

### Step 5: Rebuild index, upload, invalidate CloudFront

### Step 6: Slack notification (per `slack.notification_rules.regression_published`)

## Local-only Mode
`type = "local_html"` → report at `.claude/testing/regression/v{version}/report.html`; no upload.

## Markdown-only Mode
Skip AWS; produce `summary.md` instead of HTML.

## Config Dependencies

| Key | Purpose | If missing |
|-----|---------|-----------|
| `publish_regression.enabled` | Activates skill | Skill off |
| `publish_regression.html_generator_script` | HTML generator | Skill off |
| `publish_regression.report_pipeline.type` | Publish mode | Default `local_html` |
| `publish_regression.report_pipeline.s3_*` | AWS S3 | Switch to `local_html` |
| `slack.notification_rules.regression_published` | Notify | Skip Slack |
