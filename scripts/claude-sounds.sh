#!/usr/bin/env bash
# =============================================================
# claude-sounds: CLI management tool
# Usage: claude-sounds <command> [args]
# =============================================================

set -euo pipefail

INSTALL_DIR="$HOME/.claude/sounds"
CONFIG_FILE="$INSTALL_DIR/config.sh"
HOOKS_DIR="$HOME/.claude/hooks"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

usage() {
  cat << EOF

${BOLD}claude-sounds${NC} — manage audio notifications for Claude Code

${BOLD}USAGE${NC}
  claude-sounds <command> [args]

${BOLD}COMMANDS${NC}
  test                    Play all sounds in sequence
  theme <name>            Switch theme (minimal|forest|zen|retro|cafe|wuxia|cute|anime|space|hacker)
  volume <0.0-1.0>        Adjust playback volume
  snooze <minutes>        Silence notifications for N minutes
  snooze off              Cancel active snooze
  quiet <start> <end>     Set quiet hours (e.g. quiet 22 8)
  quiet off               Disable quiet hours
  doctor                  Diagnose installation issues
  status                  Show current configuration
  uninstall               Remove claude-sounds

${BOLD}EXAMPLES${NC}
  claude-sounds theme zen
  claude-sounds snooze 30
  claude-sounds quiet 22 8
  claude-sounds volume 0.5
  claude-sounds doctor

EOF
}

load_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
  fi
  THEME="${THEME:-minimal}"
  VOLUME="${VOLUME:-0.7}"
}

save_config_value() {
  local key="$1"
  local value="$2"
  if [[ -f "$CONFIG_FILE" ]]; then
    # Replace existing key
    sed -i.bak "s|^${key}=.*|${key}=\"${value}\"|" "$CONFIG_FILE"
  fi
}

cmd_test() {
  local play="$HOOKS_DIR/claude-sounds-play.sh"
  echo -e "\n${BOLD}Playing all sounds...${NC}"
  local events=(start permission done notify write bash subtask error)
  for e in "${events[@]}"; do
    echo -ne "  ${e}..."
    bash "$play" "$e" && sleep 1.3
    echo -e " ${GREEN}✓${NC}"
  done
  echo ""
}

cmd_theme() {
  local theme="${1:-}"
  if [[ -z "$theme" ]]; then
    echo "Available themes: minimal forest zen retro cafe wuxia cute anime space hacker voice voice-cute"
    return
  fi
  case "$theme" in
    minimal|forest|zen|retro|cafe|wuxia|cute|anime|space|hacker|voice|voice-cute) ;;
    *) echo -e "${RED}Unknown theme: $theme${NC}"; exit 1 ;;
  esac

  # Download if not already present
  local theme_dir="$INSTALL_DIR/themes/$theme"
  if [[ "$theme" != "minimal" && ! -d "$theme_dir" ]]; then
    echo -e "${BLUE}Downloading $theme theme...${NC}"
    # Re-use installer download logic
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    bash "$SCRIPT_DIR/install.sh" --theme "$theme" --dry-run 2>/dev/null || true
    # Minimal download fallback
    mkdir -p "$theme_dir"
    echo -e "${YELLOW}  Run install.sh --theme $theme to get full sounds${NC}"
  fi

  save_config_value "THEME" "$theme"
  echo -e "${GREEN}✓ Theme switched to: $theme${NC}"
  echo "  Restart Claude Code to apply."
}

cmd_volume() {
  local vol="${1:-}"
  if [[ -z "$vol" ]]; then echo "Usage: claude-sounds volume <0.0-1.0>"; return; fi
  save_config_value "VOLUME" "$vol"
  echo -e "${GREEN}✓ Volume set to $vol${NC}"
}

cmd_snooze() {
  local arg="${1:-}"
  if [[ "$arg" == "off" ]]; then
    save_config_value "SNOOZE_UNTIL" ""
    echo -e "${GREEN}✓ Snooze cancelled${NC}"
    return
  fi
  if [[ -z "$arg" ]] || ! [[ "$arg" =~ ^[0-9]+$ ]]; then
    echo "Usage: claude-sounds snooze <minutes>  or  claude-sounds snooze off"
    return
  fi
  local until=$(( $(date +%s) + arg * 60 ))
  save_config_value "SNOOZE_UNTIL" "$until"
  local until_human
  until_human=$(date -d "@$until" "+%H:%M" 2>/dev/null || date -r "$until" "+%H:%M" 2>/dev/null || echo "in $arg min")
  echo -e "${GREEN}✓ Snoozed until $until_human${NC}"
}

cmd_quiet() {
  local start="${1:-}"
  local end="${2:-}"
  if [[ "$start" == "off" ]]; then
    save_config_value "QUIET_START" ""
    save_config_value "QUIET_END" ""
    echo -e "${GREEN}✓ Quiet hours disabled${NC}"
    return
  fi
  if [[ -z "$start" || -z "$end" ]]; then
    echo "Usage: claude-sounds quiet <start_hour> <end_hour>  or  claude-sounds quiet off"
    return
  fi
  save_config_value "QUIET_START" "$start"
  save_config_value "QUIET_END" "$end"
  echo -e "${GREEN}✓ Quiet hours: ${start}:00 → ${end}:00${NC}"
}

