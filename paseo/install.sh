#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
settings_dir="${PASEO_HOME:-$HOME/.paseo}/plugin-state/paseo-review"

mkdir -p "$settings_dir"
ln -sfnv "$SCRIPT_DIR/review-settings.json" "$settings_dir/settings.json"
