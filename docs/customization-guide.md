# 客製化指南（Customization Guide）

如何把通用版 Skill 套用到你自己的組織？

[English version](./customization-guide.en.md)

---

## 🚀 30 分鐘上手版

1. `cp config/config.example.json config/config.json`
2. 修改 4 個必填欄位（JIRA + 平台）
3. `./install.sh`
4. 完成

```json
{
  "jira": {
    "instance_url": "https://your-company.atlassian.net",
    "project_key": "PROJ"
  },
  "platforms": {
    "ios": { "default_device": "iPhone 15 Pro", "default_os_version": "iOS 17.5" },
    "android": { "default_device": "Pixel 8", "default_os_version": "Android 14" }
  }
}
```

## 🎚 完整客製化指引（按使用情境）

### 情境 A: 大型團隊（JIRA + Slack + Google Workspace）

採用 `mode = "full-mcp"`，所有 MCP 整合都啟用。

```json
{
  "mode": "full-mcp",
  "jira": {
    "instance_url": "https://acme.atlassian.net",
    "project_key": "ACME",
    "reviewer_account_id": "712020:xxx",
    "reviewer_field": "customfield_10045",
    "boards": [
      { "name": "iOS-Team", "board_id": "111", "drive_folder_id": "...", "scope": "iOS" },
      { "name": "Android-Team", "board_id": "222", "drive_folder_id": "...", "scope": "Android" }
    ]
  },
  "slack": {
    "user_id": "UXXXX",
    "bug_channel_id": "CXXXX",
    "release_channel_id": "CYYYY",
    "notification_rules": {
      "bug_report": ["dm", "channel"],
      "tc_review_complete": ["dm"],
      "regression_published": ["channel"]
    }
  },
  "google": {
    "tc_template_id": "1abc...",
    "qa_tc_folder_id": "1def...",
    "default_drive": "shared"
  }
}
```

### 情境 B: 只有 JIRA、沒 Slack/Google

採用 `mode = "partial-mcp"`，缺值的部分自動降級。

```json
{
  "mode": "partial-mcp",
  "jira": {
    "instance_url": "https://acme.atlassian.net",
    "project_key": "ACME"
  },
  "slack": {
    "user_id": "",
    "notification_rules": {
      "bug_report": [],
      "tc_review_complete": []
    }
  }
}
```

→ bug-report 仍能建 JIRA，但不發 Slack；test-master 改產 .md 而非 Sheet。

### 情境 C: 單人開發者 / 內部 PoC / 學習用

採用 `mode = "markdown-only"`，所有產出寫成本地 .md。

```json
{
  "mode": "markdown-only",
  "jira": { "instance_url": "n/a", "project_key": "LOCAL" }
}
```

→ 所有 skill 仍可用，但輸出全是 .md 檔，沒外部依賴。

可參考 [`examples/solo-developer/config.json`](../examples/solo-developer/config.json)。

### 情境 D: Flutter 專案

額外啟用 Flutter skill：

```json
{
  "platforms": {
    "flutter": {
      "enabled": true,
      "repo": "your-org/your-flutter-repo",
      "min_dart_sdk": "3.0.0"
    }
  }
}
```

→ `flutter-test-master` 和 `flutter-test-automation` 才會被啟用。

### 情境 E: BE Python pytest 團隊（mutation / property test 加值）

啟用 backend pytest 整合：

```json
{
  "backend": {
    "pytest_enabled": true,
    "pytest_project_root": "~/Desktop/your-pytest-repo",
    "schema_dsl": "plain_dict",
    "feature_modules": ["auth", "payment", "wallet"],
    "mutation": { "enabled": true, "score_target": 80 },
    "property_based": { "enabled": true, "default_max_examples": 200 }
  }
}
```

→ `tc-to-pytest`、`mutation-testing`、`property-based-test-gen` 才會被啟用。

### 情境 F: 啟用 S3 Dashboard 發布

```json
{
  "publish_regression": {
    "enabled": true,
    "html_generator_script": "/path/to/your/generate_manual_html.py",
    "index_generator_script": "/path/to/your/generate_index_html.py",
    "report_pipeline": {
      "type": "s3_cloudfront",
      "s3_bucket": "your-bucket",
      "s3_region": "ap-northeast-1",
      "cloudfront_distribution_id": "EXXXX",
      "dashboard_url": "https://xxx.cloudfront.net/index.html"
    }
  }
}
```

如果還沒準備 AWS，把 `type` 改成 `"local_html"`，只在本地生 HTML 不上傳。

---

## 🔧 變數佔位符完整對照

每個變數在 `config.json` 的對應路徑：

