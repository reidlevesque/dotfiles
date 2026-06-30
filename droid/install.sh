#!/usr/bin/env bash
set -euo pipefail

installer_url="https://app.factory.ai/cli"
droid_bin="$HOME/.local/bin/droid"
droid_shell="/bin/zsh"
dotfiles_dir="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
droid_systemd_host="devvm-rlevesque"
droid_service_name="droid-daemon.service"
droid_service_src="$dotfiles_dir/droid/$droid_service_name"
droid_service_dir="$HOME/.config/systemd/user"
droid_service_dst="$droid_service_dir/$droid_service_name"
current_host="$(hostname -s)"
manage_systemd_service=false
systemd_service_restart_required=false

run_installer() {
  local installer_script="${1:-}"
  local expected_version="${2:-}"
  local new_version

  if [[ -n "$installer_script" ]]; then
    printf '%s\n' "$installer_script" | sh
  else
    curl -fsSL "$installer_url" | sh
  fi

  if [[ ! -x "$droid_bin" ]]; then
    echo "Cannot install Droid: $droid_bin was not created." >&2
    return 1
  fi

  new_version="$(installed_version || true)"
  if [[ -z "$new_version" ]]; then
    echo "Cannot determine the installed Droid version." >&2
    return 1
  fi

  if [[ -n "$expected_version" && "$new_version" != "$expected_version" ]]; then
    echo "Droid update did not install the expected version: wanted $expected_version, found $new_version." >&2
    return 1
  fi

  echo "Droid installed: $new_version"
}

installed_version() {
  "$droid_bin" --version 2>/dev/null | tr -d '[:space:]'
}

installer_version() {
  awk -F '"' '/^VER="/ { print $2; exit }'
}

get_droid_pids() {
  local pids
  local status

  if ! command -v pgrep >/dev/null 2>&1; then
    return 2
  fi

  if pids="$(pgrep -u "$(id -u)" -x droid)"; then
    printf '%s\n' "$pids"
    return 0
  else
    status=$?
  fi

  if [[ "$status" -eq 1 ]]; then
    return 1
  fi

  return 2
}

managed_service_is_stopped() {
  local active_state
  local sub_state

  if [[ "$manage_systemd_service" != true ]]; then
    return 0
  fi

  active_state="$(systemctl --user show "$droid_service_name" --property=ActiveState --value)"
  sub_state="$(systemctl --user show "$droid_service_name" --property=SubState --value)"
  [[ "$active_state" == inactive && "$sub_state" == dead ]]
}

prepare_systemd_service() {
  local command_line
  local desired_path
  local installed_target=""
  local main_pid
  local working_directory

  if [[ "$(uname)" != "Linux" ]]; then
    return
  fi

  if [[ "$current_host" != "$droid_systemd_host" ]]; then
    echo "Skipping Droid systemd service: this host is $current_host, expected $droid_systemd_host."
    return
  fi

  if ! command -v systemctl >/dev/null 2>&1; then
    echo "Skipping Droid systemd service: systemctl is not available." >&2
    return
  fi

  if [[ ! -x "$droid_shell" ]]; then
    echo "Cannot configure Droid systemd service: $droid_shell is not executable." >&2
    return 1
  fi

  mkdir -p "$droid_service_dir"
  if [[ -L "$droid_service_dst" ]]; then
    installed_target="$(readlink "$droid_service_dst")"
  fi
  if [[ "$installed_target" != "$droid_service_src" ]]; then
    ln -sfnv "$droid_service_src" "$droid_service_dst"
  fi

  systemctl --user daemon-reload
  systemctl --user enable "$droid_service_name"
  manage_systemd_service=true

  if ! systemctl --user is-active --quiet "$droid_service_name"; then
    return
  fi

  main_pid="$(systemctl --user show "$droid_service_name" --property=MainPID --value)"
  if [[ "$main_pid" == 0 || ! -r "/proc/$main_pid/environ" ]]; then
    systemd_service_restart_required=true
    return
  fi

  desired_path="$(sed -n 's/^Environment=PATH=//p' "$droid_service_src")"
  desired_path="${desired_path//%h/$HOME}"
  command_line="$(tr '\0' ' ' <"/proc/$main_pid/cmdline" 2>/dev/null || true)"
  working_directory="$(readlink "/proc/$main_pid/cwd" 2>/dev/null || true)"

  if ! grep -z -F -x -q "SHELL=$droid_shell" "/proc/$main_pid/environ" ||
    ! grep -z -F -x -q "TERMINAL_SHELL=$droid_shell" "/proc/$main_pid/environ" ||
    ! grep -z -F -x -q "PATH=$desired_path" "/proc/$main_pid/environ" ||
    [[ ! "/proc/$main_pid/exe" -ef "$droid_bin" ]] ||
    [[ "$working_directory" != "$HOME" ]] ||
    [[ "$command_line" != "$droid_bin daemon --remote-access " ]]; then
    systemd_service_restart_required=true
  fi
}

