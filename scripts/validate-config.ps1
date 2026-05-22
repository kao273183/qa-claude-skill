# QA Claude Skill — Config Validator (PowerShell / Windows native)
# Equivalent of scripts/validate-config.sh
#
# Usage:
#   .\scripts\validate-config.ps1                                    # default: config\config.json
#   .\scripts\validate-config.ps1 -ConfigFile config\presets\enterprise.json
#
# Exit codes:
#   0 — config OK (warnings may exist)
#   1 — config invalid (errors found)
#   2 — usage error (file not found, etc)

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ConfigFile = ""
)

$ErrorActionPreference = 'Continue'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
if ([string]::IsNullOrEmpty($ConfigFile)) {
    $ConfigFile = Join-Path $RepoRoot 'config\config.json'
}
$SchemaFile = Join-Path $RepoRoot 'config\config.schema.json'

# ---- Counters ----
$script:Errors = 0
$script:Warnings = 0

# ---- Helpers ----
function Write-PassMsg  { param([string]$Msg) Write-Host "✓ PASS    " -ForegroundColor Green  -NoNewline; Write-Host $Msg }
function Write-FailMsg  { param([string]$Msg) Write-Host "✗ ERROR   " -ForegroundColor Red    -NoNewline; Write-Host $Msg; $script:Errors++ }
function Write-WarnMsg  { param([string]$Msg) Write-Host "⚠ WARN    " -ForegroundColor Yellow -NoNewline; Write-Host $Msg; $script:Warnings++ }
function Write-InfoMsg  { param([string]$Msg) Write-Host "ℹ INFO    " -ForegroundColor Cyan   -NoNewline; Write-Host $Msg }

function Get-Value {
    param([object]$Obj, [string]$Path)
    $parts = $Path -split '\.'
    $current = $Obj
    foreach ($p in $parts) {
        if ($null -eq $current) { return $null }
        $current = $current.$p
    }
    return $current
}

# ---- Pre-flight ----
if (-not (Test-Path $ConfigFile)) {
    Write-Host "Config file not found: $ConfigFile" -ForegroundColor Red
    Write-Host "Hint: Copy-Item config\config.example.json config\config.json"
    exit 2
}
if (-not (Test-Path $SchemaFile)) {
    Write-Host "Schema file not found: $SchemaFile" -ForegroundColor Red
    exit 2
}

Write-Host "Validating: $ConfigFile"
Write-Host "Against:    $SchemaFile"
Write-Host ""

# ---- 1. JSON syntax ----
Write-Host "── 1. JSON syntax ─────────────────────────────"
try {
    $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
    Write-PassMsg "JSON syntax valid"
} catch {
    Write-FailMsg "Invalid JSON syntax: $($_.Exception.Message)"
    exit 1
}

# ---- 2. Required fields ----
Write-Host ""
Write-Host "── 2. Required fields ─────────────────────────"

function Check-Field {
    param([string]$Path, [string]$Desc)
    $val = Get-Value $config $Path
    if ($null -eq $val -or [string]::IsNullOrEmpty([string]$val)) {
        Write-FailMsg "Missing required: .$Path ($Desc)"
    } else {
        Write-PassMsg ".$Path = `"$val`""
    }
}

Check-Field 'mode' 'mode (full-mcp | partial-mcp | markdown-only)'
Check-Field 'jira.instance_url' 'JIRA Cloud URL'
Check-Field 'jira.project_key' 'JIRA project key (e.g. PROJ)'
Check-Field 'platforms.ios.default_device' 'iOS default test device'
Check-Field 'platforms.android.default_device' 'Android default test device'

# ---- 3. Enum values ----
Write-Host ""
Write-Host "── 3. Enum values ─────────────────────────────"

function Check-Enum {
    param([string]$Path, [string[]]$Allowed)
    $val = Get-Value $config $Path
    if ($null -eq $val -or [string]::IsNullOrEmpty([string]$val)) { return }
    if ($Allowed -contains [string]$val) {
        Write-PassMsg ".$Path = `"$val`" (valid)"
    } else {
        Write-FailMsg ".$Path = `"$val`" — expected one of: $($Allowed -join ', ')"
    }
}

Check-Enum 'mode' @('full-mcp', 'partial-mcp', 'markdown-only')
Check-Enum 'google.default_drive' @('shared', 'personal')
Check-Enum 'language.primary' @('zh-TW', 'zh-CN', 'en', 'ja')
Check-Enum 'publish_regression.report_pipeline.type' @('s3_cloudfront', 'local_html')

# ---- 4. Pattern checks ----
Write-Host ""
Write-Host "── 4. Pattern checks ──────────────────────────"

$projectKey = [string](Get-Value $config 'jira.project_key')
if ($projectKey) {
    if ($projectKey -match '^[A-Z][A-Z0-9_]+$') {
        Write-PassMsg "jira.project_key format OK"
    } else {
        Write-FailMsg "jira.project_key = `"$projectKey`" — should be UPPERCASE letters/digits/underscore"
    }
}

$reviewerField = [string](Get-Value $config 'jira.reviewer_field')
if ($reviewerField) {
    if ($reviewerField -match '^customfield_[0-9]+$') {
        Write-PassMsg "jira.reviewer_field format OK"
    } else {
        Write-FailMsg "jira.reviewer_field = `"$reviewerField`" — should match customfield_NNNNN"
    }
}

$jiraUrl = [string](Get-Value $config 'jira.instance_url')
if ($jiraUrl -and $jiraUrl -ne 'n/a') {
    if ($jiraUrl -match '^https?://.+') {
        Write-PassMsg "jira.instance_url format OK"
    } else {
        Write-FailMsg "jira.instance_url = `"$jiraUrl`" — should start with http(s):// or be `"n/a`""
    }
}

