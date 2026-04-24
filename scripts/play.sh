#!/usr/bin/env bash
# =============================================================
# claude-sounds: play.sh
# Cross-platform sound player for Claude Code hooks
# Usage: play.sh <event>
# Events: permission | done | notify | write | bash | start | subtask | error
# =============================================================

set -euo pipefail

SOUNDS_DIR="${CLAUDE_SOUNDS_DIR:-$HOME/.claude/sounds}"
CONFIG_FILE="$HOME/.claude/sounds/config.sh"
EVENT="${1:-notify}"

# ── Load user config (theme, volume, snooze) ──────────────────
THEME="minimal"
VOLUME="0.7"
SNOOZE_UNTIL=""

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

# ── Events filter ────────────────────────────────────────────
EVENTS_ENABLED="${EVENTS_ENABLED:-start done permission subtask notify write bash error}"
if ! echo " $EVENTS_ENABLED " | grep -q " $EVENT "; then
  exit 0
fi

# ── Snooze check ──────────────────────────────────────────────
if [[ -n "$SNOOZE_UNTIL" ]]; then
  now=$(date +%s)
  if [[ "$now" -lt "$SNOOZE_UNTIL" ]]; then
    exit 0
  else
    # Snooze expired — clear it
    sed -i.bak 's/^SNOOZE_UNTIL=.*/SNOOZE_UNTIL=""/' "$CONFIG_FILE" 2>/dev/null || true
  fi
fi

# ── Quiet hours check ─────────────────────────────────────────
QUIET_START="${QUIET_START:-}"
QUIET_END="${QUIET_END:-}"
if [[ -n "$QUIET_START" && -n "$QUIET_END" ]]; then
  current_hour=$(date +%H)
  if [[ "$current_hour" -ge "$QUIET_START" && "$current_hour" -lt "$QUIET_END" ]]; then
    exit 0
  fi
fi

# ── Event → filename map ──────────────────────────────────────
case "$EVENT" in
  permission) FILE="permission" ;;
  done)       FILE="done"       ;;
  notify)     FILE="notify"     ;;
  write)      FILE="write"      ;;
  bash)       FILE="bash"       ;;
  start)      FILE="start"      ;;
  subtask)    FILE="subtask"    ;;
  error)      FILE="error"      ;;
  *)          FILE="notify"     ;;
esac

THEME_DIR="$SOUNDS_DIR/themes/$THEME"

# ── Platform detection ────────────────────────────────────────
OS="$(uname -s 2>/dev/null || echo "unknown")"

play_file() {
  local f="$1"
  case "$OS" in
    Darwin)
      afplay "$f" --volume "$VOLUME" &
      ;;
    Linux)
      if command -v paplay &>/dev/null; then
        paplay "$f" &
      elif command -v aplay &>/dev/null; then
        aplay -q "$f" &
      elif command -v ffplay &>/dev/null; then
        ffplay -nodisp -autoexit -loglevel quiet "$f" &
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      # Windows via Git Bash — delegate to PowerShell player
      powershell.exe -NonInteractive -NoProfile -Command \
        "(New-Object Media.SoundPlayer '$f').PlaySync()" &
      ;;
  esac
}

play_system_fallback() {
  case "$OS" in
    Darwin)
      local sound
      case "$EVENT" in
        permission) sound="Sosumi"   ;;
        done)       sound="Glass"    ;;
        notify)     sound="Tink"     ;;
        write)      sound="Pop"      ;;
        bash)       sound="Purr"     ;;
        start)      sound="Ping"     ;;
        subtask)    sound="Funk"     ;;
        error)      sound="Basso"    ;;
        *)          sound="Tink"     ;;
      esac
      afplay "/System/Library/Sounds/${sound}.aiff" --volume "$VOLUME" &
      ;;
    Linux)
      # Try freedesktop bell
      pactl play-sample bell 2>/dev/null & true
      ;;
    MINGW*|MSYS*|CYGWIN*)
      powershell.exe -NonInteractive -NoProfile -Command \
        "[System.Media.SystemSounds]::Beep.Play()" &
      ;;
  esac
}

# ── Find and play ─────────────────────────────────────────────
# Priority: theme mp3 > theme wav > theme aiff > system fallback
for ext in mp3 wav aiff ogg; do
  candidate="$THEME_DIR/${FILE}.${ext}"
  if [[ -f "$candidate" ]]; then
    play_file "$candidate"
    exit 0
  fi
done

# No theme file found — use system fallback
play_system_fallback
exit 0
