#!/usr/bin/env bash
set -euo pipefail

package='desloppify[full]'
interfaces=(claude codex)

if ! command -v pipx >/dev/null 2>&1; then
  echo "Cannot install desloppify: pipx is not available." >&2
  exit 1
fi

if pipx list --short 2>/dev/null | grep -q '^desloppify '; then
  pipx runpip desloppify install --upgrade "$package"
else
  pipx install "$package"
fi

if command -v desloppify >/dev/null 2>&1; then
  desloppify_bin="$(command -v desloppify)"
elif [ -x "$HOME/.local/bin/desloppify" ]; then
  desloppify_bin="$HOME/.local/bin/desloppify"
else
  echo "Cannot update desloppify skills: desloppify is not available." >&2
  exit 1
fi

for interface in "${interfaces[@]}"; do
  (cd "$HOME" && "$desloppify_bin" update-skill "$interface")
done