# ---- 5. Mode consistency ----
Write-Host ""
Write-Host "── 5. Mode consistency ─────────────────────────"
$mode = [string](Get-Value $config 'mode')
switch ($mode) {
    'full-mcp' {
        if (-not (Get-Value $config 'slack.user_id')) {
            Write-WarnMsg "mode=full-mcp but slack.user_id is empty → DM notifications will skip"
        }
        if (-not (Get-Value $config 'google.qa_tc_folder_id')) {
            Write-WarnMsg "mode=full-mcp but google.qa_tc_folder_id is empty → Sheet uploads will prompt manual"
        }
        Write-PassMsg "full-mcp consistency checked"
    }
    'partial-mcp' {
        Write-InfoMsg "mode=partial-mcp — each MCP gracefully degrades when missing"
        Write-PassMsg "partial-mcp consistency checked"
    }
    'markdown-only' {
        if (Get-Value $config 'slack.user_id') {
            Write-WarnMsg "mode=markdown-only but slack.user_id is set → it will be ignored"
        }
        Write-PassMsg "markdown-only consistency checked"
    }
}

# ---- 6. Cross-field consistency ----
Write-Host ""
Write-Host "── 6. Cross-field consistency ──────────────────"

$pytestEnabled = [bool](Get-Value $config 'backend.pytest_enabled')
$pytestRoot    = [string](Get-Value $config 'backend.pytest_project_root')
if ($pytestEnabled -and [string]::IsNullOrEmpty($pytestRoot)) {
    Write-FailMsg "backend.pytest_enabled=true but backend.pytest_project_root is empty"
} elseif ($pytestEnabled) {
    Write-PassMsg "backend.pytest_enabled + pytest_project_root consistent"
}

$mutationEnabled = [bool](Get-Value $config 'backend.mutation.enabled')
if ($mutationEnabled -and -not $pytestEnabled) {
    Write-FailMsg "backend.mutation.enabled=true but backend.pytest_enabled=false (mutmut needs pytest)"
}

$pbEnabled = [bool](Get-Value $config 'backend.property_based.enabled')
if ($pbEnabled -and -not $pytestEnabled) {
    Write-FailMsg "backend.property_based.enabled=true but backend.pytest_enabled=false (hypothesis needs pytest)"
}

$publishEnabled = [bool](Get-Value $config 'publish_regression.enabled')
$publishType    = [string](Get-Value $config 'publish_regression.report_pipeline.type')
if ($publishEnabled -and $publishType -eq 's3_cloudfront') {
    foreach ($field in @('s3_bucket', 's3_region', 'cloudfront_distribution_id')) {
        $val = Get-Value $config "publish_regression.report_pipeline.$field"
        if ([string]::IsNullOrEmpty([string]$val)) {
            Write-FailMsg "report_pipeline.type=s3_cloudfront but $field is empty"
        }
    }
}

$speckitEnabled = [bool](Get-Value $config 'speckit.enabled')
$speckitRoot    = [string](Get-Value $config 'speckit.repo_root')
if ($speckitEnabled -and [string]::IsNullOrEmpty($speckitRoot)) {
    Write-FailMsg "speckit.enabled=true but speckit.repo_root is empty"
}

$webEnabled = [bool](Get-Value $config 'platforms.web.enabled')
$webFw      = [string](Get-Value $config 'platforms.web.frameworks.primary')
if ($webEnabled -and [string]::IsNullOrEmpty($webFw)) {
    Write-WarnMsg "platforms.web.enabled=true but frameworks.primary not set (will default to playwright)"
}

# ---- 7. Recommended fields ----
Write-Host ""
Write-Host "── 7. Recommended fields ───────────────────────"
$recommended = @(
    @{ Path = 'jira.reviewer_account_id';    Desc = 'Set for bug-report auto-assignee' }
    @{ Path = 'slack.user_id';                Desc = 'Set to enable DM notifications' }
    @{ Path = 'slack.bug_channel_id';         Desc = 'Set to enable bug channel notifications' }
    @{ Path = 'google.qa_tc_folder_id';       Desc = 'Set to upload TC sheets to shared drive' }
    @{ Path = 'platforms.ios.repo';           Desc = 'Set to enable iOS repo deep code analysis' }
    @{ Path = 'platforms.android.repo';       Desc = 'Set to enable Android repo deep code analysis' }
)
foreach ($rec in $recommended) {
    $val = Get-Value $config $rec.Path
    if ($null -eq $val -or [string]::IsNullOrEmpty([string]$val)) {
        Write-InfoMsg ".$($rec.Path) is empty — $($rec.Desc) (will degrade gracefully)"
    }
}

# ---- Summary ----
Write-Host ""
Write-Host "═══════════════════════════════════════════════"
if ($script:Errors -gt 0) {
    Write-Host "✗ FAILED" -ForegroundColor Red -NoNewline
    Write-Host " — $script:Errors error(s), $script:Warnings warning(s)"
    Write-Host ""
    Write-Host "Fix the errors above and re-run."
    exit 1
} elseif ($script:Warnings -gt 0) {
    Write-Host "✓ PASSED" -ForegroundColor Green -NoNewline
    Write-Host " (with $script:Warnings warning(s))"
    Write-Host ""
    Write-Host "Config is valid. Warnings indicate optional features that will degrade."
    exit 0
} else {
    Write-Host "✓ PASSED" -ForegroundColor Green -NoNewline
    Write-Host " — config is fully valid"
    exit 0
}
