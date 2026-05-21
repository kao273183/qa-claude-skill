# publish-regression 範例

## 範例 1: 標準發布流程（S3 + CloudFront）

```
User: /publish-regression https://docs.google.com/spreadsheets/d/xxx/edit 1.8.0 --env=uat
```

執行：
1. 讀 Sheet 「regression test cases」分頁
2. 過濾 separator / summary rows
3. 寫 input JSON 到 `/tmp/manual_input_1.8.0.json`
4. 跑 HTML generator → `/tmp/manual_out/`
5. 上傳 `s3://your-bucket/pytest-reports/manual-uat-1.8.0/{timestamp}/`
6. 重建 index.html
7. CloudFront invalidate `/*`
8. 報告：iOS 95% pass / Android 92% pass / 3 fails

## 範例 2: Local-only 模式（無 AWS）

```
User: /publish-regression https://docs.google.com/spreadsheets/d/xxx 1.8.0
```

`config.publish_regression.report_pipeline.type = "local_html"` 時：

```
✅ HTML report generated locally
📁 .claude/testing/regression/v1.8.0/report.html

提示：若日後啟用 S3 pipeline，重跑此 skill 可自動上傳到 dashboard
```

## 範例 3: Markdown-only 模式

```
User: /publish-regression v1.8.0
```

`mode = markdown-only`：
- 讀 cached CSV / 本地 export
- 產 `.claude/testing/regression/v1.8.0/summary.md`
- 不上傳 S3，不發 CloudFront invalidation
- 提示：「請手動分發此 .md 給團隊」

## 範例 4: Slack 通知（依 notification_rules）

`slack.notification_rules.regression_published = ["channel"]`：

```
📊 *Regression v1.8.0 已發布*

📈 統計：
- 總項目：70 (iOS 35 + Android 35)
- iOS Pass rate: 95% (33/35) ✅
- Android Pass rate: 92% (32/35) ⚠️

🔗 Dashboard: https://your-distribution.cloudfront.net/index.html
🔗 Report: http://your-bucket.s3-website-ap-northeast-1.amazonaws.com/.../report.html
```
