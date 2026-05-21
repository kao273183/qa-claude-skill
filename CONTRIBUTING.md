# Contributing to QA_Claude_Skill

歡迎貢獻！這份套件是為了讓 QA 團隊不用從零開始造輪子。

## 🐛 回報 Bug

開 issue 時請附上：
- 你的 `config.json`（**去敏感資料**：JIRA Account ID、Slack ID 換成 `<REDACTED>`）
- 你執行的 trigger phrase / Skill 名稱
- 預期行為 vs 實際行為
- `./install.sh` 輸出（如果是安裝問題）

## 💡 新增 Skill

如果你想貢獻新的 QA Skill：

1. 在 `skills/<new-skill-name>/` 建立資料夾，含：
   - `SKILL.md` — 主檔（繁中）
   - `SKILL.en.md` — 英文版
   - `examples.md` — 至少 3 個使用範例
   - `modules/config-loader.md` — 複製其他 skill 的版本
   - 其他輔助檔（templates / patterns 等）

2. 遵循[變數佔位符規範](./docs/customization-guide.md#-變數佔位符完整對照)
3. 至少支援 `markdown-only` mode（fallback）
4. 在 `README.md` / `docs/skill-index.md` / `CHANGELOG.md` 加上新 skill
5. 用 3 種 preset 跑過 `install.sh` 確認 0 unresolved variables

## 🌐 翻譯貢獻

目前支援繁中 + 英文。若想加日文 / 簡中 / 韓文：

1. 各 SKILL.md 加上對應 `.{lang}.md`
2. 在 `config.schema.json` 的 `language.primary` 加上對應枚舉
3. 在 `README` / `INSTALL` / `docs/*` 加上對應翻譯版

## 🔧 修改既有 Skill

請確保：
- 不破壞既有 `{{變數}}` 對照表
- 維持 `mode != markdown-only` / `markdown-only` 兩種行為的對等性
- 改完跑 `CLAUDE_SKILLS_DIR=/tmp/preview ./install.sh` 確認渲染正常
- 更新對應的 examples.md
- 更新 CHANGELOG.md

## 📝 提交 PR

1. Fork repo
2. 建分支：`git checkout -b feature/your-skill-name`
3. Commit：訊息開頭加 type
   - `feat: 新增 X skill`
   - `fix: 修 Y skill 的 Z bug`
   - `docs: 補 customization-guide 範例`
4. Push 到你的 fork
5. 開 PR，描述：
   - 改了什麼
   - 為什麼這樣改
   - 怎麼驗證（最好附 dry-run install 結果）

## ✅ PR 檢查表

- [ ] 跑 `CLAUDE_SKILLS_DIR=/tmp/preview ./install.sh`，無 unresolved 變數
- [ ] 至少用 1 個 preset 驗證新功能可用
- [ ] CHANGELOG.md 加上對應條目
- [ ] 不含個人敏感資料（Account ID / Slack ID / Email）
- [ ] Markdown 格式無誤（試 `npx markdownlint-cli **/*.md`）

## 💬 行為準則

- 對使用者友善（不假設使用者知道所有事）
- 對其他貢獻者尊重
- 對程式碼嚴格、對人寬厚

---

謝謝你的貢獻！
