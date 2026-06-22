#!/usr/bin/env bash
set -euo pipefail

installer_url="https://app.factory.ai/cli"
droid_bin="$HOME/.local/bin/droid"

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
