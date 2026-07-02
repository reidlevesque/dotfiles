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
droid_version_updated=false

run_installer() {
  local new_version

  curl -fsSL "$installer_url" | sh

  if [[ ! -x "$droid_bin" ]]; then
    echo "Cannot install Droid: $droid_bin was not created." >&2
    return 1
  fi

  new_version="$(installed_version || true)"
  if [[ -z "$new_version" ]]; then
    echo "Cannot determine the installed Droid version." >&2
    return 1
  fi

  echo "Droid installed: $new_version"
}

installed_version() {
  "$droid_bin" --version 2>/dev/null | tr -d '[:space:]'
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
  local new_version
  local process_status
  local update_output
  local update_status

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
  if [[ -z "$current_version" ]]; then
    echo "Cannot determine the installed Droid version." >&2
    return 1
  fi

  if update_output="$("$droid_bin" update 2>&1)"; then
    update_status=0
  else
    update_status=$?
  fi

  if [[ "$update_status" -ne 0 && -n "$update_output" ]]; then
    printf '%s\n' "$update_output" >&2
  fi

  new_version="$(installed_version || true)"
  if [[ -z "$new_version" ]]; then
    echo "Cannot determine the installed Droid version after updating." >&2
    return 1
  fi

  if [[ "$current_version" == "$new_version" ]]; then
    if [[ "$update_status" -eq 0 ]]; then
      echo "Droid is up to date: $current_version"
    fi
    return "$update_status"
  fi

  droid_version_updated=true
  echo "Droid updated from $current_version to $new_version."
  return "$update_status"
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

  if [[ "$droid_version_updated" == true ]]; then
    if ! systemctl --user restart "$droid_service_name"; then
      return 1
    fi
  elif systemctl --user is-active --quiet "$droid_service_name"; then
    # The relay has no drain operation, so do not infer idleness and restart here.
    if [[ "$systemd_service_restart_required" == true ]]; then
      echo "Droid service restart required; the active service was left untouched." >&2
      echo "When no agents are attached, run: systemctl --user restart $droid_service_name" >&2
    fi
    return
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

    if ! systemctl --user start "$droid_service_name"; then
      return 1
    fi
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
