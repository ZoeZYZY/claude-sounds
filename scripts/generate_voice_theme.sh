#!/usr/bin/env bash
# generate_voice_theme.sh
# Generates the 'voice' theme using macOS built-in text-to-speech.
# Requires: macOS with 'say' command (no extra installs needed).
#
# Usage:
#   bash scripts/generate_voice_theme.sh            # default: sexy (Samantha)
#   bash scripts/generate_voice_theme.sh --cute     # cute high-pitched voice

set -euo pipefail

THEMES_DIR="$(cd "$(dirname "$0")/../themes" && pwd)"

if ! command -v say &>/dev/null; then
  echo "❌  'say' command not found. This script requires macOS."
  echo "    On Linux, install espeak: sudo apt install espeak"
  echo "    Then adapt this script to use: espeak -w <file> '<text>'"
  exit 1
fi

# ── Select voice style ──────────────────────────────────────────────────────

STYLE="voice"
SAY_VOICE="Samantha"
SAY_RATE=155

if [[ "${1:-}" == "--cute" ]]; then
  STYLE="voice-cute"
  SAY_VOICE="Kathy"
  SAY_RATE=200
fi

OUT_DIR="$THEMES_DIR/$STYLE"
mkdir -p "$OUT_DIR"

echo "Generating '$STYLE' theme with voice: $SAY_VOICE (rate: $SAY_RATE)..."

# ── Helper ──────────────────────────────────────────────────────────────────

say_to_wav() {
  local text="$1"
  local file="$2"
  local tmp="${file%.wav}.aiff"
  say -v "$SAY_VOICE" -r "$SAY_RATE" -o "$tmp" "$text"
  # Convert AIFF → WAV using afconvert (built-in on macOS)
  afconvert -f WAVE -d LEI16 "$tmp" "$file"
  rm -f "$tmp"
}

# ── Voice lines ─────────────────────────────────────────────────────────────

if [[ "$STYLE" == "voice" ]]; then
  say_to_wav "Let's begin, darling."              "$OUT_DIR/start.wav"
  say_to_wav "All done."                          "$OUT_DIR/done.wav"
  say_to_wav "May I?"                             "$OUT_DIR/permission.wav"
  say_to_wav "Hey, heads up."                     "$OUT_DIR/notify.wav"
  say_to_wav "Writing that for you."              "$OUT_DIR/write.wav"
  say_to_wav "On it."                             "$OUT_DIR/bash.wav"
  say_to_wav "Finished."                          "$OUT_DIR/subtask.wav"
  say_to_wav "Oops. Something went wrong."        "$OUT_DIR/error.wav"
else
  say_to_wav "Yay, let's go!"                     "$OUT_DIR/start.wav"
  say_to_wav "Done done done!"                    "$OUT_DIR/done.wav"
  say_to_wav "Um, can I?"                         "$OUT_DIR/permission.wav"
  say_to_wav "Hey hey!"                           "$OUT_DIR/notify.wav"
  say_to_wav "Writing!"                           "$OUT_DIR/write.wav"
  say_to_wav "Okay!"                              "$OUT_DIR/bash.wav"
  say_to_wav "Ta-da!"                             "$OUT_DIR/subtask.wav"
  say_to_wav "Uh oh..."                           "$OUT_DIR/error.wav"
fi

echo "✓ $STYLE theme generated in $OUT_DIR"
echo ""
echo "To activate:  claude-sounds theme $STYLE"
