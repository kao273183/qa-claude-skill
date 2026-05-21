# Regression Test Templates

## 回歸測試用例欄位結構 (A-O, 15 欄)

| Col | Header | Width | Purpose | Dropdown | Align |
|-----|--------|-------|---------|----------|-------|
| A | 編號 | 80 | RT-{NNN} | - | center |
| B | 測試區域 | 140 | 功能模組名稱 | - | - |
| C | 測試類型 | 130 | 分區分類 | Yes | center |
| D | 測試項目 | 300 | 測試標題（描述行為+預期） | - | - |
| E | 平台 | 90 | iOS / Android / Both | Yes | center |
| F | 優先度 | 70 | P0 / P1 / P2 | Yes | center |
| G | 風險等級 | 90 | High / Medium / Low | Yes | center |
| H | 前置條件 | 200 | 測試前提條件 | - | - |
| I | 測試步驟 | 350 | 編號步驟 | - | - |
| J | 預期結果 | 350 | 編號預期結果 | - | - |
| K | iOS 結果 | 100 | Pass/Fail/Blocked/N/A | Yes | center |
| L | Android 結果 | 100 | Pass/Fail/Blocked/N/A | Yes | center |
| M | 預估時間(天) | 90 | 該項測試預估天數 | - | center |
| N | 相關 JIRA | 120 | HYPERLINK 公式連結 | - | center |
| O | 備註 | 200 | 補充說明 | - | - |

## Dropdown 值

| Column | Values |
|--------|--------|
| C 測試類型 | Smoke Test, 新功能驗證, Bug Fix 驗證, 高風險回歸, 歷史問題回歸 |
| E 平台 | iOS, Android, Both |
| F 優先度 | P0, P1, P2 |
| G 風險等級 | High, Medium, Low |
| K iOS 結果 | Pass, Fail, Blocked, N/A |
| L Android 結果 | Pass, Fail, Blocked, N/A |

## 條件格式顏色

### 測試類型 (Col C)
| Value | Background | Font Color | Bold |
|-------|-----------|------------|------|
| Smoke Test | #FF6B6B (red) | white | Yes |
| 新功能驗證 | #4ECDC4 (teal) | black | Yes |
| Bug Fix 驗證 | #85C1E9 (blue) | black | Yes |
| 高風險回歸 | #FFA500 (orange) | black | Yes |
| 歷史問題回歸 | #DDA0DD (purple) | black | Yes |

### 風險等級 (Col G)
| Value | Background | Font Color | Bold |
|-------|-----------|------------|------|
| High | #FF6B6B | white | Yes |
| Medium | #FFA500 | black | Yes |
| Low | #90EE90 | black | No |

### iOS/Android 結果 (Col K/L)
| Value | Background | Font Color | Bold |
|-------|-----------|------------|------|
| Pass | #90EE90 (green) | black | Yes |
| Fail | #FF6B6B (red) | white | Yes |
| Blocked | #FFA500 (orange) | black | Yes |
| N/A | #D3D3D3 (gray) | black | No |

### 優先度 (Col F) / 平台 (Col E)
沿用 `test-case-format` 既有的顏色方案。

## Header 格式
- Fill: `#366092` (dark blue)
- Font: bold, white, 11pt
- Alignment: center
- Freeze row 1
- Auto-filter enabled

## 回歸測試總覽 Sheet 結構

```
=== Release 資訊 ===
Row 1:  [section header: #366092]
Row 2:  Release 版本 | iOS: x.x.x / Android: x.x.x
Row 3:  測試日期     | YYYY/MM/DD ~ YYYY/MM/DD
Row 4:  測試人員     | (填入)
Row 5:  測試環境     | UAT / Staging / Production
Row 6:  JIRA Fix Version | (版本號)
Row 7:  (empty)

=== 風險評估矩陣 ===
Row 8:  [section header]
Row 9:  模組 | 變更量 | 歷史 Bug | 業務關鍵性 | 跨平台 | 重複問題 | 綜合風險
Row 10+: (每個模組一行)

=== 測試時間估算 ===
Row N:  [section header]
Row N+1: 平台 | P0 項目數 | P1 項目數 | P2 項目數 | 總項目 | 預估天數 | 含 Buffer
Row N+2: iOS | (formula) | ... | ... | ... | (formula) | x1.2
Row N+3: Android | (formula) | ... | ... | ... | (formula) | x1.2
Row N+4: 合計 | ... | ... | ... | ... | (sum) | (sum)

=== 建議測試順序 ===
Row M:  [section header]
Row M+1: 順序 | 測試類型 | 預估天數 | 說明
Row M+2: 1 | Smoke Test | 0.5 | 核心流程驗證，必須全 Pass 才繼續
Row M+3: 2 | 高風險回歸 | x | 風險最高的模組優先
Row M+4: 3 | 新功能驗證 | x | 本次 Release 新增/修改功能
Row M+5: 4 | Bug Fix 驗證 | x | 確認修復且無 side effect
Row M+6: 5 | 歷史問題回歸 | x | 過去重複出現的問題

=== 測試進度統計 ===
Row P:  [section header]
Row P+1: 指標 | iOS | Android | 合計
Row P+2: 總測試項目 | =COUNTIFS(E,"iOS")+COUNTIFS(E,"Both") | =COUNTIFS(E,"Android")+COUNTIFS(E,"Both") | =COUNTA(A2:A)
Row P+3: Pass | (COUNTIFS K/L="Pass") | ... | ...
Row P+4: Fail | (COUNTIFS K/L="Fail") | ... | ...
Row P+5: Blocked | ... | ... | ...
Row P+6: 未執行 | ... | ... | ...
Row P+7: 執行率 | (Pass+Fail)/Total | ... | ...
Row P+8: 通過率 | Pass/(Pass+Fail) | ... | ...
```

## 注意事項

### Section Header 寫入
`=== xxx ===` 格式的 section header 會被 Google Sheets 當成公式解析（#ERROR!）。
- **解法 1**: 使用 `valueInputOption: RAW` 寫入
- **解法 2**: 前面加單引號 `'=== xxx ===`

### 美化腳本
若需要 Apps Script 美化，可放在 `~/Desktop/QA_Claude_Skill/examples/format-regression-sheet.gs`（範例腳本，使用者自行貼到 Google Sheet → 擴充功能 → Apps Script）。

## JIRA 單號 HYPERLINK 格式

相關 JIRA 欄位（Col N）使用 HYPERLINK 公式：
```
=HYPERLINK("{{JIRA_INSTANCE_URL}}/browse/{{JIRA_PROJECT_KEY}}-xxxx", "{{JIRA_PROJECT_KEY}}-xxxx")
```

## 檔案命名與位置

```
{{GDRIVE_QA_FOLDER_ID}}/
└── Release {version}/
    └── 回歸測試-v{version}  (Google Sheet)
```

## Markdown-only 模式輸出

```
.claude/testing/regression/v{version}/
├── overview.md          ← Release 資訊 + 進度統計
├── risk-matrix.md       ← 風險評估矩陣
├── changelog.md         ← 變更清單
├── test-cases.md        ← 15 欄表格
└── history-analysis.md  ← 歷史 Bug 分析
```
