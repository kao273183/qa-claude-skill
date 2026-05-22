# QA Claude Skill — Installer (PowerShell / Windows native)
# Equivalent of install.sh but using PowerShell built-ins (no jq required).
#
# Usage:
#   .\install.ps1
#
# Optional env var:
#   $env:CLAUDE_SKILLS_DIR = "C:\custom\path"   # override default ~\.claude\skills

#Requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ---- Paths ----
$ScriptDir       = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsSrc       = Join-Path $ScriptDir 'skills'
$ConfigFile      = Join-Path $ScriptDir 'config\config.json'
$ExampleFile     = Join-Path $ScriptDir 'config\config.example.json'
$ValidatorPs1    = Join-Path $ScriptDir 'scripts\validate-config.ps1'
$ClaudeSkillsDir = if ($env:CLAUDE_SKILLS_DIR) { $env:CLAUDE_SKILLS_DIR } else { Join-Path $env:USERPROFILE '.claude\skills' }
$Timestamp       = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupDir       = Join-Path $env:USERPROFILE ".claude\skills.backup-$Timestamp"

# ---- Color helpers ----
function Write-Info  { param([string]$Msg) Write-Host "[INFO] " -ForegroundColor Blue   -NoNewline; Write-Host $Msg }
function Write-Ok    { param([string]$Msg) Write-Host "[OK  ] " -ForegroundColor Green  -NoNewline; Write-Host $Msg }
function Write-Warn  { param([string]$Msg) Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline; Write-Host $Msg }
function Write-Err   { param([string]$Msg) Write-Host "[ERR ] " -ForegroundColor Red    -NoNewline; Write-Host $Msg }

# ---- Pre-flight ----
if (-not (Test-Path $ConfigFile)) {
    Write-Warn "config.json not found."
    $ans = Read-Host "Copy config.example.json -> config.json now? [Y/n]"
    if ([string]::IsNullOrEmpty($ans) -or $ans -match '^[Yy]') {
        Copy-Item $ExampleFile $ConfigFile
        Write-Ok "Created $ConfigFile"
        Write-Warn "Please edit it and re-run .\install.ps1"
        exit 0
    } else {
        Write-Err "Aborted. Provide config\config.json first."
        exit 1
    }
}

# ---- Validate config ----
if (Test-Path $ValidatorPs1) {
    Write-Info "Validating config.json (delegating to scripts\validate-config.ps1) ..."
    & powershell -NoProfile -ExecutionPolicy Bypass -File $ValidatorPs1 $ConfigFile
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Config validation failed. Fix the errors above and re-run."
        exit 1
    }
    Write-Host ""
} else {
    # Inline minimal check
    Write-Info "Validating config.json (inline minimal check) ..."
    $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
    $missing = 0
    $required = @{
        '.jira.instance_url'              = $config.jira.instance_url
        '.jira.project_key'               = $config.jira.project_key
        '.platforms.ios.default_device'   = $config.platforms.ios.default_device
        '.platforms.android.default_device' = $config.platforms.android.default_device
    }
    foreach ($key in $required.Keys) {
        if ([string]::IsNullOrEmpty($required[$key])) {
            Write-Err "Missing required field: $key"
            $missing++
        }
    }
    if ($missing -gt 0) { Write-Err "Fix config.json and re-run."; exit 1 }
    Write-Ok "config.json passes minimal check"
}

# ---- Load config ----
$config = Get-Content $ConfigFile -Raw | ConvertFrom-Json

# ---- Build substitution map ----
function Get-Value {
    param([object]$Obj, [string]$Path, [string]$Default = "")
    $parts = $Path -split '\.'
    $current = $Obj
    foreach ($p in $parts) {
        if ($null -eq $current) { return $Default }
        $current = $current.$p
    }
    if ($null -eq $current -or [string]::IsNullOrEmpty([string]$current)) { return $Default }
    return [string]$current
}

$browsersArr = if ($config.platforms.web.default_browsers) { $config.platforms.web.default_browsers -join ', ' } else { '' }

