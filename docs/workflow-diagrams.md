# Skill 串接工作流圖

15 個 Skill 不是孤立的工具，而是組合成不同情境的測試流程。

---

## 🌊 工作流 1: 從規格到上線（完整 BE feature pipeline）

```
                     ┌──────────────────────────┐
                     │  Jira spec ticket close  │
                     └────────────┬─────────────┘
                                  ▼
                     ┌──────────────────────────┐
                     │     speckit-to-tc        │  自動草擬 BB+WB TC
                     └────────────┬─────────────┘
                                  ▼
                  ┌────────tc-be-{KEY}-draft.md────────┐
                                  ▼
                     ┌──────────────────────────┐
                     │      test-review         │  10 維度評分審查
                     └────────────┬─────────────┘
                            critical/major 修正
                                  ▼
                     ┌──────────────────────────┐
                     │    sheet-md-sync         │  正式上 Google Sheet
                     │       --to-sheet         │
                     └────────────┬─────────────┘
                                  ▼
                     ┌──────────────────────────┐
                     │      tc-to-pytest        │  白箱 → pytest 三件套
                     └────────────┬─────────────┘
                                  ▼
                     ┌─────baseline pytest pass─────┐
                                  ▼
                     ┌──────────────────────────┐
                     │   mutation-testing       │  量化 TC 強度
                     └────────────┬─────────────┘
                          survived → 補測
                                  ▼
                     ┌──────────────────────────┐
                     │ property-based-test-gen  │  fuzz 封死 boundary
                     └────────────┬─────────────┘
                                  ▼
                     ┌──────────────────────────┐
                     │      release-ready       │
                     └──────────────────────────┘
```

---

## 🌊 工作流 2: 客戶端 Release 前準備

```
                     ┌──────────────────────────┐
                     │   新功能規格 / Sprint    │
                     └────────────┬─────────────┘
                                  ▼
        ┌──────────────test-master / flutter-test-master────────────┐
        │      （依專案是原生還是 Flutter 選一個）                   │
        └────────────┬─────────────────────────────────────────────┘
                     ▼
        ┌──────test-automation / flutter-test-automation──────┐
        │      （把 Column L=Y 的 TC 轉成腳本）              │
        └────────────┬─────────────────────────────────────────┘
                     ▼
        ┌──────────────────────────┐
        │  smoke-test-analyzer     │  挑出 T0/T1 加入 daily CI
        └────────────┬─────────────┘
                     ▼
                Release 前
                     ▼
        ┌──────────────────────────┐
        │   regression-test 1.x.0  │  撈本 release 需求 + 歷史 bug
        └────────────┬─────────────┘
                     ▼
        ┌──────────[ 跑回歸測試 ]──────────┐
                     ▼
        ┌────────────────────┐    ┌─────────────────┐
        │   有 Fail 項目     │───→│   bug-report    │  RIDER + JIRA
        └────────────────────┘    └────────┬────────┘
                                           ▼
                                 cross-platform pairing
                                  + a11y pairing
                                           │
        ┌────────────────────────────────────┘
        ▼
┌──────────────────────────┐
│   publish-regression     │  S3 + CloudFront + Slack
└──────────────────────────┘
```

---

## 🌊 工作流 3: TC 升版（v0.2 → v0.3）

```
                     ┌──────────────────────────┐
                     │   Spec / Bug 反饋找到缺口 │
                     └────────────┬─────────────┘
                                  ▼
                     ┌──────────────────────────┐
                     │ test-master --mode=quick │  補新 TC（v0.3）
                     └────────────┬─────────────┘
                                  ▼
                     ┌──────────────────────────┐
                     │      test-review         │  v0.3 自評
                     └────────────┬─────────────┘
                                  ▼
                     ┌──────────────────────────┐
                     │    tc-version-diff       │  v0.2 vs v0.3
                     │    v0.2 v0.3             │
                     └────────────┬─────────────┘
                       changelog + 補測清單
                                  ▼
                     ┌──────────────────────────┐
                     │ tc-to-pytest             │  同步 pytest
                     │ --incremental            │
                     └────────────┬─────────────┘
                                  ▼
                          [跑補測清單]
                                  ▼
                     ┌──────────────────────────┐
                     │ status sheet 自動更新     │
                     └──────────────────────────┘
```

