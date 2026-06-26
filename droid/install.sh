#!/usr/bin/env bash
set -euo pipefail

installer_url="https://app.factory.ai/cli"
droid_bin="$HOME/.local/bin/droid"
dotfiles_dir="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
droid_systemd_host="devvm-rlevesque.c.nv-hwlpu-20260103060253.internal"
droid_service_name="droid-daemon.service"
droid_service_src="$dotfiles_dir/droid/$droid_service_name"
droid_service_dir="$HOME/.config/systemd/user"
droid_service_dst="$droid_service_dir/$droid_service_name"
current_host="$(hostname)"
log_file="${TMPDIR:-/tmp}/droid-install.log"

if ! command -v curl >/dev/null 2>&1; then
  echo "Cannot install droid: curl is not available." >&2
  exit 1
fi

run_installer() {
  curl -fsSL "$installer_url" | sh

  if [[ ! -x "$droid_bin" ]]; then
    echo "Cannot install droid: $droid_bin was not created." >&2
    exit 1
  fi

  "$droid_bin" --version
}

installed_version() {
  "$droid_bin" --version 2>/dev/null | tr -d '[:space:]'
}

installer_version() {
  sed -n 's/^VER="\([^"]*\)".*/\1/p' | head -n 1
}

droid_is_running() {
  command -v pgrep >/dev/null 2>&1 && pgrep -x droid >/dev/null 2>&1
}

start_background_update() {
  local installer_script="$1"
  local installer_file

  installer_file="$(mktemp "${TMPDIR:-/tmp}/droid-installer.XXXXXX")"
  printf '%s\n' "$installer_script" >"$installer_file"

  nohup sh -c "sh \"\$1\"; status=\$?; rm -f \"\$1\"; exit \"\$status\"" sh "$installer_file" >"$log_file" 2>&1 </dev/null &
}

if [[ ! -x "$droid_bin" ]]; then
  if droid_is_running; then
    echo "Droid is running; skipping install to avoid killing active sessions."
    exit 0
  fi

  run_installer
  exit 0
fi

current_version="$(installed_version || true)"
if ! installer_script="$(curl -fsSL "$installer_url")"; then
  echo "Cannot check for droid updates; leaving existing installation unchanged." >&2
  "$droid_bin" --version
  exit 0
fi

latest_version="$(printf '%s\n' "$installer_script" | installer_version)"
if [[ -n "$current_version" && -n "$latest_version" && "$current_version" == "$latest_version" ]]; then
  echo "Droid is current: $current_version"
  exit 0
fi

if ! command -v pgrep >/dev/null 2>&1; then
  echo "Cannot check for running droids; skipping update to avoid killing active sessions." >&2
  "$droid_bin" --version
  exit 0
fi

if droid_is_running; then
  echo "Droid is running; skipping update to avoid killing active sessions."
  "$droid_bin" --version
  exit 0
fi

if [[ -z "$latest_version" ]]; then
  echo "Cannot determine the latest droid version; leaving existing installation unchanged." >&2
  "$droid_bin" --version
  exit 0
fi

echo "Updating droid from ${current_version:-unknown} to $latest_version in the background."
start_background_update "$installer_script"
echo "Update log: $log_file"
"$droid_bin" --version

if [[ "$(uname)" != "Linux" ]]; then
  exit 0
fi

if [[ "$current_host" != "$droid_systemd_host" ]]; then
  echo "Skipping Droid systemd service: this host is $current_host, expected $droid_systemd_host."
  exit 0
fi

if ! command -v systemctl >/dev/null 2>&1; then
  echo "Skipping Droid systemd service: systemctl is not available." >&2
  exit 0
fi

mkdir -p "$droid_service_dir"
ln -sfv "$droid_service_src" "$droid_service_dst"

systemctl --user daemon-reload
systemctl --user enable "$droid_service_name"
systemctl --user restart "$droid_service_name"
systemctl --user --no-pager --full status "$droid_service_name"