$Substitutions = [ordered]@{
    '{{JIRA_PROJECT_KEY}}'            = Get-Value $config 'jira.project_key'
    '{{JIRA_INSTANCE_URL}}'           = Get-Value $config 'jira.instance_url'
    '{{JIRA_REVIEWER_ACCOUNT_ID}}'    = Get-Value $config 'jira.reviewer_account_id'
    '{{JIRA_REVIEWER_FIELD}}'         = Get-Value $config 'jira.reviewer_field' 'customfield_10045'
    '{{JIRA_BUG_ISSUE_TYPE_ID}}'      = Get-Value $config 'jira.bug_issue_type_id' '10046'
    '{{SLACK_USER_ID}}'               = Get-Value $config 'slack.user_id'
    '{{SLACK_BUG_CHANNEL_ID}}'        = Get-Value $config 'slack.bug_channel_id'
    '{{SLACK_RELEASE_CHANNEL_ID}}'    = Get-Value $config 'slack.release_channel_id'
    '{{GSHEET_TC_TEMPLATE_ID}}'       = Get-Value $config 'google.tc_template_id'
    '{{GDRIVE_QA_FOLDER_ID}}'         = Get-Value $config 'google.qa_tc_folder_id'
    '{{GSHEET_RELEASE_SCHEDULE_ID}}'  = Get-Value $config 'google.release_schedule_id'
    '{{GSHEET_REGRESSION_TEMPLATE}}'  = Get-Value $config 'google.regression_template_id'
    '{{IOS_DEFAULT_DEVICE}}'          = Get-Value $config 'platforms.ios.default_device'
    '{{IOS_DEFAULT_VERSION}}'         = Get-Value $config 'platforms.ios.default_os_version'
    '{{MIN_IOS_VERSION}}'             = Get-Value $config 'platforms.ios.min_os_version'
    '{{IOS_REPO}}'                    = Get-Value $config 'platforms.ios.repo'
    '{{IOS_RELEASE_BRANCH_PATTERN}}'  = Get-Value $config 'platforms.ios.release_branch_pattern' 'release/{version}'
    '{{IOS_VERSION_FILE_PATTERN}}'    = Get-Value $config 'platforms.ios.version_file' '**/*.xcconfig'
    '{{ANDROID_DEFAULT_DEVICE}}'      = Get-Value $config 'platforms.android.default_device'
    '{{ANDROID_DEFAULT_VERSION}}'     = Get-Value $config 'platforms.android.default_os_version'
    '{{MIN_ANDROID_API}}'             = if ($config.platforms.android.min_api_level) { [string]$config.platforms.android.min_api_level } else { '' }
    '{{ANDROID_REPO}}'                = Get-Value $config 'platforms.android.repo'
    '{{ANDROID_RELEASE_TAG_PATTERN}}' = Get-Value $config 'platforms.android.release_tag_pattern' 'v{version}'
    '{{ANDROID_VERSION_FILE_PATTERN}}' = Get-Value $config 'platforms.android.version_file' '**/build.gradle'
    '{{PYTEST_PROJECT_ROOT}}'         = Get-Value $config 'backend.pytest_project_root'
    '{{SPECKIT_REPO_ROOT}}'           = Get-Value $config 'speckit.repo_root'
    '{{PUBLISH_HTML_GENERATOR}}'      = Get-Value $config 'publish_regression.html_generator_script'
    '{{PUBLISH_INDEX_GENERATOR}}'     = Get-Value $config 'publish_regression.index_generator_script'
    '{{WEB_REPO}}'                    = Get-Value $config 'platforms.web.repo'
    '{{WEB_PRIMARY_FRAMEWORK}}'       = Get-Value $config 'platforms.web.frameworks.primary' 'playwright'
    '{{WEB_DEFAULT_BROWSERS}}'        = $browsersArr
    '{{PERF_PRIMARY_FRAMEWORK}}'      = Get-Value $config 'performance.primary_framework' 'k6'
    '{{VR_TOOL}}'                     = Get-Value $config 'visual_regression.tool' 'playwright'
    '{{CONTRACT_PRIMARY_TOOL}}'       = Get-Value $config 'contract_test.primary_tool' 'pact'
    '{{FLAKY_DAYS}}'                  = if ($config.flaky_hunter.lookback_days) { [string]$config.flaky_hunter.lookback_days } else { '30' }
}

# ---- Render a single skill ----
function Render-Skill {
    param([string]$Src, [string]$Dest)

    if (-not (Test-Path $Dest)) {
        New-Item -ItemType Directory -Path $Dest -Force | Out-Null
    }

    Get-ChildItem -Path $Src -Recurse -File | ForEach-Object {
        $relPath = $_.FullName.Substring($Src.Length + 1)
        $destFile = Join-Path $Dest $relPath
        $destDir = Split-Path -Parent $destFile
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        # Render text files; copy binaries as-is
        if ($_.Extension -in '.md', '.json', '.yaml', '.yml', '.txt') {
            $content = Get-Content $_.FullName -Raw
            foreach ($key in $Substitutions.Keys) {
                $content = $content -replace [regex]::Escape($key), [string]$Substitutions[$key]
            }
            Set-Content -Path $destFile -Value $content -NoNewline
        } else {
            Copy-Item $_.FullName $destFile -Force
        }
    }
}

# ---- Discover skills to install ----
if (-not (Test-Path $SkillsSrc)) {
    Write-Err "$SkillsSrc not found"
    exit 1
}
$SkillsToInstall = Get-ChildItem -Path $SkillsSrc -Directory | Select-Object -ExpandProperty Name

if ($SkillsToInstall.Count -eq 0) {
    Write-Err "No skills found under $SkillsSrc"
    exit 1
}

Write-Info "Will install $($SkillsToInstall.Count) skills: $($SkillsToInstall -join ', ')"

# ---- Backup conflicts ----
if (-not (Test-Path $ClaudeSkillsDir)) {
    New-Item -ItemType Directory -Path $ClaudeSkillsDir -Force | Out-Null
}

$NeedBackup = @()
foreach ($s in $SkillsToInstall) {
    if (Test-Path (Join-Path $ClaudeSkillsDir $s)) {
        $NeedBackup += $s
    }
}

if ($NeedBackup.Count -gt 0) {
    Write-Info "Backing up existing skills to $BackupDir"
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    foreach ($s in $NeedBackup) {
        Move-Item (Join-Path $ClaudeSkillsDir $s) (Join-Path $BackupDir $s)
    }
    Write-Ok "Backup complete"
}

# ---- Install ----
foreach ($s in $SkillsToInstall) {
    Write-Info "Installing $s ..."
    Render-Skill (Join-Path $SkillsSrc $s) (Join-Path $ClaudeSkillsDir $s)
}

Write-Ok "Installed $($SkillsToInstall.Count) skills to $ClaudeSkillsDir"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Restart Claude Code (or run /reload-skills if available)"
Write-Host "  2. Try a trigger phrase, e.g.: 'Generate test plan for feature X'"
Write-Host "  3. To revert: .\uninstall.ps1 (restores from backup)"