---

## 🌊 工作流 4: Markdown-only 模式（單人 / 無 MCP / 純文件）

```
                     ┌──────────────────────────┐
                     │   功能描述 / spec.md      │
                     └────────────┬─────────────┘
                                  ▼
                     ┌──────────────────────────┐
                     │   test-master            │  → .claude/testing/features/.../*.md
                     └────────────┬─────────────┘
                                  ▼
                     ┌──────────────────────────┐
                     │   test-review            │  → reviews/{name}-summary.md
                     └────────────┬─────────────┘
                                  ▼
                     ┌──────────────────────────┐
                     │   test-automation        │  仍可生成 .swift / .kt
                     │   （讀 .md TC）           │
                     └────────────┬─────────────┘
                                  ▼
                     ┌──────────────────────────┐
                     │   bug-report             │  → ./bugs/bug-{slug}.md
                     └──────────────────────────┘
```

---

## 🌊 工作流 5: 三方審查協議（Claude + Codex + Gemini）

`review_protocol.tri_party_enabled = true` 時：

```
                     ┌──────────────────────────┐
                     │     Google Sheet TC      │
                     └────────────┬─────────────┘
                ┌─────────────────┼─────────────────┐
                ▼                 ▼                 ▼
       ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
       │   Claude     │ │    Codex     │ │   Gemini     │
       │ test-review  │ │ test-review  │ │ test-master  │
       │              │ │              │ │   審查模式    │
       └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
              │                │                │
              └───────────┬────┴────────────────┘
                          ▼
              ┌──────────────────────────┐
              │  status sheet 寫 3 行    │
              │   + 綜合評分（平均）       │
              └────────────┬─────────────┘
                           ▼
                  爭議項目（差距 ≥ 2 分）
                  人工裁決
```

---

## 🔢 Skill 計數 by 角色

| 角色 | 用得到的 Skill 數 | 主要 Skills |
|------|---------------|-------------|
| QA 測試工程師 | 9 | test-master / test-review / test-automation / regression-test / bug-report / sheet-md-sync / smoke-test-analyzer / tc-version-diff / publish-regression |
| BE 工程師 | 4 | tc-to-pytest / mutation-testing / property-based-test-gen / speckit-to-tc |
| iOS 工程師 | 5 | test-master / test-automation / test-review / bug-report / smoke-test-analyzer |
| Android 工程師 | 5 | 同上 |
| Flutter 工程師 | 4 | flutter-test-master / flutter-test-automation / test-review / bug-report |
| QA Manager / Lead | 全部 15 | — |
| 單人開發者 | 5 | test-master / test-review / bug-report / test-automation / verify |

---

## 📚 進階用法

### 多 Skill 串接的 alias / shortcut

可在你的 shell rc 加上 alias（範例）：

```bash
# Sprint 結束時：一鍵跑 review + diff + 補測
alias qa-sprint-end='echo "1. /test-review {sheet}" && \
                     echo "2. /tc-version-diff" && \
                     echo "3. /tc-to-pytest --incremental"'

# Release 前：一鍵跑回歸 + smoke 篩選
alias qa-release-prep='echo "1. /regression-test {version}" && \
                       echo "2. /smoke-test-analyzer" && \
                       echo "3. /publish-regression {sheet} {version}"'
```

### 多人協作的分工

依「最後一公里」原則：
- **QA 主要負責**：test-master / test-review / regression-test / bug-report
- **開發者主要負責**：test-automation / tc-to-pytest / property-based-test-gen / mutation-testing
- **DevOps 主要負責**：smoke-test-analyzer / publish-regression
- **PM 主要負責**：speckit-to-tc（規格→TC 草稿）
