#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly script_dir
readonly config_dir="$HOME/.pi/agent"
readonly models_source="$script_dir/models.json"
readonly models_file="$config_dir/models.json"
readonly settings_source="$script_dir/settings.json"
readonly settings_file="$config_dir/settings.json"

link_models() {
  if [[ -L "$models_file" ]]; then
    ln -sfn "$models_source" "$models_file"
    return
  fi

  if [[ -e "$models_file" ]]; then
    if ! cmp -s "$models_file" "$models_source"; then
      echo "Cannot configure Pi: $models_file differs from $models_source." >&2
      exit 1
    fi

    rm "$models_file"
  fi

  ln -s "$models_source" "$models_file"
}

merge_settings() {
  local settings_temp

  if [[ ! -e "$settings_file" ]]; then
    cp "$settings_source" "$settings_file"
    return
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "Cannot configure Pi: jq is not available." >&2
    exit 1
  fi

  settings_temp="$(mktemp "${settings_file}.XXXXXX")"
  if ! jq -s '.[0] * .[1]' "$settings_file" "$settings_source" >"$settings_temp"; then
    rm "$settings_temp"
    return 1
  fi

  chmod 0644 "$settings_temp"
  mv "$settings_temp" "$settings_file"
}

if ! command -v npm >/dev/null 2>&1; then
  echo "Cannot install Pi: npm is not available." >&2
  exit 1
fi

npm install -g --ignore-scripts @earendil-works/pi-coding-agent

mkdir -p "$config_dir"
link_models
merge_settings

if [[ ! -f "$config_dir/auth.json" ]]; then
  echo "Pi is configured. Run pi, then /login nvidia-inference to authenticate."
fi
