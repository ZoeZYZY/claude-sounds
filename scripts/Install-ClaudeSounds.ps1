# =============================================================
# claude-sounds: Install-ClaudeSounds.ps1
# One-command installer for Windows
#
# Usage:
#   .\Install-ClaudeSounds.ps1
#   .\Install-ClaudeSounds.ps1 -Theme zen
#   .\Install-ClaudeSounds.ps1 -Theme minimal -DryRun
#   .\Install-ClaudeSounds.ps1 -QuietStart 22 -QuietEnd 8
# =============================================================

param(
    [ValidateSet("minimal","forest","zen","retro","cafe")]
    [string]$Theme = "",
    [float]$Volume = 0.7,
    [int]$QuietStart = -1,
    [int]$QuietEnd = -1,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$InstallDir  = "$env:USERPROFILE\.claude\sounds"
$HooksDir    = "$env:USERPROFILE\.claude\hooks"
$SettingsFile = "$env:USERPROFILE\.claude\settings.json"
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Header {
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║   🔔 claude-sounds installer          ║" -ForegroundColor Cyan
    Write-Host "  ║   Natural audio hooks for Claude Code ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    if ($DryRun) {
        Write-Host "  [DRY RUN] No files will be changed" -ForegroundColor Yellow
        Write-Host ""
    }
}

function Select-Theme {
    if ($Theme -ne "") { return $Theme }
    Write-Host "Choose a sound theme:" -ForegroundColor White
    Write-Host "  1) minimal  - Windows system sounds (zero downloads)"
    Write-Host "  2) forest   - Birds, wind, rustling leaves"
    Write-Host "  3) zen      - Bells, water drops, bamboo"
    Write-Host "  4) retro    - 8-bit chiptune alerts"
    Write-Host "  5) cafe     - Coffee shop ambience"
    Write-Host ""
    $choice = Read-Host "Enter choice [1-5, default 1]"
    switch ($choice) {
        "2" { return "forest" }
        "3" { return "zen"    }
        "4" { return "retro"  }
        "5" { return "cafe"   }
        default { return "minimal" }
    }
}

function Install-Scripts {
    New-Item -ItemType Directory -Force -Path $HooksDir | Out-Null
    Copy-Item "$ScriptDir\play.ps1" "$HooksDir\claude-sounds-play.ps1" -Force
    Copy-Item "$ScriptDir\Manage-ClaudeSounds.ps1" "$HooksDir\claude-sounds.ps1" -Force
    Write-Host "  OK Hook scripts installed" -ForegroundColor Green
}

