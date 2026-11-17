#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template="$script_dir/settings/droid.json"
settings_dir="$HOME/.factory"
settings_file="$settings_dir/settings.json"

umask 077
mkdir -p "$settings_dir"

if [[ -L "$settings_file" ]]; then
  if [[ ! "$settings_file" -ef "$template" ]]; then
    echo "Cannot migrate Droid settings: $settings_file links to another file." >&2
    exit 1
  fi

  backup="$(mktemp "$settings_file.backup.XXXXXXXX")"
  cp "$settings_file" "$backup"
  echo "Backed up Droid settings to $backup"
fi

# Rename over the old symlink, never write through it into the tracked template.
temp_file="$(mktemp "$settings_dir/.settings.json.XXXXXXXX")"
trap 'rm -f "$temp_file"' EXIT

if [[ -f "$settings_file" ]]; then
  jq -e -s '
    if length == 2 and all(.[]; type == "object") then
      .[0] * .[1]
    else
      error("Droid settings and defaults must each contain one JSON object")
    end
  ' "$settings_file" "$template" >"$temp_file"
else
  jq -e -s '
    if length == 1 and (.[0] | type == "object") then
      .[0]
    else
      error("Droid defaults must contain one JSON object")
    end
  ' "$template" >"$temp_file"
fi

mv "$temp_file" "$settings_file"
echo "Merged portable Droid defaults into $settings_file"