cmd_status() {
  load_config
  echo ""
  echo -e "${BOLD}claude-sounds status${NC}"
  echo "  Theme:        $THEME"
  echo "  Volume:       $VOLUME"
  echo "  Quiet hours:  ${QUIET_START:-off} → ${QUIET_END:-off}"
  local snooze_until="${SNOOZE_UNTIL:-}"
  if [[ -n "$snooze_until" && "$snooze_until" -gt "$(date +%s)" ]]; then
    local h
    h=$(date -d "@$snooze_until" "+%H:%M" 2>/dev/null || date -r "$snooze_until" "+%H:%M" 2>/dev/null)
    echo "  Snooze:       active until $h"
  else
    echo "  Snooze:       off"
  fi
  echo "  Config:       $CONFIG_FILE"
  echo "  Sounds dir:   $INSTALL_DIR"
  echo ""
}

cmd_doctor() {
  echo ""
  echo -e "${BOLD}🩺 claude-sounds doctor${NC}"
  echo ""

  # Check OS
  local os
  os="$(uname -s)"
  echo -e "  OS: $os"

  # Check audio player
  case "$os" in
    Darwin)
      command -v afplay &>/dev/null \
        && echo -e "  ${GREEN}✓${NC} afplay available" \
        || echo -e "  ${RED}✗${NC} afplay not found"
      ;;
    Linux)
      for p in paplay aplay ffplay; do
        command -v "$p" &>/dev/null \
          && echo -e "  ${GREEN}✓${NC} $p available" && break \
          || true
      done
      ;;
  esac

  # Check hook script
  [[ -x "$HOOKS_DIR/claude-sounds-play.sh" ]] \
    && echo -e "  ${GREEN}✓${NC} play script installed" \
    || echo -e "  ${RED}✗${NC} play script missing — re-run install.sh"

  # Check config
  [[ -f "$CONFIG_FILE" ]] \
    && echo -e "  ${GREEN}✓${NC} config file found" \
    || echo -e "  ${YELLOW}⚠${NC} config file missing (using defaults)"

  # Check settings.json
  local settings="$HOME/.claude/settings.json"
  if [[ -f "$settings" ]]; then
    if grep -q "claude-sounds-play" "$settings" 2>/dev/null; then
      echo -e "  ${GREEN}✓${NC} hooks registered in settings.json"
    else
      echo -e "  ${RED}✗${NC} hooks NOT in settings.json — re-run install.sh"
    fi
  else
    echo -e "  ${RED}✗${NC} settings.json not found"
  fi

  # Check theme sounds
  load_config
  if [[ "$THEME" != "minimal" ]]; then
    local theme_dir="$INSTALL_DIR/themes/$THEME"
    if [[ -d "$theme_dir" && "$(ls -A "$theme_dir" 2>/dev/null)" ]]; then
      local count
      count=$(find "$theme_dir" -type f | wc -l | tr -d ' ')
      echo -e "  ${GREEN}✓${NC} $THEME theme: $count sound files"
    else
      echo -e "  ${YELLOW}⚠${NC} $THEME theme sounds not downloaded — run: claude-sounds theme $THEME"
    fi
  fi

  # Quick audio test
  echo ""
  echo -ne "  Testing audio... "
  bash "$HOOKS_DIR/claude-sounds-play.sh" notify && sleep 1
  echo -e "${GREEN}OK${NC}"
  echo ""
}

cmd_uninstall() {
  echo -ne "Remove claude-sounds? This will delete $INSTALL_DIR and hooks. [y/N] "
  read -r confirm
  if [[ "${confirm:-n}" =~ ^[Yy]$ ]]; then
    rm -rf "$INSTALL_DIR"
    rm -f "$HOOKS_DIR/claude-sounds-play.sh" "$HOOKS_DIR/claude-sounds"
    # Remove hooks from settings.json
    if [[ -f "$HOME/.claude/settings.json" ]] && command -v python3 &>/dev/null; then
      python3 -c "
import json
with open('$HOME/.claude/settings.json') as f: cfg = json.load(f)
cfg.pop('hooks', None)
with open('$HOME/.claude/settings.json', 'w') as f: json.dump(cfg, f, indent=2)
"
    fi
    echo -e "${GREEN}✓ claude-sounds uninstalled${NC}"
  else
    echo "Cancelled."
  fi
}

# ── Dispatch ──────────────────────────────────────────────────
CMD="${1:-help}"
shift || true

case "$CMD" in
  test)       cmd_test ;;
  theme)      cmd_theme "$@" ;;
  volume)     cmd_volume "$@" ;;
  snooze)     cmd_snooze "$@" ;;
  quiet)      cmd_quiet "$@" ;;
  status)     cmd_status ;;
  doctor)     cmd_doctor ;;
  uninstall)  cmd_uninstall ;;
  help|--help|-h) usage ;;
  *) echo -e "${RED}Unknown command: $CMD${NC}"; usage; exit 1 ;;
esac
