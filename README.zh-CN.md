<h1 align="center">QA Claude Skill</h1>

<p align="center">
  <em>为 Claude Code 打造的 15 个生产级 QA 工作流 Skill —— 从规格到上线一条龙。</em>
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.zh-TW.md">繁體中文</a> · <strong>简体中文</strong>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT" /></a>
  <img src="https://img.shields.io/badge/skills-24-2563EB" alt="24 个 skill" />
  <img src="https://img.shields.io/badge/Claude%20Code-Compatible-7C3AED?logo=anthropic&logoColor=white" alt="Claude Code 兼容" />
  <img src="https://img.shields.io/badge/Mode-full--mcp%20%7C%20partial--mcp%20%7C%20markdown--only-10B981" alt="3 种模式" />
  <img src="https://img.shields.io/badge/i18n-en%20%7C%20zh--TW%20%7C%20zh--CN-FB923C" alt="多语言" />
  <a href="https://www.buymeacoffee.com/minikao"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Support-FFDD00?logo=buy-me-a-coffee&logoColor=black" alt="Buy Me a Coffee" /></a>
</p>

> 一个可配置的 **24 个 QA Skill** 套件，给 [Claude Code](https://claude.ai/code) 使用，
> 覆盖完整测试生命周期：**规格 → TC → 自动化 → 审查 → 回归 → 发布**。
> 从个人 QA workspace 抽离并通过 `config.json` 通用化 —— 换上你团队的 ID
> 就能套用到任何团队、任何工具栈。

---

## ✨ 设计亮点

- 🧪 **完整生命周期覆盖** —— 规格解析、TC 设计、自动化生成、代码审查、回归计划、Bug 提单、变异测试、报告发布
- 🔌 **工具独立的 3 种模式** —— `full-mcp`（Atlassian + Slack + Google）/ `partial-mcp`（缺工具自动降级）/ `markdown-only`（零外部依赖）
- 🌐 **多语言支持** —— 每个 skill 含 `SKILL.md`（繁中）+ `SKILL.en.md`；陌生概念另有 4 篇中文导读
- 📦 **单一 config 配置** —— 28 个变量涵盖 JIRA / Slack / Google / iOS / Android / BE pytest / AWS dashboard
- 🧩 **可插拔模块** —— 每个 skill 内置 `modules/{config-loader, jira/slack-integration, markdown-fallback}.md` 清晰分离
- 🚀 **一键安装** —— `./install.sh` 自动校验 config、渲染 28 个变量、备份既有 skill、安装到 `~/.claude/skills/`
- 🇹🇼🇨🇳 **跨文化设计** —— 每个 skill 内置 a11y 必检项（Dynamic Type / TalkBack / 对比度）和跨平台配对机制

---

## 📦 套件包含

24 个 Skill 分 8 类：

### 测试设计（8 个）

| Skill | 用途 |
|-------|------|
| [`test-master`](skills/test-master/) | 完整测试计划 + 黑盒/白盒 TC 生成（原生 iOS/Android + **Web**）|
| [`flutter-test-master`](skills/flutter-test-master/) | Flutter 三层测试金字塔（Unit/Widget/Integration）+ Golden + Platform Channel |
| [`test-review`](skills/test-review/) | TC + 代码审查（10 维度加权评分）；支持 Swift/Kotlin/Dart/Python/TypeScript |
| [`regression-test`](skills/regression-test/) | Release 级跨平台回归测试计划（JIRA + 历史 Bug 分析）|
| [`speckit-to-tc`](skills/speckit-to-tc/) | Spec Kit / SDD 规格 → 14 列黑白盒 TC 草稿 |
| [`tc-version-diff`](skills/tc-version-diff/) | TC 版本差异对比；产 changelog + 补测清单 |
| [`sheet-md-sync`](skills/sheet-md-sync/) | Google Sheet ↔ Markdown 双向同步（让 TC 能进 git diff / PR review）|
| [`smoke-test-analyzer`](skills/smoke-test-analyzer/) | 把现有自动化测试分到 T0/T1/T2/T3 + 产 CI 配置文件 |

### 自动化（3 个）

| Skill | 用途 |
|-------|------|
| [`test-automation`](skills/test-automation/) | iOS（Swift Testing + XCUITest）/ Android（JUnit + Espresso + Mockk）/ **Web（Playwright + Cypress + Selenium/WebdriverIO + Vitest）** 脚本生成 |
| [`flutter-test-automation`](skills/flutter-test-automation/) | Dart 自动化脚本（flutter_test / integration_test / Patrol / Golden）|
| [`tc-to-pytest`](skills/tc-to-pytest/) | 白盒 API TC → pytest-api-kit 三件套（`schemas.py` + `conftest.py` + `tests/test_*_api.py`）|

### Bug 管理（1 个）

| Skill | 用途 |
|-------|------|
| [`bug-report`](skills/bug-report/) | RIDER 格式 Bug 报告 + 自动建 JIRA + Slack 通知 + 跨平台配对 |

### 质量量化（2 个）

| Skill | 用途 |
|-------|------|
| [`mutation-testing`](skills/mutation-testing/) | mutmut 变异测试 —— 量化 TC 真实强度（不只看行覆盖率）|
| [`property-based-test-gen`](skills/property-based-test-gen/) | 生成 hypothesis @given 策略，自动探索边界 bug |

### 报告发布（1 个）

| Skill | 用途 |
|-------|------|
| [`publish-regression`](skills/publish-regression/) | 手动回归测试报告发布到 S3 + CloudFront 失效 + Slack 通知 |

### 性能与安全（3 个）— ✨ v1.5.0 新增

| Skill | 用途 |
|-------|------|
| [`performance-test-gen`](skills/performance-test-gen/) | k6 / JMeter / Locust 压测脚本 + SLA 阈值 + ramp-up 曲线 + CI 集成 |
| [`security-scan`](skills/security-scan/) | SAST (Semgrep) + DAST (OWASP ZAP) + SCA (Snyk/Trivy) + Secret scan (gitleaks) — 统一 CVSS 报告 |
| [`api-contract-test`](skills/api-contract-test/) | Pact / Schemathesis / Spring Cloud Contract — PR 时就抓到微服务 breaking change |

### CI 健康度（2 个）— ✨ v1.5.0 新增

| Skill | 用途 |
|-------|------|
| [`visual-regression-gen`](skills/visual-regression-gen/) | Playwright snapshot / Percy / Chromatic / BackstopJS — 自动 mask 动态元素 |
| [`flaky-test-hunter`](skills/flaky-test-hunter/) | 分析 CI 历史 → 找出 flaky test → 给修复建议 + 自动 quarantine |

### 质量专项（4 个）— ✨ v1.6.0 新增

| Skill | 用途 |
|-------|------|
| [`a11y-audit`](skills/a11y-audit/) | 深度无障碍审查（Lighthouse / axe / iOS Inspector / Android Scanner）— WCAG 2.1/2.2 AA 评分报告 |
| [`localization-test`](skills/localization-test/) | i18n/l10n 验证 — 翻译漏字 / 字符串溢出 / RTL / 格式 / 复数 / locale 切换 |
| [`push-notification-test`](skills/push-notification-test/) | APNs / FCM / Web Push — 8 大测试场景（送达 / 点击 / Deep link / 权限 / 大批推送性能）|
| [`test-data-factory`](skills/test-data-factory/) | 跨平台统一 fixture（Swift / Kotlin / Dart / TypeScript / Python）— 一份 schema → 5 平台 factory 对齐 |

> 💡 **第一次听到变异测试 / property-based testing / 规格驱动开发 / 测试分层？**
> 每个概念有 5 分钟中文导读：`skills/<name>/concept-zh.md`，见[概念入门](#-概念入门)。

---

## 🚀 快速开始

```bash
# 1. Clone
git clone https://github.com/kao273183/qa-claude-skill.git ~/Desktop/QA_Claude_Skill
cd ~/Desktop/QA_Claude_Skill

# 2. 创建你的 config
cp config/config.example.json config/config.json

# 3. 填入最少 4 个必要字段：
#    - jira.instance_url
#    - jira.project_key
#    - platforms.ios.default_device
#    - platforms.android.default_device

# 4. 安装（渲染 28 个变量 → ~/.claude/skills/）
./install.sh

# 5. 在 Claude Code 中试试触发词：
#    "帮我规划 X 功能的测试计划"
#    "我要开 Bug 单"
#    "审查这份测试案例"
```

### 安装前 Dry-run 预览

```bash
CLAUDE_SKILLS_DIR=/tmp/preview ./install.sh
ls /tmp/preview/   # 应该有 15 个 skill 目录
grep -r '{{' /tmp/preview/ | grep -v '变量\|變數'   # 应该为空（变量全解析）
```

Windows 用户请参阅 [docs/install-windows.md](docs/install-windows.md)。

---

## 🎛 3 种运行模式

每个 skill 都支持 3 种模式，依你团队的工具现状选一个：

| 模式 | 适用情境 | 行为 |
|------|---------|------|
| `full-mcp` | 你有 Atlassian + Slack + Google Workspace MCP | 自动建 ticket、发 Slack、写 Sheet |
| `partial-mcp` | 部分 MCP 缺漏 | 有 MCP 就用，没有就走 Markdown |
| `markdown-only` | 单人开发者 / 无 MCP / 纯文档流 | 完全不调用外部，产出 `.md` 到 `.claude/testing/` |

6 个预设 preset 在 [`config/presets/`](config/presets/) 可直接复制使用：

```bash
# 工具栈 presets
cp config/presets/full-stack.json     config/config.json   # 全套 MCP
cp config/presets/jira-only.json      config/config.json   # 只用 JIRA
cp config/presets/markdown-only.json  config/config.json   # 纯文档

# 场景 presets (v1.1.0+)
cp config/presets/startup.json        config/config.json   # 创业团队 < 10 人
cp config/presets/enterprise.json     config/config.json   # 大型企业 + 5 个 team boards
cp config/presets/government.json     config/config.json   # 政府 / 高合规 / on-prem
```

---

## ⚙️ 客制化

三层客制化可选：

1. **`config.json`** —— 28 个变量。完整对照表见 [docs/customization-guide.md](docs/customization-guide.md)
2. **`config/presets/`** —— 6 种预设情境
3. **每个 skill 的 modules** —— 每个 skill 有 `modules/markdown-fallback.md` 定义降级行为

### 校验 config（不安装）

```bash
./scripts/validate-config.sh                              # 验 config/config.json
./scripts/validate-config.sh config/presets/startup.json  # 验指定文件
```

---

## 🧩 架构设计

每个 skill 遵循相同的可插拔结构：

```
skills/<skill-name>/
├── SKILL.md                          ← 主档（繁中）
├── SKILL.en.md                       ← 英文版
├── concept-zh.md                     ← 新手入门（陌生概念才有）
├── examples.md                       ← 3-5 个实际使用情境
├── templates.md / patterns.md        ← 模板 / 代码 pattern
└── modules/                          ← 可插拔集成
    ├── config-loader.md              ← 加载 config.json 配置
    ├── jira-integration.md           ← (可选) JIRA MCP 调用
    ├── slack-integration.md          ← (可选) Slack MCP 调用
    └── markdown-fallback.md          ← 纯 Markdown 降级路径
```

意思是：
- **要移除 JIRA 集成？** 删掉 `modules/jira-integration.md` 引用 —— Slack 仍可用
- **没有 Google？** 切到 `markdown-only` 模式 —— 所有 skill 仍能跑
- **想加新工具集成？** 新增 `modules/<your-tool>.md` 并在 `SKILL.md` 引用

---

## 📖 概念入门

陌生的测试概念都有 5 分钟中文导读：

| 概念 | 讲什么 | 链接 |
|------|--------|------|
| **Property-based testing** | 为什么 fuzz 200 个 input 比写 2 个 example 强 | [property-based-test-gen/concept-zh.md](skills/property-based-test-gen/concept-zh.md) |
| **变异测试（Mutation testing）** | 为什么行覆盖率 100% 也不够 | [mutation-testing/concept-zh.md](skills/mutation-testing/concept-zh.md) |
| **规格驱动开发（Spec Kit）** | 为什么规格 ticket → 30 秒草拟 TC 是可能的 | [speckit-to-tc/concept-zh.md](skills/speckit-to-tc/concept-zh.md) |
| **测试分层 T0/T1/T2/T3** | 为什么不该每次 PR 都跑全部测试 | [smoke-test-analyzer/concept-zh.md](skills/smoke-test-analyzer/concept-zh.md) |

---

## 🌊 典型工作流

[docs/workflow-diagrams.md](docs/workflow-diagrams.md) 收录 5 个 ASCII 串接图：

1. **规格 → 上线 pipeline（BE 功能）** —— `speckit-to-tc` → `test-review` → `sheet-md-sync` → `tc-to-pytest` → `mutation-testing` → `property-based-test-gen`
2. **Release 前准备（移动端）** —— `test-master` → `test-automation` → `smoke-test-analyzer` → `regression-test` → `bug-report` → `publish-regression`
3. **TC 版本升级** —— `test-master --quick` → `test-review` → `tc-version-diff` → `tc-to-pytest --incremental`
4. **Markdown-only 流程（单人）** —— 所有 skill 写 `.md` 到 `.claude/testing/`
5. **三方审查** —— Claude + Codex + Gemini 同时审查一份 TC，加权合议

---

## 🧰 兼容性

| 项目 | 需求 |
|------|------|
| **Claude Code** | 最新版（skills 是一级公民） |
| **OS** | macOS / Linux / Windows 原生（v1.3.0+）—— 见 [docs/install-windows.md](docs/install-windows.md) |
| **MCP servers（可选）** | atlassian, slack, google-workspace, mcp-google-full, mcp-context-mode |
| **必要 CLI 工具** | `bash`, `jq`, `git` |
| **可选 CLI 工具** | `gh`（GitHub Actions）, `aws`（S3 publish）, `python3` + `pytest`（BE skills）, `flutter`（Flutter skills）, `xcodebuild`（iOS）, Gradle（Android）|

---

## 🚀 CI/CD 集成

9 个范本（GitHub Actions / GitLab CI / CircleCI × 3 种工作流）位于 [`templates/ci/`](templates/ci/)：

1. **PR Validate Config** —— 每次 PR 自动校验 config + dry-run install
2. **Weekly Mutation Testing** —— 每周跑 mutmut 量化 TC 强度
3. **Release Regression Publish** —— tag push 时自动上传 S3 + 重建 dashboard

完整指南见 [docs/ci-integration.md](docs/ci-integration.md)。

---

## 🗺 Roadmap

完整版见 [ROADMAP.md](ROADMAP.md) —— 已完成 / 计划中 / 明确不做的项目。

**接下来的重点**：
- 9 个新 skill（test-impact-analyzer / oauth-flow-test / payment-test / graphql-test / llm-quality-eval ...）
- 日语翻译
- Video walkthrough + demo GIF

想影响优先级？开 [GitHub Discussion](https://github.com/kao273183/qa-claude-skill/discussions/categories/ideas)。

## 🔒 安全性

发现漏洞？见 [SECURITY.md](SECURITY.md) —— 优先用 GitHub Security Advisory 私下回报。

---

## 🤝 贡献

欢迎 PR！见 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## 📝 授权与商标

**双重授权软件** —— 完整条款见 [LICENSE](LICENSE)：

| 使用情境 | 授权 |
|---------|------|
| 🟢 个人 / 教育 / 学术研究 / 非营利 / 评估（< 30 天）| [MIT](licenses/MIT.md)（免费）|
| 🟢 对此 repo 的开源贡献 | [MIT](licenses/MIT.md)（免费）|
| 🔴 营利组织内部使用 | [Commercial](licenses/COMMERCIAL.md)（付费）|
| 🔴 内嵌于付费产品 / SaaS / 咨询服务 | [Commercial](licenses/COMMERCIAL.md)（付费）|

商业授权请开 [GitHub Issue 并贴 `commercial-license` 标签](licenses/COMMERCIAL.md#step-1-open-a-github-issue)。

**商标**：「QA Claude Skill」为 Jack Kao 之商标 —— 使用规范见 [TRADEMARK.md](TRADEMARK.md)。MIT / Commercial license 授予源代码权利，**不**授予商标权。未经授权不得将 fork 命名为「QA Claude Skill X」。

> 本套件为 [Claude Code](https://claude.ai/code) 使用者的**社群 / 个人专案**，**非** Anthropic 官方产品。

---

## ☕ 赞助

如果这个专案帮你的 QA 团队省下时间，考虑请我喝杯咖啡 —— 让专案持续迭代：

<p align="center">
  <a href="https://buymeacoffee.com/minikao">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me a Coffee" width="200" />
  </a>
</p>

或者给 repo 一个 ⭐ —— 不花钱但能帮助其他人发现本专案。

---

<p align="center">
  ❤️ 为想专注质量、不想被文书工作淹没的 QA 团队打造。
</p>