| 變數 | config 路徑 | 預設值 |
|------|-------------|--------|
| `{{JIRA_PROJECT_KEY}}` | `jira.project_key` | — |
| `{{JIRA_INSTANCE_URL}}` | `jira.instance_url` | — |
| `{{JIRA_REVIEWER_ACCOUNT_ID}}` | `jira.reviewer_account_id` | 空字串 |
| `{{JIRA_REVIEWER_FIELD}}` | `jira.reviewer_field` | `customfield_10045` |
| `{{JIRA_BUG_ISSUE_TYPE_ID}}` | `jira.bug_issue_type_id` | `10046` |
| `{{SLACK_USER_ID}}` | `slack.user_id` | 空字串 |
| `{{SLACK_BUG_CHANNEL_ID}}` | `slack.bug_channel_id` | 空字串 |
| `{{SLACK_RELEASE_CHANNEL_ID}}` | `slack.release_channel_id` | 空字串 |
| `{{GSHEET_TC_TEMPLATE_ID}}` | `google.tc_template_id` | 空字串 |
| `{{GDRIVE_QA_FOLDER_ID}}` | `google.qa_tc_folder_id` | 空字串 |
| `{{GSHEET_RELEASE_SCHEDULE_ID}}` | `google.release_schedule_id` | 空字串 |
| `{{GSHEET_REGRESSION_TEMPLATE}}` | `google.regression_template_id` | 空字串 |
| `{{IOS_DEFAULT_DEVICE}}` | `platforms.ios.default_device` | — |
| `{{IOS_DEFAULT_VERSION}}` | `platforms.ios.default_os_version` | — |
| `{{MIN_IOS_VERSION}}` | `platforms.ios.min_os_version` | 空字串 |
| `{{IOS_REPO}}` | `platforms.ios.repo` | 空字串 |
| `{{IOS_RELEASE_BRANCH_PATTERN}}` | `platforms.ios.release_branch_pattern` | `release/{version}` |
| `{{IOS_VERSION_FILE_PATTERN}}` | `platforms.ios.version_file` | `**/*.xcconfig` |
| `{{ANDROID_DEFAULT_DEVICE}}` | `platforms.android.default_device` | — |
| `{{ANDROID_DEFAULT_VERSION}}` | `platforms.android.default_os_version` | — |
| `{{MIN_ANDROID_API}}` | `platforms.android.min_api_level` | 空字串 |
| `{{ANDROID_REPO}}` | `platforms.android.repo` | 空字串 |
| `{{ANDROID_RELEASE_TAG_PATTERN}}` | `platforms.android.release_tag_pattern` | `v{version}` |
| `{{ANDROID_VERSION_FILE_PATTERN}}` | `platforms.android.version_file` | `**/build.gradle` |
| `{{PYTEST_PROJECT_ROOT}}` | `backend.pytest_project_root` | 空字串 |
| `{{SPECKIT_REPO_ROOT}}` | `speckit.repo_root` | 空字串 |
| `{{PUBLISH_HTML_GENERATOR}}` | `publish_regression.html_generator_script` | 空字串 |
| `{{PUBLISH_INDEX_GENERATOR}}` | `publish_regression.index_generator_script` | 空字串 |

> 註：install.sh 在安裝時把這些佔位符替換成實際值；空字串值會在 skill 內降級處理。

---

## 🧪 校驗你的 config

```bash
# JSON 格式校驗（jq）
jq . config/config.json > /dev/null && echo OK

# Schema 校驗（需 ajv-cli）
npx ajv-cli validate -s config/config.schema.json -d config/config.json

# Dry-run 安裝（不動 ~/.claude）
CLAUDE_SKILLS_DIR=/tmp/preview ./install.sh
ls /tmp/preview/  # 應該有 15 個 skill 資料夾
grep -r '{{' /tmp/preview/ | grep -v '變數'  # 應該空（全解析）
```

---

## ❓ 常見問題

### Q1: 我的 JIRA 是 Cloud，不是 Server，可以用嗎？
✅ 可以。`instance_url` 直接填 `https://your-company.atlassian.net`。

### Q2: 沒有 atlassian MCP，怎麼用？
切到 `mode = "markdown-only"` 或 `"partial-mcp"`。bug-report 會降級寫 `./bugs/*.md`。

### Q3: 我們是 Test Lab / Sauce Labs / BrowserStack 跑測試，不是本地裝置
平台預設裝置只是用在 TC 模板的「預設環境資訊」，不影響執行。可填一個有代表性的雲端機型即可。

### Q4: customfield_10045 是什麼？
這是 JIRA Cloud REST API 中自訂欄位的 ID（每個 JIRA instance 不同）。獲取方式：
```bash
curl -u "$EMAIL:$TOKEN" "https://your-company.atlassian.net/rest/api/3/field" | jq '.[] | select(.name=="驗收者")'
```
找到對應的 `id` 欄位。

### Q5: 不想用 Google Sheet，可以全用 Markdown 嗎？
✅ 可以。`mode = "markdown-only"` 即可。`sheet-md-sync` 在此模式下會被停用（因為它本身就是 Sheet ↔ md 同步）。

### Q6: 我已經有舊版的 `~/.claude/skills/bug-report`，重裝會覆蓋嗎？
不會。`install.sh` 會把同名 skill 備份到 `~/.claude/skills.backup-{timestamp}/`，可用 `./uninstall.sh` 還原。

---

## 🆘 還是搞不定？

請看：
- [`README.md`](../README.md) — 套件總覽
- [`docs/skill-index.md`](./skill-index.md) — 15 個 Skill 速查
- [`docs/workflow-diagrams.md`](./workflow-diagrams.md) — Skill 串接圖
- [`examples/`](../examples/) — 完整範例 config
