#!/usr/bin/env bash
# =============================================================
# claude-sounds: install.sh
# One-command installer for macOS and Linux
#
# Usage:
#   bash install.sh                    # interactive
#   bash install.sh --theme zen        # preset theme
#   bash install.sh --theme minimal --quiet-start 22 --quiet-end 8
#   bash install.sh --dry-run          # preview only
# =============================================================

set -euo pipefail

# ── ANSI colors ───────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

INSTALL_DIR="$HOME/.claude/sounds"
HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS_FILE="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Parse args ────────────────────────────────────────────────
DRY_RUN=false
THEME=""
QUIET_START=""
QUIET_END=""
VOLUME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)        DRY_RUN=true ;;
    --theme)          THEME="$2"; shift ;;
    --quiet-start)    QUIET_START="$2"; shift ;;
    --quiet-end)      QUIET_END="$2"; shift ;;
    --volume)         VOLUME="$2"; shift ;;
    --help|-h)
      echo "Usage: install.sh [options]"
      echo "  --dry-run              Preview changes without applying"
      echo "  --theme <name>         Set theme: minimal|forest|zen|retro|cafe"
      echo "  --quiet-start <hour>   Silence start hour (0-23, e.g. 22)"
      echo "  --quiet-end <hour>     Silence end hour (0-23, e.g. 8)"
      echo "  --volume <0.0-1.0>     Playback volume (default: 0.7)"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

print_header() {
  echo ""
  echo -e "${CYAN}${BOLD}"
  echo "  ╔═══════════════════════════════════════╗"
  echo "  ║   🔔 claude-sounds installer          ║"
  echo "  ║   Natural audio hooks for Claude Code ║"
  echo "  ╚═══════════════════════════════════════╝"
  echo -e "${NC}"
  if $DRY_RUN; then
    echo -e "${YELLOW}  [DRY RUN] No files will be changed${NC}\n"
  fi
}

# ── OS detection ──────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Darwin) OS_NAME="macOS" ;;
  Linux)  OS_NAME="Linux" ;;
  *)      echo -e "${RED}Unsupported OS: $OS${NC}"; exit 1 ;;
esac

check_audio() {
  case "$OS" in
    Darwin)
      if ! command -v afplay &>/dev/null; then
        echo -e "${RED}✗ afplay not found — this is unusual on macOS${NC}"; exit 1
      fi
      echo -e "${GREEN}✓ afplay found${NC}"
      ;;
    Linux)
      if command -v paplay &>/dev/null; then
        echo -e "${GREEN}✓ paplay (PulseAudio) found${NC}"
      elif command -v aplay &>/dev/null; then
        echo -e "${GREEN}✓ aplay (ALSA) found${NC}"
      elif command -v ffplay &>/dev/null; then
        echo -e "${GREEN}✓ ffplay found${NC}"
      else
        echo -e "${YELLOW}⚠ No audio player found. Install pulseaudio-utils:${NC}"
        echo    "  sudo apt install pulseaudio-utils"
      fi
      ;;
  esac
}

select_theme() {
  if [[ -n "$THEME" ]]; then return; fi

  echo -e "\n${BOLD}Choose a sound theme:${NC}"
  echo "  1) minimal  — macOS/Windows system sounds (zero downloads)"
  echo "  2) forest   — 🌲 Birds, wind, rustling leaves"
  echo "  3) zen      — 🎋 Bells, water drops, bamboo"
  echo "  4) retro    — 🕹️  8-bit chiptune alerts"
  echo "  5) cafe     — ☕ Coffee shop ambience"
  echo ""
  read -rp "Enter choice [1-5, default 1]: " choice
  case "${choice:-1}" in
    1) THEME="minimal" ;;
    2) THEME="forest"  ;;
    3) THEME="zen"     ;;
    4) THEME="retro"   ;;
    5) THEME="cafe"    ;;
    *) THEME="minimal" ;;
  esac
}

install_theme() {
  local theme="$1"
  local theme_dir="$INSTALL_DIR/themes/$theme"

  if [[ "$theme" == "minimal" ]]; then
    echo -e "${GREEN}  ✓ minimal theme uses system sounds — nothing to copy${NC}"
    return
  fi

  # Sounds are bundled in the repo under themes/<name>/
  local src_dir="$SCRIPT_DIR/../themes/$theme"
  if [[ -d "$src_dir" ]]; then
    mkdir -p "$theme_dir"
    cp "$src_dir"/*.wav "$theme_dir/" 2>/dev/null || true
    local count
    count=$(find "$theme_dir" -name "*.wav" | wc -l | tr -d ' ')
    echo -e "${GREEN}  ✓ $theme theme installed ($count sounds)${NC}"
  else
    echo -e "${YELLOW}  ⚠ Theme '$theme' not found in repo — falling back to minimal${NC}"
    THEME="minimal"
  fi
}

write_config() {
  local vol="${VOLUME:-0.7}"
  local qs="${QUIET_START:-}"
  local qe="${QUIET_END:-}"

  mkdir -p "$INSTALL_DIR/themes/minimal"

  cat > "$INSTALL_DIR/config.sh" << CONF
# claude-sounds configuration
# Edit this file to customise your audio notifications

THEME="${THEME}"
VOLUME="${vol}"

# Quiet hours — silence during these hours (24h format)
# Example: no sound from 22:00 to 08:00
QUIET_START="${qs}"
QUIET_END="${qe}"

# Snooze — set automatically by: claude-sounds snooze <minutes>
SNOOZE_UNTIL=""
CONF
  echo -e "${GREEN}  ✓ Config written: $INSTALL_DIR/config.sh${NC}"
}

install_scripts() {
  mkdir -p "$HOOKS_DIR"
  cp "$SCRIPT_DIR/play.sh" "$HOOKS_DIR/claude-sounds-play.sh"
  chmod +x "$HOOKS_DIR/claude-sounds-play.sh"
  echo -e "${GREEN}  ✓ Hook script installed: $HOOKS_DIR/claude-sounds-play.sh${NC}"

  # Install the CLI management tool
  cp "$SCRIPT_DIR/claude-sounds.sh" "$HOOKS_DIR/claude-sounds"
  chmod +x "$HOOKS_DIR/claude-sounds"

  # Offer to add to PATH
  local shell_rc=""
  case "${SHELL:-}" in
    */zsh)  shell_rc="$HOME/.zshrc" ;;
    */bash) shell_rc="$HOME/.bashrc" ;;
  esac
  if [[ -n "$shell_rc" ]]; then
    if ! grep -q "claude-sounds" "$shell_rc" 2>/dev/null; then
      echo "" >> "$shell_rc"
      echo "# claude-sounds CLI" >> "$shell_rc"
      echo 'export PATH="$HOME/.claude/hooks:$PATH"' >> "$shell_rc"
      echo -e "${GREEN}  ✓ Added to PATH in $shell_rc${NC}"
    fi
  fi
}