install_or_update_droid() {
  local current_version=""
  local droid_pids
  local latest_version
  local process_status
  local installer_script

  if [[ ! -x "$droid_bin" ]]; then
    if droid_pids="$(get_droid_pids)"; then
      echo "Cannot install Droid while Droid processes are running: $droid_pids" >&2
      return 1
    else
      process_status=$?
      if [[ "$process_status" -ne 1 ]]; then
        echo "Cannot determine whether Droid is running; refusing to install." >&2
        return 1
      fi
    fi

    if ! command -v curl >/dev/null 2>&1; then
      echo "Cannot install Droid: curl is not available." >&2
      return 1
    fi

    if ! managed_service_is_stopped; then
      echo "Cannot install Droid while the systemd service is not fully stopped." >&2
      return 1
    fi

    run_installer
    return
  fi

  current_version="$(installed_version || true)"
  if ! command -v curl >/dev/null 2>&1; then
    echo "Cannot check for Droid updates: curl is not available." >&2
    echo "Droid installed: ${current_version:-unknown}"
    return
  fi

  if ! installer_script="$(curl -fsSL "$installer_url")"; then
    echo "Cannot check for Droid updates; leaving existing installation unchanged." >&2
    echo "Droid installed: ${current_version:-unknown}"
    return
  fi

  latest_version="$(printf '%s\n' "$installer_script" | installer_version)"
  if [[ -z "$latest_version" ]]; then
    echo "Cannot determine the latest Droid version; leaving existing installation unchanged." >&2
    echo "Droid installed: ${current_version:-unknown}"
    return
  fi

  if [[ -n "$current_version" && "$current_version" == "$latest_version" ]]; then
    echo "Droid is current: $current_version"
    return
  fi

  # The upstream installer force-kills running Droid processes before replacement.
  if droid_pids="$(get_droid_pids)"; then
    echo "Droid update deferred: processes are active (installed ${current_version:-unknown}, latest $latest_version)." >&2
    echo "Stop Droid when no agents are attached, then rerun this installer."
    return
  else
    process_status=$?
    if [[ "$process_status" -ne 1 ]]; then
      echo "Cannot determine whether Droid is running; update deferred." >&2
      return
    fi
  fi

  if ! managed_service_is_stopped; then
    echo "Droid update deferred: the systemd service is not fully stopped." >&2
    echo "When no agents are attached, stop $droid_service_name and rerun this installer."
    return
  fi

  echo "Updating Droid from ${current_version:-unknown} to $latest_version."
  run_installer "$installer_script" "$latest_version"
}

finish_systemd_service() {
  local droid_pids
  local process_status

  if [[ "$manage_systemd_service" != true ]]; then
    return
  fi

  if [[ ! -x "$droid_bin" ]]; then
    echo "Cannot start Droid systemd service: $droid_bin is not executable." >&2
    return 1
  fi

  if systemctl --user is-active --quiet "$droid_service_name"; then
    # The relay has no drain operation, so do not infer idleness and restart here.
    if [[ "$systemd_service_restart_required" == true ]]; then
      echo "Droid service restart required; the active service was left untouched." >&2
      echo "When no agents are attached, run: systemctl --user restart $droid_service_name" >&2
    fi
  else
    if droid_pids="$(get_droid_pids)"; then
      echo "Droid systemd service was not started because Droid processes are active: $droid_pids" >&2
      return 1
    else
      process_status=$?
      if [[ "$process_status" -ne 1 ]]; then
        echo "Droid systemd service was not started because running processes could not be checked." >&2
        return 1
      fi
    fi

    systemctl --user start "$droid_service_name"
  fi

  systemctl --user --no-pager --full status "$droid_service_name"
}

finish_on_exit() {
  local exit_status=$?
  local finish_status

  trap - EXIT
  set +e
  finish_systemd_service
  finish_status=$?

  if [[ "$exit_status" -eq 0 ]]; then
    exit_status=$finish_status
  fi

  exit "$exit_status"
}

trap finish_on_exit EXIT
prepare_systemd_service
install_or_update_droid
