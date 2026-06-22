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

if ! command -v curl >/dev/null 2>&1; then
  echo "Cannot install droid: curl is not available." >&2
  exit 1
fi

curl -fsSL "$installer_url" | sh

if [[ ! -x "$droid_bin" ]]; then
  echo "Cannot install droid: $droid_bin was not created." >&2
  exit 1
fi

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
