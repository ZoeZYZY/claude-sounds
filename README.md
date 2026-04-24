# 🔔 claude-sounds

**Natural audio notifications for [Claude Code](https://code.claude.com) hooks.**  
Know when Claude finishes, asks for permission, or hits an error — without watching the terminal.

<p align="center">

```
$ claude-sounds test

  SessionStart      ✓  wuxia/start.wav        🥁  deep gong
  Stop              ✓  wuxia/done.wav          🎵  guqin pluck
  PermissionRequest ✓  wuxia/permission.wav   🔔  alert chirp
  SubagentStop      ✓  wuxia/subtask.wav      🎵  short pluck
  Notification      ✓  wuxia/notify.wav       🔔  small bell
  PostToolUse:Write ✓  wuxia/write.wav        🗡️  sword swish
  PostToolUse:Bash  ✓  wuxia/bash.wav         🥁  drum hit
  PostToolUseError  ✓  wuxia/error.wav        🪨  low gong

  8/8 events OK  •  theme: wuxia  •  volume: 0.6
```

</p>

<p align="center">
  <a href="#quick-start"><strong>Quick Start</strong></a> ·
  <a href="#themes"><strong>Themes</strong></a> ·
  <a href="#events"><strong>Events</strong></a> ·
  <a href="#cli"><strong>CLI</strong></a> ·
  <a href="#windows"><strong>Windows</strong></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Windows%20%7C%20Linux-blue?style=flat-square"/>
  <img src="https://img.shields.io/badge/dependencies-zero-brightgreen?style=flat-square"/>
  <img src="https://img.shields.io/badge/license-MIT-lightgrey?style=flat-square"/>
  <img src="https://img.shields.io/github/stars/ZoeZYZY/claude-sounds?style=flat-square"/>
</p>

---

## Why?

Claude Code is great for long agentic tasks — but you end up glancing at the terminal every 30 seconds to see if it's done.

**claude-sounds** gives you distinct audio cues for 8 different hook events so you know exactly what's happening without looking.

| You hear | Claude is… |
|----------|-----------|
| 🐦 Bird tweet | Done with a task |
| 🐱 Alert call | Asking for permission |
| 🔔 Soft chime | Sending a notification |
| 💧 Water drop | Writing a file |
| 🌊 Stream | Running a bash command |
| 🌲 Morning birds | Starting a new session |
| 🎋 Small bell | Subagent finished |
| 🪨 Low gong | Something went wrong |

---

## Quick Start

### macOS / Linux

```bash
git clone https://github.com/ZoeZYZY/claude-sounds.git
cd claude-sounds
bash scripts/install.sh
```

The installer will ask you to:
1. Pick a theme
2. Choose which events trigger sounds (multi-select, all enabled by default)

**Restart Claude Code** and you'll hear sounds on every selected hook event.

Want zero downloads (system sounds only)?

```bash
bash scripts/install.sh --theme minimal
```

### Windows

```powershell
git clone https://github.com/ZoeZYZY/claude-sounds.git
cd claude-sounds
.\scripts\Install-ClaudeSounds.ps1
```

### One-liner (macOS/Linux, minimal theme)

```bash
curl -sL https://raw.githubusercontent.com/ZoeZYZY/claude-sounds/main/scripts/install.sh | bash -s -- --theme minimal
```

---

## Themes

Switch themes anytime with `claude-sounds theme <name>`.

| Theme | Description | Size |
|-------|-------------|------|
| `minimal` | macOS / Windows system sounds | 0 KB — zero files |
| `forest` 🌲 | Bird chirps, wind, nature tones | ~60 KB bundled |
| `zen` 🎋 | Singing bowls, water drops, bells | ~60 KB bundled |
| `retro` 🕹️ | 8-bit chiptune alerts | ~30 KB bundled |
| `cafe` ☕ | Warm muted tones, coffee-shop feel | ~60 KB bundled |
| `wuxia` 🗡️ | Deep gong, plucked strings, sword swish | ~80 KB bundled |
| `cute` 🌸 | Bubble pops, sparkles, cartoon boing | ~40 KB bundled |
| `anime` ✨ | Power-up sweeps, magic chimes, whoosh | ~50 KB bundled |
| `space` 🚀 | Cosmic drone, NASA-style comms beeps, thruster | ~60 KB bundled |
| `hacker` 💻 | Boot sequence, keyclick, access granted/denied | ~30 KB bundled |
| `voice` 💋 | Sultry English voice lines (macOS) | generated locally |
| `voice-cute` 🎀 | Chipper English voice lines (macOS) | generated locally |

All synthesized themes are **bundled in the repo** — no downloads needed. Voice themes are generated locally using your macOS built-in TTS.

**Voice themes (macOS only):**
```bash
bash scripts/generate_voice_theme.sh           # sexy / Samantha voice
bash scripts/generate_voice_theme.sh --cute    # cute / high-pitched voice
```

**Custom sounds:** drop any `.mp3` / `.wav` file into `~/.claude/sounds/themes/my-theme/` and run `claude-sounds theme my-theme`.

---

## Events

All 8 hook events are covered:

| Event | Trigger | Sound name |
|-------|---------|-----------|
| `SessionStart` | New Claude Code session opens | `start` |
| `PermissionRequest` | Claude asks to run a tool | `permission` |
| `Stop` | Main task / response complete | `done` |
| `SubagentStop` | Sub-task complete | `subtask` |
| `Notification` | System notification | `notify` |
| `PostToolUse: Write\|Edit` | File written or edited | `write` |
| `PostToolUse: Bash` | Shell command executed | `bash` |
| `PostToolUseFailure` | Tool call failed | `error` |

---

## CLI

After install, the `claude-sounds` command is available:

```bash
# Test all sounds
claude-sounds test

# Switch theme
claude-sounds theme zen

# Choose which events trigger sounds (interactive toggle)
claude-sounds events

# Enable / disable specific events
claude-sounds events off write bash      # no sound when writing files or running commands
claude-sounds events on  write bash      # re-enable them

# Adjust volume (0.0 – 1.0)
claude-sounds volume 0.5

# Silence for 30 minutes (e.g. during a meeting)
claude-sounds snooze 30
claude-sounds snooze off

# Set quiet hours — no sound from 22:00 to 08:00
claude-sounds quiet 22 8
claude-sounds quiet off

# Check installation health
claude-sounds doctor

# Show current config
claude-sounds status

# Uninstall
claude-sounds uninstall
```

---

## Configuration

Settings live in `~/.claude/sounds/config.sh` (macOS/Linux) or `~/.claude/sounds/config.ps1` (Windows):

```bash
THEME="zen"          # Active theme
VOLUME="0.6"         # 0.0 – 1.0
QUIET_START="22"     # Silence from 22:00...
QUIET_END="8"        # ...until 08:00
SNOOZE_UNTIL=""      # Set by 'claude-sounds snooze'
```

---

## How It Works

```
Claude Code event fires
       │
       ▼
~/.claude/settings.json hook entry
       │
       ▼
~/.claude/hooks/claude-sounds-play.sh <event>
       │
       ├─ Load ~/.claude/sounds/config.sh
       ├─ Check snooze / quiet hours
       ├─ Look up ~/.claude/sounds/themes/<theme>/<event>.mp3
       │
       ├─ Found → afplay / paplay / PowerShell
       └─ Not found → OS system sound fallback
```

All hooks use `async: true` — sounds play in the background and never block Claude.

---

## Windows

Windows support uses PowerShell's built-in `System.Media.SoundPlayer` (WAV) and Windows Media Player COM (MP3). No external tools required.

Run PowerShell as a normal user (no admin needed):

```powershell
.\scripts\Install-ClaudeSounds.ps1 -Theme zen
```

If you see an execution policy error:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

---

## Troubleshooting

```bash
claude-sounds doctor
```

This checks:
- Audio player availability
- Hook script installation
- settings.json registration
- Theme sound files
- Live audio test

Common issues:

| Problem | Fix |
|---------|-----|
| No sound on macOS | Run `claude-sounds doctor` — checks afplay |
| No sound on Linux | Install: `sudo apt install pulseaudio-utils` |
| Hooks not firing | Restart Claude Code after install |
| Wrong volume | `claude-sounds volume 0.8` |
| Want silence now | `claude-sounds snooze 60` |

---

## Adding Custom Sounds

1. Create a folder: `mkdir -p ~/.claude/sounds/themes/mytheme`
2. Add `.mp3` or `.wav` files named after events:
   ```
   ~/.claude/sounds/themes/mytheme/
   ├── start.mp3
   ├── done.mp3
   ├── permission.mp3
   ├── notify.mp3
   ├── write.mp3
   ├── bash.mp3
   ├── subtask.mp3
   └── error.mp3
   ```
3. Switch: `claude-sounds theme mytheme`

Any missing events fall back to the `minimal` system sounds.

---

## Contributing

PRs welcome, especially for:
- New themes with CC0-licensed sounds
- Better Windows audio support  
- Linux distro-specific fixes

See [CONTRIBUTING.md](docs/CONTRIBUTING.md).

---

## License

MIT — see [LICENSE](LICENSE).

Sound files are CC0 from [freesound.org](https://freesound.org).  
See [themes/MANIFEST.sh](themes/MANIFEST.sh) for individual credits.

---

<p align="center">
  Made for the Claude Code community · <a href="https://code.claude.com">code.claude.com</a>
</p>