function Write-Config {
    param([string]$SelectedTheme)
    New-Item -ItemType Directory -Force -Path "$InstallDir\themes\minimal" | Out-Null
    $qs = if ($QuietStart -ge 0) { $QuietStart } else { "" }
    $qe = if ($QuietEnd -ge 0) { $QuietEnd } else { "" }
    @"
# claude-sounds configuration (PowerShell)
`$Theme = "$SelectedTheme"
`$Volume = $Volume
`$QuietStart = $qs
`$QuietEnd = $qe
`$SnoozeUntil = 0
"@ | Set-Content "$InstallDir\config.ps1"
    Write-Host "  OK Config written" -ForegroundColor Green
}

function Download-Theme {
    param([string]$SelectedTheme)
    if ($SelectedTheme -eq "minimal") {
        Write-Host "  OK minimal theme uses system sounds - no download needed" -ForegroundColor Green
        return
    }
    $themeDir = "$InstallDir\themes\$SelectedTheme"
    New-Item -ItemType Directory -Force -Path $themeDir | Out-Null

    # Same CC0 URLs as the bash installer
    $urls = @{
        forest = @{
            start      = "https://cdn.freesound.org/previews/416/416529_4284968-lq.mp3"
            done       = "https://cdn.freesound.org/previews/220/220786_4100290-lq.mp3"
            permission = "https://cdn.freesound.org/previews/244/244981_4284968-lq.mp3"
            notify     = "https://cdn.freesound.org/previews/514/514444_6830699-lq.mp3"
            write      = "https://cdn.freesound.org/previews/235/235911_3336598-lq.mp3"
            bash       = "https://cdn.freesound.org/previews/264/264762_3986423-lq.mp3"
            subtask    = "https://cdn.freesound.org/previews/376/376804_6891950-lq.mp3"
            error      = "https://cdn.freesound.org/previews/339/339822_5121236-lq.mp3"
        }
        zen = @{
            start      = "https://cdn.freesound.org/previews/411/411090_5121236-lq.mp3"
            done       = "https://cdn.freesound.org/previews/411/411089_5121236-lq.mp3"
            permission = "https://cdn.freesound.org/previews/411/411088_5121236-lq.mp3"
            notify     = "https://cdn.freesound.org/previews/411/411087_5121236-lq.mp3"
            write      = "https://cdn.freesound.org/previews/235/235911_3336598-lq.mp3"
            bash       = "https://cdn.freesound.org/previews/264/264762_3986423-lq.mp3"
            subtask    = "https://cdn.freesound.org/previews/411/411086_5121236-lq.mp3"
            error      = "https://cdn.freesound.org/previews/339/339822_5121236-lq.mp3"
        }
    }

    $themeUrls = $urls[$SelectedTheme]
    if ($null -eq $themeUrls) {
        Write-Host "  Theme URLs not yet defined, using minimal fallback" -ForegroundColor Yellow
        return
    }

    $ok = 0
    foreach ($event in $themeUrls.Keys) {
        $url  = $themeUrls[$event]
        $dest = "$themeDir\$event.mp3"
        try {
            Invoke-WebRequest -Uri $url -OutFile $dest -TimeoutSec 15 -ErrorAction Stop
            Write-Host "  OK $event" -ForegroundColor Green
            $ok++
        } catch {
            Write-Host "  SKIP $event (network unavailable)" -ForegroundColor Yellow
        }
    }
    Write-Host "  Downloaded $ok/$($themeUrls.Count) sounds"
}

function Update-SettingsJson {
    param([string]$SelectedTheme)
    $playCmd = "$HooksDir\claude-sounds-play.ps1"
    $psPlay  = "powershell -NonInteractive -NoProfile -File `"$playCmd`""

    $hooks = [ordered]@{
        SessionStart      = @(@{hooks = @(@{type="command"; command="$psPlay -Event start";      async=$true})})
        PermissionRequest = @(@{hooks = @(@{type="command"; command="$psPlay -Event permission"; async=$true})})
        Stop              = @(@{hooks = @(@{type="command"; command="$psPlay -Event done";        async=$true})})
        SubagentStop      = @(@{hooks = @(@{type="command"; command="$psPlay -Event subtask";    async=$true})})
        Notification      = @(@{hooks = @(@{type="command"; command="$psPlay -Event notify";     async=$true})})
        PostToolUse       = @(
            @{matcher="Write|Edit"; hooks=@(@{type="command"; command="$psPlay -Event write"; async=$true})}
            @{matcher="Bash";       hooks=@(@{type="command"; command="$psPlay -Event bash";  async=$true})}
        )
        PostToolUseFailure = @(@{hooks = @(@{type="command"; command="$psPlay -Event error";     async=$true})})
    }

    if (Test-Path $SettingsFile) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        Copy-Item $SettingsFile "$SettingsFile.bak.$timestamp"
        $cfg = Get-Content $SettingsFile -Raw | ConvertFrom-Json
        Write-Host "  OK Backed up existing settings.json" -ForegroundColor Green
    } else {
        $cfg = [PSCustomObject]@{}
    }

    $cfg | Add-Member -Force -NotePropertyName "hooks" -NotePropertyValue $hooks
    $cfg | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile -Encoding UTF8
    Write-Host "  OK settings.json updated" -ForegroundColor Green
}

function Test-Sounds {
    Write-Host "`nTesting sounds..." -ForegroundColor White
    $playScript = "$HooksDir\claude-sounds-play.ps1"
    foreach ($event in @("start","permission","done","error")) {
        Write-Host -NoNewline "  ${event}... "
        & powershell -NonInteractive -NoProfile -File $playScript -Event $event
        Start-Sleep -Milliseconds 1200
        Write-Host "OK" -ForegroundColor Green
    }
}

# ── Main ──────────────────────────────────────────────────────
Write-Header
Write-Host "System: Windows" -ForegroundColor White
Write-Host ""

$selectedTheme = Select-Theme
Write-Host "  Theme: $selectedTheme" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY RUN] Would perform:" -ForegroundColor Yellow
    Write-Host "  New-Item $InstallDir\themes\$selectedTheme"
    Write-Host "  Copy play.ps1 -> $HooksDir\claude-sounds-play.ps1"
    Write-Host "  Write config:  $InstallDir\config.ps1"
    Write-Host "  Update:        $SettingsFile"
    if ($selectedTheme -ne "minimal") {
        Write-Host "  Download:      $selectedTheme theme sounds"
    }
    Write-Host ""
    Write-Host "Dry run complete. No changes made." -ForegroundColor Green
    exit 0
}

Write-Host "`nInstalling scripts:" -ForegroundColor White
Install-Scripts

Write-Host "`nWriting config:" -ForegroundColor White
Write-Config -SelectedTheme $selectedTheme

Write-Host "`nDownloading sounds:" -ForegroundColor White
Download-Theme -SelectedTheme $selectedTheme

Write-Host "`nUpdating Claude Code settings:" -ForegroundColor White
Update-SettingsJson -SelectedTheme $selectedTheme

Test-Sounds

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Restart Claude Code to activate hooks."
Write-Host ""
Write-Host "  Useful commands:"
Write-Host "    claude-sounds theme zen        # Switch theme"
Write-Host "    claude-sounds snooze 60        # Silence for 60 minutes"
Write-Host "    claude-sounds doctor           # Diagnose issues"
Write-Host "    claude-sounds test             # Play all sounds"
Write-Host ""