update_settings_json() {
  local play_cmd="$HOME/.claude/hooks/claude-sounds-play.sh"

  local hooks_fragment
  hooks_fragment=$(cat << HOOKS
{
  "SessionStart":       [{"hooks":[{"type":"command","command":"$play_cmd start","async":true}]}],
  "PermissionRequest":  [{"hooks":[{"type":"command","command":"$play_cmd permission","async":true}]}],
  "Stop":               [{"hooks":[{"type":"command","command":"$play_cmd done","async":true}]}],
  "SubagentStop":       [{"hooks":[{"type":"command","command":"$play_cmd subtask","async":true}]}],
  "Notification":       [{"hooks":[{"type":"command","command":"$play_cmd notify","async":true}]}],
  "PostToolUse": [
    {"matcher":"Write|Edit","hooks":[{"type":"command","command":"$play_cmd write","async":true}]},
    {"matcher":"Bash",      "hooks":[{"type":"command","command":"$play_cmd bash","async":true}]}
  ],
  "PostToolUseFailure": [{"hooks":[{"type":"command","command":"$play_cmd error","async":true}]}]
}
HOOKS
  )

  if [[ -f "$SETTINGS_FILE" ]]; then
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}  ✓ Backed up existing settings.json${NC}"
    python3 - << PYEOF
import json, sys
with open('$SETTINGS_FILE') as f:
    cfg = json.load(f)
import json as j2
cfg['hooks'] = j2.loads('''$hooks_fragment''')
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(cfg, f, indent=2)
PYEOF
  else
    echo "{\"hooks\": $hooks_fragment}" | python3 -m json.tool > "$SETTINGS_FILE"
  fi
  echo -e "${GREEN}  ✓ settings.json updated${NC}"
}

test_sounds() {
  echo -e "\n${BOLD}Testing sounds...${NC}"
  local play="$HOOKS_DIR/claude-sounds-play.sh"
  for event in start permission done error; do
    echo -ne "  $event... "
    bash "$play" "$event"
    sleep 1.2
    echo -e "${GREEN}✓${NC}"
  done
}

# ── Main ──────────────────────────────────────────────────────
print_header
echo -e "${BOLD}System:${NC} $OS_NAME"
echo ""

echo -e "${BOLD}Checking audio:${NC}"
check_audio

echo -e "\n${BOLD}Selecting theme:${NC}"
select_theme
echo -e "  Theme: ${CYAN}$THEME${NC}"

if $DRY_RUN; then
  echo ""
  echo -e "${YELLOW}[DRY RUN] Would perform:${NC}"
  echo "  mkdir -p $INSTALL_DIR/themes/$THEME"
  echo "  mkdir -p $HOOKS_DIR"
  echo "  cp play.sh $HOOKS_DIR/claude-sounds-play.sh"
  echo "  write config: $INSTALL_DIR/config.sh  (theme=$THEME, volume=${VOLUME:-0.7})"
  echo "  update: $SETTINGS_FILE"
  [[ "$THEME" != "minimal" ]] && echo "  download: $THEME theme sounds from freesound.org"
  echo ""
  echo -e "${GREEN}Dry run complete. No changes made.${NC}"
  exit 0
fi

echo -e "\n${BOLD}Installing files:${NC}"
install_scripts

echo -e "\n${BOLD}Writing config:${NC}"
write_config

echo -e "\n${BOLD}Installing sounds:${NC}"
install_theme "$THEME"

echo -e "\n${BOLD}Updating Claude Code settings:${NC}"
update_settings_json

test_sounds

echo ""
echo -e "${GREEN}${BOLD}✅ Installation complete!${NC}"
echo ""
echo -e "  ${BOLD}Restart Claude Code${NC} to activate hooks."
echo ""
echo -e "  ${BOLD}Useful commands:${NC}"
echo "    claude-sounds theme zen        # Switch theme"
echo "    claude-sounds snooze 60        # Silence for 60 minutes"
echo "    claude-sounds doctor           # Diagnose issues"
echo "    claude-sounds test             # Play all sounds"
echo "    claude-sounds --help           # Full help"
echo ""
