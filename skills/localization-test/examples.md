# localization-test 範例

## 範例 1: 全套 6 維度檢查

```
User: /localization-test --check=all
```

執行：
1. 偵測 i18n 框架（i18next + react-i18next）
2. 對 6 個 locale（en/zh-TW/zh-CN/ja/de/ar）跑：
   - Missing translations: 28
   - Length overflow: 12 (mostly de)
   - RTL: 4 issues (icon mirror)
   - Format: 6 hard-coded date
   - Pluralization: 3 raw count > 1
   - Locale switch: 0 ✅

3. 寫 `localization-report.md`

## 範例 2: 只跑 RTL 檢查

```
User: /localization-test --check=rtl --locales=ar,he
```

執行：
1. 切到 ar / he locale 跑 Playwright snapshot
2. 對比是否 mirror layout
3. 找到 4 個 icon 該翻轉但沒翻轉

## 範例 3: 加新語言 baseline

```
User: 我們要加韓文支援，先做 baseline check
```

執行：
1. 比對 `i18n/en.json` vs `i18n/ko.json` → 列出要翻譯的 432 key
2. 跑韓文 UI snapshot → 看是否有 layout issue
3. 報告：「先翻 432 keys，然後跑 length overflow check」

## 範例 4: CI 整合

```
User: 把 localization-test 加進 PR CI
```

生成 `.github/workflows/i18n-check.yml`：
```yaml
on:
  pull_request:
    paths: ['i18n/**', 'src/**']

jobs:
  i18n-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm install
      - run: npm run i18n:lint
      # 找 missing key + hard-coded format
```
