#!/usr/bin/env bash
set -euo pipefail

dotfiles_dir="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

install_systemd_timer() {
  local unit_dir="$HOME/.config/systemd/user"
  local unit

  if ! command -v systemctl >/dev/null 2>&1; then
    echo "Skipping dotfiles auto-update: systemctl is not available." >&2
    return
  fi

  mkdir -p "$unit_dir"
  for unit in dotfiles-update.service dotfiles-update.timer; do
    ln -sfnv "$dotfiles_dir/autoupdate/$unit" "$unit_dir/$unit"
  done

  systemctl --user daemon-reload
  systemctl --user enable --now dotfiles-update.timer
}

install_launchd_agent() {
  local label="com.user.dotfiles-update"
  local domain
  local plist="$HOME/Library/LaunchAgents/$label.plist"
  local rendered
  local stamp="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-update/last-success"

  domain="gui/$(id -u)"
  rendered="$(sed -e "s|@DOTFILES@|$dotfiles_dir|g" -e "s|@HOME@|$HOME|g" \
    "$dotfiles_dir/autoupdate/$label.plist")"

  # This install counts as today's update, so loading the agent does not
  # immediately run it again.
  if [[ ! -f "$stamp" ]]; then
    mkdir -p "$(dirname "$stamp")"
    date +%s >"$stamp"
  fi

  if [[ -f "$plist" && "$(cat "$plist")" == "$rendered" ]] &&
    launchctl print "$domain/$label" >/dev/null 2>&1; then
    return
  fi

  mkdir -p "$(dirname "$plist")"
  printf '%s\n' "$rendered" >"$plist"

  # Reloading from inside the agent would kill this run.
  if [[ "${DOTFILES_AUTOUPDATE:-}" == 1 ]]; then
    echo "Updated $plist; launchd loads it at next login."
    return
  fi

  launchctl bootout "$domain/$label" 2>/dev/null || true
  launchctl bootstrap "$domain" "$plist"
  echo "Loaded LaunchAgent $label"
}

case "$(uname)" in
  Linux) install_systemd_timer ;;
  Darwin) install_launchd_agent ;;
esac
