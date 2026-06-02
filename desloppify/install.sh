#!/usr/bin/env bash
set -euo pipefail

package='desloppify[full]'

if ! command -v pipx >/dev/null 2>&1; then
  echo "Cannot install desloppify: pipx is not available." >&2
  exit 1
fi

if pipx list --short 2>/dev/null | grep -q '^desloppify '; then
  pipx upgrade "$package"
else
  pipx install "$package"
fi
