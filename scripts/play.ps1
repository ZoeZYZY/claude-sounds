# =============================================================
# claude-sounds: play.ps1
# Windows-native sound player for Claude Code hooks
# Usage: play.ps1 -Event <event>
# =============================================================
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("permission","done","notify","write","bash","start","subtask","error")]
    [string]$Event = "notify"
)

$SoundsDir = if ($env:CLAUDE_SOUNDS_DIR) { $env:CLAUDE_SOUNDS_DIR } else { "$env:USERPROFILE\.claude\sounds" }
$ConfigFile = "$SoundsDir\config.ps1"

# ── Load config ───────────────────────────────────────────────
$Theme = "minimal"
$Volume = 0.7
$SnoozeUntil = 0
$QuietStart = $null
$QuietEnd = $null

if (Test-Path $ConfigFile) {
    . $ConfigFile
}

# ── Snooze check ──────────────────────────────────────────────
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
if ($SnoozeUntil -gt 0 -and $now -lt $SnoozeUntil) {
    exit 0
}

# ── Quiet hours ───────────────────────────────────────────────
if ($null -ne $QuietStart -and $null -ne $QuietEnd) {
    $hour = (Get-Date).Hour
    if ($hour -ge $QuietStart -and $hour -lt $QuietEnd) {
        exit 0
    }
}

# ── Event → filename ──────────────────────────────────────────
$FileMap = @{
    "permission" = "permission"
    "done"       = "done"
    "notify"     = "notify"
    "write"      = "write"
    "bash"       = "bash"
    "start"      = "start"
    "subtask"    = "subtask"
    "error"      = "error"
}
$FileName = $FileMap[$Event]
$ThemeDir = "$SoundsDir\themes\$Theme"

# ── System sound fallback map ─────────────────────────────────
Add-Type -AssemblyName System.Windows.Forms 2>$null
$SystemMap = @{
    "permission" = [System.Media.SystemSounds]::Exclamation
    "done"       = [System.Media.SystemSounds]::Asterisk
    "notify"     = [System.Media.SystemSounds]::Beep
    "write"      = [System.Media.SystemSounds]::Beep
    "bash"       = [System.Media.SystemSounds]::Beep
    "start"      = [System.Media.SystemSounds]::Asterisk
    "subtask"    = [System.Media.SystemSounds]::Asterisk
    "error"      = [System.Media.SystemSounds]::Hand
}

# ── Find and play ─────────────────────────────────────────────
$Extensions = @("mp3", "wav", "ogg")
$Played = $false

foreach ($ext in $Extensions) {
    $candidate = "$ThemeDir\$FileName.$ext"
    if (Test-Path $candidate) {
        try {
            if ($ext -eq "wav") {
                $player = New-Object System.Media.SoundPlayer $candidate
                $player.Play()
            } else {
                # mp3/ogg — use Windows Media Player COM
                $wmp = New-Object -ComObject WMPlayer.OCX
                $wmp.settings.volume = [int]($Volume * 100)
                $wmp.URL = $candidate
                $wmp.controls.play()
                Start-Sleep -Milliseconds 100
                while ($wmp.playState -eq 3) { Start-Sleep -Milliseconds 50 }
                [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wmp) | Out-Null
            }
            $Played = $true
            break
        } catch {
            # Try next extension
        }
    }
}

if (-not $Played) {
    # System sound fallback
    $SystemMap[$Event].Play()
}
