# QA Claude Skill — Uninstaller (PowerShell / Windows native)
# Equivalent of uninstall.sh
#
# Usage:
#   .\uninstall.ps1

#Requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ScriptDir       = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsSrc       = Join-Path $ScriptDir 'skills'
$ClaudeSkillsDir = if ($env:CLAUDE_SKILLS_DIR) { $env:CLAUDE_SKILLS_DIR } else { Join-Path $env:USERPROFILE '.claude\skills' }

function Write-Info { param([string]$Msg) Write-Host "[INFO] " -ForegroundColor Blue   -NoNewline; Write-Host $Msg }
function Write-Ok   { param([string]$Msg) Write-Host "[OK  ] " -ForegroundColor Green  -NoNewline; Write-Host $Msg }
function Write-Warn { param([string]$Msg) Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline; Write-Host $Msg }
function Write-Err  { param([string]$Msg) Write-Host "[ERR ] " -ForegroundColor Red    -NoNewline; Write-Host $Msg }

# ---- List skills shipped with this repo ----
$Skills = Get-ChildItem -Path $SkillsSrc -Directory | Select-Object -ExpandProperty Name

Write-Info "Will remove from $ClaudeSkillsDir: $($Skills -join ', ')"
$ans = Read-Host "Continue? [y/N]"
if ($ans -notmatch '^[Yy]') {
    Write-Warn "Aborted"
    exit 0
}

# ---- Remove ----
$Removed = 0
foreach ($s in $Skills) {
    $target = Join-Path $ClaudeSkillsDir $s
    if (Test-Path $target) {
        Remove-Item -Recurse -Force $target
        $Removed++
        Write-Ok "Removed $s"
    }
}

# ---- Offer restore from latest backup ----
$ClaudeRoot = Join-Path $env:USERPROFILE '.claude'
$LatestBackup = Get-ChildItem -Path $ClaudeRoot -Directory -Filter 'skills.backup-*' -ErrorAction SilentlyContinue |
                Sort-Object Name -Descending | Select-Object -First 1

if ($LatestBackup) {
    Write-Host ""
    Write-Info "Latest backup found: $($LatestBackup.FullName)"
    $ans = Read-Host "Restore skills from this backup? [y/N]"
    if ($ans -match '^[Yy]') {
        foreach ($s in $Skills) {
            $src = Join-Path $LatestBackup.FullName $s
            if (Test-Path $src) {
                Copy-Item -Recurse $src (Join-Path $ClaudeSkillsDir $s)
                Write-Ok "Restored $s"
            }
        }
    }
}

Write-Ok "Done. Removed $Removed skills."
