# Windows 安裝指南

QA Claude Skill 在 Windows 上有 3 種安裝方式，按複雜度排序：

| 方式 | 適合 | 需要安裝 |
|------|------|---------|
| **A. PowerShell 原生**（推薦）| 一般 Windows 使用者 | 無（PowerShell 5.1+ 內建）|
| **B. Git Bash / MSYS2** | 熟悉 bash 的使用者 | Git for Windows（含 jq）|
| **C. WSL（Windows Subsystem for Linux）** | 開發者 / 重度使用 Linux 工具的使用者 | WSL2 + Ubuntu |

---

## 方式 A：PowerShell 原生（推薦）

✨ **零依賴** — 用 Windows 內建 PowerShell 5.1+ 即可（Win 10 / Win 11 都預裝）。

### 安裝步驟

```powershell
# 1. Clone repo
git clone https://github.com/kao273183/qa-claude-skill.git $env:USERPROFILE\Desktop\QA_Claude_Skill
cd $env:USERPROFILE\Desktop\QA_Claude_Skill

# 2. 複製設定範本
Copy-Item config\config.example.json config\config.json

# 3. 編輯 config.json（用 notepad / VS Code / 任何編輯器）
notepad config\config.json

# 4. 安裝（注意斜線是反斜線）
.\install.ps1

# 5. 在 Claude Code 中試
#    "Generate test plan for feature X"
```

### 若遇到 PowerShell 執行策略阻擋

預設 Windows 不允許跑未簽章的 .ps1，會看到：
```
無法載入檔案 install.ps1，原因是這個系統上停用了指令碼執行。
```

**選項 1**（一次性，最安全）：
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

**選項 2**（永久開啟自寫 script，需要管理員權限）：
```powershell
# 開 PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Dry-run 預覽（不動 ~/.claude/skills）

```powershell
$env:CLAUDE_SKILLS_DIR = "C:\temp\qa-preview"
.\install.ps1
ls C:\temp\qa-preview\
```

### 校驗 config（不安裝）

```powershell
.\scripts\validate-config.ps1
.\scripts\validate-config.ps1 config\presets\enterprise.json
```

### 移除

```powershell
.\uninstall.ps1
```

---

## 方式 B：Git Bash / MSYS2

如果你已經有 Git for Windows，可以直接跑 `install.sh`（bash 版本）。

### 安裝步驟

```bash
# 在 Git Bash 中（不是 PowerShell）
cd ~/Desktop/QA_Claude_Skill

# 確認 jq 已裝（Git for Windows 通常沒裝 jq）
which jq

# 若 jq 沒裝：用 Chocolatey 或 Scoop 裝
# Chocolatey:
choco install jq
# Scoop:
scoop install jq

# 之後步驟跟 macOS / Linux 完全一樣
cp config/config.example.json config/config.json
vim config/config.json
./install.sh
```

> 💡 路徑提醒：Git Bash 中 `~` 對應到 `C:\Users\<你>`，但 `$HOME/.claude/skills` 實際是 `C:\Users\<你>\.claude\skills`。

---

## 方式 C：WSL（Windows Subsystem for Linux）

最完整的 Linux 體驗，所有 bash 工具都能跑。

### 一次性設定

```powershell
# 在 PowerShell as Administrator 中
wsl --install
# 重啟，會自動安裝 Ubuntu
```

### 在 WSL 內安裝

```bash
# 進 WSL Ubuntu
wsl

# 安裝必要工具
sudo apt update
sudo apt install -y git jq

# Clone repo
cd ~
git clone https://github.com/kao273183/qa-claude-skill.git
cd qa-claude-skill

# 之後步驟跟 Linux 完全一樣
cp config/config.example.json config/config.json
nano config/config.json
./install.sh
```

⚠️ **重要**：WSL 安裝的 skill 在 WSL 的 `~/.claude/skills/`，**不在 Windows 的 C:\Users**。要讓 Windows 的 Claude Code 找到，需要：

選項 A：把 Claude Code 也在 WSL 內跑（推薦）

選項 B：用 PowerShell 版本（方式 A），避免兩個檔案系統混淆

---

## 三種方式對照

| 面向 | A. PowerShell | B. Git Bash | C. WSL |
|------|---------------|-------------|--------|
| 安裝難度 | ⭐ 最低 | ⭐⭐ | ⭐⭐⭐ |
| 額外依賴 | 無 | Git for Windows + jq | WSL2 + Ubuntu + jq |
| 跨平台一致性 | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 與 Claude Code 整合 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐（檔案系統獨立）|
| 效能 | 中等 | 快 | 最快 |
| 適合誰 | 一般使用者 | 熟悉 Unix 的 Windows 使用者 | 開發者 |

---

## 疑難排解

### 1. PowerShell 版本太舊

```powershell
$PSVersionTable.PSVersion
```

需要 5.1 以上。Win 10 / Win 11 都有；Win 7 / Win 8 升級到 PowerShell 5.1 或 PowerShell Core 7.x。

下載 PowerShell 7：https://github.com/PowerShell/PowerShell/releases

### 2. ConvertFrom-Json 解析失敗

```
ConvertFrom-Json : Cannot bind argument to parameter 'InputObject'
```

通常是 config.json 有 BOM 或編碼問題。用 PowerShell 重存：

```powershell
$content = Get-Content config\config.json -Raw
Set-Content -Path config\config.json -Value $content -Encoding UTF8
```

### 3. 變數沒被替換（看到 `{{JIRA_PROJECT_KEY}}` 還在）

確認對應 config 欄位有填值：

```powershell
$config = Get-Content config\config.json -Raw | ConvertFrom-Json
$config.jira.project_key   # 應該有值，不是 null
```

### 4. 路徑含空格 / 中文

PowerShell 路徑要用反引號或雙引號：

```powershell
$env:CLAUDE_SKILLS_DIR = "C:\Users\我的使用者\Custom Folder\skills"
.\install.ps1
```

### 5. 重啟 Claude Code 後 skill 仍找不到

確認 skill 已寫進 `~\.claude\skills\`：

```powershell
ls $env:USERPROFILE\.claude\skills\
# 應該看到 15 個資料夾
```

如果沒有，重跑 `.\install.ps1`。

---

## 進階：在 Windows CI 跑

GitHub Actions / GitLab CI 也支援 Windows runner：

```yaml
# GitHub Actions
jobs:
  validate:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate config (PowerShell)
        run: .\scripts\validate-config.ps1
        shell: powershell
```

```yaml
# GitLab CI
validate-config:
  tags: [windows]
  script:
    - .\scripts\validate-config.ps1
```

---

## 🔗 相關

- [INSTALL.md](../INSTALL.md) — macOS / Linux 安裝
- [customization-guide.md](./customization-guide.md) — config.json 完整客製化
- [ci-integration.md](./ci-integration.md) — CI/CD 整合
